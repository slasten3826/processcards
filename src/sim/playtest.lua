-- Playtest harness: a readable session, played through the honest observation.
--
-- A test answers "did anything break". A playtest answers "what was it like
-- to play". Code cannot judge the second, so this module does not try. It
-- produces a transcript a human or a machine can read, plus the qualitative
-- signals that are mechanical enough to count:
--
--     which operators were offered and never taken
--     how often a turn ended with nothing to do
--     whether the board ever failed to close
--     where the session stopped and why
--
-- Everything the policy sees comes from view.observe, never from
-- inspect.snapshot, so a session recorded here is a session that a real
-- player could have had.

local core = require("src.core.game")
local view = require("src.core.view")
local rng = require("src.sim.rng")
local invariants = require("src.sim.invariants")

local M = {}

local function new_game(seed, trumps)
    local game = core.new()
    core.start_game(game, {
        rng = rng.from_seed(seed),
        enabled_trumps = (trumps == "none") and {} or nil,
    })
    return game
end

local function first_of_kind(actions, kind)
    for _, action in ipairs(actions) do
        if action.kind == kind then
            return action
        end
    end
    return nil
end

-- Default policy: phase driven, deliberately dumb about WHICH card or operator
-- it picks, but correct about the protocol.
--
-- Naive "first legal action" livelocks here: arm_hand and arm_operator are
-- toggles, so re-picking the same action disarms it and the session never
-- reaches the operator phase. The fix is to advance whenever the interaction
-- says advancing is possible, and only arm when it is not.
function M.protocol_policy(observation, actions)
    local phase = observation.phase

    if observation.advance_enabled and phase ~= "await_operator" then
        return first_of_kind(actions, "advance")
    end

    if phase == "await_start" then
        -- Arm the hand card first. The protocol allows either order, but
        -- committing first can land on a node no card fits, and then the only
        -- legal moves are re-committing or clearing, which is a livelock.
        -- Arming first means the commit slots offered next are exactly the
        -- ones that fit.
        return first_of_kind(actions, "arm_hand")
            or first_of_kind(actions, "commit_manifest")
            or actions[1]
    end

    if phase == "await_complete" then
        -- With a card already armed, every offered slot fits it.
        local committed = first_of_kind(actions, "commit_manifest")
        if committed then
            return committed
        end
        -- Armed card that fits nothing: drop it and take another.
        return first_of_kind(actions, "clear_armed")
            or first_of_kind(actions, "arm_hand")
            or first_of_kind(actions, "clear_committed")
            or first_of_kind(actions, "advance")
            or actions[1]
    end

    if phase == "await_operator" then
        -- discharge means nothing is armed yet; confirm means one is
        if observation.advance_reason == "confirm_operator" then
            return first_of_kind(actions, "advance")
        end
        return first_of_kind(actions, "arm_operator") or first_of_kind(actions, "advance")
    end

    if phase == "await_target" then
        return first_of_kind(actions, "arm_target")
            or first_of_kind(actions, "arm_direction")
            or first_of_kind(actions, "advance")
            or actions[1]
    end

    if phase == "await_trump" then
        return first_of_kind(actions, "resolve_pending_trump")
            or first_of_kind(actions, "advance")
            or actions[1]
    end

    return first_of_kind(actions, "advance") or actions[1]
end

