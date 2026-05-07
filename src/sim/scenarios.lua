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

local function legal_start_hand_cards(state)
    local out = {}
    for _, card_id in ipairs(state.zones.hand.cards) do
        if #rules.legal_manifest_slots_for_hand(state, card_id) > 0 then
            out[#out + 1] = card_id
        end
    end
    return out
end

local function same_list(a, b)
    if #a ~= #b then
        return false
    end
    for i = 1, #a do
        if a[i] ~= b[i] then
            return false
        end
    end
    return true
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

function M.interaction_start_surface(state)
    local ix = core.interaction(state)
    local expected_hand = legal_start_hand_cards(state)

    if ix.phase ~= "await_start" then
        return nil, "unexpected_phase"
    end
    if #ix.legal.commit_slots == 0 then
        return nil, "no_commit_slots_at_start"
    end
    if not same_list(ix.legal.hand_cards, expected_hand) then
        return nil, "start_hand_surface_mismatch"
    end
    if ix.advance and ix.advance.enabled then
        return nil, "start_advance_should_be_disabled"
    end
    if ix.legal.clears.selection or ix.legal.clears.committed or ix.legal.clears.armed then
        return nil, "start_clears_should_be_disabled"
    end

    return {
        name = "interaction_start_surface",
        hand_cards = ix.legal.hand_cards,
        commit_slots = ix.legal.commit_slots,
    }
end

function M.interaction_complete_from_commit(state)
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
    local ix = core.interaction(state)

    if ix.phase ~= "await_complete" then
        return nil, "unexpected_phase"
    end
    if ix.armed.hand_card_id ~= nil then
        return nil, "commit_only_should_not_arm_hand"
    end
    if not same_list(ix.legal.hand_cards, legal) then
        return nil, "commit_hand_surface_mismatch"
    end
    if not ix.legal.clears.selection or not ix.legal.clears.committed or ix.legal.clears.armed then
        return nil, "commit_clear_surface_mismatch"
    end

    return {
        name = "interaction_complete_from_commit",
        slot = slot,
        hand_cards = ix.legal.hand_cards,
        commit_slots = ix.legal.commit_slots,
    }
end

function M.interaction_complete_from_hand(state)
    local hand_card_id = legal_start_hand_cards(state)[1]
    if not hand_card_id then
        return nil, "no_legal_start_hand"
    end

    local expected_slots = rules.legal_manifest_slots_for_hand(state, hand_card_id)
    local expected_hand = legal_start_hand_cards(state)

    core.arm_hand(state, hand_card_id)
    local ix = core.interaction(state)

    if ix.phase ~= "await_complete" then
        return nil, "unexpected_phase"
    end
    if ix.armed.hand_card_id ~= hand_card_id then
        return nil, "hand_anchor_not_armed"
    end
    if not same_list(ix.legal.commit_slots, expected_slots) then
        return nil, "hand_commit_surface_mismatch"
    end
    if not same_list(ix.legal.hand_cards, expected_hand) then
        return nil, "hand_switch_surface_mismatch"
    end
    if not ix.legal.clears.selection or ix.legal.clears.committed or not ix.legal.clears.armed then
        return nil, "hand_clear_surface_mismatch"
    end

    return {
        name = "interaction_complete_from_hand",
        hand_card_id = hand_card_id,
        commit_slots = ix.legal.commit_slots,
        hand_cards = ix.legal.hand_cards,
    }
end

function M.interaction_ready_surface(state)
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

    local expected_commit = rules.legal_manifest_slots_for_hand(state, hand_card_id)
    core.commit_manifest(state, slot)
    core.arm_hand(state, hand_card_id)
    local ix = core.interaction(state)

    if ix.phase ~= "await_ready" then
        return nil, "unexpected_phase"
    end
    if not ix.advance or not ix.advance.enabled then
        return nil, "ready_advance_should_be_enabled"
    end
    if not same_list(ix.legal.commit_slots, expected_commit) then
        return nil, "ready_commit_surface_mismatch"
    end
    if not same_list(ix.legal.hand_cards, legal) then
        return nil, "ready_hand_surface_mismatch"
    end
    if not ix.legal.clears.selection or not ix.legal.clears.committed or not ix.legal.clears.armed then
        return nil, "ready_clear_surface_mismatch"
    end

    return {
        name = "interaction_ready_surface",
        slot = slot,
        hand_card_id = hand_card_id,
        commit_slots = ix.legal.commit_slots,
        hand_cards = ix.legal.hand_cards,
    }
end

function M.arm_hand_blocked_in_operator_phase(state)
    local info, err = M.one_turn_setup_only(state)
    if not info then
        return nil, err
    end

    local ix = core.interaction(state)
    if ix.phase ~= "await_operator" then
        return nil, "unexpected_phase"
    end

    local blocked_card_id = state.zones.hand.cards[1]
    if not blocked_card_id then
        return nil, "no_hand_card"
    end

    local before = state.armed_hand
    local result = core.apply_action(state, {
        kind = "arm_hand",
        card_id = blocked_card_id,
    })
    local summary = result and result.summary or {}
    if summary.error ~= "arm_hand_not_available" then
        return nil, "arm_hand_should_be_blocked"
    end
    if state.armed_hand ~= before then
        return nil, "armed_hand_mutated_in_operator_phase"
    end

    return {
        name = "arm_hand_blocked_in_operator_phase",
        hand_card_id = blocked_card_id,
        error = summary.error,
    }
end

function M.clear_actions_blocked_in_start(state)
    local ix = core.interaction(state)
    if ix.phase ~= "await_start" then
        return nil, "unexpected_phase"
    end

    local clear_selection = core.apply_action(state, {kind = "clear_selection"})
    local clear_committed = core.apply_action(state, {kind = "clear_committed"})
    local clear_armed = core.apply_action(state, {kind = "clear_armed"})

    if clear_selection.summary.error ~= "clear_selection_not_available" then
        return nil, "clear_selection_should_be_blocked"
    end
    if clear_committed.summary.error ~= "clear_committed_not_available" then
        return nil, "clear_committed_should_be_blocked"
    end
    if clear_armed.summary.error ~= "clear_armed_not_available" then
        return nil, "clear_armed_should_be_blocked"
    end

    return {
        name = "clear_actions_blocked_in_start",
        selection = clear_selection.summary.error,
        committed = clear_committed.summary.error,
        armed = clear_armed.summary.error,
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

function M.one_turn_setup_only(state)
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

    return {
        name = "one_turn_setup_only",
        slot = slot,
        hand_card_id = hand_card_id,
        legal_count = legal and #legal or 0,
        result = result,
    }
end

function M.one_turn(state)
    local setup, err = M.one_turn_setup_only(state)
    if not setup then
        return nil, err
    end

    local choose_result = nil
    if state.pending_operator_choice then
        local op_name = state.pending_operator_choice.choices[1]
        core.arm_operator(state, op_name)
        if state.pending_manifest_choice then
            local target_slot = state.pending_manifest_choice.legal_slots[1]
            core.arm_manifest_target(state, target_slot)
            choose_result = core.confirm_manifest_target(state)
        elseif state.pending_public_choice then
            local target_card_id = state.pending_public_choice.legal_card_ids[1]
            core.arm_public_target(state, target_card_id)
            choose_result = core.confirm_public_target(state)
            if state.pending_hand_choice then
                local hand_target = state.pending_hand_choice.legal_card_ids[1]
                core.arm_hand_target(state, hand_target)
                choose_result = core.confirm_hand_target(state)
            end
        elseif state.pending_pair_card_choice then
            local target_card_id = state.pending_pair_card_choice.legal_public_card_ids[1]
            if target_card_id then
                core.arm_pair_card_target(state, target_card_id)
            end
            local hand_target = state.pending_pair_card_choice.legal_hand_card_ids[1]
            if hand_target then
                core.arm_pair_card_target(state, hand_target)
            end
            choose_result = core.confirm_pair_card_target(state)
        elseif state.pending_hidden_choice then
            local target_card_id = state.pending_hidden_choice.legal_card_ids[1]
            core.arm_hidden_target(state, target_card_id)
            choose_result = core.confirm_hidden_target(state)
        elseif state.pending_unrevealed_choice then
            local target_card_id = state.pending_unrevealed_choice.legal_card_ids[1]
            core.arm_unrevealed_target(state, target_card_id)
            choose_result = core.confirm_unrevealed_target(state)
        else
            choose_result = core.confirm_operator_phase(state)
            if state.pending_hand_choice then
                local target_card_id = state.pending_hand_choice.legal_card_ids[1]
                core.arm_hand_target(state, target_card_id)
                choose_result = core.confirm_hand_target(state)
            end
        end
    end
    return {
        name = "one_turn",
        slot = setup.slot,
        hand_card_id = setup.hand_card_id,
        legal_count = setup.legal_count,
        result = setup.result,
        choose_result = choose_result,
    }
end

local function first_target_action(interaction)
    local targets = interaction.legal and interaction.legal.targets or {}
    if targets.slots and #targets.slots > 0 then
        return {
            kind = "arm_target",
            target = {
                kind = "slot",
                zone = targets.zones and targets.zones.manifest and "manifest" or nil,
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

function M.one_turn_via_protocol(state)
    local step_limit = 24
    local actions = {}
    local committed_slot = nil
    local played_hand = nil

    for _ = 1, step_limit do
        local ix = core.interaction(state)

        if ix.phase == "await_start" then
            local slot = ix.legal.commit_slots[1]
            if slot then
                committed_slot = slot
                local result = core.apply_action(state, {
                    kind = "commit_manifest",
                    slot = slot,
                })
                if result.summary and result.summary.error then
                    return nil, result.summary.error
                end
                actions[#actions + 1] = "commit:" .. tostring(slot)
            else
                local card_id = ix.legal.hand_cards[1]
                if not card_id then
                    return nil, "no_legal_turn"
                end
                played_hand = card_id
                local result = core.apply_action(state, {
                    kind = "arm_hand",
                    card_id = card_id,
                })
                if result.summary and result.summary.error then
                    return nil, result.summary.error
                end
                actions[#actions + 1] = "arm_hand:" .. tostring(card_id)
            end

        elseif ix.phase == "await_complete" then
            if not ix.armed.hand_card_id then
                local card_id = ix.legal.hand_cards[1]
                if not card_id then
                    return nil, "no_legal_hand_card"
                end
                played_hand = card_id
                local result = core.apply_action(state, {
                    kind = "arm_hand",
                    card_id = card_id,
                })
                if result.summary and result.summary.error then
                    return nil, result.summary.error
                end
                actions[#actions + 1] = "arm_hand:" .. tostring(card_id)
            else
                local slot = ix.legal.commit_slots[1]
                if not slot then
                    return nil, "no_commit_slot_for_armed_hand"
                end
                committed_slot = slot
                local result = core.apply_action(state, {
                    kind = "commit_manifest",
                    slot = slot,
                })
                if result.summary and result.summary.error then
                    return nil, result.summary.error
                end
                actions[#actions + 1] = "commit:" .. tostring(slot)
            end

        elseif ix.phase == "await_ready" then
            do
                local result = core.apply_action(state, {kind = "advance"})
                if result.summary and result.summary.error then
                    return nil, result.summary.error
                end
                actions[#actions + 1] = "advance:turn"
            end

        elseif ix.phase == "await_operator" then
            if not ix.armed.operator then
                local op_name = ix.legal.operators[1]
                if op_name then
                    local result = core.apply_action(state, {
                        kind = "arm_operator",
                        operator = op_name,
                    })
                    if result.summary and result.summary.error then
                        return nil, result.summary.error
                    end
                    actions[#actions + 1] = "arm_operator:" .. tostring(op_name)
                else
                    local result = core.apply_action(state, {kind = "advance"})
                    if result.summary and result.summary.error then
                        return nil, result.summary.error
                    end
                    actions[#actions + 1] = "advance:discharge"
                end
            else
                local result = core.apply_action(state, {kind = "advance"})
                if result.summary and result.summary.error then
                    return nil, result.summary.error
                end
                actions[#actions + 1] = "advance:operator"
            end

        elseif ix.phase == "await_target" then
            if not (ix.advance and ix.advance.enabled) then
                local action = first_target_action(ix)
                if not action then
                    return nil, "no_target_action"
                end
                local result = core.apply_action(state, action)
                if result.summary and result.summary.error then
                    return nil, result.summary.error
                end
                local target_desc = action.target.card_id or action.target.slot
                actions[#actions + 1] = "arm_target:" .. tostring(target_desc)
            else
                local result = core.apply_action(state, {kind = "advance"})
                if result.summary and result.summary.error then
                    return nil, result.summary.error
                end
                actions[#actions + 1] = "advance:target"
            end

        elseif ix.phase == "await_trump" or ix.phase == "idle" or ix.phase == "terminal" then
            break
        else
            return nil, "unknown_phase_" .. tostring(ix.phase)
        end
    end

    return {
        name = "one_turn_via_protocol",
        slot = committed_slot,
        hand_card_id = played_hand,
        actions = actions,
    }
end

function M.unrevealed_target_arm_toggle(state)
    local info, err = M.one_turn_setup_only(state)
    if not info then
        return nil, err
    end

    local op_name = state.pending_operator_choice.choices[1]
    if op_name ~= "MANIFEST" and state.pending_operator_choice.choices[2] == "MANIFEST" then
        op_name = "MANIFEST"
    end
    if op_name ~= "MANIFEST" then
        return nil, "no_manifest_operator"
    end

    core.arm_operator(state, op_name)
    if not state.pending_unrevealed_choice then
        return nil, "no_pending_unrevealed_choice"
    end

    local target_card_id = state.pending_unrevealed_choice.legal_card_ids[1]
    if not target_card_id then
        return nil, "no_unrevealed_target"
    end
    core.arm_unrevealed_target(state, target_card_id)
    if state.pending_unrevealed_choice.armed_card_id ~= target_card_id then
        return nil, "arm_unrevealed_target_failed"
    end
    core.arm_unrevealed_target(state, target_card_id)
    if state.pending_unrevealed_choice.armed_card_id ~= nil then
        return nil, "disarm_unrevealed_target_failed"
    end

    return {
        name = "unrevealed_target_arm_toggle",
        hand_card_id = info.hand_card_id,
        target_card_id = target_card_id,
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

local function arm_named_operator_choice(state, wanted)
    local pending = state.pending_operator_choice
    if not pending then
        return nil, "no_pending_operator_choice"
    end

    local op_name
    if pending.choices[1] == wanted then
        op_name = wanted
    elseif pending.choices[2] == wanted then
        op_name = wanted
    else
        return nil, "missing_operator_" .. wanted
    end

    local arm_result = core.arm_operator(state, op_name)
    if not arm_result then
        return nil, "operator_arm_failed_" .. wanted
    end
    return arm_result, nil, op_name
end

local function enter_logic_choice(state)
    local choose_result, err = arm_named_operator_choice(state, "LOGIC")
    if not choose_result then
        return nil, err or "logic_arm_failed"
    end
    if not state.pending_pair_card_choice then
        return nil, "no_pending_pair_card_choice"
    end
    return choose_result
end

function M.manifest_target_arm_toggle(state)
    local info, err = M.one_turn_setup_only(state)
    if not info then
        return nil, err
    end

    local choose_result, choose_err = arm_named_operator_choice(state, "CHOOSE")
    if not choose_result then
        return nil, choose_err
    end
    if not state.pending_manifest_choice then
        return nil, "no_pending_manifest_choice"
    end

    local slot = state.pending_manifest_choice.legal_slots[1]
    if not slot then
        return nil, "no_manifest_target"
    end

    core.arm_manifest_target(state, slot)
    if state.pending_manifest_choice.armed_slot ~= slot then
        return nil, "arm_manifest_target_failed"
    end
    core.arm_manifest_target(state, slot)
    if state.pending_manifest_choice.armed_slot ~= nil then
        return nil, "disarm_manifest_target_failed"
    end

    return {
        name = "manifest_target_arm_toggle",
        hand_card_id = info.hand_card_id,
        target_slot = slot,
    }
end

function M.hidden_target_arm_toggle(state)
    local info, err = M.one_turn_setup_only(state)
    if not info then
        return nil, err
    end

    local choose_result, choose_err = arm_named_operator_choice(state, "OBSERVE")
    if not choose_result then
        return nil, choose_err
    end
    if not state.pending_hidden_choice then
        return nil, "no_pending_hidden_choice"
    end

    local target_card_id = state.pending_hidden_choice.legal_card_ids[1]
    if not target_card_id then
        return nil, "no_hidden_target"
    end

    core.arm_hidden_target(state, target_card_id)
    if state.pending_hidden_choice.armed_card_id ~= target_card_id then
        return nil, "arm_hidden_target_failed"
    end
    core.arm_hidden_target(state, target_card_id)
    if state.pending_hidden_choice.armed_card_id ~= nil then
        return nil, "disarm_hidden_target_failed"
    end

    return {
        name = "hidden_target_arm_toggle",
        hand_card_id = info.hand_card_id,
        target_card_id = target_card_id,
    }
end

function M.public_target_arm_toggle(state)
    local prep, err = prepare_logic_turn(state)
    if not prep then
        return nil, err
    end
    local choose_result, choose_err = enter_logic_choice(state)
    if not choose_result then
        return nil, choose_err
    end

    local target_card_id = state.pending_pair_card_choice.legal_public_card_ids[1]
    if not target_card_id then
        return nil, "no_public_target"
    end

    core.arm_pair_card_target(state, target_card_id)
    if state.pending_pair_card_choice.armed_public_card_id ~= target_card_id then
        return nil, "arm_public_target_failed"
    end
    core.arm_pair_card_target(state, target_card_id)
    if state.pending_pair_card_choice.armed_public_card_id ~= nil then
        return nil, "disarm_public_target_failed"
    end

    return {
        name = "public_target_arm_toggle",
        hand_card_id = prep.hand_card_id,
        target_card_id = target_card_id,
    }
end

function M.hand_target_arm_toggle(state)
    local prep, err = prepare_logic_turn(state)
    if not prep then
        return nil, err
    end
    local choose_result, choose_err = enter_logic_choice(state)
    if not choose_result then
        return nil, choose_err
    end

    local public_target = state.pending_pair_card_choice.legal_public_card_ids[1]
    if not public_target then
        return nil, "no_public_target"
    end
    local hand_target = state.pending_pair_card_choice.legal_hand_card_ids[1]
    if not hand_target then
        return nil, "no_hand_target"
    end

    core.arm_pair_card_target(state, public_target)
    core.arm_pair_card_target(state, hand_target)
    if state.pending_pair_card_choice.armed_hand_card_id ~= hand_target then
        return nil, "arm_hand_target_failed"
    end
    core.arm_pair_card_target(state, hand_target)
    if state.pending_pair_card_choice.armed_hand_card_id ~= nil then
        return nil, "disarm_hand_target_failed"
    end

    return {
        name = "hand_target_arm_toggle",
        hand_card_id = prep.hand_card_id,
        target_card_id = hand_target,
    }
end

function M.operator_arm_toggle(state)
    local info, err = M.one_turn_setup_only(state)
    if not info then
        return nil, err
    end

    local op_a = state.pending_operator_choice.choices[1]
    local arm_a = core.arm_operator(state, op_a)
    if state.pending_operator_choice.armed_operator ~= op_a then
        return nil, "arm_operator_a_failed"
    end

    local disarm = core.arm_operator(state, op_a)
    if state.pending_operator_choice.armed_operator ~= nil then
        return nil, "disarm_operator_failed"
    end

    local op_b = state.pending_operator_choice.choices[2]
    local arm_b = core.arm_operator(state, op_b)
    if state.pending_operator_choice.armed_operator ~= op_b then
        return nil, "arm_operator_b_failed"
    end

    return {
        name = "operator_arm_toggle",
        slot = info.slot,
        hand_card_id = info.hand_card_id,
        arm_a = arm_a,
        disarm = disarm,
        arm_b = arm_b,
    }
end

function M.operator_skip_discharge(state)
    local info, err = M.one_turn_setup_only(state)
    if not info then
        return nil, err
    end

    local play_card_id = state.zones.play.cards[1]
    if not play_card_id then
        return nil, "missing_play_card"
    end

    local result = core.confirm_operator_phase(state)
    if state.pending_operator_choice then
        return nil, "pending_operator_not_cleared"
    end
    if state.cards[play_card_id].zone ~= "grave" then
        return nil, "operator_skip_did_not_discharge"
    end

    return {
        name = "operator_skip_discharge",
        slot = info.slot,
        hand_card_id = info.hand_card_id,
        play_card_id = play_card_id,
        result = result,
    }
end

function M.action_protocol_skip_turn(state)
    local slot
    local hand_card_id
    for i = 1, 6 do
        local candidate, _ = first_legal_hand(state, i)
        if candidate then
            slot = i
            hand_card_id = candidate
            break
        end
    end
    if not slot or not hand_card_id then
        return nil, "no_legal_turn"
    end

    local result
    result = core.apply_action(state, {kind = "commit_manifest", slot = slot})
    if result.summary and result.summary.error then
        return nil, result.summary.error
    end

    result = core.apply_action(state, {kind = "arm_hand", card_id = hand_card_id})
    if result.summary and result.summary.error then
        return nil, result.summary.error
    end

    result = core.apply_action(state, {kind = "advance"})
    if result.summary and result.summary.error then
        return nil, result.summary.error
    end

    if not state.pending_operator_choice then
        return nil, "missing_operator_phase"
    end

    local play_card_id = state.zones.play.cards[1]
    result = core.apply_action(state, {kind = "advance"})
    if result.summary and result.summary.error then
        return nil, result.summary.error
    end

    if state.pending_operator_choice then
        return nil, "pending_operator_not_cleared"
    end
    if state.cards[play_card_id].zone ~= "grave" then
        return nil, "operator_skip_did_not_discharge"
    end

    return {
        name = "action_protocol_skip_turn",
        slot = slot,
        hand_card_id = hand_card_id,
        play_card_id = play_card_id,
    }
end

function M.action_protocol_manifest_target(state)
    local info, err = M.one_turn_setup_only(state)
    if not info then
        return nil, err
    end

    local pending = state.pending_operator_choice
    local op_name
    if pending.choices[1] == "MANIFEST" then
        op_name = "MANIFEST"
    elseif pending.choices[2] == "MANIFEST" then
        op_name = "MANIFEST"
    else
        return nil, "no_manifest_operator"
    end

    local result = core.apply_action(state, {kind = "arm_operator", operator = op_name})
    if result.summary and result.summary.error then
        return nil, result.summary.error
    end
    if not state.pending_unrevealed_choice then
        return nil, "no_pending_unrevealed_choice"
    end

    local target_card_id = state.pending_unrevealed_choice.legal_card_ids[1]
    if not target_card_id then
        return nil, "no_unrevealed_target"
    end

    result = core.apply_action(state, {
        kind = "arm_target",
        target = {kind = "card", card_id = target_card_id},
    })
    if result.summary and result.summary.error then
        return nil, result.summary.error
    end
    if state.pending_unrevealed_choice.armed_card_id ~= target_card_id then
        return nil, "arm_unrevealed_target_failed"
    end

    result = core.apply_action(state, {kind = "advance"})
    if result.summary and result.summary.error then
        return nil, result.summary.error
    end
    if state.pending_unrevealed_choice or state.pending_operator_choice then
        return nil, "manifest_target_not_resolved"
    end

    return {
        name = "action_protocol_manifest_target",
        hand_card_id = info.hand_card_id,
        target_card_id = target_card_id,
    }
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
    for _, candidate in ipairs(state.pending_pair_card_choice.legal_public_card_ids or {}) do
        if state.cards[candidate].zone == "manifest" then
            target_card_id = candidate
            break
        end
    end
    if not target_card_id then
        return nil, "no_logic_manifest_target"
    end
    local target_slot = state.cards[target_card_id].slot
    core.arm_pair_card_target(state, target_card_id)
    local hand_target = state.pending_pair_card_choice and state.pending_pair_card_choice.legal_hand_card_ids[1]
    if not hand_target then
        return nil, "no_logic_hand_target"
    end
    core.arm_pair_card_target(state, hand_target)
    local hand_result = core.confirm_pair_card_target(state)
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
    core.arm_pair_card_target(state, target_card_id)
    local hand_target = state.pending_pair_card_choice and state.pending_pair_card_choice.legal_hand_card_ids[1]
    if not hand_target then
        return nil, "no_logic_hand_target"
    end
    core.arm_pair_card_target(state, hand_target)
    local hand_result = core.confirm_pair_card_target(state)
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
    for _, candidate in ipairs(state.pending_pair_card_choice.legal_public_card_ids or {}) do
        if state.cards[candidate].zone == "grave" then
            target_card_id = candidate
            break
        end
    end
    if not target_card_id then
        return nil, "no_logic_grave_target"
    end
    core.arm_pair_card_target(state, target_card_id)
    local hand_target = state.pending_pair_card_choice and state.pending_pair_card_choice.legal_hand_card_ids[1]
    if not hand_target then
        return nil, "no_logic_hand_target"
    end
    core.arm_pair_card_target(state, hand_target)
    local hand_result = core.confirm_pair_card_target(state)
    if state.cards[hand_target].zone ~= "grave" then
        return nil, "logic_grave_swap_failed"
    end
    return {
        name = "logic_grave_swap",
        target_card_id = target_card_id,
        inserted_card_id = hand_target,
        prep = prep,
        choose_result = choose_result,
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
    core.arm_pair_card_target(state, target_card_id)
    local hand_target = state.pending_pair_card_choice and state.pending_pair_card_choice.legal_hand_card_ids[1]
    if not hand_target then
        return nil, "no_logic_hand_target"
    end
    core.arm_pair_card_target(state, hand_target)
    local hand_result = core.confirm_pair_card_target(state)
    if state.zones.deck.cards[#state.zones.deck.cards] ~= hand_target then
        return nil, "logic_topdeck_swap_failed"
    end
    return {
        name = "logic_topdeck_swap",
        target_card_id = target_card_id,
        inserted_card_id = hand_target,
        prep = prep,
        choose_result = choose_result,
        hand_result = hand_result,
    }
end

return M
