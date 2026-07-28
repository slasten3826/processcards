-- TURN_STEP_LAW section 8, made checkable.
--
--     in one turn's event stream, no trump RESOLUTION event stands earlier
--     than step_spend_end
--
-- Entering the queue is allowed during BURN, UPDATE and EFFECT, so entry
-- events are not violations. Only resolution is deferred.
--
--     lua cli.lua check_steps [seeds] [steps]

local core = require("src.core.game")
local rng = require("src.sim.rng")
local view = require("src.core.view")
local playtest = require("src.sim.playtest")

local M = {}

-- resolution, not entry
local RESOLUTION = {
    pending_trump = true,
    trump_effect_begin = true,
    trump_effect_end = true,
}

-- entry into the queue: legal before SPEND
local ENTRY = {
    trump_flow_entry = true,
    latent_trump_revealed = true,
}

function M.run(seeds, steps)
    seeds = seeds or 20
    steps = steps or 300

    local report = {
        turns = 0,
        violations = 0,
        entries_before_spend = 0,
        resolutions_after_spend = 0,
        examples = {},
    }

    for seed = 1, seeds do
        local game = core.new()
        core.start_game(game, {rng = rng.from_seed(seed)})

        local turn = {}
        for _ = 1, steps do
            local ix = core.interaction(game)
            local actions = core.enumerate_legal_actions(game)
            if #actions == 0 then
                break
            end
            local observation = view.observe(game, {
                interaction = ix,
                legal_action_count = #actions,
            })
            core.apply_action(game, playtest.protocol_policy(observation, actions) or actions[1])

            for _, event in ipairs(core.drain_events(game)) do
                turn[#turn + 1] = event.type
                if event.type == "turn_closed" then
                    report.turns = report.turns + 1

                    local spend_at = nil
                    for index, name in ipairs(turn) do
                        if name == "step_spend_end" then
                            spend_at = index
                            break
                        end
                    end

                    for index, name in ipairs(turn) do
                        if RESOLUTION[name] then
                            if spend_at and index < spend_at then
                                report.violations = report.violations + 1
                                if #report.examples < 5 then
                                    report.examples[#report.examples + 1] = string.format(
                                        "seed %d: %s at %d, step_spend_end at %d",
                                        seed, name, index, spend_at)
                                end
                            else
                                report.resolutions_after_spend = report.resolutions_after_spend + 1
                            end
                        elseif ENTRY[name] and spend_at and index < spend_at then
                            report.entries_before_spend = report.entries_before_spend + 1
                        end
                    end

                    turn = {}
                end
            end
        end
    end

    report.ok = report.violations == 0
    return report
end

function M.format(report)
    local lines = {}
    lines[#lines + 1] = "TURN STEP INVARIANT"
    lines[#lines + 1] = string.format("turns observed              %d", report.turns)
    lines[#lines + 1] = string.format("trump resolutions after SPEND %d", report.resolutions_after_spend)
    lines[#lines + 1] = string.format("queue entries before SPEND    %d  (legal)", report.entries_before_spend)
    lines[#lines + 1] = string.format("violations                  %d", report.violations)
    for _, example in ipairs(report.examples) do
        lines[#lines + 1] = "  " .. example
    end
    lines[#lines + 1] = report.ok and "INVARIANT HOLDS" or "INVARIANT BROKEN"
    return table.concat(lines, "\n")
end

return M