function M.run(opts)
    opts = opts or {}
    local seed = opts.seed or 1
    local max_steps = opts.steps or 200
    local trumps = opts.trumps or "none"
    local policy = opts.policy or M.protocol_policy

    local game = new_game(seed, trumps)

    local session = {
        seed = seed,
        trumps = trumps,
        steps = {},
        operators_offered = {},
        operators_taken = {},
        board_open_steps = 0,
        invariant_failures = {},
        stop_reason = "step_limit",
    }

    for step = 1, max_steps do
        local ix = core.interaction(game)
        local actions = core.enumerate_legal_actions(game)
        local observation = view.observe(game, {
            interaction = ix,
            legal_action_count = #actions,
        })

        if not observation.board_closed then
            session.board_open_steps = session.board_open_steps + 1
        end

        for _, operator in ipairs(observation.legal_operators or {}) do
            session.operators_offered[operator] = (session.operators_offered[operator] or 0) + 1
        end

        if #actions == 0 then
            session.stop_reason = "no_legal_action"
            break
        end

        local action = policy(observation, actions)
        if not action then
            session.stop_reason = "policy_declined"
            break
        end

        if action.kind == "arm_operator" and action.operator then
            session.operators_taken[action.operator] =
                (session.operators_taken[action.operator] or 0) + 1
        end

        local result = core.apply_action(game, action)
        local err = result and result.summary and result.summary.error

        local events = {}
        for _, event in ipairs(core.drain_events(game)) do
            events[#events + 1] = event.type
        end

        session.steps[#session.steps + 1] = {
            step = step,
            phase = observation.phase,
            hidden = observation.hidden_count,
            hand = observation.counts.hand,
            deck = observation.counts.deck,
            grave = observation.counts.grave,
            action = action,
            error = err,
            events = events,
        }

        local ok, detail = invariants.run_all(game)
        if not ok then
            session.invariant_failures[#session.invariant_failures + 1] = {
                step = step,
                detail = detail,
            }
            session.stop_reason = "invariant_failure"
            break
        end

        if err then
            session.stop_reason = "error:" .. tostring(err)
            break
        end
    end

    session.final = view.observe(game, {
        interaction = core.interaction(game),
        legal_action_count = #core.enumerate_legal_actions(game),
    })

    return session
end

local OPERATOR_ORDER = {
    "FLOW", "CONNECT", "DISSOLVE", "ENCODE", "CHOOSE",
    "OBSERVE", "LOGIC", "CYCLE", "RUNTIME", "MANIFEST",
}

local function action_text(action)
    if not action then
        return "-"
    end
    local text = action.kind
    if action.operator then
        text = text .. ":" .. action.operator
    elseif action.slot then
        text = text .. ":" .. tostring(action.slot)
    elseif action.card_id then
        text = text .. ":" .. tostring(action.card_id)
    elseif action.target and action.target.slot then
        text = text .. ":slot" .. tostring(action.target.slot)
    end
    return text
end

function M.format(session, opts)
    opts = opts or {}
    local lines = {}
    lines[#lines + 1] = string.format(
        "PLAYTEST seed=%d trumps=%s steps=%d stop=%s",
        session.seed, session.trumps, #session.steps, session.stop_reason)

    if not opts.summary_only then
        for _, entry in ipairs(session.steps) do
            lines[#lines + 1] = string.format(
                "%03d %-16s hand=%-2d deck=%-3d grave=%-3d hidden=%-2d %-24s %s",
                entry.step,
                tostring(entry.phase or "-"),
                entry.hand, entry.deck, entry.grave, entry.hidden,
                action_text(entry.action),
                table.concat(entry.events, ","))
        end
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "operator take-rate in this session"
    lines[#lines + 1] = string.format("%-10s %8s %8s %10s", "operator", "offered", "taken", "rate")
    for _, operator in ipairs(OPERATOR_ORDER) do
        local offered = session.operators_offered[operator] or 0
        local taken = session.operators_taken[operator] or 0
        local rate = offered > 0 and string.format("%.1f%%", 100.0 * taken / offered) or "-"
        lines[#lines + 1] = string.format("%-10s %8d %8d %10s", operator, offered, taken, rate)
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = string.format("steps with an open board  %d", session.board_open_steps)
    lines[#lines + 1] = string.format("invariant failures        %d", #session.invariant_failures)
    for _, failure in ipairs(session.invariant_failures) do
        lines[#lines + 1] = string.format("  step %d: %s", failure.step, tostring(failure.detail))
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "final position as the player sees it:"
    lines[#lines + 1] = view.format(session.final)

    return table.concat(lines, "\n")
end

return M
