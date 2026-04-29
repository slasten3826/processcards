local core = require("src.core.api")
local rules = require("src.core.rules")

local M = {}

local function first_legal_hand(state, slot)
    local manifest_id = state.zones.manifest.cards[slot]
    if not manifest_id then
        return nil
    end
    local legal = rules.legal_hand_ids(state, manifest_id)
    return legal[1], legal
end

function M.draw_once(state)
    local top_before = state.zones.deck.cards[#state.zones.deck.cards]
    local top_class = top_before and state.cards[top_before].class or nil
    local hand_before = #state.zones.hand.cards
    local flow_before = #state.zones.trump_flow.cards
    local result = core.draw_to_hand(state)
    return {
        name = "draw_once",
        top_before = top_before,
        top_class = top_class,
        hand_before = hand_before,
        flow_before = flow_before,
        result = result,
        hand_after = #state.zones.hand.cards,
        flow_after = #state.zones.trump_flow.cards,
    }
end

function M.latent_trump_closure(state)
    local slot
    local latent_before
    for i = 1, 6 do
        local latent_id = state.zones.latent.cards[i]
        if latent_id and state.cards[latent_id].class == "trump" then
            slot = i
            latent_before = latent_id
            break
        end
    end
    if not slot then
        return nil, "no_latent_trump"
    end

    local manifest_before = state.zones.manifest.cards[slot]
    local commit = core.commit_manifest(state, slot)
    local legal = commit.summary.legal or {}
    local hand_card_id = legal[1]
    if not hand_card_id then
        return nil, "no_legal_hand_card"
    end
    core.arm_hand(state, hand_card_id)
    local result = core.resolve_turn(state, slot, hand_card_id)
    return {
        name = "latent_trump_closure",
        slot = slot,
        manifest_before = manifest_before,
        latent_before = latent_before,
        hand_card_id = hand_card_id,
        result = result,
    }
end

function M.resolve_pending_trump(state)
    local pending_before = state.pending_trump
    if not pending_before then
        return nil, "no_pending_trump"
    end
    local result = core.resolve_pending_trump(state)
    return {
        name = "resolve_pending_trump",
        pending_before = pending_before,
        result = result,
        trump_after = {state.zones.trump.cards[1], state.zones.trump.cards[2]},
    }
end

function M.one_turn(state)
    local slot
    local hand_card_id
    local legal

    for i = 1, 6 do
        hand_card_id, legal = first_legal_hand(state, i)
        if hand_card_id then
            slot = i
            break
        end
    end

    if not slot then
        return nil, "no_legal_turn"
    end

    core.commit_manifest(state, slot)
    core.arm_hand(state, hand_card_id)
    local result = core.resolve_turn(state, slot, hand_card_id)
    local choose_result = nil
    if state.pending_operator_choice then
        local op_name = state.pending_operator_choice.choices[1]
        choose_result = core.choose_operator(state, op_name)
        if state.pending_manifest_choice then
            local target_slot = state.pending_manifest_choice.legal_slots[1]
            choose_result = core.choose_manifest_target(state, target_slot)
        elseif state.pending_hidden_choice then
            local target_card_id = state.pending_hidden_choice.legal_card_ids[1]
            choose_result = core.choose_hidden_target(state, target_card_id)
        elseif state.pending_hand_choice then
            local target_card_id = state.pending_hand_choice.legal_card_ids[1]
            choose_result = core.choose_hand_target(state, target_card_id)
        end
    end
    return {
        name = "one_turn",
        slot = slot,
        hand_card_id = hand_card_id,
        legal_count = legal and #legal or 0,
        result = result,
        choose_result = choose_result,
    }
end

return M
