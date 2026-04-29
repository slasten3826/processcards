local core = require("src.core.api")
local inspect = require("src.core.inspect")
local rng = require("src.sim.rng")
local invariants = require("src.sim.invariants")
local scenarios = require("src.sim.scenarios")

local M = {}

local SKIP_ERRORS = {
    no_latent_trump = true,
    no_pending_trump = true,
    no_legal_turn = true,
}

local function new_game(seed)
    local game = core.new()
    core.start_game(game, {
        rng = rng.from_seed(seed),
    })
    return game
end

function M.run_scenario(name, seed)
    local game = new_game(seed or 1)
    local ok, inv = invariants.run_all(game)
    if not ok then
        return {
            ok = false,
            stage = "setup",
            error = inv,
            snapshot = inspect.snapshot(game),
        }
    end

    local scenario = scenarios[name]
    if not scenario then
        return {
            ok = false,
            stage = "dispatch",
            error = {name = "unknown_scenario", details = name},
            snapshot = inspect.snapshot(game),
        }
    end

    local info, err = scenario(game)
    if not info then
        if SKIP_ERRORS[err] then
            return {
                ok = true,
                skipped = err,
                snapshot = inspect.snapshot(game),
            }
        end
        return {
            ok = false,
            stage = "scenario",
            error = {name = err or "scenario_failed", details = name},
            snapshot = inspect.snapshot(game),
        }
    end

    ok, inv = invariants.run_all(game)
    if not ok then
        return {
            ok = false,
            stage = "post_scenario",
            scenario = info,
            error = inv,
            snapshot = inspect.snapshot(game),
        }
    end

    return {
        ok = true,
        scenario = info,
        transition = core.last_transition(game),
        snapshot = inspect.snapshot(game),
    }
end

function M.run_smoke(seed, turns)
    local game = new_game(seed or 1)
    local reports = {}

    local function append(stage, ok, err)
        reports[#reports + 1] = {
            stage = stage,
            ok = ok,
            error = err,
        }
    end

    local ok, inv = invariants.run_all(game)
    append("setup", ok, inv)
    if not ok then
        return {
            ok = false,
            reports = reports,
            snapshot = inspect.snapshot(game),
        }
    end

    local draw_info = scenarios.draw_once(game)
    ok, inv = invariants.run_all(game)
    append("draw_once", ok, inv)
    if not ok then
        return {
            ok = false,
            reports = reports,
            draw = draw_info,
            snapshot = inspect.snapshot(game),
        }
    end

    local max_turns = turns or 8
    local turn_reports = {}
    for i = 1, max_turns do
        local info, err = scenarios.one_turn(game)
        if not info then
            turn_reports[#turn_reports + 1] = {index = i, skipped = err}
            break
        end
        turn_reports[#turn_reports + 1] = {index = i, slot = info.slot, hand_card_id = info.hand_card_id}
        ok, inv = invariants.run_all(game)
        append("turn_" .. i, ok, inv)
        if not ok then
            return {
                ok = false,
                reports = reports,
                turns = turn_reports,
                snapshot = inspect.snapshot(game),
            }
        end

        while game.pending_trump do
            local trump_info = scenarios.resolve_pending_trump(game)
            if not trump_info then
                return {
                    ok = false,
                    reports = reports,
                    turns = turn_reports,
                    snapshot = inspect.snapshot(game),
                }
            end
            ok, inv = invariants.run_all(game)
            append("resolve_pending_trump", ok, inv)
            if not ok then
                return {
                    ok = false,
                    reports = reports,
                    turns = turn_reports,
                    snapshot = inspect.snapshot(game),
                }
            end
        end
    end

    return {
        ok = true,
        reports = reports,
        turns = turn_reports,
        snapshot = inspect.snapshot(game),
    }
end

function M.bench(mode, count, seed0)
    local total = count or 100
    local start_seed = seed0 or 1
    local passed = 0
    local failed = 0
    local skipped = 0
    local first_failure = nil

    for i = 0, total - 1 do
        local seed = start_seed + i
        local result
        if mode == "smoke" then
            result = M.run_smoke(seed)
        else
            result = M.run_scenario(mode, seed)
        end

        if result.ok then
            if result.skipped then
                skipped = skipped + 1
            else
                passed = passed + 1
            end
        else
            failed = failed + 1
            if not first_failure then
                first_failure = {
                    seed = seed,
                    result = result,
                }
            end
        end
    end

    return {
        mode = mode,
        total = total,
        passed = passed,
        failed = failed,
        skipped = skipped,
        first_failure = first_failure,
    }
end

return M
