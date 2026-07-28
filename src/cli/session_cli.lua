-- Command dispatch for the machine session CLI.
--
-- Every command follows the same shape, and the shape IS the design:
--
--     read the journal -> replay it -> act -> append on success
--
-- Nothing is written back except journal lines, so a session cannot drift
-- from the sequence of decisions that produced it.

local core = require("src.core.game")
local view = require("src.core.view")
local session = require("src.cli.session")
local readout = require("src.cli.session_view")

local M = {}

local function out(text)
    io.write(text .. "\n")
end

local function fail(text)
    out("FAIL " .. text)
    return 2
end

-- Loads and replays. A journal that cannot be replayed is a bug worth
-- stopping on, not something to route around.
local function load_game()
    local log, err = session.read()
    if not log then
        return nil, nil, err
    end
    local game, events, failure = session.rebuild(log)
    if failure then
        return nil, nil, string.format(
            "replay failed at entry %d (%s): %s",
            failure.entry, failure.text, tostring(failure.error))
    end
    return log, game, nil, events
end

local function print_position(game)
    out(view.format(session.observe(game)))
end

--------------------------------------------------------------------------

local commands = {}

function commands.new(args)
    local seed = tonumber(args[1]) or 1
    local trumps = args[2] or "full"
    if trumps ~= "full" and trumps ~= "none" then
        return fail("trumps must be full or none")
    end
    local log = session.new_log(seed, trumps)
    local ok, err = session.write(log)
    if not ok then
        return fail(tostring(err))
    end
    local game = session.rebuild(log)
    out(string.format("session seed=%d trumps=%s", seed, trumps))
    print_position(game)
    return 0
end

function commands.drop()
    session.drop()
    out("session dropped")
    return 0
end

function commands.show()
    local _, game, err = load_game()
    if not game then
        return fail(tostring(err))
    end
    print_position(game)
    return 0
end

commands["do"] = function(args)
    if #args == 0 then
        return fail("do needs at least one action")
    end
    local log, game, err = load_game()
    if not game then
        return fail(tostring(err))
    end
    for _, text in ipairs(args) do
        local action, parse_err = session.parse_action(game, text)
        if not action then
            print_position(game)
            return fail(text .. ": " .. tostring(parse_err))
        end
        local result = core.apply_action(game, action)
        -- A missing result is a refusal that did not bother to build a
        -- transition. Reading it as success is how an illegal move gets into
        -- the journal and quietly does nothing.
        local apply_err = result == nil
            and "refused_without_transition"
            or (result.summary and result.summary.error)
        if apply_err then
            print_position(game)
            return fail(text .. ": " .. tostring(apply_err))
        end
        session.append(log, "do", text)
        out("OK " .. text)
    end
    print_position(game)
    return 0
end

function commands.plant(args)
    local card_id, zone_name = args[1], args[2]
    if not card_id or not zone_name then
        return fail("plant needs <card> <zone> [slot] [info_state]")
    end
    local log, game, err = load_game()
    if not game then
        return fail(tostring(err))
    end
    out(readout.DEBUG_BANNER)
    local report, plant_err = session.plant(
        game, card_id, zone_name, tonumber(args[3]), args[4])
    if not report then
        return fail(tostring(plant_err))
    end
    out(session.format_plant(report))
    local text = table.concat({card_id, zone_name, args[3] or "", args[4] or ""}, " ")
    session.append(log, "plant", (text:gsub("%s+$", "")))
    print_position(game)
    return 0
end

function commands.fits()
    local _, game, err = load_game()
    if not game then
        return fail(tostring(err))
    end
    out(readout.format_fits(readout.fits(game)))
    return 0
end

function commands.metrics()
    local _, game, err = load_game()
    if not game then
        return fail(tostring(err))
    end
    out(readout.format_metrics(readout.metrics(game)))
    return 0
end

function commands.trace(args)
    local log, game, err, events = load_game()
    if not game then
        return fail(tostring(err))
    end
    local _ = log
    out(readout.format_trace(readout.group_turns(events), tonumber(args[1])))
    return 0
end

-- Reads the journal directly instead of replaying it first. A journal that no
-- longer replays is precisely when undo is needed, so making undo depend on a
-- clean replay would lock the session shut at the one moment it must open.
function commands.undo(args)
    local count = tonumber(args[1]) or 1
    local log, err = session.read()
    if not log then
        return fail(tostring(err))
    end
    local removed = 0
    for _ = 1, count do
        if #log.entries == 0 then
            break
        end
        table.remove(log.entries)
        removed = removed + 1
    end
    session.write(log)
    local game, _, failure = session.rebuild(log)
    if failure then
        return fail("replay after undo failed: " .. tostring(failure.error))
    end
    out(string.format("undid %d entr%s", removed, removed == 1 and "y" or "ies"))
    print_position(game)
    return 0
end

function commands.save(args)
    local name = args[1]
    if not name then
        return fail("save needs a name")
    end
    local log, _, err = load_game()
    if not log then
        return fail(tostring(err))
    end
    session.write(log, name)
    out(string.format("saved %d entries to %s", #log.entries, session.path(name)))
    return 0
end

function commands.load(args)
    local name = args[1]
    if not name then
        return fail("load needs a name")
    end
    local log, err = session.read(name)
    if not log then
        return fail(tostring(err))
    end
    session.write(log)
    local game, _, failure = session.rebuild(log)
    if failure then
        return fail("replay failed: " .. tostring(failure.error))
    end
    out(string.format("loaded %d entries from %s", #log.entries, session.path(name)))
    print_position(game)
    return 0
end

function commands.log()
    local log, err = session.read()
    if not log then
        return fail(tostring(err))
    end
    out(string.format("# seed=%d trumps=%s", log.seed, log.trumps))
    for index, entry in ipairs(log.entries) do
        out(string.format("%3d %s %s", index, entry.kind, entry.text))
    end
    return 0
end

function commands.card(args)
    local card_id = args[1]
    if not card_id then
        return fail("card needs an id")
    end
    local _, game, err = load_game()
    if not game then
        return fail(tostring(err))
    end
    out(readout.DEBUG_BANNER)
    local text, lookup_err = readout.card_lookup(game, card_id)
    if not text then
        return fail(tostring(lookup_err))
    end
    out(text)
    return 0
end

function commands.find(args)
    local pair = args[1]
    if not pair then
        return fail("find needs <OP_A>/<OP_B>")
    end
    local op_a, op_b = pair:match("^(%u+)/(%u+)$")
    if not op_a then
        return fail("find needs <OP_A>/<OP_B>")
    end
    if not readout.valid_operator(op_a) or not readout.valid_operator(op_b) then
        return fail("unknown operator in " .. pair)
    end
    local _, game, err = load_game()
    if not game then
        return fail(tostring(err))
    end
    out(readout.DEBUG_BANNER)
    local matches = readout.find_pair(game, op_a, op_b)
    if #matches == 0 then
        out("(no card with that pair)")
        return 0
    end
    for _, card_id in ipairs(matches) do
        out((readout.card_lookup(game, card_id)))
    end
    return 0
end

--------------------------------------------------------------------------

function M.run(args)
    local name = args[1]
    if not name or not commands[name] then
        out("session commands: new show do plant fits trace metrics undo save load log drop")
        out("card <id>   find <A>/<B>")
        return 1
    end
    return commands[name]({table.unpack(args, 2)})
end

return M
