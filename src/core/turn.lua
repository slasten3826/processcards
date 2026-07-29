local state_lib = require("src.core.state")
local rules = require("src.core.rules")
local draw = require("src.core.draw")
local repair = require("src.core.repair")
local trump = require("src.core.trump")
local transition = require("src.core.transition")
local operators = require("src.core.operators")
local win = require("src.core.win")

local M = {}

-- STEP_CHECK_LAW: the ninth step is the turn ASKING the win module. The turn
-- owns the step boundaries; the module does not know steps exist.
--
-- Exported so game.lua can call the same function. Both places used to carry
-- their own copy of the two emits, which is the shape that already produced a
-- defect once: play_to_grave lived in eleven places and one path went
-- uninstrumented.
function M.step_check(state)
    transition.emit(state, "step_check_begin", {})
    local outcome = win.request(state, {signature = "TURN"})
    transition.emit(state, "step_check_end", {
        outcome = outcome and outcome.by or nil,
    })
end

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
    return legal
end

function M.arm_hand(state, card_id)
    if not state.committed then
        if state.armed_hand == card_id then
            state.armed_hand = nil
        else
            state.armed_hand = card_id
        end
        return state.armed_hand
    end
    if not state.legal_hints[card_id] then
        return nil, "illegal_hand_card"
    end
    if state.armed_hand == card_id then
        state.armed_hand = nil
    else
        state.armed_hand = card_id
    end
    return state.armed_hand
end

function M.clear_selection(state)
    state.committed = nil
    state.legal_hints = {}
    state.armed_hand = nil
end

function M.clear_committed(state)
    state.committed = nil
    state.legal_hints = {}
end

function M.clear_armed(state)
    state.armed_hand = nil
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

local function perform_ordinary_world_update(state, slot, manifest_id)
    move_to_grave(state, manifest_id)
    transition.emit(state, "manifest_to_grave", {
        card_id = manifest_id,
        slot = slot,
    })
    repair.repair_manifest_slot(state, slot)
end

local function resolve_dissolve_column_burn(state, slot)
    local latent_id = state.zones.latent.cards[slot]
    if not latent_id then
        transition.emit(state, "dissolve_skipped", {
            slot = slot,
            reason = "empty_latent",
        })
        return nil
    end

    state_lib.remove_from_current_zone(state, latent_id)
    state_lib.reveal_card(state, latent_id)

    if state.cards[latent_id].class == "trump" then
        transition.emit(state, "latent_trump_revealed", {
            card_id = latent_id,
            slot = slot,
            reason = "dissolve",
        })
        trump.enter_trump_flow(state, latent_id, "dissolve")
    else
        state_lib.place_card(state, latent_id, "grave", nil)
        transition.emit(state, "latent_to_grave", {
            card_id = latent_id,
            slot = slot,
            operator = "DISSOLVE",
        })
    end

    draw.concealed_refill(state, "latent", slot)
    return latent_id
end

local function operator_choice_is_legal(choices, op_name)
    for _, choice in ipairs(choices or {}) do
        if op_name == choice then
            return true
        end
    end
    return false
end

local function choices_include(choices, op_name)
    return operator_choice_is_legal(choices, op_name)
end

local function card_choice_is_legal(legal_card_ids, card_id)
    for _, legal_card_id in ipairs(legal_card_ids or {}) do
        if legal_card_id == card_id then
            return true
        end
    end
    return false
end

local function slot_choice_is_legal(legal_slots, slot)
    for _, legal_slot in ipairs(legal_slots or {}) do
        if legal_slot == slot then
            return true
        end
    end
    return false
end

local function clear_operator_target_phases(state)
    state.pending_flow_choice = nil
    state.pending_encode_choice = nil
    state.pending_pair_card_choice = nil
    state.pending_public_choice = nil
    state.pending_hidden_choice = nil
    state.pending_hand_choice = nil
    state.pending_manifest_choice = nil
    state.pending_unrevealed_choice = nil
end

-- FLOW no longer opens a target phase: the ring rotation takes no target and
-- no direction, so it resolves immediately like CONNECT.
-- FLOW rotates the ring and LOGIC is a pass; neither takes a target.
local function operator_opens_target_phase(op_name)
    return op_name == "ENCODE"
        or op_name == "CHOOSE"
        or op_name == "OBSERVE"
        or op_name == "MANIFEST"
end

local function runtime_granted_operators(state)
    local runtime_card_id = state.zones.runtime.cards[1]
    if not runtime_card_id then
        return {}
    end

    local runtime_card = state.cards[runtime_card_id]
    if not runtime_card then
        return {}
    end

    if runtime_card.op_a == "RUNTIME" and runtime_card.op_b == "RUNTIME" then
        return {"RUNTIME"}
    end

    if runtime_card.op_a == "RUNTIME" then
        return {runtime_card.op_b}
    end

    if runtime_card.op_b == "RUNTIME" then
        return {runtime_card.op_a}
    end

    return {runtime_card.op_a, runtime_card.op_b}
end

