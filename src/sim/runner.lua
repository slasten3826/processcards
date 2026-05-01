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
    no_logic_turn = true,
    no_logic_manifest_target = true,
    no_logic_latent_target = true,
    no_logic_grave_target = true,
    no_logic_topdeck_target = true,
    no_manifest_operator = true,
    no_unrevealed_target = true,
    missing_operator_CHOOSE = true,
    missing_operator_OBSERVE = true,
    no_manifest_target = true,
    no_hidden_target = true,
    no_public_target = true,
    no_hand_target = true,
}

local function new_game(seed)
    local game = core.new()
    core.start_game(game, {
        rng = rng.from_seed(seed),
    })
    return game
end

local function first_target_action(ix)
    local targets = ix.legal and ix.legal.targets or {}
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

local function choose_protocol_action(ix)
    if ix.phase == "await_commit" then
        local slot = ix.legal.commit_slots[1]
        if not slot then
            return nil, "no_commit_slot"
        end
        return {kind = "commit_manifest", slot = slot}
    end

    if ix.phase == "await_hand" then
        if ix.armed.hand_card_id then
            if ix.advance and ix.advance.enabled then
                return {kind = "advance"}
            end
            return nil, "hand_armed_but_cannot_advance"
        end
        local card_id = ix.legal.hand_cards[1]
        if not card_id then
            return nil, "no_legal_hand_card"
        end
        return {kind = "arm_hand", card_id = card_id}
    end

    if ix.phase == "await_operator" then
        if ix.armed.operator then
            if ix.advance and ix.advance.enabled then
                return {kind = "advance"}
            end
            return nil, "operator_armed_but_cannot_advance"
        end
        local op_name = ix.legal.operators[1]
        if op_name then
            return {kind = "arm_operator", operator = op_name}
        end
        if ix.advance and ix.advance.enabled then
            return {kind = "advance"}
        end
        return nil, "no_operator_action"
    end

    if ix.phase == "await_target" then
        if ix.advance and ix.advance.enabled then
            return {kind = "advance"}
        end
        local action = first_target_action(ix)
        if action then
            return action
        end
        return nil, "no_target_action"
    end

    if ix.phase == "await_trump" then
        if ix.advance and ix.advance.enabled then
            return {kind = "advance"}
        end
        return nil, "trump_pending_but_cannot_advance"
    end

    if ix.phase == "terminal" then
        return nil, "terminal"
    end

    if ix.phase == "idle" then
        return nil, "idle"
    end

    return nil, "unknown_phase_" .. tostring(ix.phase)
end

function M.run_autoplay(seed, turns)
    local game = new_game(seed or 1)
    local reports = {}
    local transcript = {}

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
            transcript = transcript,
            snapshot = inspect.snapshot(game),
        }
    end

    local max_steps = turns or 32
    local stop_reason = "step_limit"
    for i = 1, max_steps do
        local ix = core.interaction(game)
        transcript[#transcript + 1] = {
            step = i,
            phase = ix.phase,
            prompt = ix.prompt,
            advance = ix.advance,
        }

        local action, reason = choose_protocol_action(ix)
        if not action then
            stop_reason = reason
            break
        end

        transcript[#transcript].action = action

        local result = core.apply_action(game, action)
        local err = result and result.summary and result.summary.error or nil
        if err then
            return {
                ok = false,
                stage = "autoplay",
                error = {name = err, details = ix.phase},
                transcript = transcript,
                snapshot = inspect.snapshot(game),
            }
        end

        ok, inv = invariants.run_all(game)
        append("step_" .. i, ok, inv)
        if not ok then
            return {
                ok = false,
                stage = "post_action",
                error = inv,
                transcript = transcript,
                snapshot = inspect.snapshot(game),
            }
        end
    end

    return {
        ok = true,
        reports = reports,
        transcript = transcript,
        snapshot = inspect.snapshot(game),
        stop_reason = stop_reason,
        interaction = core.interaction(game),
    }
end

function M.run_headless_game(seed, max_steps)
    local game = new_game(seed or 1)
    local reports = {}
    local transcript = {}
    local limit = max_steps or 256
    local stop_reason = "step_limit"

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
            stage = "setup",
            error = inv,
            reports = reports,
            transcript = transcript,
            snapshot = inspect.snapshot(game),
        }
    end

    for i = 1, limit do
        local ix = core.interaction(game)
        local action, reason = choose_protocol_action(ix)
        transcript[#transcript + 1] = {
            step = i,
            phase = ix.phase,
            prompt = ix.prompt,
            advance = ix.advance,
            action = action,
        }

        if not action then
            stop_reason = reason
            break
        end

        local result = core.apply_action(game, action)
        local err = result and result.summary and result.summary.error or nil
        if err then
            return {
                ok = false,
                stage = "headless_apply",
                error = {name = err, details = ix.phase},
                reports = reports,
                transcript = transcript,
                snapshot = inspect.snapshot(game),
            }
        end

        ok, inv = invariants.run_all(game)
        append("step_" .. i, ok, inv)
        if not ok then
            return {
                ok = false,
                stage = "post_action",
                error = inv,
                reports = reports,
                transcript = transcript,
                snapshot = inspect.snapshot(game),
            }
        end
    end

    return {
        ok = true,
        reports = reports,
        transcript = transcript,
        snapshot = inspect.snapshot(game),
        stop_reason = stop_reason,
        interaction = core.interaction(game),
    }
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
        local info, err = scenarios.one_turn_via_protocol(game)
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
        elseif mode == "autoplay" then
            result = M.run_autoplay(seed)
        elseif mode == "headless" then
            result = M.run_headless_game(seed)
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
