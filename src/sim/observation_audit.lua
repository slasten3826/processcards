-- Audit: does the player-facing observation leak hidden card identity?
--
-- A card id encodes its operators (cards.lua derives op_a / op_b from the
-- index inside "MINOR-<n>" and "TRUMP-<n>"). So the leak test is:
--
--     for every card with info_state == "hidden",
--     its id must not appear anywhere in the observation
--
-- The audit also runs a CONTROL over inspect.snapshot, which is expected to
-- FAIL. An audit that cannot detect a known leak proves nothing.

local core = require("src.core.game")
local inspect = require("src.core.inspect")
local view = require("src.core.view")
local rng = require("src.sim.rng")

local M = {}

local function hidden_ids(state)
    local out = {}
    for id, card in pairs(state.cards) do
        if card.info_state == "hidden" then
            out[#out + 1] = id
        end
    end
    return out
end

-- Collect every string that appears anywhere in a nested table, including keys.
local function collect_strings(value, sink, seen)
    if type(value) == "string" then
        sink[value] = true
        return
    end
    if type(value) ~= "table" then
        return
    end
    seen = seen or {}
    if seen[value] then
        return
    end
    seen[value] = true
    for k, v in pairs(value) do
        collect_strings(k, sink, seen)
        collect_strings(v, sink, seen)
    end
end

local function leaks_in_table(state, payload)
    local strings = {}
    collect_strings(payload, strings)
    local found = {}
    for _, id in ipairs(hidden_ids(state)) do
        if strings[id] then
            found[#found + 1] = id
        end
    end
    return found
end

-- Implements MACHINE_CLI_SLICE_2026-07-28 §12.6: an identifier is a WHOLE
-- TOKEN. Substring matching reported MINOR-3 as leaked whenever MINOR-34 was
-- lawfully shown, because one id is a prefix of the other.
local function shown_tokens(text)
    local shown = {}
    for token in text:gmatch("%u+%-%d+") do
        shown[token] = true
    end
    return shown
end

local function leaks_in_text(state, text)
    local found = {}
    local shown = shown_tokens(text)
    for _, id in ipairs(hidden_ids(state)) do
        if shown[id] then
            found[#found + 1] = id
        end
    end
    return found
end

-- Second check: no observation entry may carry operators for a hidden card.
local function operator_leaks(state, observation)
    local found = {}
    local function walk(node, seen)
        if type(node) ~= "table" then
            return
        end
        seen = seen or {}
        if seen[node] then
            return
        end
        seen[node] = true
        if node.present and node.state == "hidden" and (node.op_a or node.op_b or node.id or node.class) then
            found[#found + 1] = node.handle or "unnamed"
        end
        for _, v in pairs(node) do
            walk(v, seen)
        end
    end
    walk(observation)
    return found
end

local function new_game(seed)
    local game = core.new()
    core.start_game(game, {rng = rng.from_seed(seed)})
    return game
end

function M.run(seeds, steps, opts)
    opts = opts or {}
    seeds = seeds or 20
    steps = steps or 120

    local report = {
        observations_checked = 0,
        id_leaks = 0,
        operator_leaks = 0,
        handle_resolution_failures = 0,
        control_snapshot_leaks = 0,
        control_snapshot_checked = 0,
        examples = {},
    }

    math.randomseed(opts.walk_seed or 20260726)

    for seed = 1, seeds do
        local game = new_game(seed)

        for _ = 1, steps do
            local ix = core.interaction(game)
            local actions = core.enumerate_legal_actions(game)
            local observation = view.observe(game, {
                interaction = ix,
                legal_action_count = #actions,
            })

            report.observations_checked = report.observations_checked + 1

            local id_found = leaks_in_table(game, observation)
            if #id_found > 0 then
                report.id_leaks = report.id_leaks + 1
                if #report.examples < 5 then
                    report.examples[#report.examples + 1] = string.format(
                        "seed %d: observation exposed hidden id %s", seed, id_found[1])
                end
            end

            local text_found = leaks_in_text(game, view.format(observation))
            if #text_found > 0 then
                report.id_leaks = report.id_leaks + 1
                if #report.examples < 5 then
                    report.examples[#report.examples + 1] = string.format(
                        "seed %d: rendered observation exposed hidden id %s", seed, text_found[1])
                end
            end

            local op_found = operator_leaks(game, observation)
            if #op_found > 0 then
                report.operator_leaks = report.operator_leaks + #op_found
            end

            -- every handle must resolve, otherwise an agent cannot act blind
            for handle in pairs(observation.handles) do
                local card_id = view.resolve_handle(game, observation, handle)
                if not card_id then
                    report.handle_resolution_failures = report.handle_resolution_failures + 1
                end
            end

            -- CONTROL: the debug snapshot is expected to leak
            local snapshot_found = leaks_in_text(game, inspect.snapshot(game))
            report.control_snapshot_checked = report.control_snapshot_checked + 1
            if #snapshot_found > 0 then
                report.control_snapshot_leaks = report.control_snapshot_leaks + 1
            end

            if #actions == 0 then
                break
            end
            local action = actions[math.random(#actions)]
            core.apply_action(game, action)
        end
    end

    report.ok = report.id_leaks == 0
        and report.operator_leaks == 0
        and report.handle_resolution_failures == 0
    report.control_ok = report.control_snapshot_leaks > 0

    return report
end

function M.format(report)
    local lines = {}
    lines[#lines + 1] = "OBSERVATION LEAK AUDIT"
    lines[#lines + 1] = string.format("observations checked          %d", report.observations_checked)
    lines[#lines + 1] = string.format("hidden id leaks              %d", report.id_leaks)
    lines[#lines + 1] = string.format("hidden operator leaks        %d", report.operator_leaks)
    lines[#lines + 1] = string.format("handle resolution failures   %d", report.handle_resolution_failures)
    lines[#lines + 1] = string.format(
        "CONTROL inspect.snapshot     %d of %d leaked (must be > 0)",
        report.control_snapshot_leaks, report.control_snapshot_checked)
    for _, example in ipairs(report.examples) do
        lines[#lines + 1] = "  " .. example
    end
    lines[#lines + 1] = string.format("view honest:   %s", report.ok and "PASS" or "FAIL")
    lines[#lines + 1] = string.format("audit sensitive: %s", report.control_ok and "PASS" or "FAIL")
    return table.concat(lines, "\n")
end

return M