-- ENCODE_SWAP_LAW: the latent row entire, with no condition on information
-- state. The topdeck and the target zone leave the operator's scope. Swapping
-- two unknowns has zero expectation and stays legal anyway: useless is not
-- forbidden here, the incentive does the selecting.
local function legal_encode_card_ids(state)
    local legal = {}
    local zone = state.zones.latent
    for slot = 1, zone.slot_count do
        local card_id = zone.cards[slot]
        if card_id then
            legal[#legal + 1] = card_id
        end
    end
    return legal
end

local function legal_flow_card_ids(state)
    local legal = {}

    local function append_zone_if_movable(zone_name)
        local zone = state.zones[zone_name]
        local movable = {}
        for slot = 1, zone.slot_count do
            local card_id = zone.cards[slot]
            if card_id and not state_lib.is_revealed(state, card_id) then
                movable[#movable + 1] = card_id
            end
        end
        if #movable > 1 then
            for _, card_id in ipairs(movable) do
                legal[#legal + 1] = card_id
            end
        end
    end

    append_zone_if_movable("targets")
    append_zone_if_movable("latent")

    local deck = state.zones.deck.cards
    local concealed_count = 0
    for _, card_id in ipairs(deck) do
        if not state_lib.is_revealed(state, card_id) then
            concealed_count = concealed_count + 1
        end
    end
    if concealed_count > 1 then
        local topdeck = deck[#deck]
        if topdeck and not state_lib.is_revealed(state, topdeck) then
            legal[#legal + 1] = topdeck
        end
    end

    return legal
end

local function runtime_install_allowed(state, card_id)
    local card = state.cards[card_id]
    if not card then
        return false
    end

    if card.op_a == "RUNTIME" or card.op_b == "RUNTIME" then
        return true
    end

    local runtime_card_id = state.zones.runtime.cards[1]
    if not runtime_card_id then
        return false
    end

    local runtime_card = state.cards[runtime_card_id]
    return runtime_card and runtime_card.op_a == "RUNTIME" and runtime_card.op_b == "RUNTIME"
end

local function runtime_install_granted_operators(state, card_id)
    local card = state.cards[card_id]
    if not card then
        return {}
    end

    if card.op_a == "RUNTIME" and card.op_b == "RUNTIME" then
        return {"RUNTIME"}
    end

    if card.op_a == "RUNTIME" then
        return {card.op_b}
    end

    if card.op_b == "RUNTIME" then
        return {card.op_a}
    end

    return {card.op_a, card.op_b}
end

local function rotate_slots(zone, slots, direction)
    if #slots < 2 then
        return
    end

    local values = {}
    for i, slot in ipairs(slots) do
        values[i] = zone.cards[slot]
    end

    if direction == "left" then
        for i, slot in ipairs(slots) do
            local src = i + 1
            if src > #slots then
                src = 1
            end
            zone.cards[slot] = values[src]
        end
    else
        for i, slot in ipairs(slots) do
            local src = i - 1
            if src < 1 then
                src = #slots
            end
            zone.cards[slot] = values[src]
        end
    end
end

local function rotate_deck(state, direction)
    local deck = state.zones.deck.cards
    if #deck < 2 then
        return
    end

    local fixed_top = false
    local topdeck = deck[#deck]
    if topdeck and state_lib.is_revealed(state, topdeck) then
        fixed_top = true
    end

    local last_movable = fixed_top and (#deck - 1) or #deck
    if last_movable <= 1 then
        return
    end

    if direction == "left" then
        local top_index = fixed_top and last_movable or #deck
        local card_id = table.remove(deck, top_index)
        table.insert(deck, 1, card_id)
    else
        local card_id = table.remove(deck, 1)
        table.insert(deck, fixed_top and last_movable or #deck + 1, card_id)
    end

    state_lib.sync_zone_cards(state, "deck")
end

-- FLOW ring, per docs/table/OPERATOR_REVISION_PROPOSAL_2026-07-26.md 2.1
--
--     topdeck -> latent1 -> ... -> latent6 -> deck bottom -> ... -> topdeck
--
-- Only not-known cards move. known and revealed are anchors and hold the
-- flow: a moving card travels to the next not-known position, skipping them.
-- The target zone is not part of the ring. One direction only, because a
-- direction choice is CHOOSE inside FLOW, and FLOW moves only cards whose
-- identity is unknown, so the choice would have no information to stand on.
--
-- The ring is closed, so nothing is created or destroyed: latent6 goes under
-- the deck and the top of the deck becomes a concealed draw into latent1.
local function flow_ring_positions(state)
    local positions = {}
    local latent = state.zones.latent
    for slot = 1, latent.slot_count do
        positions[#positions + 1] = {zone = "latent", slot = slot}
    end
    local deck = state.zones.deck.cards
    for index = 1, #deck do
        positions[#positions + 1] = {zone = "deck", index = index}
    end
    return positions
end

local function ring_card_at(state, position)
    if position.zone == "latent" then
        return state.zones.latent.cards[position.slot]
    end
    return state.zones.deck.cards[position.index]
end

local function ring_set_card(state, position, card_id)
    if position.zone == "latent" then
        state.zones.latent.cards[position.slot] = card_id
        return
    end
    state.zones.deck.cards[position.index] = card_id
end

local function flow_ring_rotate(state)
    local movable = {}
    for _, position in ipairs(flow_ring_positions(state)) do
        local card_id = ring_card_at(state, position)
        -- FLOW_RING_LAW §2: the anchor is REVEALED, not known. A known card is
        -- identified to the player but not shown on the board, and the ring
        -- carries it like any other. Anchoring on is_known gave OBSERVE two
        -- jobs at once and took MANIFEST's only job in the ring away.
        if card_id and not state_lib.is_revealed(state, card_id) then
            movable[#movable + 1] = {position = position, card_id = card_id}
        end
    end

    if #movable < 2 then
        transition.emit(state, "flow_ring_skipped", {
            movable = #movable,
            reason = "not_enough_not_revealed_cards",
        })
        return 0
    end

    for index, entry in ipairs(movable) do
        local destination = movable[index + 1] or movable[1]
        ring_set_card(state, destination.position, entry.card_id)
    end

    state_lib.sync_zone_cards(state, "latent")
    state_lib.sync_zone_cards(state, "deck")

    transition.emit(state, "flow_ring_rotated", {
        moved = #movable,
        anchors = #flow_ring_positions(state) - #movable,
    })
    return #movable
end

-- exported so the ring law can be checked directly, without having to reach
-- it through a full turn
M.flow_ring_rotate = flow_ring_rotate

local function flow_rotate_zone(state, zone_name, direction)
    if zone_name == "deck" then
        rotate_deck(state, direction)
        return
    end

    local zone = state.zones[zone_name]
    local movable_slots = {}
    for slot = 1, zone.slot_count do
        local card_id = zone.cards[slot]
        if card_id and not state_lib.is_revealed(state, card_id) then
            movable_slots[#movable_slots + 1] = slot
        end
    end
    rotate_slots(zone, movable_slots, direction)
    state_lib.sync_zone_cards(state, zone_name)
end

local function operator_choices_for_card(state, card_id)
    local card = state.cards[card_id]
    if not card then
        return nil
    end

    -- A double card is an ordinary minor; the only difference is that there is
    -- nothing to choose. Without this dedupe it offered the same operator
    -- twice as two separate options.
    local choices = {card.op_a}
    local seen = {[card.op_a] = true}
    if not seen[card.op_b] then
        choices[#choices + 1] = card.op_b
        seen[card.op_b] = true
    end
    for _, op_name in ipairs(runtime_granted_operators(state)) do
        if not seen[op_name] then
            choices[#choices + 1] = op_name
            seen[op_name] = true
        end
    end
    return choices
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

local function legal_not_revealed_board_card_ids(state)
    local legal = {}

    local function maybe_add(card_id)
        if card_id and state.cards[card_id] and not state_lib.is_revealed(state, card_id) then
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

local function legal_public_minor_card_ids(state)
    local legal = {}

    local function maybe_add(card_id)
        if not card_id then
            return
        end
        local card = state.cards[card_id]
        if not card or card.class ~= "minor" or not state_lib.is_revealed(state, card_id) then
            return
        end
        legal[#legal + 1] = card_id
    end

    maybe_add(state.zones.deck.cards[#state.zones.deck.cards])

    for _, zone_name in ipairs({"manifest", "latent", "grave"}) do
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

local function card_in_hand(state, card_id)
    local card = state.cards[card_id]
    return card and card.zone == "hand"
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
    local choices = operator_choices_for_card(state, hand_card_id)
    -- LOGIC_JOKER_LAW: a move is a joker move only when it would NOT have
    -- passed the ordinary topology check on its own. A card carrying LOGIC
    -- whose fit closes normally keeps its full operator choice.
    local joker_move = not rules.full_pair_fit(state.cards[manifest_id], state.cards[hand_card_id])
    -- TURN_STEP_LAW: the world update is deferred when any available operator
    -- binds to BURN. Same answer as the old DISSOLVE check while DISSOLVE is
    -- the only operator on that step.
    local defer_world_update = false
    for _, choice_name in ipairs(choices) do
        if operators.step_of(choice_name) == "BURN" then
            defer_world_update = true
        end
    end
    if not defer_world_update then
        perform_ordinary_world_update(state, slot, manifest_id)
    end
    state_lib.clear_gameplay_selection(state)

    state.pending_operator_choice = {
        card_id = hand_card_id,
        choices = joker_move and {"LOGIC"} or choices,
        armed_operator = nil,
        turn_context = {
            slot = slot,
            manifest_card_id = manifest_id,
            defer_world_update = defer_world_update,
            joker_move = joker_move,
        },
    }
    transition.emit(state, "operator_choice_pending", {
        card_id = hand_card_id,
        choices = state.pending_operator_choice.choices,
        armed_operator = state.pending_operator_choice.armed_operator,
    })
    return transition.finish(state, {
        board_closed = state_lib.is_board_closed(state),
        pending_operator_choice = state.pending_operator_choice,
        pending_trump = state.pending_trump,
    })
end

function M.arm_operator(state, op_name)
    local pending = state.pending_operator_choice
    if not pending then
        return nil, "no_pending_operator_choice"
    end
    local card_id = pending.card_id
    local choices = pending.choices or operator_choices_for_card(state, card_id) or {}
    if op_name ~= nil and not operator_choice_is_legal(choices, op_name) then
        return nil, "illegal_operator_choice"
    end

    transition.begin(state, "arm_operator", {
        card_id = card_id,
        operator = op_name,
    })

    if pending.armed_operator == op_name then
        op_name = nil
    end
    state_lib.set_armed_operator(state, op_name)
    clear_operator_target_phases(state)

    if pending.turn_context and pending.turn_context.defer_world_update
        and op_name ~= nil and operators.step_of(op_name) ~= "BURN" then
        perform_ordinary_world_update(state, pending.turn_context.slot, pending.turn_context.manifest_card_id)
        pending.turn_context.defer_world_update = false
    end

    if op_name == "CHOOSE" then
        local legal_slots = {}
        for slot = 1, state.zones.manifest.slot_count do
            local manifest_id = state.zones.manifest.cards[slot]
            if manifest_id and state_lib.is_revealed(state, manifest_id) then
                legal_slots[#legal_slots + 1] = slot
            end
        end
        state.pending_manifest_choice = {
            card_id = card_id,
            operator = op_name,
            legal_slots = legal_slots,
            armed_slot = nil,
        }
        transition.emit(state, "manifest_choice_pending", {
            card_id = card_id,
            operator = op_name,
            legal_slots = legal_slots,
        })
    elseif op_name == "ENCODE" then
        local legal_card_ids = legal_encode_card_ids(state)
        state.pending_encode_choice = {
            card_id = card_id,
            operator = op_name,
            legal_card_ids = legal_card_ids,
            armed_first_card_id = nil,
            armed_second_card_id = nil,
        }
        transition.emit(state, "encode_choice_pending", {
            card_id = card_id,
            operator = op_name,
            legal_card_ids = legal_card_ids,
        })
    elseif op_name == "OBSERVE" then
        local legal_card_ids = legal_hidden_board_card_ids(state)
        state.pending_hidden_choice = {
            card_id = card_id,
            operator = op_name,
            legal_card_ids = legal_card_ids,
            armed_card_id = nil,
        }
        transition.emit(state, "hidden_choice_pending", {
            card_id = card_id,
            operator = op_name,
            legal_card_ids = legal_card_ids,
        })
    elseif op_name == "MANIFEST" then
        local legal_card_ids = legal_not_revealed_board_card_ids(state)
        state.pending_unrevealed_choice = {
            card_id = card_id,
            operator = op_name,
            legal_card_ids = legal_card_ids,
            armed_card_id = nil,
        }
        transition.emit(state, "unrevealed_choice_pending", {
            card_id = card_id,
            operator = op_name,
            legal_card_ids = legal_card_ids,
        })
    end

    transition.emit(state, "operator_armed", {
        card_id = card_id,
        armed_operator = pending.armed_operator,
    })

    return transition.finish(state, {
        card_id = card_id,
        pending_operator_choice = state.pending_operator_choice,
        pending_pair_card_choice = state.pending_pair_card_choice,
        pending_public_choice = state.pending_public_choice,
        pending_hidden_choice = state.pending_hidden_choice,
        pending_hand_choice = state.pending_hand_choice,
        pending_manifest_choice = state.pending_manifest_choice,
        pending_unrevealed_choice = state.pending_unrevealed_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

-- TURN_STEP_LAW steps 7 to 9. Every path that finishes a turn must pass
-- through here, otherwise the queue is never made visible and a trump raised
-- during that turn does not drain in its own step 8. There are twelve such
-- paths: the general operator path, the RUNTIME install, the discharge, and
-- every target-phase confirm.
local function close_turn(state)
    transition.emit(state, "step_spend_end", {})
    trump.refresh_pending_trump(state)
    transition.emit(state, "step_trump_begin", {
        pending_trump = state.pending_trump,
    })
    if not state.pending_trump then
        transition.emit(state, "step_trump_end", {})
        M.step_check(state)
        transition.emit(state, "turn_closed", {})
    end
end

local function start_operator_effect(state, op_name)
    local pending = state.pending_operator_choice
    local card_id = pending.card_id

    if op_name == "RUNTIME" then
        if not runtime_install_allowed(state, card_id) then
            return nil, "runtime_install_not_available"
        end

        local replaced_card_id = state.zones.runtime.cards[1]
        if replaced_card_id then
            state_lib.remove_from_current_zone(state, replaced_card_id)
            move_to_grave(state, replaced_card_id)
            transition.emit(state, "runtime_to_grave", {
                card_id = replaced_card_id,
                replaced_by = card_id,
            })
        end

        state_lib.remove_from_current_zone(state, card_id)
        state_lib.reveal_card(state, card_id)
        state_lib.place_card(state, card_id, "runtime", 1)
        transition.emit(state, "play_to_runtime", {
            card_id = card_id,
            granted_operators = runtime_install_granted_operators(state, card_id),
        })
        operators.finish_runtime(state, card_id, runtime_install_granted_operators(state, card_id))

        state.pending_operator_choice = nil
        state_lib.clear_gameplay_selection(state)
        close_turn(state)
    
        return transition.finish(state, {
            operator = op_name,
            pending_operator_choice = state.pending_operator_choice,
            pending_trump = state.pending_trump,
            board_closed = state_lib.is_board_closed(state),
        })
    end

    if op_name == "LOGIC" then
        -- LOGIC_JOKER_LAW: the effect was spent by legalising the move, so
        -- nothing resolves here. The turn still turns the machine.
        local joker = pending.turn_context and pending.turn_context.joker_move or false
        transition.emit(state, "operator_effect_begin", {operator = op_name, joker = joker})
        if joker then
            transition.emit(state, "logic_joker_pass", {
                card_id = card_id,
                manifest_card_id = pending.turn_context and pending.turn_context.manifest_card_id or nil,
            })
        end
        transition.emit(state, "operator_effect_end", {operator = op_name})
    elseif op_name == "CYCLE" then
        -- CYCLE_ADVANCE_LAW: the committed column advances a second time, on
        -- its NEW state. The manifest card is read from the board, not from
        -- turn_context, which still holds the card the first advance already
        -- sent to the grave.
        local slot = pending.turn_context and pending.turn_context.slot
        local current_manifest_id = slot and state.zones.manifest.cards[slot]
        transition.emit(state, "operator_effect_begin", {operator = op_name})
        if slot and current_manifest_id then
            transition.emit(state, "cycle_second_advance", {slot = slot})
            perform_ordinary_world_update(state, slot, current_manifest_id)
        else
            transition.emit(state, "cycle_advance_skipped", {
                slot = slot,
                reason = slot and "empty_manifest_slot" or "no_slot",
            })
        end
        transition.emit(state, "operator_effect_end", {operator = op_name})
    elseif op_name == "FLOW" then
        transition.emit(state, "operator_effect_begin", {operator = op_name})
        flow_ring_rotate(state)
        operators.finish_flow(state, "ring", "forward")
    else
        operators.resolve(state, op_name)
    end

    move_to_grave(state, card_id)
    transition.emit(state, "play_to_grave", {
        card_id = card_id,
        operator = op_name,
    })

    state.pending_operator_choice = nil
    state_lib.clear_gameplay_selection(state)
    close_turn(state)

    return transition.finish(state, {
        operator = op_name,
        board_closed = state_lib.is_board_closed(state),
        pending_operator_choice = state.pending_operator_choice,
        pending_trump = state.pending_trump,
    })
end

function M.confirm_operator_phase(state)
    local pending = state.pending_operator_choice
    if not pending then
        return nil, "no_pending_operator_choice"
    end

    local card_id = pending.card_id
    local choices = pending.choices or operator_choices_for_card(state, card_id) or {}
    local op_name = pending.armed_operator
    if op_name ~= nil and not operator_choice_is_legal(choices, op_name) then
        return nil, "illegal_operator_choice"
    end

    transition.begin(state, "confirm_operator_phase", {
        card_id = card_id,
        operator = op_name,
    })

    transition.emit(state, "operator_phase_confirmed", {
        card_id = card_id,
        operator = op_name,
    })

    if op_name == nil then
        clear_operator_target_phases(state)
        if pending.turn_context and pending.turn_context.defer_world_update then
            perform_ordinary_world_update(state, pending.turn_context.slot, pending.turn_context.manifest_card_id)
            pending.turn_context.defer_world_update = false
        end
        move_to_grave(state, card_id)
        transition.emit(state, "play_to_grave", {
            card_id = card_id,
            operator = nil,
        })

        state.pending_operator_choice = nil
        state_lib.clear_gameplay_selection(state)
        close_turn(state)
    
        return transition.finish(state, {
            operator = nil,
            board_closed = state_lib.is_board_closed(state),
            pending_operator_choice = state.pending_operator_choice,
            pending_trump = state.pending_trump,
        })
    end

    if op_name == "DISSOLVE" then
        local turn_context = pending.turn_context
        if not turn_context then
            return nil, "missing_turn_context"
        end

        local dissolved_card_id = resolve_dissolve_column_burn(state, turn_context.slot)
        perform_ordinary_world_update(state, turn_context.slot, turn_context.manifest_card_id)
        turn_context.defer_world_update = false
        operators.finish_dissolve(state, dissolved_card_id)

        move_to_grave(state, card_id)
        transition.emit(state, "play_to_grave", {
            card_id = card_id,
            operator = op_name,
        })

        state.pending_operator_choice = nil
        state_lib.clear_gameplay_selection(state)
        close_turn(state)
    
        return transition.finish(state, {
            operator = op_name,
            board_closed = state_lib.is_board_closed(state),
            pending_operator_choice = state.pending_operator_choice,
            pending_trump = state.pending_trump,
        })
    end

    if operator_opens_target_phase(op_name) then
        return nil, "target_selection_pending"
    end

    return start_operator_effect(state, op_name)
end

function M.choose_operator(state, op_name)
    local armed, err = M.arm_operator(state, op_name)
    if not armed and err then
        return nil, err
    end
    if state.pending_public_choice
        or state.pending_flow_choice
        or state.pending_encode_choice
        or state.pending_pair_card_choice
        or state.pending_hidden_choice
        or state.pending_manifest_choice
        or state.pending_unrevealed_choice
    then
        return armed
    end
    return M.confirm_operator_phase(state)
end

function M.arm_pair_card_target(state, card_id)
    local pending = state.pending_pair_card_choice
    if not pending then
        return nil, "no_pending_pair_card_choice"
    end

    local is_public = card_choice_is_legal(pending.legal_public_card_ids, card_id)
    local is_hand = card_choice_is_legal(pending.legal_hand_card_ids, card_id)
    if not is_public and not is_hand then
        return nil, "illegal_pair_card_choice"
    end

    transition.begin(state, "arm_pair_card_target", {
        card_id = card_id,
        source_card_id = pending.card_id,
        operator = pending.operator,
    })

    if is_public then
        if pending.armed_public_card_id == card_id then
            pending.armed_public_card_id = nil
        else
            pending.armed_public_card_id = card_id
        end
    elseif is_hand then
        if pending.armed_hand_card_id == card_id then
            pending.armed_hand_card_id = nil
        else
            pending.armed_hand_card_id = card_id
        end
    end

    transition.emit(state, "pair_card_target_armed", {
        operator = pending.operator,
        source_card_id = pending.card_id,
        armed_public_card_id = pending.armed_public_card_id,
        armed_hand_card_id = pending.armed_hand_card_id,
    })

    return transition.finish(state, {
        pending_pair_card_choice = state.pending_pair_card_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.confirm_pair_card_target(state)
    local pending = state.pending_pair_card_choice
    if not pending then
        return nil, "no_pending_pair_card_choice"
    end
    if not pending.armed_public_card_id or not pending.armed_hand_card_id then
        return nil, "incomplete_pair_card_choice"
    end

    local target_card_id = pending.armed_public_card_id
    local hand_card_id = pending.armed_hand_card_id
    local target_zone = state.cards[target_card_id].zone
    local target_slot = state.cards[target_card_id].slot

    transition.begin(state, "confirm_pair_card_target", {
        public_card_id = target_card_id,
        hand_card_id = hand_card_id,
        source_card_id = pending.card_id,
        operator = pending.operator,
    })

    state_lib.remove_from_current_zone(state, target_card_id)
    state_lib.reveal_card(state, target_card_id)
    state_lib.place_card(state, target_card_id, "hand", nil)
    transition.emit(state, "public_to_hand", {
        card_id = target_card_id,
        zone = target_zone,
        slot = target_slot,
        operator = pending.operator,
    })

    state_lib.remove_from_current_zone(state, hand_card_id)
    state_lib.reveal_card(state, hand_card_id)
    if target_zone == "deck" then
        state_lib.place_card(state, hand_card_id, "deck", nil)
        transition.emit(state, "hand_to_deck_top", {
            card_id = hand_card_id,
            operator = pending.operator,
        })
    elseif target_zone == "grave" then
        state_lib.place_card(state, hand_card_id, "grave", nil)
        transition.emit(state, "hand_to_grave", {
            card_id = hand_card_id,
            operator = pending.operator,
        })
    else
        state_lib.place_card(state, hand_card_id, target_zone, target_slot)
        transition.emit(state, "hand_to_public", {
            card_id = hand_card_id,
            zone = target_zone,
            slot = target_slot,
            operator = pending.operator,
        })
    end

    operators.finish_logic(state, target_card_id, hand_card_id)

    local play_card_id = pending.card_id
    move_to_grave(state, play_card_id)
    transition.emit(state, "play_to_grave", {
        card_id = play_card_id,
        operator = pending.operator,
    })

    state.pending_pair_card_choice = nil
    state.pending_operator_choice = nil
    state_lib.clear_gameplay_selection(state)
    close_turn(state)

    return transition.finish(state, {
        pending_operator_choice = state.pending_operator_choice,
        pending_pair_card_choice = state.pending_pair_card_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.choose_pair_card_target(state, card_id)
    local armed, err = M.arm_pair_card_target(state, card_id)
    if not armed and err then
        return nil, err
    end
    return M.confirm_pair_card_target(state)
end

function M.arm_flow_target(state, card_id)
    local pending = state.pending_flow_choice
    if not pending then
        return nil, "no_pending_flow_choice"
    end
    if not card_choice_is_legal(pending.legal_card_ids, card_id) then
        return nil, "illegal_flow_choice"
    end

    transition.begin(state, "arm_flow_target", {
        card_id = card_id,
        source_card_id = pending.card_id,
        operator = pending.operator,
    })

    if pending.armed_card_id == card_id then
        pending.armed_card_id = nil
        pending.armed_direction = nil
    else
        pending.armed_card_id = card_id
        pending.armed_direction = nil
    end

    transition.emit(state, "flow_target_armed", {
        card_id = pending.armed_card_id,
        operator = pending.operator,
        source_card_id = pending.card_id,
    })

    return transition.finish(state, {
        pending_flow_choice = state.pending_flow_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.arm_flow_direction(state, direction)
    local pending = state.pending_flow_choice
    if not pending then
        return nil, "no_pending_flow_choice"
    end
    if not pending.armed_card_id then
        return nil, "no_armed_flow_target"
    end
    if direction ~= "left" and direction ~= "right" then
        return nil, "illegal_flow_direction"
    end

    transition.begin(state, "arm_flow_direction", {
        direction = direction,
        source_card_id = pending.card_id,
        operator = pending.operator,
    })

    if pending.armed_direction == direction then
        pending.armed_direction = nil
    else
        pending.armed_direction = direction
    end

    transition.emit(state, "flow_direction_armed", {
        direction = pending.armed_direction,
        operator = pending.operator,
        source_card_id = pending.card_id,
    })

    return transition.finish(state, {
        pending_flow_choice = state.pending_flow_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.confirm_flow_target(state)
    local pending = state.pending_flow_choice
    if not pending then
        return nil, "no_pending_flow_choice"
    end
    if not pending.armed_card_id then
        return nil, "no_armed_flow_target"
    end
    if not pending.armed_direction then
        return nil, "no_armed_flow_direction"
    end

    local card_id = pending.armed_card_id
    local zone_name = state.cards[card_id].zone

    transition.begin(state, "confirm_flow_target", {
        card_id = card_id,
        zone = zone_name,
        direction = pending.armed_direction,
        source_card_id = pending.card_id,
        operator = pending.operator,
    })

    flow_rotate_zone(state, zone_name, pending.armed_direction)
    transition.emit(state, "flow_step_resolved", {
        zone = zone_name,
        direction = pending.armed_direction,
        operator = pending.operator,
    })
    operators.finish_flow(state, zone_name, pending.armed_direction)

    local play_card_id = pending.card_id
    move_to_grave(state, play_card_id)
    transition.emit(state, "play_to_grave", {
        card_id = play_card_id,
        operator = pending.operator,
    })

    state.pending_flow_choice = nil
    state.pending_operator_choice = nil
    state_lib.clear_gameplay_selection(state)
    close_turn(state)

    return transition.finish(state, {
        pending_operator_choice = state.pending_operator_choice,
        pending_flow_choice = state.pending_flow_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.arm_encode_target(state, card_id)
    local pending = state.pending_encode_choice
    if not pending then
        return nil, "no_pending_encode_choice"
    end
    if not card_choice_is_legal(pending.legal_card_ids, card_id) then
        return nil, "illegal_encode_choice"
    end

    transition.begin(state, "arm_encode_target", {
        card_id = card_id,
        source_card_id = pending.card_id,
        operator = pending.operator,
    })

    if pending.armed_first_card_id == card_id then
        pending.armed_first_card_id = nil
        pending.armed_second_card_id = nil
    elseif pending.armed_second_card_id == card_id then
        pending.armed_second_card_id = nil
    elseif not pending.armed_first_card_id then
        pending.armed_first_card_id = card_id
    else
        pending.armed_second_card_id = card_id
    end

    transition.emit(state, "encode_target_armed", {
        first_card_id = pending.armed_first_card_id,
        second_card_id = pending.armed_second_card_id,
        operator = pending.operator,
        source_card_id = pending.card_id,
    })

    return transition.finish(state, {
        pending_encode_choice = state.pending_encode_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.confirm_encode_target(state)
    local pending = state.pending_encode_choice
    if not pending then
        return nil, "no_pending_encode_choice"
    end
    if not pending.armed_first_card_id or not pending.armed_second_card_id then
        return nil, "incomplete_encode_choice"
    end

    local first_card_id = pending.armed_first_card_id
    local second_card_id = pending.armed_second_card_id
    local first = state.cards[first_card_id]
    local second = state.cards[second_card_id]
    if not first or not second or not first.zone or not second.zone then
        return nil, "encode_target_missing"
    end

    local first_zone, first_slot = first.zone, first.slot
    local second_zone, second_slot = second.zone, second.slot

    transition.begin(state, "confirm_encode_target", {
        first_card_id = first_card_id,
        second_card_id = second_card_id,
        source_card_id = pending.card_id,
        operator = pending.operator,
    })

    state_lib.remove_from_current_zone(state, first_card_id)
    state_lib.remove_from_current_zone(state, second_card_id)
    state_lib.place_card(state, first_card_id, second_zone, second_zone == "deck" and nil or second_slot)
    state_lib.place_card(state, second_card_id, first_zone, first_zone == "deck" and nil or first_slot)
    transition.emit(state, "concealed_swap_resolved", {
        first_card_id = first_card_id,
        second_card_id = second_card_id,
        operator = pending.operator,
    })
    operators.finish_encode(state, first_card_id, second_card_id)

    local play_card_id = pending.card_id
    move_to_grave(state, play_card_id)
    transition.emit(state, "play_to_grave", {
        card_id = play_card_id,
        operator = pending.operator,
    })

    state.pending_encode_choice = nil
    state.pending_operator_choice = nil
    state_lib.clear_gameplay_selection(state)
    close_turn(state)

    return transition.finish(state, {
        pending_operator_choice = state.pending_operator_choice,
        pending_encode_choice = state.pending_encode_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.arm_public_target(state, card_id)
    local pending = state.pending_public_choice
    if not pending then
        return nil, "no_pending_public_choice"
    end
    if not card_choice_is_legal(pending.legal_card_ids, card_id) then
        return nil, "illegal_public_choice"
    end

    transition.begin(state, "arm_public_target", {
        card_id = card_id,
        source_card_id = pending.card_id,
        operator = pending.operator,
    })

    if pending.armed_card_id == card_id then
        pending.armed_card_id = nil
    else
        pending.armed_card_id = card_id
    end
    transition.emit(state, "public_target_armed", {
        card_id = pending.armed_card_id,
        operator = pending.operator,
        source_card_id = pending.card_id,
    })

    return transition.finish(state, {
        pending_public_choice = state.pending_public_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.confirm_public_target(state)
    local pending = state.pending_public_choice
    if not pending then
        return nil, "no_pending_public_choice"
    end
    if not pending.armed_card_id then
        return nil, "no_armed_public_target"
    end

    local card_id = pending.armed_card_id
    transition.begin(state, "confirm_public_target", {
        card_id = card_id,
        source_card_id = pending.card_id,
        operator = pending.operator,
    })

    if pending.operator == "DISSOLVE" then
        local target_zone = state.cards[card_id].zone
        local target_slot = state.cards[card_id].slot

        state_lib.remove_from_current_zone(state, card_id)
        state_lib.reveal_card(state, card_id)
        state_lib.place_card(state, card_id, "grave", nil)
        transition.emit(state, "field_to_grave", {
            card_id = card_id,
            zone = target_zone,
            slot = target_slot,
            operator = pending.operator,
        })

        repair_after_field_removal(state, target_zone, target_slot)
        operators.finish_dissolve(state, card_id)

        local play_card_id = pending.card_id
        move_to_grave(state, play_card_id)
        transition.emit(state, "play_to_grave", {
            card_id = play_card_id,
            operator = pending.operator,
        })

        state.pending_public_choice = nil
        state.pending_operator_choice = nil
        state_lib.clear_gameplay_selection(state)
        close_turn(state)
    
        return transition.finish(state, {
            pending_operator_choice = state.pending_operator_choice,
            pending_public_choice = state.pending_public_choice,
            pending_trump = state.pending_trump,
            board_closed = state_lib.is_board_closed(state),
        })
    end

    state.pending_public_choice = nil
    state.pending_hand_choice = {
        card_id = pending.card_id,
        operator = pending.operator,
        target_card_id = card_id,
        target_zone = state.cards[card_id].zone,
        target_slot = state.cards[card_id].slot,
        legal_card_ids = {},
        armed_card_id = nil,
    }
    for _, hand_card_id in ipairs(state.zones.hand.cards) do
        state.pending_hand_choice.legal_card_ids[#state.pending_hand_choice.legal_card_ids + 1] = hand_card_id
    end
    transition.emit(state, "hand_choice_pending", {
        card_id = pending.card_id,
        operator = pending.operator,
        legal_card_ids = state.pending_hand_choice.legal_card_ids,
        target_card_id = card_id,
    })
    return transition.finish(state, {
        pending_operator_choice = state.pending_operator_choice,
        pending_public_choice = state.pending_public_choice,
        pending_hand_choice = state.pending_hand_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.choose_public_target(state, card_id)
    local armed, err = M.arm_public_target(state, card_id)
    if not armed and err then
        return nil, err
    end
    return M.confirm_public_target(state)
end

function M.arm_unrevealed_target(state, card_id)
    local pending = state.pending_unrevealed_choice
    if not pending then
        return nil, "no_pending_unrevealed_choice"
    end
    if not card_choice_is_legal(pending.legal_card_ids, card_id) then
        return nil, "illegal_unrevealed_choice"
    end

    transition.begin(state, "arm_unrevealed_target", {
        card_id = card_id,
        source_card_id = pending.card_id,
        operator = pending.operator,
    })

    if pending.armed_card_id == card_id then
        pending.armed_card_id = nil
    else
        pending.armed_card_id = card_id
    end
    transition.emit(state, "unrevealed_target_armed", {
        card_id = pending.armed_card_id,
        operator = pending.operator,
        source_card_id = pending.card_id,
    })

    return transition.finish(state, {
        pending_unrevealed_choice = state.pending_unrevealed_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.confirm_unrevealed_target(state)
    local pending = state.pending_unrevealed_choice
    if not pending then
        return nil, "no_pending_unrevealed_choice"
    end
    if not pending.armed_card_id then
        return nil, "no_armed_unrevealed_target"
    end

    local card_id = pending.armed_card_id

    transition.begin(state, "confirm_unrevealed_target", {
        card_id = card_id,
        source_card_id = pending.card_id,
        operator = pending.operator,
    })

    local source_zone = state.cards[card_id].zone
    local source_slot = state.cards[card_id].slot
    local card = state.cards[card_id]

    if source_zone == "targets" and source_slot then
        repair.resolve_revealed_target_card(state, card_id, source_slot, pending.operator)
    elseif card.class == "trump" and source_zone == "latent" and source_slot then
        state_lib.remove_from_current_zone(state, card_id)
        transition.emit(state, "latent_trump_revealed", {
            card_id = card_id,
            slot = source_slot,
            reason = "manifest",
        })
        trump.enter_trump_flow(state, card_id, "manifest")
        draw.concealed_refill(state, "latent", source_slot)
    else
        state_lib.reveal_card(state, card_id)
        transition.emit(state, "card_revealed_in_place", {
            card_id = card_id,
            zone = source_zone,
            slot = source_slot,
            operator = pending.operator,
        })
        if card.class == "trump" and source_zone ~= "targets" then
            if source_zone == "deck" then
                state_lib.remove_from_current_zone(state, card_id)
            elseif source_zone ~= "latent" then
                state_lib.remove_from_current_zone(state, card_id)
            end
            trump.enter_trump_flow(state, card_id, "manifest")
        end
    end

    transition.emit(state, "operator_effect_end", {
        operator = "MANIFEST",
        manifested_card_id = card_id,
    })

    local play_card_id = pending.card_id
    move_to_grave(state, play_card_id)
    transition.emit(state, "play_to_grave", {
        card_id = play_card_id,
        operator = pending.operator,
    })

    state.pending_unrevealed_choice = nil
    state.pending_operator_choice = nil
    state_lib.clear_gameplay_selection(state)
    close_turn(state)

    return transition.finish(state, {
        card_id = card_id,
        pending_operator_choice = state.pending_operator_choice,
        pending_unrevealed_choice = state.pending_unrevealed_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.choose_unrevealed_target(state, card_id)
    local armed, err = M.arm_unrevealed_target(state, card_id)
    if not armed and err then
        return nil, err
    end
    return M.confirm_unrevealed_target(state)
end

function M.arm_manifest_target(state, slot)
    local pending = state.pending_manifest_choice
    if not pending then
        return nil, "no_pending_manifest_choice"
    end
    if not slot_choice_is_legal(pending.legal_slots, slot) then
        return nil, "illegal_manifest_choice"
    end

    transition.begin(state, "arm_manifest_target", {
        slot = slot,
        source_card_id = pending.card_id,
        operator = pending.operator,
    })

    if pending.armed_slot == slot then
        pending.armed_slot = nil
    else
        pending.armed_slot = slot
    end
    transition.emit(state, "manifest_target_armed", {
        slot = pending.armed_slot,
        operator = pending.operator,
        source_card_id = pending.card_id,
    })

    return transition.finish(state, {
        pending_manifest_choice = state.pending_manifest_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.confirm_manifest_target(state)
    local pending = state.pending_manifest_choice
    if not pending then
        return nil, "no_pending_manifest_choice"
    end
    if not pending.armed_slot then
        return nil, "no_armed_manifest_target"
    end

    local slot = pending.armed_slot
    local manifest_id = state.zones.manifest.cards[slot]
    if not manifest_id then
        return nil, "empty_manifest_slot"
    end

    transition.begin(state, "confirm_manifest_target", {
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
    state.pending_operator_choice = nil
    state_lib.clear_gameplay_selection(state)
    close_turn(state)

    return transition.finish(state, {
        slot = slot,
        card_id = manifest_id,
        pending_operator_choice = state.pending_operator_choice,
        pending_manifest_choice = state.pending_manifest_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.choose_manifest_target(state, slot)
    local armed, err = M.arm_manifest_target(state, slot)
    if not armed and err then
        return nil, err
    end
    return M.confirm_manifest_target(state)
end

function M.arm_hand_target(state, card_id)
    local pending = state.pending_hand_choice
    if not pending then
        return nil, "no_pending_hand_choice"
    end
    if not card_choice_is_legal(pending.legal_card_ids, card_id) then
        return nil, "illegal_hand_choice"
    end

    transition.begin(state, "arm_hand_target", {
        card_id = card_id,
        source_card_id = pending.card_id,
        operator = pending.operator,
    })

    if pending.armed_card_id == card_id then
        pending.armed_card_id = nil
    else
        pending.armed_card_id = card_id
    end
    transition.emit(state, "hand_target_armed", {
        card_id = pending.armed_card_id,
        operator = pending.operator,
        source_card_id = pending.card_id,
    })

    return transition.finish(state, {
        pending_hand_choice = state.pending_hand_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.confirm_hand_target(state)
    local pending = state.pending_hand_choice
    if not pending then
        return nil, "no_pending_hand_choice"
    end
    if not pending.armed_card_id then
        return nil, "no_armed_hand_target"
    end

    local card_id = pending.armed_card_id

    transition.begin(state, "confirm_hand_target", {
        card_id = card_id,
        source_card_id = pending.card_id,
        operator = pending.operator,
    })

    move_to_grave(state, card_id)
    transition.emit(state, "hand_to_grave", {
        card_id = card_id,
        operator = pending.operator,
    })

    -- This path is unreachable since LOGIC became a joker: its only creators
    -- were the CYCLE discard, now gone, and pending_public_choice, which
    -- nothing sets any more. Kept until the phase machine removes it wholesale,
    -- with the generic emit so it cannot call a function that no longer exists.
    transition.emit(state, "operator_effect_end", {
        operator = pending.operator,
        discarded_card_id = card_id,
    })

    local play_card_id = pending.card_id
    move_to_grave(state, play_card_id)
    transition.emit(state, "play_to_grave", {
        card_id = play_card_id,
        operator = pending.operator,
    })

    state.pending_hand_choice = nil
    state.pending_operator_choice = nil
    state_lib.clear_gameplay_selection(state)
    close_turn(state)

    return transition.finish(state, {
        card_id = card_id,
        pending_operator_choice = state.pending_operator_choice,
        pending_hand_choice = state.pending_hand_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.choose_hand_target(state, card_id)
    local armed, err = M.arm_hand_target(state, card_id)
    if not armed and err then
        return nil, err
    end
    return M.confirm_hand_target(state)
end

function M.arm_hidden_target(state, card_id)
    local pending = state.pending_hidden_choice
    if not pending then
        return nil, "no_pending_hidden_choice"
    end
    if not card_choice_is_legal(pending.legal_card_ids, card_id) then
        return nil, "illegal_hidden_choice"
    end

    transition.begin(state, "arm_hidden_target", {
        card_id = card_id,
        source_card_id = pending.card_id,
        operator = pending.operator,
    })

    if pending.armed_card_id == card_id then
        pending.armed_card_id = nil
    else
        pending.armed_card_id = card_id
    end
    transition.emit(state, "hidden_target_armed", {
        card_id = pending.armed_card_id,
        operator = pending.operator,
        source_card_id = pending.card_id,
    })

    return transition.finish(state, {
        pending_hidden_choice = state.pending_hidden_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.confirm_hidden_target(state)
    local pending = state.pending_hidden_choice
    if not pending then
        return nil, "no_pending_hidden_choice"
    end
    if not pending.armed_card_id then
        return nil, "no_armed_hidden_target"
    end

    local card_id = pending.armed_card_id

    transition.begin(state, "confirm_hidden_target", {
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
    elseif source_zone == "targets" and source_slot and card.class == "trump" then
        -- TARGET_ZONE_LAW §7: a trump that becomes KNOWN through observe is
        -- the override case. It stays in its slot and turns face-up.
        repair.resolve_revealed_target_card(state, card_id, source_slot, pending.operator)
    else
        -- OBSERVE_LAW §6: observe upgrades information state and nothing more.
        -- It "does not by itself imply mandatory public reveal", so a minor in
        -- targets becomes known and stays face-down where it is.
        --
        -- TARGET_ZONE_LAW §4 sends a non-trump target to the grave when it is
        -- REVEALED, not when it becomes known. Routing observe through the
        -- reveal path burned minors the law never allowed observe to touch,
        -- and it made OBSERVE and MANIFEST behave identically in this zone
        -- when the laws deliberately separate them.
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
    state.pending_operator_choice = nil
    state_lib.clear_gameplay_selection(state)
    close_turn(state)

    return transition.finish(state, {
        card_id = card_id,
        pending_operator_choice = state.pending_operator_choice,
        pending_hidden_choice = state.pending_hidden_choice,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.choose_hidden_target(state, card_id)
    local armed, err = M.arm_hidden_target(state, card_id)
    if not armed and err then
        return nil, err
    end
    return M.confirm_hidden_target(state)
end

return M
