local core = require("src.core.api")
local rules = require("src.core.rules")
local state_lib = require("src.core.state")

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
        elseif state.pending_public_choice then
            local target_card_id = state.pending_public_choice.legal_card_ids[1]
            choose_result = core.choose_public_target(state, target_card_id)
            if state.pending_hand_choice then
                local hand_target = state.pending_hand_choice.legal_card_ids[1]
                choose_result = core.choose_hand_target(state, hand_target)
            end
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

local function prepare_logic_turn(state)
    local slot
    local hand_card_id

    for i = 1, 6 do
        local manifest_id = state.zones.manifest.cards[i]
        if manifest_id then
            local legal = rules.legal_hand_ids(state, manifest_id)
            for _, candidate in ipairs(legal) do
                local card = state.cards[candidate]
                if card.op_a == "LOGIC" or card.op_b == "LOGIC" then
                    slot = i
                    hand_card_id = candidate
                    break
                end
            end
        end
        if hand_card_id then
            break
        end
    end

    if not hand_card_id then
        return nil, "no_logic_turn"
    end

    core.commit_manifest(state, slot)
    core.arm_hand(state, hand_card_id)
    local turn_result = core.resolve_turn(state, slot, hand_card_id)
    return {
        slot = slot,
        hand_card_id = hand_card_id,
        turn_result = turn_result,
    }
end

local function enter_logic_choice(state)
    local choose_result = core.choose_operator(state, "LOGIC")
    if not state.pending_public_choice then
        return nil, "no_pending_public_choice"
    end
    return choose_result
end

function M.logic_manifest_swap(state)
    local prep, err = prepare_logic_turn(state)
    if not prep then
        return nil, err
    end
    local choose_result, choose_err = enter_logic_choice(state)
    if not choose_result then
        return nil, choose_err
    end
    local target_card_id
    for _, candidate in ipairs(state.pending_public_choice.legal_card_ids or {}) do
        if state.cards[candidate].zone == "manifest" then
            target_card_id = candidate
            break
        end
    end
    if not target_card_id then
        return nil, "no_logic_manifest_target"
    end
    local target_slot = state.cards[target_card_id].slot
    local public_result = core.choose_public_target(state, target_card_id)
    local hand_target = state.pending_hand_choice and state.pending_hand_choice.legal_card_ids[1]
    if not hand_target then
        return nil, "no_logic_hand_target"
    end
    local hand_result = core.choose_hand_target(state, hand_target)
    if state.zones.manifest.cards[target_slot] ~= hand_target then
        return nil, "logic_manifest_swap_failed"
    end
    return {
        name = "logic_manifest_swap",
        target_card_id = target_card_id,
        target_slot = target_slot,
        inserted_card_id = hand_target,
        prep = prep,
        choose_result = choose_result,
        public_result = public_result,
        hand_result = hand_result,
    }
end

function M.logic_latent_swap(state)
    local prep, err = prepare_logic_turn(state)
    if not prep then
        return nil, err
    end
    local target_card_id
    local target_slot
    for slot = 1, state.zones.latent.slot_count do
        local card_id = state.zones.latent.cards[slot]
        if card_id and state.cards[card_id].class == "minor" then
            state_lib.reveal_card(state, card_id)
            target_card_id = card_id
            target_slot = slot
            break
        end
    end
    if not target_card_id then
        return nil, "no_logic_latent_target"
    end
    local choose_result, choose_err = enter_logic_choice(state)
    if not choose_result then
        return nil, choose_err
    end
    local public_result = core.choose_public_target(state, target_card_id)
    local hand_target = state.pending_hand_choice and state.pending_hand_choice.legal_card_ids[1]
    if not hand_target then
        return nil, "no_logic_hand_target"
    end
    local hand_result = core.choose_hand_target(state, hand_target)
    if state.zones.latent.cards[target_slot] ~= hand_target then
        return nil, "logic_latent_swap_failed"
    end
    return {
        name = "logic_latent_swap",
        target_card_id = target_card_id,
        target_slot = target_slot,
        inserted_card_id = hand_target,
        prep = prep,
        choose_result = choose_result,
        public_result = public_result,
        hand_result = hand_result,
    }
end

function M.logic_grave_swap(state)
    local prep, err = prepare_logic_turn(state)
    if not prep then
        return nil, err
    end
    local choose_result, choose_err = enter_logic_choice(state)
    if not choose_result then
        return nil, choose_err
    end
    local target_card_id
    for _, candidate in ipairs(state.pending_public_choice.legal_card_ids or {}) do
        if state.cards[candidate].zone == "grave" then
            target_card_id = candidate
            break
        end
    end
    if not target_card_id then
        return nil, "no_logic_grave_target"
    end
    local public_result = core.choose_public_target(state, target_card_id)
    local hand_target = state.pending_hand_choice and state.pending_hand_choice.legal_card_ids[1]
    if not hand_target then
        return nil, "no_logic_hand_target"
    end
    local hand_result = core.choose_hand_target(state, hand_target)
    if state.cards[hand_target].zone ~= "grave" then
        return nil, "logic_grave_swap_failed"
    end
    return {
        name = "logic_grave_swap",
        target_card_id = target_card_id,
        inserted_card_id = hand_target,
        prep = prep,
        choose_result = choose_result,
        public_result = public_result,
        hand_result = hand_result,
    }
end

function M.logic_topdeck_swap(state)
    local prep, err = prepare_logic_turn(state)
    if not prep then
        return nil, err
    end
    local deck = state.zones.deck.cards
    if #deck == 0 then
        return nil, "deck_empty"
    end
    local target_card_id
    for i = #deck, 1, -1 do
        local candidate = deck[i]
        if state.cards[candidate].class == "minor" then
            table.remove(deck, i)
            table.insert(deck, candidate)
            state_lib.sync_zone_cards(state, "deck")
            state_lib.reveal_card(state, candidate)
            target_card_id = candidate
            break
        end
    end
    if not target_card_id then
        return nil, "no_logic_topdeck_target"
    end
    local choose_result, choose_err = enter_logic_choice(state)
    if not choose_result then
        return nil, choose_err
    end
    local public_result = core.choose_public_target(state, target_card_id)
    local hand_target = state.pending_hand_choice and state.pending_hand_choice.legal_card_ids[1]
    if not hand_target then
        return nil, "no_logic_hand_target"
    end
    local hand_result = core.choose_hand_target(state, hand_target)
    if state.zones.deck.cards[#state.zones.deck.cards] ~= hand_target then
        return nil, "logic_topdeck_swap_failed"
    end
    return {
        name = "logic_topdeck_swap",
        target_card_id = target_card_id,
        inserted_card_id = hand_target,
        prep = prep,
        choose_result = choose_result,
        public_result = public_result,
        hand_result = hand_result,
    }
end

return M
