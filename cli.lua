local core = require("src.core.api")
local interaction_lib = require("src.core.interaction")
local sim = require("src.sim.runner")

local function usage()
    io.write([[
Usage:
  lua cli.lua snapshot
  lua cli.lua interaction
  lua cli.lua advance
  lua cli.lua events
  lua cli.lua draw
  lua cli.lua latent_trump_closure
  lua cli.lua scenario <name> [seed]
  lua cli.lua autoplay [seed] [steps]
  lua cli.lua headless [seed] [steps]
  lua cli.lua play [seed]
  lua cli.lua smoke [seed] [turns]
  lua cli.lua bench <name|smoke|autoplay|headless> [count] [seed]
]])
end

local function action_desc(action)
    if not action then
        return "-"
    end
    local desc = action.kind or "-"
    if action.slot then
        return desc .. ":" .. tostring(action.slot)
    end
    if action.card_id then
        return desc .. ":" .. tostring(action.card_id)
    end
    if action.operator then
        return desc .. ":" .. tostring(action.operator)
    end
    if action.target then
        return desc .. ":" .. tostring(action.target.card_id or action.target.slot or "-")
    end
    return desc
end

local function print_failure(result)
    io.write("FAIL\n")
    if result.stage then
        io.write("stage=" .. result.stage .. "\n")
    end
    if result.error then
        io.write("error=" .. tostring(result.error.name) .. "\n")
        io.write("details=" .. tostring(result.error.details) .. "\n")
    end
    if result.snapshot then
        io.write(result.snapshot .. "\n")
    end
end

local function print_success(result)
    io.write("OK\n")
    if result.transition then
        io.write("transition=" .. tostring(result.transition.kind) .. "\n")
    end
    if result.snapshot then
        io.write(result.snapshot .. "\n")
    end
end

local command = arg[1]
if not command then
    usage()
    os.exit(1)
end

if command == "scenario" then
    local name = arg[2]
    local seed = tonumber(arg[3]) or 1
    if not name then
        usage()
        os.exit(1)
    end
    local result = sim.run_scenario(name, seed)
    if result.ok then
        print_success(result)
        os.exit(0)
    end
    print_failure(result)
    os.exit(2)
end

