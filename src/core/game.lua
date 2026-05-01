local state_lib = require("src.core.state")
local setup = require("src.core.setup")
local inspect = require("src.core.inspect")
local interaction = require("src.core.interaction")
local transition = require("src.core.transition")
local turn = require("src.core.turn")
local draw = require("src.core.draw")
local trump = require("src.core.trump")

local M = {}

function M.new()
    return state_lib.new_game()
end

function M.start_game(state, opts)
    transition.begin(state, "start_game", {})
    setup.start_game(state, opts)
    transition.emit(state, "setup_complete", {
        deck = #state.zones.deck.cards,
        hand = #state.zones.hand.cards,
        manifest = state_lib.zone_count(state, "manifest"),
        latent = state_lib.zone_count(state, "latent"),
        targets = state_lib.zone_count(state, "targets"),
    })
    return transition.finish(state, {
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.snapshot(state)
    return inspect.snapshot(state)
end

function M.interaction(state)
    return interaction.read(state)
end

function M.interaction_text(state)
    return interaction.format(interaction.read(state))
end

function M.advance(state)
    local ix = interaction.read(state)

    if ix.phase == "await_hand" then
        if not state.committed or not state.armed_hand then
            transition.begin(state, "advance", {phase = ix.phase})
            return transition.finish(state, {error = "no_armed_hand"})
        end
        return turn.resolve_turn(state, state.committed.slot, state.armed_hand)
    end

    if ix.phase == "await_operator" then
        return M.confirm_operator_phase(state)
    end

    if ix.phase == "await_target" then
        if state.pending_manifest_choice then
            return M.confirm_manifest_target(state)
        end
        if state.pending_hidden_choice then
            return M.confirm_hidden_target(state)
        end
        if state.pending_unrevealed_choice then
            return M.confirm_unrevealed_target(state)
        end
        if state.pending_public_choice then
            return M.confirm_public_target(state)
        end
        if state.pending_hand_choice then
            return M.confirm_hand_target(state)
        end
        transition.begin(state, "advance", {phase = ix.phase})
        return transition.finish(state, {error = "missing_target_phase"})
    end

    if ix.phase == "await_trump" then
        return M.resolve_pending_trump(state)
    end

    transition.begin(state, "advance", {phase = ix.phase})
    return transition.finish(state, {error = "advance_not_available"})
end

function M.apply_action(state, action)
    if type(action) ~= "table" then
        transition.begin(state, "apply_action", {})
        return transition.finish(state, {error = "invalid_action"})
    end

    local kind = action.kind
    if kind == "commit_manifest" then
        return M.commit_manifest(state, action.slot)
    end
    if kind == "arm_hand" then
        return M.arm_hand(state, action.card_id)
    end
    if kind == "arm_operator" then
        return M.arm_operator(state, action.operator)
    end
    if kind == "arm_target" then
        local target = action.target or {}
        if state.pending_manifest_choice then
            return M.arm_manifest_target(state, target.slot)
        end
        if state.pending_hidden_choice then
            return M.arm_hidden_target(state, target.card_id)
        end
        if state.pending_unrevealed_choice then
            return M.arm_unrevealed_target(state, target.card_id)
        end
        if state.pending_public_choice then
            return M.arm_public_target(state, target.card_id)
        end
        if state.pending_hand_choice then
            return M.arm_hand_target(state, target.card_id)
        end
        transition.begin(state, "apply_action", {kind = kind})
        return transition.finish(state, {error = "no_pending_target_phase"})
    end
    if kind == "advance" then
        return M.advance(state)
    end
    if kind == "draw" then
        return M.draw_to_hand(state)
    end
    if kind == "resolve_pending_trump" then
        return M.resolve_pending_trump(state)
    end

    transition.begin(state, "apply_action", {kind = tostring(kind)})
    return transition.finish(state, {error = "unknown_action"})
end

function M.commit_manifest(state, slot)
    transition.begin(state, "commit_manifest", {slot = slot})
    local legal, err = turn.commit_manifest(state, slot)
    if err then
        return transition.finish(state, {error = err})
    end
    transition.emit(state, "commit_manifest", {
        slot = slot,
        card_id = state.committed and state.committed.card_id or nil,
        legal = legal,
    })
    return transition.finish(state, {legal = legal})
end

function M.arm_hand(state, card_id)
    transition.begin(state, "arm_hand", {card_id = card_id})
    local armed, err = turn.arm_hand(state, card_id)
    if err then
        return transition.finish(state, {error = err})
    end
    transition.emit(state, "arm_hand", {
        card_id = card_id,
        armed = armed,
    })
    return transition.finish(state, {armed = armed})
end

function M.reorder_hand(state, card_id, index)
    transition.begin(state, "reorder_hand", {
        card_id = card_id,
        index = index,
    })
    local insert_at, err = turn.reorder_hand(state, card_id, index)
    if err then
        return transition.finish(state, {error = err})
    end
    transition.emit(state, "reorder_hand", {
        card_id = card_id,
        index = insert_at,
    })
    return transition.finish(state, {index = insert_at})
end

function M.resolve_turn(state, slot, hand_card_id)
    return turn.resolve_turn(state, slot, hand_card_id)
end

function M.choose_operator(state, op_name)
    return turn.choose_operator(state, op_name)
end

function M.arm_operator(state, op_name)
    return turn.arm_operator(state, op_name)
end

function M.confirm_operator_phase(state)
    return turn.confirm_operator_phase(state)
end

function M.choose_manifest_target(state, slot)
    return turn.choose_manifest_target(state, slot)
end

function M.arm_manifest_target(state, slot)
    return turn.arm_manifest_target(state, slot)
end

function M.confirm_manifest_target(state)
    return turn.confirm_manifest_target(state)
end

function M.choose_public_target(state, card_id)
    return turn.choose_public_target(state, card_id)
end

function M.arm_public_target(state, card_id)
    return turn.arm_public_target(state, card_id)
end

function M.confirm_public_target(state)
    return turn.confirm_public_target(state)
end

function M.choose_hand_target(state, card_id)
    return turn.choose_hand_target(state, card_id)
end

function M.arm_hand_target(state, card_id)
    return turn.arm_hand_target(state, card_id)
end

function M.confirm_hand_target(state)
    return turn.confirm_hand_target(state)
end

function M.choose_hidden_target(state, card_id)
    return turn.choose_hidden_target(state, card_id)
end

function M.arm_hidden_target(state, card_id)
    return turn.arm_hidden_target(state, card_id)
end

function M.confirm_hidden_target(state)
    return turn.confirm_hidden_target(state)
end

function M.choose_unrevealed_target(state, card_id)
    return turn.choose_unrevealed_target(state, card_id)
end

function M.arm_unrevealed_target(state, card_id)
    return turn.arm_unrevealed_target(state, card_id)
end

function M.confirm_unrevealed_target(state)
    return turn.confirm_unrevealed_target(state)
end

function M.draw_to_hand(state)
    transition.begin(state, "draw_to_hand", {})
    local card_id, err = draw.draw_to_hand(state)
    trump.refresh_pending_trump(state)
    return transition.finish(state, {
        card_id = card_id,
        error = err,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.resolve_pending_trump(state)
    transition.begin(state, "resolve_pending_trump", {})
    local card_id, err = trump.resolve_pending_trump(state)
    trump.refresh_pending_trump(state)
    return transition.finish(state, {
        card_id = card_id,
        error = err,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.drain_events(state)
    return transition.drain_events(state)
end

function M.last_transition(state)
    return state.last_transition
end

return M
