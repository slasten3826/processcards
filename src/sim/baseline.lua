-- Trace baselines: the safety net for refactoring a core with no test suite.
--
-- The core is deterministic from a seed and emits an ordered event stream.
-- So the cheapest correctness statement available is:
--
--     same seed, same policy  ->  same sequence of event types
--
-- Baselines are written as plain text, one event per line, so that a change
-- in behaviour shows up as a readable git diff instead of an opaque blob.
--
-- Usage:
--     lua cli.lua baseline record     writes docs/../baselines/*.txt
--     lua cli.lua baseline check      compares current behaviour to them
--
-- A divergence is not automatically a failure. It is a question: was this
-- change intended? Intended changes are recorded by re-running record.

local core = require("src.core.game")
local runner = require("src.sim.runner")
local rng = require("src.sim.rng")
local view = require("src.core.view")
local playtest = require("src.sim.playtest")

local M = {}

M.dir = "baselines"

-- Fixed matrix. trump_free is the pure 100-minor machine: enabled_trumps = {}
-- removes every trump from the deck, so minor-machine work can be measured
-- without any trump interference.
M.matrix = {
    {name = "minor_headless", mode = "headless", seeds = {1, 2, 3, 4, 5}, steps = 200, trumps = "none"},
    {name = "minor_survival", mode = "survival", seeds = {1, 2, 3, 4, 5}, steps = 200, trumps = "none"},
    {name = "full_headless", mode = "headless", seeds = {1, 2, 3, 4, 5}, steps = 200, trumps = "full"},
    {name = "full_survival", mode = "survival", seeds = {1, 2, 3, 4, 5}, steps = 200, trumps = "full"},
}

local function enabled_for(trumps)
    if trumps == "none" then
        return {}
    end
    return nil
end

-- The runner builds its own games, so for trump-free runs we drive the core
-- directly with the same protocol the runner uses.
local function run_one(mode, seed, steps, trumps)
    local game = core.new()
    core.start_game(game, {
        rng = rng.from_seed(seed),
        enabled_trumps = enabled_for(trumps),
    })

    local types = {}
    for _ = 1, steps do
        local actions = core.enumerate_legal_actions(game)
        if #actions == 0 then
            break
        end

        -- The first version of this used "advance, else first legal", which
        -- never reached the operator phase at all. That made the baselines
        -- insensitive to operator changes: a FLOW rewrite left every trace
        -- identical, which is a false green. Both modes now drive through the
        -- same phase-driven policy the playtest uses, so operators are
        -- actually played.
        local observation = view.observe(game, {
            interaction = core.interaction(game),
            legal_action_count = #actions,
        })
        local action = playtest.protocol_policy(observation, actions)
        if mode == "headless" then
            action = action or actions[1]
        else
            action = action or actions[#actions]
        end

        core.apply_action(game, action)
        for _, event in ipairs(core.drain_events(game)) do
            types[#types + 1] = event.type
        end
    end

    return types
end

function M.collect()
    local out = {}
    for _, entry in ipairs(M.matrix) do
        for _, seed in ipairs(entry.seeds) do
            local key = string.format("%s_seed%d", entry.name, seed)
            out[key] = run_one(entry.mode, seed, entry.steps, entry.trumps)
        end
    end
    return out
end

local function path_for(key)
    return string.format("%s/%s.txt", M.dir, key)
end

local function sorted_keys(map)
    local keys = {}
    for key in pairs(map) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

function M.record()
    os.execute("mkdir -p " .. M.dir)
    local data = M.collect()
    local written = 0
    for _, key in ipairs(sorted_keys(data)) do
        local file, err = io.open(path_for(key), "w")
        if not file then
            return nil, err
        end
        file:write("# " .. key .. "\n")
        for _, event_type in ipairs(data[key]) do
            file:write(event_type .. "\n")
        end
        file:close()
        written = written + 1
    end
    return written
end

local function load_baseline(key)
    local file = io.open(path_for(key), "r")
    if not file then
        return nil
    end
    local types = {}
    for line in file:lines() do
        if line:sub(1, 1) ~= "#" then
            types[#types + 1] = line
        end
    end
    file:close()
    return types
end

function M.check()
    local data = M.collect()
    local report = {
        checked = 0,
        missing = {},
        diverged = {},
        matched = 0,
    }

    for _, key in ipairs(sorted_keys(data)) do
        local recorded = load_baseline(key)
        report.checked = report.checked + 1
        if not recorded then
            report.missing[#report.missing + 1] = key
        else
            local current = data[key]
            local first_diff = nil
            local limit = math.max(#recorded, #current)
            for index = 1, limit do
                if recorded[index] ~= current[index] then
                    first_diff = {
                        index = index,
                        expected = recorded[index] or "<end>",
                        actual = current[index] or "<end>",
                    }
                    break
                end
            end
            if first_diff then
                report.diverged[#report.diverged + 1] = {
                    key = key,
                    index = first_diff.index,
                    expected = first_diff.expected,
                    actual = first_diff.actual,
                    recorded_length = #recorded,
                    current_length = #current,
                }
            else
                report.matched = report.matched + 1
            end
        end
    end

    report.ok = #report.diverged == 0 and #report.missing == 0
    return report
end

function M.format(report)
    local lines = {}
    lines[#lines + 1] = "TRACE BASELINE CHECK"
    lines[#lines + 1] = string.format("runs checked   %d", report.checked)
    lines[#lines + 1] = string.format("matched        %d", report.matched)
    lines[#lines + 1] = string.format("diverged       %d", #report.diverged)
    lines[#lines + 1] = string.format("missing        %d", #report.missing)
    for _, key in ipairs(report.missing) do
        lines[#lines + 1] = "  missing: " .. key
    end
    for _, entry in ipairs(report.diverged) do
        lines[#lines + 1] = string.format(
            "  %s: event %d expected %s got %s  (len %d -> %d)",
            entry.key, entry.index, entry.expected, entry.actual,
            entry.recorded_length, entry.current_length)
    end
    lines[#lines + 1] = report.ok and "BASELINE OK" or "BASELINE DIVERGED"
    return table.concat(lines, "\n")
end

return M