if command == "smoke" then
    local seed = tonumber(arg[2]) or 1
    local turns = tonumber(arg[3]) or 8
    local result = sim.run_smoke(seed, turns)
    if result.ok then
        io.write("OK\n")
        io.write("turns=" .. #result.turns .. "\n")
        io.write(result.snapshot .. "\n")
        os.exit(0)
    end
    print_failure(result)
    os.exit(2)
end

if command == "autoplay" then
    local seed = tonumber(arg[2]) or 1
    local steps = tonumber(arg[3]) or 32
    local result = sim.run_autoplay(seed, steps)
    if result.ok then
        io.write("OK\n")
        io.write("steps=" .. #result.transcript .. "\n")
        io.write("stop_reason=" .. tostring(result.stop_reason or "-") .. "\n")
        for _, entry in ipairs(result.transcript) do
            io.write(string.format("%02d phase=%s action=%s\n", entry.step, tostring(entry.phase), action_desc(entry.action)))
        end
        io.write(result.snapshot .. "\n")
        os.exit(0)
    end
    print_failure(result)
    os.exit(2)
end

if command == "headless" then
    local seed = tonumber(arg[2]) or 1
    local steps = tonumber(arg[3]) or 256
    local result = sim.run_headless_game(seed, steps)
    if result.ok then
        io.write("OK\n")
        io.write("steps=" .. #result.transcript .. "\n")
        io.write("stop_reason=" .. tostring(result.stop_reason or "-") .. "\n")
        for _, entry in ipairs(result.transcript) do
            io.write(string.format("%02d phase=%s action=%s\n", entry.step, tostring(entry.phase), action_desc(entry.action)))
        end
        io.write(result.snapshot .. "\n")
        if result.interaction then
            io.write(interaction_lib.format(result.interaction) .. "\n")
        end
        os.exit(0)
    end
    print_failure(result)
    os.exit(2)
end

if command == "bench" then
    local mode = arg[2]
    local count = tonumber(arg[3]) or 100
    local seed = tonumber(arg[4]) or 1
    if not mode then
        usage()
        os.exit(1)
    end
    local result = sim.bench(mode, count, seed)
    io.write(string.format(
        "mode=%s total=%d passed=%d skipped=%d failed=%d\n",
        result.mode,
        result.total,
        result.passed,
        result.skipped or 0,
        result.failed
    ))
    if result.first_failure then
        io.write("first_failure_seed=" .. result.first_failure.seed .. "\n")
        print_failure(result.first_failure.result)
        os.exit(2)
    end
    os.exit(0)
end

local function print_state(game)
    io.write(core.snapshot(game) .. "\n")
    io.write(core.interaction_text(game) .. "\n")
end

local function legal_target_descriptions(ix)
    local targets = ix.legal and ix.legal.targets or {}
    local out = {}
    for _, slot in ipairs(targets.slots or {}) do
        out[#out + 1] = string.format("slot:%d", slot)
    end
    for _, card_id in ipairs(targets.cards or {}) do
        out[#out + 1] = string.format("card:%s", card_id)
    end
    return table.concat(out, ", ")
end

local function print_help()
    io.write([[
Commands:
  show                     snapshot + interaction
  ix                       interaction only
  snapshot                 snapshot only
  events                   drain and print events
  advance                  apply advance
  draw                      draw once
  commit <slot>            commit manifest slot
  hand <card_id>           arm hand card
  op <name>                arm operator
  target <slot|card_id>    arm target by slot number or card id
  auto [steps]             autoplay from current state
  help                     show this help
  quit                     exit
]])
end

local function choose_cli_auto_action(ix)
    local targets = ix.legal and ix.legal.targets or {}

    if ix.phase == "await_commit" then
        local slot = ix.legal.commit_slots[1]
        if slot then
            return {kind = "commit_manifest", slot = slot}
        end
        return nil
    end

    if ix.phase == "await_hand" then
        if ix.armed.hand_card_id and ix.advance and ix.advance.enabled then
            return {kind = "advance"}
        end
        local card_id = ix.legal.hand_cards[1]
        if card_id then
            return {kind = "arm_hand", card_id = card_id}
        end
        return nil
    end

    if ix.phase == "await_operator" then
        if ix.armed.operator and ix.advance and ix.advance.enabled then
            return {kind = "advance"}
        end
        local operator = ix.legal.operators[1]
        if operator then
            return {kind = "arm_operator", operator = operator}
        end
        if ix.advance and ix.advance.enabled then
            return {kind = "advance"}
        end
        return nil
    end

    if ix.phase == "await_target" then
        if ix.advance and ix.advance.enabled then
            return {kind = "advance"}
        end
        if targets.slots and #targets.slots > 0 then
            return {
                kind = "arm_target",
                target = {
                    kind = "slot",
                    zone = "manifest",
                    slot = targets.slots[1],
                },
            }
        end
        if targets.cards and #targets.cards > 0 then
            return {
                kind = "arm_target",
                target = {
                    kind = "card",
                    card_id = targets.cards[1],
                },
            }
        end
        return nil
    end

    if ix.phase == "await_trump" and ix.advance and ix.advance.enabled then
        return {kind = "advance"}
    end

    return nil
end

local function autoplay_current(game, steps)
    local transcript = {}
    local max_steps = steps or 16
    local stop_reason = "step_limit"

    for i = 1, max_steps do
        local ix = core.interaction(game)
        local action = choose_cli_auto_action(ix)
        transcript[#transcript + 1] = {
            step = i,
            phase = ix.phase,
            action = action,
        }
        if not action then
            stop_reason = "no_action"
            break
        end
        local result = core.apply_action(game, action)
        if result.summary and result.summary.error then
            stop_reason = tostring(result.summary.error)
            break
        end
    end

    return {
        transcript = transcript,
        stop_reason = stop_reason,
    }
end

local function run_play(seed)
    local game = core.new()
    core.start_game(game, {rng = require("src.sim.rng").from_seed(seed or 1)})
    print_state(game)
    print_help()

    while true do
        io.write("> ")
        local line = io.read("*line")
        if not line then
            return 0
        end

        local parts = {}
        for token in string.gmatch(line, "%S+") do
            parts[#parts + 1] = token
        end
        local cmd = parts[1]

        if not cmd or cmd == "" then
            -- no-op
        elseif cmd == "quit" or cmd == "exit" then
            return 0
        elseif cmd == "help" then
            print_help()
        elseif cmd == "show" then
            print_state(game)
        elseif cmd == "ix" then
            io.write(core.interaction_text(game) .. "\n")
        elseif cmd == "snapshot" then
            io.write(core.snapshot(game) .. "\n")
        elseif cmd == "events" then
            local events = core.drain_events(game)
            for _, event in ipairs(events) do
                io.write(string.format("%s\n", event.type))
            end
        elseif cmd == "advance" then
            local result = core.apply_action(game, {kind = "advance"})
            if result.summary and result.summary.error then
                io.write("FAIL error=" .. tostring(result.summary.error) .. "\n")
            else
                io.write("OK " .. tostring(result.kind) .. "\n")
            end
            io.write(core.interaction_text(game) .. "\n")
        elseif cmd == "draw" then
            local result = core.apply_action(game, {kind = "draw"})
            if result.summary and result.summary.error then
                io.write("FAIL error=" .. tostring(result.summary.error) .. "\n")
            else
                io.write("OK " .. tostring(result.kind) .. "\n")
            end
            io.write(core.interaction_text(game) .. "\n")
        elseif cmd == "commit" then
            local slot = tonumber(parts[2])
            local result = core.apply_action(game, {kind = "commit_manifest", slot = slot})
            if result.summary and result.summary.error then
                io.write("FAIL error=" .. tostring(result.summary.error) .. "\n")
            else
                io.write("OK " .. tostring(result.kind) .. "\n")
            end
            io.write(core.interaction_text(game) .. "\n")
        elseif cmd == "hand" then
            local card_id = parts[2]
            local result = core.apply_action(game, {kind = "arm_hand", card_id = card_id})
            if result.summary and result.summary.error then
                io.write("FAIL error=" .. tostring(result.summary.error) .. "\n")
            else
                io.write("OK " .. tostring(result.kind) .. "\n")
            end
            io.write(core.interaction_text(game) .. "\n")
        elseif cmd == "op" then
            local operator = parts[2]
            local result = core.apply_action(game, {kind = "arm_operator", operator = operator})
            if result.summary and result.summary.error then
                io.write("FAIL error=" .. tostring(result.summary.error) .. "\n")
            else
                io.write("OK " .. tostring(result.kind) .. "\n")
            end
            io.write(core.interaction_text(game) .. "\n")
        elseif cmd == "target" then
            local raw = parts[2]
            local ix = core.interaction(game)
            local target
            if raw and tonumber(raw) and ix.legal and ix.legal.targets and ix.legal.targets.slots then
                target = {
                    kind = "slot",
                    zone = "manifest",
                    slot = tonumber(raw),
                }
            elseif raw then
                target = {
                    kind = "card",
                    card_id = raw,
                }
            end
            local result = core.apply_action(game, {kind = "arm_target", target = target})
            if result.summary and result.summary.error then
                io.write("FAIL error=" .. tostring(result.summary.error) .. "\n")
                io.write("legal_targets=" .. legal_target_descriptions(ix) .. "\n")
            else
                io.write("OK " .. tostring(result.kind) .. "\n")
            end
            io.write(core.interaction_text(game) .. "\n")
        elseif cmd == "auto" then
            local steps = tonumber(parts[2]) or 16
            local result = autoplay_current(game, steps)
            io.write("OK steps=" .. tostring(#result.transcript) .. " stop_reason=" .. tostring(result.stop_reason or "-") .. "\n")
            for _, entry in ipairs(result.transcript) do
                io.write(string.format("%02d phase=%s action=%s\n", entry.step, tostring(entry.phase), action_desc(entry.action)))
            end
            io.write(core.interaction_text(game) .. "\n")
        else
            io.write("Unknown command. Type 'help'.\n")
        end
    end
end

local game = core.new()
core.start_game(game)

if command == "setup" or command == "snapshot" then
    io.write(core.snapshot(game) .. "\n")
    os.exit(0)
end

if command == "play" then
    local seed = tonumber(arg[2]) or 1
    local exit_code = run_play(seed)
    os.exit(exit_code)
end

if command == "interaction" then
    io.write(core.interaction_text(game) .. "\n")
    os.exit(0)
end

if command == "advance" then
    local result = core.advance(game)
    if result and result.summary and not result.summary.error then
        io.write("OK\n")
        io.write("transition=" .. tostring(result.kind) .. "\n")
        io.write(core.snapshot(game) .. "\n")
        os.exit(0)
    end
    io.write("FAIL\n")
    io.write("error=" .. tostring(result and result.summary and result.summary.error or "advance_failed") .. "\n")
    io.write(core.snapshot(game) .. "\n")
    os.exit(2)
end

if command == "events" then
    local events = core.drain_events(game)
    for _, event in ipairs(events) do
        io.write(string.format("%s\n", event.type))
    end
    os.exit(0)
end

if command == "draw" then
    core.draw_to_hand(game)
    io.write(core.snapshot(game) .. "\n")
    os.exit(0)
end

if command == "latent_trump_closure" then
    local result = sim.run_scenario("latent_trump_closure", 1)
    if result.ok then
        local info = result.scenario or {}
        io.write(string.format(
            "slot=%d manifest_before=%s latent_before=%s hand=%s\n",
            info.slot or -1,
            info.manifest_before or "-",
            info.latent_before or "-",
            info.hand_card_id or "-"
        ))
        if info.result and info.result.events then
            for _, event in ipairs(info.result.events) do
                io.write(string.format("event=%s\n", event.type))
            end
        end
        io.write(result.snapshot .. "\n")
        os.exit(0)
    end
    print_failure(result)
    os.exit(2)
end

usage()
os.exit(1)
