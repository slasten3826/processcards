local state_lib = require("src.core.state")
local rules = require("src.core.rules")
local draw = require("src.core.draw")
local repair = require("src.core.repair")
local trump = require("src.core.trump")
local transition = require("src.core.transition")
local operators = require("src.core.operators")

local M = {}

function M.commit_manifest(state, slot)
    local card_id = state.zones.manifest.cards[slot]
    if not card_id then
        return nil, "empty_manifest_slot"
    end
    state.committed = {card_id = card_id, slot = slot}
    state.legal_hints = {}
    local legal = rules.legal_hand_ids(state, card_id)
    for _, hand_card_id in ipairs(legal) do
        state.legal_hints[hand_card_id] = true
    end
    state.armed_hand = nil
    return legal
end

function M.arm_hand(state, card_id)
    if not state.committed then
        return nil, "no_commit"
    end
    if not state.legal_hints[card_id] then
        return nil, "illegal_hand_card"
    end
    state.armed_hand = (state.armed_hand == card_id) and nil or card_id
    return state.armed_hand
end

function M.reorder_hand(state, card_id, index)
    local card = state.cards[card_id]
    if not card or card.zone ~= "hand" then
        return nil, "card_not_in_hand"
    end

    state_lib.remove_from_current_zone(state, card_id)
    local hand = state.zones.hand.cards
    local insert_at = math.max(1, math.min(index or (#hand + 1), #hand + 1))
    table.insert(hand, insert_at, card_id)
    state_lib.sync_zone_cards(state, "hand")
    return insert_at
end

local function move_to_grave(state, card_id)
    state_lib.remove_from_current_zone(state, card_id)
    state_lib.reveal_card(state, card_id)
    state_lib.place_card(state, card_id, "grave", nil)
end

local function operator_choices_for_card(state, card_id)
    local card = state.cards[card_id]
    if not card then
        return nil
    end
    return {card.op_a, card.op_b}
end

local function legal_hidden_board_card_ids(state)
    local legal = {}

    local function maybe_add(card_id)
        if card_id and state.cards[card_id] and state_lib.is_hidden(state, card_id) then
            legal[#legal + 1] = card_id
        end
    end

    maybe_add(state.zones.deck.cards[#state.zones.deck.cards])

    for _, zone_name in ipairs({"runtime", "play", "trump_flow", "trump", "targets", "manifest", "latent", "grave"}) do
        local zone = state.zones[zone_name]
        if zone.kind == "slots" then
            for slot = 1, zone.slot_count do
                maybe_add(zone.cards[slot])
            end
        else
            for _, card_id in ipairs(zone.cards) do
                maybe_add(card_id)
            end
        end
    end

    return legal
end

function M.resolve_turn(state, slot, hand_card_id)
    if not state.committed or state.committed.slot ~= slot then
        return nil, "no_matching_commit"
    end
    if hand_card_id ~= state.armed_hand then
        return nil, "hand_not_armed"
    end

    transition.begin(state, "resolve_turn", {
        slot = slot,
        hand_card_id = hand_card_id,
        manifest_card_id = state.committed.card_id,
    })

    state_lib.remove_from_current_zone(state, hand_card_id)
    state_lib.place_card(state, hand_card_id, "play", 1)
    transition.emit(state, "hand_to_play", {
        card_id = hand_card_id,
        slot = 1,
    })

    local manifest_id = state.committed.card_id
    move_to_grave(state, manifest_id)
    transition.emit(state, "manifest_to_grave", {
        card_id = manifest_id,
        slot = slot,
    })

    repair.repair_manifest_slot(state, slot)

    state.pending_operator_choice = {
        card_id = hand_card_id,
        choices = operator_choices_for_card(state, hand_card_id),
    }
    transition.emit(state, "operator_choice_pending", {
        card_id = hand_card_id,
        choices = state.pending_operator_choice.choices,
    })
    return transition.finish(state, {
        board_closed = state_lib.is_board_closed(state),
        pending_operator_choice = state.pending_operator_choice,
        pending_trump = state.pending_trump,
    })
end

function M.choose_operator(state, op_name)
    local pending = state.pending_operator_choice
    if not pending then
        return nil, "no_pending_operator_choice"
    end
    local card_id = pending.card_id
    local choices = pending.choices or operator_choices_for_card(state, card_id) or {}
    if op_name ~= choices[1] and op_name ~= choices[2] then
        return nil, "illegal_operator_choice"
    end

    transition.begin(state, "choose_operator", {
        card_id = card_id,
        operator = op_name,
    })

    transition.emit(state, "operator_chosen", {
        card_id = card_id,
        operator = op_name,
    })

    if op_name == "CHOOSE" then
        local legal_slots = {}
        for slot = 1, state.zones.manifest.slot_count do
            local manifest_id = state.zones.manifest.cards[slot]
            if manifest_id and state_lib.is_revealed(state, manifest_id) then
                legal_slots[#legal_slots + 1] = slot
            end
        end
        state.pending_operator_choice = nil
        state.pending_manifest_choice = {
            card_id = card_id,
            operator = op_name,
            legal_slots = legal_slots,
        }
        transition.emit(state, "manifest_choice_pending", {
            card_id = card_id,
            legal_slots = legal_slots,
        })
        return transition.finish(state, {
            pending_manifest_choice = state.pending_manifest_choice,
            pending_trump = state.pending_trump,
            board_closed = state_lib.is_board_closed(state),
        })
    end

    if op_name == "OBSERVE" then
        local legal_card_ids = legal_hidden_board_card_ids(state)
        state.pending_operator_choice = nil
        state.pending_hidden_choice = {
            card_id = card_id,
            operator = op_name,
            legal_card_ids = legal_card_ids,
        }
        transition.emit(state, "hidden_choice_pending", {
            card_id = card_id,
            operator = op_name,
            legal_card_ids = legal_card_ids,
        })
        return transition.finish(state, {
            operator = op_name,
            pending_hidden_choice = state.pending_hidden_choice,
            pending_trump = state.pending_trump,
            board_closed = state_lib.is_board_closed(state),
        })
    end

    if op_name == "CYCLE" then
        operators.resolve_cycle_draw(state)
        state.pending_operator_choice = nil
        state.pending_hand_choice = {
            card_id = card_id,
            operator = op_name,
            legal_card_ids = {},
        }
        for _, legal_card_id in ipairs(state.zones.hand.cards) do
            state.pending_hand_choice.legal_card_ids[#state.pending_hand_choice.legal_card_ids + 1] = legal_card_id
        end
        transition.emit(state, "hand_choice_pending", {
            card_id = card_id,
            operator = op_name,
            legal_card_ids = state.pending_hand_choice.legal_card_ids,
        })
        return transition.finish(state, {
            operator = op_name,
            pending_hand_choice = state.pending_hand_choice,
            pending_trump = state.pending_trump,
            board_closed = state_lib.is_board_closed(state),
        })
    end

    operators.resolve(state, op_name)

    move_to_grave(state, card_id)
    transition.emit(state, "play_to_grave", {
        card_id = card_id,
        operator = op_name,
    })

    state.pending_operator_choice = nil
    state_lib.clear_gameplay_selection(state)
    trump.refresh_pending_trump(state)

    return transition.finish(state, {
        operator = op_name,
        board_closed = state_lib.is_board_closed(state),
        pending_operator_choice = state.pending_operator_choice,
        pending_trump = state.pending_trump,
    })
end

function M.choose_manifest_target(state, slot)
    local pending = state.pending_manifest_choice
    if not pending then
        return nil, "no_pending_manifest_choice"
    end

    local legal = false
    for _, legal_slot in ipairs(pending.legal_slots or {}) do
        if legal_slot == slot then
            legal = true
            break
        end
    end
    if not legal then
        return nil, "illegal_manifest_choice"
    end

    local manifest_id = state.zones.manifest.cards[slot]
    if not manifest_id then
        return nil, "empty_manifest_slot"
    end

    transition.begin(state, "choose_manifest_target", {
        slot = slot,
        card_id = manifest_id,
        source_card_id = pending.card_id,
    })

    state_lib.remove_from_current_zone(state, manifest_id)
    state_lib.reveal_card(state, manifest_id)
    state_lib.place_card(state, manifest_id, "hand", nil)
    transition.emit(state, "manifest_to_hand", {
        card_id = manifest_id,
        slot = slot,
    })

    repair.repair_manifest_slot(state, slot)

    local play_card_id = pending.card_id
    move_to_grave(state, play_card_id)
    transition.emit(state, "play_to_grave", {
        card_id = play_card_id,
        operator = pending.operator,
    })

    state.pending_manifest_choice = nil
    state_lib.clear_gameplay_selection(state)
    trump.refresh_pending_trump(state)

    return transition.finish(state, {
        slot = slot,
        card_id = manifest_id,
        pending_manifest_choice = state.pending_manifest_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.choose_hand_target(state, card_id)
    local pending = state.pending_hand_choice
    if not pending then
        return nil, "no_pending_hand_choice"
    end

    local legal = false
    for _, legal_card_id in ipairs(pending.legal_card_ids or {}) do
        if legal_card_id == card_id then
            legal = true
            break
        end
    end
    if not legal then
        return nil, "illegal_hand_choice"
    end

    transition.begin(state, "choose_hand_target", {
        card_id = card_id,
        source_card_id = pending.card_id,
        operator = pending.operator,
    })

    move_to_grave(state, card_id)
    transition.emit(state, "hand_to_grave", {
        card_id = card_id,
        operator = pending.operator,
    })

    operators.finish_cycle(state, card_id)

    local play_card_id = pending.card_id
    move_to_grave(state, play_card_id)
    transition.emit(state, "play_to_grave", {
        card_id = play_card_id,
        operator = pending.operator,
    })

    state.pending_hand_choice = nil
    state_lib.clear_gameplay_selection(state)
    trump.refresh_pending_trump(state)

    return transition.finish(state, {
        card_id = card_id,
        pending_hand_choice = state.pending_hand_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.choose_hidden_target(state, card_id)
    local pending = state.pending_hidden_choice
    if not pending then
        return nil, "no_pending_hidden_choice"
    end

    local legal = false
    for _, legal_card_id in ipairs(pending.legal_card_ids or {}) do
        if legal_card_id == card_id then
            legal = true
            break
        end
    end
    if not legal then
        return nil, "illegal_hidden_choice"
    end

    transition.begin(state, "choose_hidden_target", {
        card_id = card_id,
        source_card_id = pending.card_id,
        operator = pending.operator,
    })

    local source_zone = state.cards[card_id].zone
    local source_slot = state.cards[card_id].slot
    local card = state.cards[card_id]

    if card.class == "trump" and source_zone == "latent" and source_slot then
        state_lib.remove_from_current_zone(state, card_id)
        transition.emit(state, "latent_trump_revealed", {
            card_id = card_id,
            slot = source_slot,
            reason = "observe",
        })
        trump.enter_trump_flow(state, card_id, "observe")
        draw.concealed_refill(state, "latent", source_slot)
    elseif card.class == "trump" and source_zone == "targets" and source_slot then
        state_lib.reveal_card(state, card_id)
        transition.emit(state, "card_revealed_in_place", {
            card_id = card_id,
            zone = "targets",
            slot = source_slot,
            operator = pending.operator,
        })
    else
        state_lib.know_card(state, card_id)
        transition.emit(state, "card_became_known", {
            card_id = card_id,
            operator = pending.operator,
        })
    end

    operators.finish_observe(state, card_id)

    local play_card_id = pending.card_id
    move_to_grave(state, play_card_id)
    transition.emit(state, "play_to_grave", {
        card_id = play_card_id,
        operator = pending.operator,
    })

    state.pending_hidden_choice = nil
    state_lib.clear_gameplay_selection(state)
    trump.refresh_pending_trump(state)

    return transition.finish(state, {
        card_id = card_id,
        pending_hidden_choice = state.pending_hidden_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

return M
