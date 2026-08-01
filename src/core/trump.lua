local constants = require("src.core.constants")
local state_lib = require("src.core.state")
local transition = require("src.core.transition")

local M = {}
local resolve_trump_card
local handle_revealed_trump

local DEFAULT_TRUMP_GUARD = {
    max_trump_chain_steps = 128,
    max_repair_attempts = 128,
}

-- nil means every effect runs, which is the ordinary game. A table means only
-- the named indices run; an empty table means none do.
function M.effect_enabled(state, trump_name)
    local enabled = state.setup_options and state.setup_options.enabled_effects
    if enabled == nil then
        return true
    end
    local index = trump_name and constants.TRUMP_NAME_TO_INDEX[trump_name]
    if not index then
        return false
    end
    return enabled[index] == true
end

local function guard_limit(state, key)
    local guard = state.trump_guard or (state.setup_options and state.setup_options.guard) or {}
    return guard[key] or DEFAULT_TRUMP_GUARD[key]
end

local function card_list(state, zone_name)
    local out = {}
    local zone = state.zones[zone_name]
    if not zone then
        return out
    end
    if zone.kind == "slots" then
        for slot = 1, zone.slot_count do
            out[#out + 1] = zone.cards[slot] or "-"
        end
        return out
    end
    for _, card_id in ipairs(zone.cards) do
        out[#out + 1] = card_id
    end
    return out
end

local function mark_runaway(state, reason, extra)
    if state.trump_runaway then
        return false
    end
    state.trump_runaway = {
        reason = reason,
        trump_chain_steps = state.trump_chain_steps or 0,
        max_trump_chain_steps = guard_limit(state, "max_trump_chain_steps"),
        repair_attempts = state.trump_repair_attempts or 0,
        max_repair_attempts = guard_limit(state, "max_repair_attempts"),
        board_closed = state_lib.is_board_closed(state),
        deck = #state.zones.deck.cards,
        hand = #state.zones.hand.cards,
        grave = #state.zones.grave.cards,
        trump_flow = card_list(state, "trump_flow"),
        trump_zone = card_list(state, "trump"),
        pending_trump = state.pending_trump,
        current_resolving_trump = state.current_resolving_trump,
        extra = extra or {},
    }
    transition.emit(state, "trump_flow_runaway", state.trump_runaway)
    return false
end

local function guard_trump_step(state, card_id)
    if state.trump_runaway then
        return false
    end
    state.trump_chain_steps = (state.trump_chain_steps or 0) + 1
    if state.trump_chain_steps > guard_limit(state, "max_trump_chain_steps") then
        return mark_runaway(state, "max_trump_chain_steps", {
            card_id = card_id,
        })
    end
    return true
end

local function guard_repair(state, zone_name, slot)
    if state.trump_runaway then
        return false
    end
    state.trump_repair_attempts = (state.trump_repair_attempts or 0) + 1
    if state.trump_repair_attempts > guard_limit(state, "max_repair_attempts") then
        return mark_runaway(state, "max_repair_attempts", {
            zone = zone_name,
            slot = slot,
        })
    end
    return true
end

local function shuffle_in_place(list, rng)
    local roll = rng or math.random
    for i = #list, 2, -1 do
        local j = roll(i)
        list[i], list[j] = list[j], list[i]
    end
end

local function pop_topdeck(state)
    local deck = state.zones.deck.cards
    if #deck == 0 then
        return nil
    end
    local card_id = deck[#deck]
    state_lib.remove_from_current_zone(state, card_id)
    return card_id
end

local function reveal_minor_to_hand(state, card_id, reason)
    state_lib.reveal_card(state, card_id)
    state_lib.place_card(state, card_id, "hand", nil)
    transition.emit(state, "draw_to_hand", {
        card_id = card_id,
        reason = reason,
    })
end

local function reveal_minor_to_grave(state, card_id, reason)
    state_lib.reveal_card(state, card_id)
    state_lib.place_card(state, card_id, "grave", nil)
    transition.emit(state, "deck_reveal_to_grave", {
        card_id = card_id,
        reason = reason,
    })
end

local function concealed_refill(state, zone_name, slot)
    if not guard_repair(state, zone_name, slot) then
        return nil
    end
    local top = pop_topdeck(state)
    if not top then
        return nil
    end
    state_lib.hide_card(state, top)
    state_lib.place_card(state, top, zone_name, slot)
    transition.emit(state, "concealed_refill", {
        card_id = top,
        zone = zone_name,
        slot = slot,
    })
    return top
end

local function repair_manifest_slot(state, slot)
    if state.trump_runaway then
        return
    end
    local latent_id = state.zones.latent.cards[slot]
    if not latent_id then
        transition.emit(state, "repair_skipped", {slot = slot})
        return
    end

    state_lib.remove_from_current_zone(state, latent_id)
    state_lib.reveal_card(state, latent_id)

    if state.cards[latent_id].class == "trump" then
        transition.emit(state, "latent_trump_revealed", {
            card_id = latent_id,
            slot = slot,
            reason = "eject_repair",
        })
        handle_revealed_trump(state, latent_id, "EJECT repair", "queue")

        while true do
            local top = pop_topdeck(state)
            if not top then
                break
            end
            state_lib.reveal_card(state, top)
            if state.cards[top].class == "trump" then
                transition.emit(state, "trump_flow_entry", {
                    card_id = top,
                    reason = "open closure",
                })
                state_lib.place_card(state, top, "trump_flow", nil)
            else
                state_lib.place_card(state, top, "manifest", slot)
                transition.emit(state, "manifest_closure", {
                    card_id = top,
                    slot = slot,
                })
                break
            end
        end

        concealed_refill(state, "latent", slot)
        return
    end

    state_lib.place_card(state, latent_id, "manifest", slot)
    transition.emit(state, "latent_to_manifest", {
        card_id = latent_id,
        slot = slot,
    })
    concealed_refill(state, "latent", slot)
end

local function repair_open_board_from_deck(state)
    for slot = 1, state.zones.latent.slot_count do
        if state.trump_runaway then
            return
        end
        if not state.zones.latent.cards[slot] then
            concealed_refill(state, "latent", slot)
        end
        if not state.zones.manifest.cards[slot] then
            repair_manifest_slot(state, slot)
        end
    end
    for slot = 1, state.zones.targets.slot_count do
        if state.trump_runaway then
            return
        end
        if not state.zones.targets.cards[slot] then
            concealed_refill(state, "targets", slot)
        end
    end
end

local function first_matching_in_slots(state, zone_name, predicate, reverse)
    local zone = state.zones[zone_name]
    local from_i, to_i, step = 1, zone.slot_count, 1
    if reverse then
        from_i, to_i, step = zone.slot_count, 1, -1
    end
    for slot = from_i, to_i, step do
        local card_id = zone.cards[slot]
        if card_id and predicate(card_id) then
            return card_id, zone_name, slot
        end
    end
    return nil
end

local function first_matching_in_row(state, zone_name, predicate, reverse)
    local zone = state.zones[zone_name]
    local from_i, to_i, step = 1, #zone.cards, 1
    if reverse then
        from_i, to_i, step = #zone.cards, 1, -1
    end
    for index = from_i, to_i, step do
        local card_id = zone.cards[index]
        if card_id and predicate(card_id) then
            return card_id, zone_name, index
        end
    end
    return nil
end

local function class_is(state, card_id, class_name)
    return state.cards[card_id] and state.cards[card_id].class == class_name
end

local function choose_eject_target(state)
    local function is_trump(card_id)
        return class_is(state, card_id, "trump")
    end
    local function any(card_id)
        return state.cards[card_id] ~= nil
    end

    local pickers = {
        function() return first_matching_in_slots(state, "trump", is_trump) end,
        function() return first_matching_in_slots(state, "targets", is_trump) end,
        function() return first_matching_in_slots(state, "latent", is_trump) end,
        function() return first_matching_in_slots(state, "manifest", is_trump) end,
        function() return first_matching_in_row(state, "grave", is_trump, true) end,
        function() return first_matching_in_row(state, "hand", is_trump) end,
        function() return first_matching_in_slots(state, "runtime", is_trump) end,
        function() return first_matching_in_slots(state, "play", is_trump) end,
        function()
            local top = state.zones.deck.cards[#state.zones.deck.cards]
            if top and is_trump(top) then
                return top, "deck", #state.zones.deck.cards
            end
            return nil
        end,
        function() return first_matching_in_slots(state, "targets", any) end,
        function() return first_matching_in_slots(state, "latent", any) end,
        function() return first_matching_in_slots(state, "manifest", any) end,
        function() return first_matching_in_row(state, "grave", any, true) end,
        function() return first_matching_in_row(state, "hand", any) end,
        function() return first_matching_in_slots(state, "runtime", any) end,
        function() return first_matching_in_slots(state, "play", any) end,
        function()
            local top = state.zones.deck.cards[#state.zones.deck.cards]
            if top then
                return top, "deck", #state.zones.deck.cards
            end
            return nil
        end,
    }

    for _, picker in ipairs(pickers) do
        local card_id, zone_name, slot = picker()
        if card_id then
            return card_id, zone_name, slot
        end
    end
    return nil
end

local function resolve_all_pending_trumps(state)
    if state.trump_flow_draining then
        return
    end
    state.trump_flow_draining = true
    while true do
        if state.trump_runaway then
            break
        end
        local card_id = state.zones.trump_flow.cards[1]
        if not card_id then
            state.pending_trump = nil
            break
        end
        if (state.trump_chain_steps or 0) + 1 > guard_limit(state, "max_trump_chain_steps") then
            mark_runaway(state, "max_trump_chain_steps", {
                card_id = card_id,
            })
            break
        end
        state.pending_trump = nil
        transition.emit(state, "pending_trump", {card_id = card_id})
        state_lib.remove_from_current_zone(state, card_id)
        resolve_trump_card(state, card_id)
        repair_open_board_from_deck(state)
    end
    repair_open_board_from_deck(state)
    state.trump_flow_draining = nil
end

local function resolve_eject_effect(state)
    local card_id, zone_name, slot = choose_eject_target(state)
    if not card_id then
        transition.emit(state, "eject_skipped", {
            reason = "no_target",
        })
        return
    end

    transition.emit(state, "eject_target", {
        card_id = card_id,
        zone = zone_name,
        slot = slot,
    })

    if not state_lib.is_revealed(state, card_id) then
        state_lib.reveal_card(state, card_id)
        transition.emit(state, "eject_reveal", {
            card_id = card_id,
            zone = zone_name,
            slot = slot,
        })
    end

    state_lib.remove_from_current_zone(state, card_id)

    if zone_name == "manifest" and slot then
        repair_manifest_slot(state, slot)
    elseif zone_name == "latent" and slot then
        concealed_refill(state, "latent", slot)
    elseif zone_name == "targets" and slot then
        concealed_refill(state, "targets", slot)
    end

    if class_is(state, card_id, "trump") then
        handle_revealed_trump(state, card_id, "EJECT", "queue")
        resolve_all_pending_trumps(state)
        return
    end

    state_lib.place_card(state, card_id, "grave", nil)
    transition.emit(state, "eject_to_grave", {
        card_id = card_id,
        from_zone = zone_name,
        from_slot = slot,
    })
end

local function unveil_target_slot(state, slot)
    local card_id = state.zones.targets.cards[slot]
    if not card_id or state_lib.is_revealed(state, card_id) then
        return
    end

    state_lib.reveal_card(state, card_id)
    transition.emit(state, "unveil_target", {
        card_id = card_id,
        slot = slot,
    })

    if class_is(state, card_id, "trump") then
        return
    end

    state_lib.remove_from_current_zone(state, card_id)
    state_lib.place_card(state, card_id, "grave", nil)
    transition.emit(state, "target_minor_to_grave", {
        card_id = card_id,
        slot = slot,
        operator = "UNVEIL",
    })
    concealed_refill(state, "targets", slot)
end

local function unveil_latent_slot(state, slot)
    local card_id = state.zones.latent.cards[slot]
    if not card_id or state_lib.is_revealed(state, card_id) then
        return
    end

    state_lib.reveal_card(state, card_id)
    transition.emit(state, "unveil_latent", {
        card_id = card_id,
        slot = slot,
    })

    if not class_is(state, card_id, "trump") then
        return
    end

    state_lib.remove_from_current_zone(state, card_id)
    handle_revealed_trump(state, card_id, "UNVEIL latent", "queue")
    concealed_refill(state, "latent", slot)
end

local function unveil_topdeck(state)
    local card_id = state.zones.deck.cards[#state.zones.deck.cards]
    if not card_id or state_lib.is_revealed(state, card_id) then
        return
    end

    state_lib.reveal_card(state, card_id)
    transition.emit(state, "unveil_topdeck", {
        card_id = card_id,
    })

    -- Implements DECK_LAW_SLICE_2026-07-31 §4, authorised by DECK_LAW §6-§7.
    -- The topdeck zone is empty at rest, so a revealed minor cannot stay.
    --
    -- The card is still IN the deck here: reveal_minor_to_grave assumes its
    -- caller already popped it (FOOL does), so removal has to happen first.
    -- Without it the card is listed in both zones and pop_topdeck can never
    -- drain the deck, which hangs open_manifest_closure.
    if not class_is(state, card_id, "trump") then
        state_lib.remove_from_current_zone(state, card_id)
        reveal_minor_to_grave(state, card_id, "UNVEIL topdeck")
        return
    end

    state_lib.remove_from_current_zone(state, card_id)
    handle_revealed_trump(state, card_id, "UNVEIL topdeck", "queue")
end

local function resolve_unveil_effect(state)
    for slot = 1, state.zones.targets.slot_count do
        unveil_target_slot(state, slot)
    end
    for slot = 1, state.zones.latent.slot_count do
        unveil_latent_slot(state, slot)
    end
    unveil_topdeck(state)
end

local function purge_to_grave(state, card_id, reason, slot)
    state_lib.remove_from_current_zone(state, card_id)
    state_lib.reveal_card(state, card_id)
    state_lib.place_card(state, card_id, "grave", nil)
    transition.emit(state, "purge_to_grave", {
        card_id = card_id,
        reason = reason,
        slot = slot,
    })
end

local function purge_card(state, card_id, reason, slot)
    if class_is(state, card_id, "trump") then
        state_lib.remove_from_current_zone(state, card_id)
        handle_revealed_trump(state, card_id, reason, "queue")
        return "trump"
    end
    purge_to_grave(state, card_id, reason, slot)
    return "grave"
end

local function purge_topdeck(state)
    local card_id = state.zones.deck.cards[#state.zones.deck.cards]
    if not card_id or not state_lib.is_revealed(state, card_id) then
        transition.emit(state, "purge_topdeck_skipped", {
            card_id = card_id,
            reason = card_id and "not_revealed" or "empty",
        })
        return
    end

    transition.emit(state, "purge_topdeck", {
        card_id = card_id,
    })
    purge_card(state, card_id, "PURGE topdeck")
end

local function purge_latent_slot(state, slot)
    local card_id = state.zones.latent.cards[slot]
    if not card_id or not state_lib.is_revealed(state, card_id) then
        transition.emit(state, "purge_latent_skipped", {
            card_id = card_id,
            slot = slot,
            reason = card_id and "not_revealed" or "empty",
        })
        return
    end

    transition.emit(state, "purge_latent", {
        card_id = card_id,
        slot = slot,
    })
    purge_card(state, card_id, "PURGE latent", slot)
    concealed_refill(state, "latent", slot)
end

local function purge_manifest_slot(state, slot)
    local card_id = state.zones.manifest.cards[slot]
    if not card_id then
        transition.emit(state, "purge_manifest_skipped", {
            slot = slot,
            reason = "empty",
        })
        return
    end

    transition.emit(state, "purge_manifest", {
        card_id = card_id,
        slot = slot,
    })
    purge_card(state, card_id, "PURGE manifest", slot)
    repair_manifest_slot(state, slot)
end

local function resolve_purge_effect(state)
    purge_topdeck(state)
    for slot = 1, state.zones.manifest.slot_count do
        purge_latent_slot(state, slot)
        purge_manifest_slot(state, slot)
    end
end

local function oracle_reorder_top_six(state)
    local viewed = {}
    for _ = 1, 6 do
        local top = pop_topdeck(state)
        if not top then
            break
        end
        viewed[#viewed + 1] = top
    end

    transition.emit(state, "oracle_view", {
        cards = viewed,
    })

    if #viewed == 0 then
        return
    end

    local chosen_index = 1
    for index, card_id in ipairs(viewed) do
        if state.cards[card_id].class ~= "trump" then
            chosen_index = index
            break
        end
    end

    local chosen_id = table.remove(viewed, chosen_index)
    transition.emit(state, "oracle_pick", {
        card_id = chosen_id,
        picked_index = chosen_index,
    })

    if state.cards[chosen_id].class == "trump" then
        handle_revealed_trump(state, chosen_id, "ORACLE pick", "resolve_now")
    else
        state_lib.reveal_card(state, chosen_id)
        state_lib.place_card(state, chosen_id, "hand", nil)
        transition.emit(state, "oracle_to_hand", {
            card_id = chosen_id,
        })
    end

    for i = #viewed, 1, -1 do
        state_lib.hide_card(state, viewed[i])
        state_lib.place_card(state, viewed[i], "deck", nil)
    end
    state_lib.sync_zone_cards(state, "deck")
    transition.emit(state, "oracle_return_top", {
        cards = viewed,
    })
end

local function trump_name(state, card_id)
    local card = state.cards[card_id]
    return card and card.trump_name or nil
end

local function remember_chain_participant(state, card_id, parent_id)
    state.trump_chain_participants = state.trump_chain_participants or {}
    state.trump_chain_seen = state.trump_chain_seen or {}
    state.trump_parent = state.trump_parent or {}
    if not state.trump_chain_seen[card_id] then
        state.trump_chain_seen[card_id] = true
        state.trump_chain_participants[#state.trump_chain_participants + 1] = card_id
    end
    if parent_id ~= nil then
        state.trump_parent[card_id] = parent_id
    end
end

handle_revealed_trump = function(state, card_id, reason, mode)
    if state.trump_runaway then
        return "blocked"
    end
    local parent_id = state.current_resolving_trump
    local name = trump_name(state, card_id)
    M.enter_trump_flow(state, card_id, reason)
    if name == "REPEAT" and mode == "resolve_now" then
        remember_chain_participant(state, card_id, parent_id)
        state.trump_chain_deferred = state.trump_chain_deferred or {}
        state.trump_chain_deferred[#state.trump_chain_deferred + 1] = card_id
        return "queued"
    end
    if mode == "resolve_now" then
        state_lib.remove_from_current_zone(state, card_id)
        resolve_trump_card(state, card_id, parent_id)
        return "resolved"
    end
    remember_chain_participant(state, card_id, parent_id)
    return "queued"
end

local function begin_trump_chain(state)
    if state.trump_chain_depth and state.trump_chain_depth > 0 then
        state.trump_chain_depth = state.trump_chain_depth + 1
        return false
    end
    state.trump_chain_depth = 1
    state.trump_chain_participants = {}
    state.trump_chain_seen = {}
    state.trump_parent = {}
    state.trump_chain_deferred = {}
    return true
end

-- Implements DECK_LAW_SLICE_2026-07-31 §3, authorised by HALT_MODE_LAW §4
-- revision 2 and DECK_LAW §2.
--
-- Revision 1 preserved the information state, citing CARD_INFORMATION_STATE_LAW
-- section 7. It was wrong twice: the displaced cards are trumps and therefore
-- revealed, not known, and a revealed card inside the deck is an anchor by
-- FLOW_RING_LAW section 2 -- the ring covers the whole deck body, so every HALT
-- permanently reduced the ring's mobility.
--
-- HALT displacement and trump-zone overflow now do the same thing.
local function shuffle_into_deck(state, card_ids, event_name)
    if #card_ids == 0 then
        return
    end
    for _, card_id in ipairs(card_ids) do
        if state.cards[card_id].zone then
            state_lib.remove_from_current_zone(state, card_id)
        end
        state_lib.hide_card(state, card_id)
        state_lib.place_card(state, card_id, "deck", nil)
    end
    shuffle_in_place(state.zones.deck.cards, state.rng)
    state_lib.sync_zone_cards(state, "deck")
    transition.emit(state, event_name, {
        cards = card_ids,
    })
end

local function finish_trump_chain(state)
    state.trump_chain_depth = state.trump_chain_depth - 1
    if state.trump_chain_depth > 0 then
        return
    end

    state.trump_chain_depth = 0
    state.trump_chain_participants = nil
    state.trump_chain_seen = nil
    state.trump_parent = nil
    state.trump_chain_deferred = nil
    state.current_resolving_trump = nil
end

local function resolve_revealed_draw_step(state, card_id, reason)
    if state.cards[card_id].class == "trump" then
        handle_revealed_trump(state, card_id, reason, "resolve_now")
        return
    end
    reveal_minor_to_hand(state, card_id, reason)
end

local function draw_revealed_steps(state, count, reason)
    for _ = 1, count do
        local top = pop_topdeck(state)
        if not top then
            break
        end
        resolve_revealed_draw_step(state, top, reason)
    end
end

local function discard_hand_to_grave(state, reason)
    local hand = state.zones.hand.cards
    while #hand > 0 do
        local card_id = hand[#hand]
        state_lib.remove_from_current_zone(state, card_id)
        state_lib.reveal_card(state, card_id)
        state_lib.place_card(state, card_id, "grave", nil)
        transition.emit(state, "hand_to_grave", {
            card_id = card_id,
            reason = reason,
        })
    end
end

local function shuffle_grave_into_deck(state, reason)
    local grave = state.zones.grave.cards
    while #grave > 0 do
        local card_id = grave[#grave]
        state_lib.remove_from_current_zone(state, card_id)
        state_lib.hide_card(state, card_id)
        state_lib.place_card(state, card_id, "deck", nil)
        transition.emit(state, "grave_to_deck", {
            card_id = card_id,
            reason = reason,
        })
    end
    shuffle_in_place(state.zones.deck.cards, state.rng)
    state_lib.sync_zone_cards(state, "deck")
    transition.emit(state, "deck_shuffled", {
        reason = reason,
        deck = #state.zones.deck.cards,
    })
end

local function move_grave_to_hand(state)
    local ordered = {}
    for _, card_id in ipairs(state.zones.grave.cards) do
        ordered[#ordered + 1] = card_id
    end

    for _, card_id in ipairs(ordered) do
        if state.cards[card_id] and state.cards[card_id].zone == "grave" then
            state_lib.remove_from_current_zone(state, card_id)
            state_lib.reveal_card(state, card_id)
            state_lib.place_card(state, card_id, "hand", nil)
            transition.emit(state, "grave_to_hand", {
                card_id = card_id,
                reason = "ERROR",
            })
        end
    end

    transition.emit(state, "grave_opened_to_hand", {
        cards = ordered,
        count = #ordered,
    })
end

local function move_manifest_row_to_proto_hand(state, proto_hand)
    local manifest = state.zones.manifest.cards
    for slot = 1, 6 do
        local card_id = manifest[slot]
        if card_id then
            state_lib.remove_from_current_zone(state, card_id)
            proto_hand[#proto_hand + 1] = card_id
            transition.emit(state, "manifest_to_proto_hand", {
                card_id = card_id,
                slot = slot,
            })
        end
    end
end

local function promote_latent_to_manifest(state)
    local latent = state.zones.latent.cards
    for slot = 1, 6 do
        local card_id = latent[slot]
        if card_id then
            state_lib.remove_from_current_zone(state, card_id)
            state_lib.reveal_card(state, card_id)
            state_lib.place_card(state, card_id, "manifest", slot)
            transition.emit(state, "latent_to_manifest", {
                card_id = card_id,
                slot = slot,
            })
        end
    end
end

local function shuffle_hand_in_place(state)
    shuffle_in_place(state.zones.hand.cards, state.rng)
    state_lib.sync_zone_cards(state, "hand")
    transition.emit(state, "hand_shuffled", {
        hand = #state.zones.hand.cards,
    })
end

local function deal_hand_to_latent(state)
    local dealt = 0
    while dealt < 6 and #state.zones.hand.cards > 0 do
        local card_id = state.zones.hand.cards[#state.zones.hand.cards]
        state_lib.remove_from_current_zone(state, card_id)
        state_lib.hide_card(state, card_id)
        state_lib.place_card(state, card_id, "latent", dealt + 1)
        dealt = dealt + 1
        transition.emit(state, "hand_to_latent", {
            card_id = card_id,
            slot = dealt,
        })
    end
    return dealt
end

local function fill_latent_from_deck(state, from_slot)
    for slot = from_slot, 6 do
        local top = pop_topdeck(state)
        if not top then
            break
        end
        state_lib.hide_card(state, top)
        state_lib.place_card(state, top, "latent", slot)
        transition.emit(state, "deck_to_latent", {
            card_id = top,
            slot = slot,
        })
    end
end

local function route_hand_overflow(state)
    local overflow = {}
    while #state.zones.hand.cards > 0 do
        local card_id = state.zones.hand.cards[#state.zones.hand.cards]
        overflow[#overflow + 1] = card_id
        state_lib.remove_from_current_zone(state, card_id)
    end

    for _, card_id in ipairs(overflow) do
        if state.cards[card_id].class == "trump" then
            handle_revealed_trump(state, card_id, "RECAST overflow", "resolve_now")
        else
            reveal_minor_to_grave(state, card_id, "RECAST overflow")
        end
    end
end

local function move_proto_hand_to_hand(state, proto_hand)
    for _, card_id in ipairs(proto_hand) do
        state_lib.reveal_card(state, card_id)
        state_lib.place_card(state, card_id, "hand", nil)
        transition.emit(state, "proto_hand_to_hand", {
            card_id = card_id,
        })
    end
end

local function resolve_recast_effect(state)
    local proto_hand = {}
    move_manifest_row_to_proto_hand(state, proto_hand)
    promote_latent_to_manifest(state)
    shuffle_hand_in_place(state)
    local dealt = deal_hand_to_latent(state)
    if dealt < 6 then
        fill_latent_from_deck(state, dealt + 1)
    end
    route_hand_overflow(state)
    move_proto_hand_to_hand(state, proto_hand)
end

-- HALT_MODE_LAW. Capacity is expressed here as the number of trumps the flow
-- itself may hold. The law states two, counting the trump currently resolving,
-- but a resolving trump has already been removed from the flow, so the code
-- number is one lower: while HALT sits in the flow, nothing else may join it.
local HALT_FLOW_CAPACITY = 1

local function flow_is_full(state)
    local capacity = state.trump_flow_capacity
    if not capacity then
        return false
    end
    return #state.zones.trump_flow.cards >= capacity
end

function M.enter_trump_flow(state, card_id, reason)
    if flow_is_full(state) then
        state_lib.reveal_card(state, card_id)
        transition.emit(state, "trump_flow_displaced", {
            card_id = card_id,
            reason = reason,
        })
        shuffle_into_deck(state, {card_id}, "halt_displaced_to_deck")
        return
    end

    state_lib.place_card(state, card_id, "trump_flow", nil)
    state_lib.reveal_card(state, card_id)
    state_lib.push_log(state, card_id .. " -> trump flow" .. (reason and (" (" .. reason .. ")") or "") .. ".")
    transition.emit(state, "trump_flow_entry", {
        card_id = card_id,
        reason = reason,
    })

    if trump_name(state, card_id) == "HALT" then
        state.trump_flow_capacity = HALT_FLOW_CAPACITY
        transition.emit(state, "halt_mode_begin", {
            card_id = card_id,
            capacity = HALT_FLOW_CAPACITY,
        })
        local displaced = {}
        for _, queued_id in ipairs(state.zones.trump_flow.cards) do
            if queued_id ~= card_id then
                displaced[#displaced + 1] = queued_id
            end
        end
        shuffle_into_deck(state, displaced, "halt_cleared_queue")
    end
end

resolve_trump_card = function(state, card_id)
    if not guard_trump_step(state, card_id) then
        return nil, "trump_flow_runaway"
    end
    local parent_id = state.current_resolving_trump
    begin_trump_chain(state)
    remember_chain_participant(state, card_id, parent_id)
    local previous_current = state.current_resolving_trump
    state.current_resolving_trump = card_id
    local name = trump_name(state, card_id)

    transition.emit(state, "trump_effect_begin", {
        card_id = card_id,
        trump = name,
    })

    if not M.effect_enabled(state, name) then
        -- Stub: everything around the effect still runs. The card sat in the
        -- deck, was revealed, entered the flow, resolves in step 8, counts for
        -- HALT capacity and for the victory compiler, and goes on to
        -- resolve_trump_zone_entry below. Only its own body is skipped.
        transition.emit(state, "trump_effect_stubbed", {
            card_id = card_id,
            trump = name,
        })
    elseif name == "FOOL" then
        while true do
            local top = pop_topdeck(state)
            if not top then
                break
            end
            if state.cards[top].class == "trump" then
                handle_revealed_trump(state, top, "FOOL contact", "resolve_now")
                break
            end
            reveal_minor_to_grave(state, top, "FOOL drill")
        end
    elseif name == "EJECT" then
        resolve_eject_effect(state)
    elseif name == "ORACLE" then
        oracle_reorder_top_six(state)
    elseif name == "RUSH" then
        local queued = {}
        for _ = 1, 6 do
            local top = pop_topdeck(state)
            if not top then
                break
            end
            if state.cards[top].class == "trump" then
                local result = handle_revealed_trump(state, top, "RUSH draw", "queue")
                if result == "queued" then
                    queued[#queued + 1] = top
                end
            else
                reveal_minor_to_hand(state, top, "RUSH draw")
            end
        end
        for _, queued_id in ipairs(queued) do
            state_lib.remove_from_current_zone(state, queued_id)
            resolve_trump_card(state, queued_id)
        end
    elseif name == "RESET" then
        discard_hand_to_grave(state, "RESET")
        draw_revealed_steps(state, 6, "RESET draw")
    elseif name == "SHUFFLE" then
        shuffle_grave_into_deck(state, "SHUFFLE")
    elseif name == "ERROR" then
        move_grave_to_hand(state)
    elseif name == "UNVEIL" then
        resolve_unveil_effect(state)
    elseif name == "PURGE" then
        resolve_purge_effect(state)
    elseif name == "HALT" then
        -- HALT_MODE_LAW section 2 point 5: it resolves empty and lifts the mode.
        state.trump_flow_capacity = nil
        transition.emit(state, "halt_mode_end", {card_id = card_id})
    elseif name == "REPEAT" then
        if parent_id then
            local parent_name = trump_name(state, parent_id)
            if parent_name == "FOOL" then
                while true do
                    local top = pop_topdeck(state)
                    if not top then
                        break
                    end
                    if state.cards[top].class == "trump" then
                        handle_revealed_trump(state, top, "FOOL contact", "resolve_now")
                        break
                    end
                    reveal_minor_to_grave(state, top, "FOOL drill")
                end
            elseif parent_name == "RUSH" then
                local queued = {}
                for _ = 1, 6 do
                    local top = pop_topdeck(state)
                    if not top then
                        break
                    end
                    if state.cards[top].class == "trump" then
                        local result = handle_revealed_trump(state, top, "RUSH draw", "queue")
                        if result == "queued" then
                            queued[#queued + 1] = top
                        end
                    else
                        reveal_minor_to_hand(state, top, "RUSH draw")
                    end
                end
                for _, queued_id in ipairs(queued) do
                    state_lib.remove_from_current_zone(state, queued_id)
                    resolve_trump_card(state, queued_id)
                end
            elseif parent_name == "EJECT" then
                resolve_eject_effect(state)
            elseif parent_name == "ORACLE" then
                oracle_reorder_top_six(state)
            elseif parent_name == "RESET" then
                discard_hand_to_grave(state, "RESET")
                draw_revealed_steps(state, 6, "RESET draw")
            elseif parent_name == "SHUFFLE" then
                shuffle_grave_into_deck(state, "SHUFFLE")
            elseif parent_name == "ERROR" then
                move_grave_to_hand(state)
            elseif parent_name == "UNVEIL" then
                resolve_unveil_effect(state)
            elseif parent_name == "PURGE" then
                resolve_purge_effect(state)
            elseif parent_name == "RECAST" then
                resolve_recast_effect(state)
            end
        end
    elseif name == "RECAST" then
        resolve_recast_effect(state)
    end

    transition.emit(state, "trump_effect_end", {
        card_id = card_id,
        trump = name,
    })

    M.resolve_trump_zone_entry(state, card_id)

    while state.trump_chain_deferred and #state.trump_chain_deferred > 0 do
        local deferred_id = table.remove(state.trump_chain_deferred, 1)
        if state.cards[deferred_id].zone == "trump_flow" then
            state_lib.remove_from_current_zone(state, deferred_id)
            resolve_trump_card(state, deferred_id)
        end
    end

    state.current_resolving_trump = previous_current
    finish_trump_chain(state)
end

function M.resolve_trump_zone_entry(state, card_id)
    local open_slot = state_lib.first_open_slot(state, "trump")
    if open_slot then
        state_lib.place_card(state, card_id, "trump", open_slot)
        state_lib.reveal_card(state, card_id)
        state_lib.push_log(state, card_id .. " -> trump[" .. open_slot .. "] (TRUMP event).")
        transition.emit(state, "trump_zone_entry", {
            card_id = card_id,
            slot = open_slot,
        })
        return
    end

    local zone = state.zones.trump
    local flushed = {card_id}
    for slot = 1, zone.slot_count do
        local resident = zone.cards[slot]
        if resident then
            flushed[#flushed + 1] = resident
            state_lib.remove_from_current_zone(state, resident)
        end
    end
    for _, flushed_id in ipairs(flushed) do
        state_lib.hide_card(state, flushed_id)
        state_lib.place_card(state, flushed_id, "deck", nil)
    end
    shuffle_in_place(state.zones.deck.cards, state.rng)
    state_lib.sync_zone_cards(state, "deck")
    state_lib.push_log(state, "TRUMP zone overflow flush -> deck.")
    transition.emit(state, "trump_zone_overflow_flush", {
        cards = flushed,
    })
end

function M.refresh_pending_trump(state)
    if state.trump_runaway then
        return nil
    end
    if state.pending_trump or not state_lib.is_board_closed(state) then
        return nil
    end
    local card_id = state.zones.trump_flow.cards[1]
    if not card_id then
        return nil
    end
    state.pending_trump = card_id
    state_lib.push_log(state, card_id .. " pending trump event.")
    transition.emit(state, "pending_trump", {card_id = card_id})
    return card_id
end

function M.resolve_pending_trump(state)
    if state.trump_runaway then
        return nil, "trump_flow_runaway"
    end
    local card_id = state.pending_trump
    if not card_id then
        return nil, "no_pending_trump"
    end
    if not state_lib.is_board_closed(state) then
        return nil, "board_not_closed"
    end
    if (state.trump_chain_steps or 0) + 1 > guard_limit(state, "max_trump_chain_steps") then
        mark_runaway(state, "max_trump_chain_steps", {
            card_id = card_id,
        })
        return nil, "trump_flow_runaway"
    end
    state.pending_trump = nil
    state_lib.remove_from_current_zone(state, card_id)
    resolve_trump_card(state, card_id)
    resolve_all_pending_trumps(state)
    repair_open_board_from_deck(state)
    if state.trump_runaway then
        return nil, "trump_flow_runaway"
    end
    return card_id
end

return M
