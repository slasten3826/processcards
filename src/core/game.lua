local state_lib = require("src.core.state")
local setup = require("src.core.setup")
local inspect = require("src.core.inspect")
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

function M.choose_manifest_target(state, slot)
    return turn.choose_manifest_target(state, slot)
end

function M.choose_hand_target(state, card_id)
    return turn.choose_hand_target(state, card_id)
end

function M.choose_hidden_target(state, card_id)
    return turn.choose_hidden_target(state, card_id)
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
