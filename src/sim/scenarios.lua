local core = require("src.core.api")
local draw = require("src.core.draw")
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

local function relocate_existing_card(state, card_id)
    local card = state.cards[card_id]
    if not card or not card.zone then
        return nil, "missing_card_zone"
    end

    local from_zone = card.zone
    local from_slot = card.slot
    state_lib.remove_from_current_zone(state, card_id)

    if (from_zone == "latent" or from_zone == "targets") and from_slot then
        draw.concealed_refill(state, from_zone, from_slot)
    end

    return {
        from_zone = from_zone,
        from_slot = from_slot,
    }, nil
end

local function move_card_to_deck_top(state, card_id)
    local moved, err = relocate_existing_card(state, card_id)
    if err then
        return nil, err
    end
    state_lib.hide_card(state, card_id)
    table.insert(state.zones.deck.cards, card_id)
    state_lib.sync_zone_cards(state, "deck")
    return moved
end

local function move_card_to_deck_bottom(state, card_id)
    local moved, err = relocate_existing_card(state, card_id)
    if err then
        return nil, err
    end
    state_lib.hide_card(state, card_id)
    local deck = state.zones.deck.cards
    table.insert(deck, 1, card_id)
    state_lib.sync_zone_cards(state, "deck")
    return moved
end

local function insert_card_at_hand_front(state, card_id)
    local moved, err = relocate_existing_card(state, card_id)
    if err then
        return nil, err
    end
    state_lib.reveal_card(state, card_id)
    table.insert(state.zones.hand.cards, 1, card_id)
    state_lib.sync_zone_cards(state, "hand")
    return moved
end

local function move_card_to_slot(state, card_id, zone_name, slot, info_state)
    local moved, err = relocate_existing_card(state, card_id)
    if err then
        return nil, err
    end
    if info_state == "hidden" then
        state_lib.hide_card(state, card_id)
    elseif info_state == "known" then
        state_lib.hide_card(state, card_id)
        state_lib.know_card(state, card_id)
    else
        state_lib.reveal_card(state, card_id)
    end
    state_lib.place_card(state, card_id, zone_name, slot)
    return moved
end

local function move_card_to_zone_tail(state, card_id, zone_name, info_state)
    local moved, err = relocate_existing_card(state, card_id)
    if err then
        return nil, err
    end
    if info_state == "hidden" then
        state_lib.hide_card(state, card_id)
    elseif info_state == "known" then
        state_lib.hide_card(state, card_id)
        state_lib.know_card(state, card_id)
    else
        state_lib.reveal_card(state, card_id)
    end
    state_lib.place_card(state, card_id, zone_name, nil)
    return moved
end

local function created_trump_ids(state)
    local out = {}
    for card_id, card in pairs(state.cards) do
        if card.class == "trump" then
            out[#out + 1] = card_id
        end
    end
    table.sort(out)
    return out
end

local function first_card_matching(state, predicate, excluded)
    excluded = excluded or {}
    for _, zone_name in ipairs({"hand", "deck", "grave", "manifest", "latent", "targets"}) do
        local zone = state.zones[zone_name]
        if zone.kind == "slots" then
            for slot = 1, zone.slot_count do
                local card_id = zone.cards[slot]
                if card_id and not excluded[card_id] and predicate(card_id) then
                    excluded[card_id] = true
                    return card_id
                end
            end
        else
            for _, card_id in ipairs(zone.cards) do
                if card_id and not excluded[card_id] and predicate(card_id) then
                    excluded[card_id] = true
                    return card_id
                end
            end
        end
    end
    return nil
end

local function first_minor(state, excluded)
    return first_card_matching(state, function(card_id)
        return state.cards[card_id].class == "minor"
    end, excluded)
end

local function stage_card_to_slot(state, card_id, zone_name, slot, info_state)
    local zone = state.zones[zone_name]
    local occupant = zone.cards[slot]
    if occupant and occupant ~= card_id then
        state_lib.remove_from_current_zone(state, occupant)
        state_lib.hide_card(state, occupant)
        table.insert(state.zones.deck.cards, 1, occupant)
        state_lib.sync_zone_cards(state, "deck")
    end

    if state.cards[card_id].zone then
        state_lib.remove_from_current_zone(state, card_id)
    end

    if info_state == "hidden" then
        state_lib.hide_card(state, card_id)
    elseif info_state == "known" then
        state_lib.hide_card(state, card_id)
        state_lib.know_card(state, card_id)
    else
        state_lib.reveal_card(state, card_id)
    end
    state_lib.place_card(state, card_id, zone_name, slot)
end

local function stage_card_to_deck_top(state, card_id, info_state)
    if state.cards[card_id].zone then
        state_lib.remove_from_current_zone(state, card_id)
    end
    if info_state == "hidden" then
        state_lib.hide_card(state, card_id)
    elseif info_state == "known" then
        state_lib.hide_card(state, card_id)
        state_lib.know_card(state, card_id)
    else
        state_lib.reveal_card(state, card_id)
    end
    table.insert(state.zones.deck.cards, card_id)
    state_lib.sync_zone_cards(state, "deck")
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

function M.draw_reveal_routes_trump(state)
    local deck = state.zones.deck.cards
    local minor_a
    local minor_b
    local trump_id

    for _, card_id in ipairs(deck) do
        local card = state.cards[card_id]
        if card.class == "trump" and not trump_id then
            trump_id = card_id
        elseif card.class == "minor" then
            if not minor_a then
                minor_a = card_id
            elseif not minor_b then
                minor_b = card_id
            end
        end
        if minor_a and minor_b and trump_id then
            break
        end
    end

    if not (minor_a and minor_b and trump_id) then
        return nil, "missing_draw_sequence_cards"
    end

    move_card_to_deck_top(state, minor_b)
    move_card_to_deck_top(state, trump_id)
    move_card_to_deck_top(state, minor_a)

    local hand_before = #state.zones.hand.cards
    local deck_before = #state.zones.deck.cards

    local first = core.draw_to_hand(state)
    local second = core.draw_to_hand(state)
    local third = core.draw_to_hand(state)

    if first.summary.error or second.summary.error or third.summary.error then
        return nil, "unexpected_draw_error"
    end
    if #state.zones.hand.cards ~= hand_before + 2 then
        return nil, "draw_hand_count_mismatch"
    end
    if #state.zones.deck.cards ~= deck_before - 3 then
        return nil, "draw_deck_count_mismatch"
    end
    if state_lib.zone_count(state, "trump") ~= 1 then
        return nil, "draw_trump_zone_count_mismatch"
    end
    if #state.zones.trump_flow.cards ~= 0 then
        return nil, "draw_trump_flow_should_be_empty"
    end
    if state.pending_trump ~= nil then
        return nil, "draw_pending_trump_should_be_empty"
    end

    return {
        name = "draw_reveal_routes_trump",
        hand_after = #state.zones.hand.cards,
        deck_after = #state.zones.deck.cards,
        trump_zone = state_lib.zone_count(state, "trump"),
    }
end

function M.fool_trump_drill(state)
    local fool_id = "TRUMP-1"
    local contact_id = "TRUMP-2"
    local minor_id = state.zones.deck.cards[1]

    if not (state.cards[fool_id] and state.cards[contact_id] and minor_id) then
        return nil, "missing_trump_cards"
    end

    move_card_to_deck_top(state, contact_id)
    move_card_to_deck_top(state, minor_id)
    move_card_to_deck_top(state, fool_id)

    local deck = state.zones.deck.cards
    local fool_top = deck[#deck]
    if fool_top ~= fool_id then
        return nil, "fool_not_on_top"
    end

    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "fool_draw_error"
    end

    if state_lib.zone_count(state, "grave") < 1 then
        return nil, "fool_should_drill_minor_to_grave"
    end
    if state_lib.zone_count(state, "trump") < 2 then
        return nil, "fool_should_resolve_contact_trump_and_self"
    end
    if #state.zones.trump_flow.cards ~= 0 or state.pending_trump ~= nil then
        return nil, "fool_should_leave_no_pending_trump"
    end

    return {
        name = "fool_trump_drill",
        grave = state_lib.zone_count(state, "grave"),
        trump = state_lib.zone_count(state, "trump"),
    }
end

function M.rush_trump_burst(state)
    local rush_id = "TRUMP-8"
    if not state.cards[rush_id] then
        return nil, "missing_rush"
    end

    local minors = {}
    local extra_trump
    for _, card_id in ipairs(state.zones.deck.cards) do
        local card = state.cards[card_id]
        if card.class == "minor" then
            minors[#minors + 1] = card_id
        elseif card_id ~= rush_id and not extra_trump then
            extra_trump = card_id
        end
        if #minors >= 5 and extra_trump then
            break
        end
    end
    if #minors < 5 or not extra_trump then
        return nil, "missing_rush_sequence_cards"
    end

    for i = 1, 5 do
        move_card_to_deck_top(state, minors[i])
    end
    move_card_to_deck_top(state, extra_trump)
    move_card_to_deck_top(state, rush_id)

    local hand_before = #state.zones.hand.cards
    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "rush_draw_error"
    end

    if #state.zones.hand.cards ~= hand_before + 5 then
        return nil, "rush_hand_gain_mismatch"
    end
    if state_lib.zone_count(state, "trump") < 2 then
        return nil, "rush_should_resolve_self_and_queued_trump"
    end
    if #state.zones.trump_flow.cards ~= 0 or state.pending_trump ~= nil then
        return nil, "rush_should_leave_no_pending_trump"
    end

    return {
        name = "rush_trump_burst",
        hand_after = #state.zones.hand.cards,
        trump = state_lib.zone_count(state, "trump"),
    }
end

function M.reset_hand_rebuild(state)
    local reset_id = "TRUMP-17"
    if not state.cards[reset_id] then
        return nil, "missing_reset"
    end

    local minors = {}
    for _, card_id in ipairs(state.zones.deck.cards) do
        if state.cards[card_id].class == "minor" then
            minors[#minors + 1] = card_id
        end
        if #minors >= 6 then
            break
        end
    end
    if #minors < 6 then
        return nil, "missing_reset_draw_minors"
    end

    for i = 1, 6 do
        move_card_to_deck_top(state, minors[i])
    end
    move_card_to_deck_top(state, reset_id)

    local hand_before = #state.zones.hand.cards
    local grave_before = #state.zones.grave.cards
    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "reset_draw_error"
    end
    if #state.zones.hand.cards ~= 6 then
        return nil, "reset_hand_size_mismatch"
    end
    if #state.zones.grave.cards < grave_before + hand_before then
        return nil, "reset_should_dump_old_hand_to_grave"
    end
    if state.zones.trump.cards[1] ~= reset_id and state.zones.trump.cards[2] ~= reset_id then
        return nil, "reset_should_enter_trump_zone"
    end

    return {
        name = "reset_hand_rebuild",
        hand_after = #state.zones.hand.cards,
        grave_after = #state.zones.grave.cards,
    }
end

function M.shuffle_grave_to_deck(state)
    local shuffle_id = "TRUMP-14"
    if not state.cards[shuffle_id] then
        return nil, "missing_shuffle"
    end

    local hand_card = state.zones.hand.cards[1]
    if not hand_card then
        return nil, "missing_hand_card_for_shuffle_prep"
    end
    state_lib.remove_from_current_zone(state, hand_card)
    state_lib.reveal_card(state, hand_card)
    state_lib.place_card(state, hand_card, "grave", nil)

    move_card_to_deck_top(state, shuffle_id)

    local deck_before = #state.zones.deck.cards
    local grave_before = #state.zones.grave.cards
    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "shuffle_draw_error"
    end
    if #state.zones.grave.cards ~= 0 then
        return nil, "shuffle_should_empty_grave"
    end
    if #state.zones.deck.cards ~= deck_before + grave_before - 1 then
        return nil, "shuffle_deck_count_mismatch"
    end
    if state.zones.trump.cards[1] ~= shuffle_id and state.zones.trump.cards[2] ~= shuffle_id then
        return nil, "shuffle_should_enter_trump_zone"
    end

    return {
        name = "shuffle_grave_to_deck",
        deck_after = #state.zones.deck.cards,
    }
end

function M.repeat_rush_echo(state)
    local rush_id = "TRUMP-8"
    local repeat_id = "TRUMP-20"
    if not (state.cards[rush_id] and state.cards[repeat_id]) then
        return nil, "missing_repeat_or_rush"
    end

    local minors = {}
    for _, card_id in ipairs(state.zones.deck.cards) do
        if state.cards[card_id].class == "minor" then
            minors[#minors + 1] = card_id
        end
        if #minors >= 11 then
            break
        end
    end
    if #minors < 11 then
        return nil, "missing_repeat_rush_minors"
    end

    for i = 11, 7, -1 do
        move_card_to_deck_top(state, minors[i])
    end
    for i = 6, 2, -1 do
        move_card_to_deck_top(state, minors[i])
    end
    move_card_to_deck_top(state, repeat_id)
    move_card_to_deck_top(state, rush_id)

    local hand_before = #state.zones.hand.cards
    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "repeat_rush_draw_error"
    end
    if #state.zones.hand.cards ~= hand_before + 11 then
        return nil, "repeat_rush_hand_gain_mismatch"
    end
    if state.zones.trump.cards[1] ~= repeat_id and state.zones.trump.cards[2] ~= repeat_id then
        return nil, "repeat_should_enter_trump_zone"
    end
    if state.zones.trump.cards[1] ~= rush_id and state.zones.trump.cards[2] ~= rush_id then
        return nil, "rush_should_enter_trump_zone"
    end

    return {
        name = "repeat_rush_echo",
        hand_after = #state.zones.hand.cards,
    }
end

function M.halt_blocks_later_trump(state)
    local rush_id = "TRUMP-8"
    local halt_id = "TRUMP-22"
    local reset_id = "TRUMP-17"
    if not (state.cards[rush_id] and state.cards[halt_id] and state.cards[reset_id]) then
        return nil, "missing_halt_chain_cards"
    end

    local minors = {}
    for _, card_id in ipairs(state.zones.deck.cards) do
        if state.cards[card_id].class == "minor" then
            minors[#minors + 1] = card_id
        end
        if #minors >= 4 then
            break
        end
    end
    if #minors < 4 then
        return nil, "missing_halt_chain_minors"
    end

    for i = 4, 1, -1 do
        move_card_to_deck_top(state, minors[i])
    end
    move_card_to_deck_top(state, reset_id)
    move_card_to_deck_top(state, halt_id)
    move_card_to_deck_top(state, rush_id)

    local hand_before = #state.zones.hand.cards
    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "halt_chain_draw_error"
    end
    if #state.zones.hand.cards ~= hand_before + 4 then
        return nil, "halt_should_only_keep_minor_draws"
    end
    if state.zones.trump.cards[1] ~= halt_id and state.zones.trump.cards[2] ~= halt_id then
        return nil, "halt_should_survive_chain"
    end
    if state.zones.trump.cards[1] ~= rush_id and state.zones.trump.cards[2] ~= rush_id then
        return nil, "rush_should_survive_its_own_burst"
    end
    if state.zones.trump.cards[1] == reset_id or state.zones.trump.cards[2] == reset_id then
        return nil, "reset_should_be_halted_and_flushed"
    end

    return {
        name = "halt_blocks_later_trump",
        hand_after = #state.zones.hand.cards,
        halt_zone_1 = state.zones.trump.cards[1],
        halt_zone_2 = state.zones.trump.cards[2],
    }
end

function M.recast_manifest_inversion(state)
    local recast_id = "TRUMP-16"
    if not state.cards[recast_id] then
        return nil, "missing_recast"
    end

    local old_manifest = {}
    local old_latent = {}
    local old_hand = {}
    for slot = 1, 6 do
        old_manifest[slot] = state.zones.manifest.cards[slot]
        old_latent[slot] = state.zones.latent.cards[slot]
    end
    for _, card_id in ipairs(state.zones.hand.cards) do
        old_hand[#old_hand + 1] = card_id
    end

    move_card_to_deck_top(state, recast_id)

    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "recast_draw_error"
    end

    for slot = 1, 6 do
        if state.zones.manifest.cards[slot] ~= old_latent[slot] then
            return nil, "recast_manifest_not_promoted"
        end
        if not state_lib.is_revealed(state, state.zones.manifest.cards[slot]) then
            return nil, "recast_manifest_should_be_revealed"
        end
    end

    local hand_set = {}
    for _, card_id in ipairs(state.zones.hand.cards) do
        hand_set[card_id] = true
    end
    for _, card_id in ipairs(old_manifest) do
        if not hand_set[card_id] then
            return nil, "recast_old_manifest_not_in_hand"
        end
    end

    for slot = 1, 6 do
        local latent_id = state.zones.latent.cards[slot]
        if not latent_id then
            return nil, "recast_latent_not_refilled"
        end
        if not state_lib.is_hidden(state, latent_id) then
            return nil, "recast_latent_should_be_hidden"
        end
    end

    if state.zones.trump.cards[1] ~= recast_id and state.zones.trump.cards[2] ~= recast_id then
        return nil, "recast_should_enter_trump_zone"
    end

    return {
        name = "recast_manifest_inversion",
        hand_after = #state.zones.hand.cards,
        grave_after = #state.zones.grave.cards,
    }
end

function M.repeat_fool_contacts_shuffle(state)
    local fool_id = "TRUMP-1"
    local repeat_id = "TRUMP-20"
    local shuffle_id = "TRUMP-14"
    if not (state.cards[fool_id] and state.cards[repeat_id] and state.cards[shuffle_id]) then
        return nil, "missing_repeat_fool_shuffle_cards"
    end

    move_card_to_deck_top(state, shuffle_id)
    move_card_to_deck_top(state, repeat_id)
    move_card_to_deck_top(state, fool_id)

    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "repeat_fool_draw_error"
    end

    if state_lib.zone_count(state, "trump") ~= 0 then
        return nil, "repeat_fool_should_flush_all_three"
    end
    if #state.zones.trump_flow.cards ~= 0 or state.pending_trump ~= nil then
        return nil, "repeat_fool_should_leave_no_pending_trump"
    end

    return {
        name = "repeat_fool_contacts_shuffle",
        deck_after = #state.zones.deck.cards,
        grave_after = #state.zones.grave.cards,
    }
end

function M.recast_overflow_trump_routes(state)
    local recast_id = "TRUMP-16"
    local shuffle_id = "TRUMP-14"
    if not (state.cards[recast_id] and state.cards[shuffle_id]) then
        return nil, "missing_recast_or_shuffle"
    end

    state.rng = function(n) return n end
    insert_card_at_hand_front(state, shuffle_id)
    move_card_to_deck_top(state, recast_id)

    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "recast_overflow_draw_error"
    end

    local has_recast = state.zones.trump.cards[1] == recast_id or state.zones.trump.cards[2] == recast_id
    local has_shuffle = state.zones.trump.cards[1] == shuffle_id or state.zones.trump.cards[2] == shuffle_id
    if not has_recast then
        return nil, "recast_should_enter_trump_zone"
    end
    if not has_shuffle then
        return nil, "overflow_trump_should_resolve_and_enter_trump_zone"
    end
    if #state.zones.grave.cards ~= 0 then
        return nil, "shuffle_overflow_should_clear_grave"
    end

    return {
        name = "recast_overflow_trump_routes",
        hand_after = #state.zones.hand.cards,
        trump_1 = state.zones.trump.cards[1],
        trump_2 = state.zones.trump.cards[2],
    }
end

function M.recast_survives_halt(state)
    local recast_id = "TRUMP-16"
    local halt_id = "TRUMP-22"
    if not (state.cards[recast_id] and state.cards[halt_id]) then
        return nil, "missing_recast_or_halt"
    end

    local old_manifest = {}
    local old_latent = {}
    for slot = 1, 6 do
        old_manifest[slot] = state.zones.manifest.cards[slot]
        old_latent[slot] = state.zones.latent.cards[slot]
    end

    state.rng = function(n) return n end
    insert_card_at_hand_front(state, halt_id)
    move_card_to_deck_top(state, recast_id)

    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "recast_halt_draw_error"
    end

    local hand_set = {}
    for _, card_id in ipairs(state.zones.hand.cards) do
        hand_set[card_id] = true
    end
    for _, card_id in ipairs(old_manifest) do
        if not hand_set[card_id] then
            return nil, "recast_halt_old_manifest_not_restored"
        end
    end

    for slot = 1, 6 do
        if state.zones.manifest.cards[slot] ~= old_latent[slot] then
            return nil, "recast_halt_manifest_not_promoted"
        end
    end

    local has_recast = state.zones.trump.cards[1] == recast_id or state.zones.trump.cards[2] == recast_id
    local has_halt = state.zones.trump.cards[1] == halt_id or state.zones.trump.cards[2] == halt_id
    if not has_recast then
        return nil, "recast_should_survive_halt"
    end
    if not has_halt then
        return nil, "halt_should_enter_trump_zone"
    end
    if not state_lib.is_board_closed(state) then
        return nil, "recast_halt_should_leave_board_closed"
    end

    return {
        name = "recast_survives_halt",
        hand_after = #state.zones.hand.cards,
        trump_1 = state.zones.trump.cards[1],
        trump_2 = state.zones.trump.cards[2],
    }
end

function M.repeat_recast_echo(state)
    local recast_id = "TRUMP-16"
    local repeat_id = "TRUMP-20"
    if not (state.cards[recast_id] and state.cards[repeat_id]) then
        return nil, "missing_recast_or_repeat"
    end

    local old_manifest = {}
    local old_latent = {}
    for slot = 1, 6 do
        old_manifest[slot] = state.zones.manifest.cards[slot]
        old_latent[slot] = state.zones.latent.cards[slot]
    end

    state.rng = function(n) return n end
    insert_card_at_hand_front(state, repeat_id)
    move_card_to_deck_top(state, recast_id)

    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "repeat_recast_draw_error"
    end

    local hand_set = {}
    for _, card_id in ipairs(state.zones.hand.cards) do
        hand_set[card_id] = true
    end
    for _, card_id in ipairs(old_latent) do
        if not hand_set[card_id] then
            return nil, "repeat_recast_old_latent_missing_from_hand"
        end
    end

    local manifest_set = {}
    for slot = 1, 6 do
        manifest_set[state.zones.manifest.cards[slot]] = true
    end
    for _, card_id in ipairs(old_latent) do
        if manifest_set[card_id] then
            return nil, "repeat_recast_manifest_should_not_be_old_latent"
        end
    end

    local latent_set = {}
    for slot = 1, 6 do
        latent_set[state.zones.latent.cards[slot]] = true
    end
    for _, card_id in ipairs(old_manifest) do
        if not latent_set[card_id] then
            return nil, "repeat_recast_old_manifest_should_become_new_latent"
        end
    end

    local has_recast = state.zones.trump.cards[1] == recast_id or state.zones.trump.cards[2] == recast_id
    local has_repeat = state.zones.trump.cards[1] == repeat_id or state.zones.trump.cards[2] == repeat_id
    if not has_recast then
        return nil, "recast_should_enter_trump_zone"
    end
    if not has_repeat then
        return nil, "repeat_should_echo_recast_and_enter_trump_zone"
    end
    if #state.zones.hand.cards ~= 6 then
        return nil, "repeat_recast_should_leave_one_full_hand"
    end

    return {
        name = "repeat_recast_echo",
        hand_after = #state.zones.hand.cards,
        trump_1 = state.zones.trump.cards[1],
        trump_2 = state.zones.trump.cards[2],
    }
end

function M.oracle_top_six_pick_minor(state)
    local oracle_id = "TRUMP-3"
    if not state.cards[oracle_id] then
        return nil, "missing_oracle"
    end

    local deck = state.zones.deck.cards
    local viewed = {}
    for i = #deck, math.max(1, #deck - 5), -1 do
        viewed[#viewed + 1] = deck[i]
    end
    if #viewed < 3 then
        return nil, "deck_too_small_for_oracle"
    end

    local chosen_minor = nil
    local chosen_index = nil
    for index, card_id in ipairs(viewed) do
        if state.cards[card_id].class ~= "trump" then
            chosen_minor = card_id
            chosen_index = index
            break
        end
    end
    if not chosen_minor then
        return nil, "oracle_view_has_no_minor"
    end

    move_card_to_deck_top(state, oracle_id)

    local hand_before = #state.zones.hand.cards
    local deck_before = #state.zones.deck.cards
    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "oracle_draw_error"
    end

    local hand_top = state.zones.hand.cards[#state.zones.hand.cards]
    if hand_top ~= chosen_minor then
        return nil, "oracle_should_take_first_minor_from_view"
    end
    if #state.zones.hand.cards ~= hand_before + 1 then
        return nil, "oracle_should_add_one_card_to_hand"
    end
    if #state.zones.deck.cards ~= deck_before - 2 then
        return nil, "oracle_deck_count_mismatch"
    end
    if state.zones.trump.cards[1] ~= oracle_id and state.zones.trump.cards[2] ~= oracle_id then
        return nil, "oracle_should_enter_trump_zone"
    end
    if state_lib.zone_count(state, "trump") ~= 1 then
        return nil, "oracle_should_not_trigger_viewed_trumps"
    end

    return {
        name = "oracle_top_six_pick_minor",
        picked_index = chosen_index,
        picked_card = chosen_minor,
    }
end

function M.oracle_recast_fat_deck(state)
    local oracle_id = "TRUMP-3"
    local recast_id = "TRUMP-16"
    if not (state.cards[oracle_id] and state.cards[recast_id]) then
        return nil, "missing_oracle_or_recast"
    end

    local deck_before = #state.zones.deck.cards
    if deck_before < 40 then
        return nil, "deck_not_fat_enough"
    end

    local staged_to_deck = {}
    for _, card_id in ipairs({recast_id, oracle_id}) do
        if state.cards[card_id].zone ~= "deck" then
            local moved, err = relocate_existing_card(state, card_id)
            if err then
                return nil, err
            end
            if not moved then
                return nil, "failed_to_stage_oracle_recast"
            end
            state_lib.hide_card(state, card_id)
            staged_to_deck[#staged_to_deck + 1] = card_id
        end
    end
    for _, card_id in ipairs(staged_to_deck) do
        table.insert(state.zones.deck.cards, card_id)
    end
    if #staged_to_deck > 0 then
        state_lib.sync_zone_cards(state, "deck")
    end

    local deck_trumps = {}
    for _, card_id in ipairs(state.zones.deck.cards) do
        if state.cards[card_id].class == "trump" and card_id ~= oracle_id then
            deck_trumps[#deck_trumps + 1] = card_id
        end
    end
    if #deck_trumps < 6 then
        return nil, "not_enough_deck_trumps_for_oracle_recast_view"
    end

    local viewed = {recast_id}
    for _, card_id in ipairs(deck_trumps) do
        if card_id ~= recast_id then
            viewed[#viewed + 1] = card_id
        end
        if #viewed == 6 then
            break
        end
    end
    if #viewed < 6 then
        return nil, "not_enough_deck_trumps_for_oracle_recast_view"
    end

    for i = #viewed, 1, -1 do
        move_card_to_deck_top(state, viewed[i])
    end
    move_card_to_deck_top(state, oracle_id)

    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "oracle_recast_fat_draw_error"
    end

    if not state_lib.is_board_closed(state) then
        return nil, "oracle_recast_fat_should_leave_board_closed"
    end
    if #state.zones.deck.cards >= deck_before then
        return nil, "oracle_recast_fat_should_consume_some_deck"
    end
    if #state.zones.deck.cards <= 20 then
        return nil, "oracle_recast_fat_should_not_nearly_empty_deck"
    end

    local has_oracle = state.zones.trump.cards[1] == oracle_id or state.zones.trump.cards[2] == oracle_id
    local has_recast = state.zones.trump.cards[1] == recast_id or state.zones.trump.cards[2] == recast_id
    if not has_oracle then
        return nil, "oracle_should_enter_trump_zone"
    end
    if not has_recast then
        return nil, "recast_should_enter_trump_zone"
    end

    return {
        name = "oracle_recast_fat_deck",
        deck_before = deck_before,
        deck_after = #state.zones.deck.cards,
        hand_after = #state.zones.hand.cards,
        trump_1 = state.zones.trump.cards[1],
        trump_2 = state.zones.trump.cards[2],
    }
end

function M.eject_target_trump_breaks_seal(state)
    local eject_id = "TRUMP-2"
    local shuffle_id = "TRUMP-14"
    if not (state.cards[eject_id] and state.cards[shuffle_id]) then
        return nil, "missing_eject_or_shuffle"
    end

    local grave_minor = state.zones.hand.cards[1]
    if not grave_minor then
        return nil, "missing_grave_minor"
    end
    move_card_to_zone_tail(state, grave_minor, "grave", "revealed")
    move_card_to_slot(state, shuffle_id, "targets", 1, "hidden")
    move_card_to_deck_top(state, eject_id)

    local deck_before = #state.zones.deck.cards
    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "eject_target_trump_draw_error"
    end

    local has_eject = state.zones.trump.cards[1] == eject_id or state.zones.trump.cards[2] == eject_id
    local has_shuffle = state.zones.trump.cards[1] == shuffle_id or state.zones.trump.cards[2] == shuffle_id
    if not has_eject or not has_shuffle then
        return nil, "eject_target_trump_should_resolve_shuffle_and_self"
    end
    if not state.zones.targets.cards[1] then
        return nil, "eject_target_trump_should_refill_target_slot"
    end
    if state.cards[shuffle_id].zone ~= "trump" then
        return nil, "eject_target_trump_shuffle_should_end_in_trump_zone"
    end
    if state_lib.zone_count(state, "grave") ~= 0 then
        return nil, "eject_target_trump_shuffle_should_empty_grave"
    end
    if state.cards[grave_minor].zone ~= "deck" then
        return nil, "eject_target_trump_shuffle_should_return_grave_card_to_deck"
    end

    return {
        name = "eject_target_trump_breaks_seal",
        deck_before = deck_before,
        deck_after = #state.zones.deck.cards,
        trump_1 = state.zones.trump.cards[1],
        trump_2 = state.zones.trump.cards[2],
    }
end

function M.eject_trump_zone_releases_stored_trump(state)
    local eject_id = "TRUMP-2"
    local shuffle_id = "TRUMP-14"
    if not (state.cards[eject_id] and state.cards[shuffle_id]) then
        return nil, "missing_eject_or_shuffle"
    end

    local grave_minor = state.zones.hand.cards[1]
    if not grave_minor then
        return nil, "missing_grave_minor"
    end
    move_card_to_zone_tail(state, grave_minor, "grave", "revealed")
    move_card_to_slot(state, shuffle_id, "trump", 1, "revealed")
    move_card_to_deck_top(state, eject_id)

    local deck_before = #state.zones.deck.cards
    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "eject_trump_zone_draw_error"
    end

    local has_eject = state.zones.trump.cards[1] == eject_id or state.zones.trump.cards[2] == eject_id
    local has_shuffle = state.zones.trump.cards[1] == shuffle_id or state.zones.trump.cards[2] == shuffle_id
    if not has_eject or not has_shuffle then
        return nil, "eject_trump_zone_should_resolve_stored_trump_and_self"
    end
    if state_lib.zone_count(state, "grave") ~= 0 then
        return nil, "eject_trump_zone_shuffle_should_empty_grave"
    end
    if state.cards[grave_minor].zone ~= "deck" then
        return nil, "eject_trump_zone_shuffle_should_return_grave_card_to_deck"
    end

    return {
        name = "eject_trump_zone_releases_stored_trump",
        deck_before = deck_before,
        deck_after = #state.zones.deck.cards,
        trump_1 = state.zones.trump.cards[1],
        trump_2 = state.zones.trump.cards[2],
    }
end

function M.eject_manifest_trump_repairs_before_resolution(state)
    local eject_id = "TRUMP-2"
    local shuffle_id = "TRUMP-14"
    if not (state.cards[eject_id] and state.cards[shuffle_id]) then
        return nil, "missing_eject_or_shuffle"
    end

    local grave_minor = state.zones.hand.cards[1]
    if not grave_minor then
        return nil, "missing_grave_minor"
    end
    move_card_to_zone_tail(state, grave_minor, "grave", "revealed")

    local repair_minor = state.zones.latent.cards[1]
    if not repair_minor or state.cards[repair_minor].class == "trump" then
        return nil, "missing_repair_minor"
    end

    for slot = 1, state.zones.targets.slot_count do
        local card_id = state.zones.targets.cards[slot]
        if card_id and state.cards[card_id].class == "trump" then
            move_card_to_deck_bottom(state, card_id)
        end
    end
    for slot = 1, state.zones.latent.slot_count do
        local card_id = state.zones.latent.cards[slot]
        if card_id and slot ~= 1 and state.cards[card_id].class == "trump" then
            move_card_to_deck_bottom(state, card_id)
        end
    end

    move_card_to_slot(state, shuffle_id, "manifest", 1, "revealed")
    move_card_to_deck_top(state, eject_id)

    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "eject_manifest_trump_draw_error"
    end

    local has_eject = state.zones.trump.cards[1] == eject_id or state.zones.trump.cards[2] == eject_id
    local has_shuffle = state.zones.trump.cards[1] == shuffle_id or state.zones.trump.cards[2] == shuffle_id
    if not has_eject or not has_shuffle then
        return nil, "eject_manifest_trump_should_resolve_shuffle_and_self"
    end
    if state.zones.manifest.cards[1] ~= repair_minor then
        return nil, "eject_manifest_trump_should_repair_manifest_before_resolution"
    end
    if state.cards[repair_minor].zone ~= "manifest" then
        return nil, "repair_minor_should_end_in_manifest"
    end
    if state_lib.zone_count(state, "grave") ~= 0 then
        return nil, "eject_manifest_shuffle_should_empty_grave"
    end

    return {
        name = "eject_manifest_trump_repairs_before_resolution",
        manifest_1 = state.zones.manifest.cards[1],
        trump_1 = state.zones.trump.cards[1],
        trump_2 = state.zones.trump.cards[2],
    }
end

function M.oracle_pick_trump_without_triggering_other_viewed_trumps(state)
    local oracle_id = "TRUMP-3"
    local chosen_trump_id = "TRUMP-14"
    if not (state.cards[oracle_id] and state.cards[chosen_trump_id]) then
        return nil, "missing_oracle_or_chosen_trump"
    end

    local viewed = { chosen_trump_id }
    for _, card_id in ipairs(created_trump_ids(state)) do
        if card_id ~= oracle_id and card_id ~= chosen_trump_id then
            viewed[#viewed + 1] = card_id
        end
        if #viewed == 6 then
            break
        end
    end
    if #viewed < 6 then
        return nil, "not_enough_viewed_trumps"
    end

    local staged_to_deck = {}
    for _, card_id in ipairs(viewed) do
        if state.cards[card_id].zone ~= "deck" then
            local moved, err = relocate_existing_card(state, card_id)
            if err then
                return nil, err
            end
            if not moved then
                return nil, "failed_to_stage_oracle_pick_trump"
            end
            state_lib.hide_card(state, card_id)
            staged_to_deck[#staged_to_deck + 1] = card_id
        end
    end
    if state.cards[oracle_id].zone ~= "deck" then
        local moved, err = relocate_existing_card(state, oracle_id)
        if err then
            return nil, err
        end
        if not moved then
            return nil, "failed_to_stage_oracle_pick_trump"
        end
        state_lib.hide_card(state, oracle_id)
        staged_to_deck[#staged_to_deck + 1] = oracle_id
    end
    for _, card_id in ipairs(staged_to_deck) do
        table.insert(state.zones.deck.cards, card_id)
    end
    if #staged_to_deck > 0 then
        state_lib.sync_zone_cards(state, "deck")
    end

    for i = #viewed, 1, -1 do
        move_card_to_deck_top(state, viewed[i])
    end
    move_card_to_deck_top(state, oracle_id)

    local deck_before = #state.zones.deck.cards
    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "oracle_pick_trump_draw_error"
    end

    local has_oracle = state.zones.trump.cards[1] == oracle_id or state.zones.trump.cards[2] == oracle_id
    local has_chosen = state.zones.trump.cards[1] == chosen_trump_id or state.zones.trump.cards[2] == chosen_trump_id
    if not has_oracle then
        return nil, "oracle_should_enter_trump_zone"
    end
    if not has_chosen then
        return nil, "oracle_chosen_trump_should_enter_trump_zone"
    end
    if state_lib.zone_count(state, "trump") ~= 2 then
        return nil, "oracle_should_only_trigger_chosen_trump"
    end
    if #state.zones.trump_flow.cards ~= 0 or state.pending_trump ~= nil then
        return nil, "oracle_should_leave_no_pending_trump"
    end
    if #state.zones.deck.cards ~= deck_before - 2 then
        return nil, "oracle_pick_trump_deck_count_mismatch"
    end

    for i = 2, #viewed do
        local card_id = viewed[i]
        if state.cards[card_id].zone ~= "deck" then
            return nil, "oracle_viewed_trump_should_remain_in_deck"
        end
    end

    return {
        name = "oracle_pick_trump_without_triggering_other_viewed_trumps",
        chosen_trump = chosen_trump_id,
        deck_after = #state.zones.deck.cards,
        trump_1 = state.zones.trump.cards[1],
        trump_2 = state.zones.trump.cards[2],
    }
end

function M.repeat_oracle_echo(state)
    local oracle_id = "TRUMP-3"
    local repeat_id = "TRUMP-20"
    if not (state.cards[oracle_id] and state.cards[repeat_id]) then
        return nil, "missing_oracle_or_repeat"
    end

    local echo_viewed_trumps = {}
    local echo_minor = nil
    for _, card_id in ipairs(created_trump_ids(state)) do
        if card_id ~= oracle_id and card_id ~= repeat_id then
            echo_viewed_trumps[#echo_viewed_trumps + 1] = card_id
        end
        if #echo_viewed_trumps == 5 then
            break
        end
    end
    for i = #state.zones.deck.cards, 1, -1 do
        local card_id = state.zones.deck.cards[i]
        if state.cards[card_id].class ~= "trump" then
            echo_minor = card_id
            break
        end
    end
    if #echo_viewed_trumps < 5 or not echo_minor then
        return nil, "missing_repeat_oracle_view_cards"
    end

    local initial_view = { repeat_id }
    for i = 1, 5 do
        initial_view[#initial_view + 1] = echo_viewed_trumps[i]
    end

    local staged_to_deck = {}
    for _, card_id in ipairs(initial_view) do
        if state.cards[card_id].zone ~= "deck" then
            local moved, err = relocate_existing_card(state, card_id)
            if err then
                return nil, err
            end
            if not moved then
                return nil, "failed_to_stage_repeat_oracle"
            end
            state_lib.hide_card(state, card_id)
            staged_to_deck[#staged_to_deck + 1] = card_id
        end
    end
    for _, card_id in ipairs({ echo_minor, oracle_id }) do
        if state.cards[card_id].zone ~= "deck" then
            local moved, err = relocate_existing_card(state, card_id)
            if err then
                return nil, err
            end
            if not moved then
                return nil, "failed_to_stage_repeat_oracle"
            end
            state_lib.hide_card(state, card_id)
            staged_to_deck[#staged_to_deck + 1] = card_id
        end
    end
    for _, card_id in ipairs(staged_to_deck) do
        table.insert(state.zones.deck.cards, card_id)
    end
    if #staged_to_deck > 0 then
        state_lib.sync_zone_cards(state, "deck")
    end

    move_card_to_deck_top(state, echo_minor)
    for i = #initial_view, 1, -1 do
        move_card_to_deck_top(state, initial_view[i])
    end
    move_card_to_deck_top(state, oracle_id)

    local hand_before = #state.zones.hand.cards
    local deck_before = #state.zones.deck.cards
    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "repeat_oracle_draw_error"
    end

    local hand_top = state.zones.hand.cards[#state.zones.hand.cards]
    if hand_top ~= echo_minor then
        return nil, "repeat_oracle_should_pick_echo_minor"
    end
    if #state.zones.hand.cards ~= hand_before + 1 then
        return nil, "repeat_oracle_should_add_one_card_to_hand"
    end
    if #state.zones.deck.cards ~= deck_before - 3 then
        return nil, "repeat_oracle_deck_count_mismatch"
    end

    local has_oracle = state.zones.trump.cards[1] == oracle_id or state.zones.trump.cards[2] == oracle_id
    local has_repeat = state.zones.trump.cards[1] == repeat_id or state.zones.trump.cards[2] == repeat_id
    if not has_oracle or not has_repeat then
        return nil, "repeat_oracle_should_leave_oracle_and_repeat_in_trump_zone"
    end
    if state_lib.zone_count(state, "trump") ~= 2 then
        return nil, "repeat_oracle_should_not_trigger_other_viewed_trumps"
    end
    if #state.zones.trump_flow.cards ~= 0 or state.pending_trump ~= nil then
        return nil, "repeat_oracle_should_leave_no_pending_trump"
    end

    for _, card_id in ipairs(echo_viewed_trumps) do
        if state.cards[card_id].zone ~= "deck" then
            return nil, "repeat_oracle_viewed_trumps_should_remain_in_deck"
        end
    end

    return {
        name = "repeat_oracle_echo",
        picked_minor = echo_minor,
        hand_after = #state.zones.hand.cards,
        trump_1 = state.zones.trump.cards[1],
        trump_2 = state.zones.trump.cards[2],
    }
end

function M.unveil_reveals_known_targets_and_topdeck(state)
    local unveil_id = "TRUMP-21"
    local target_trump_id = "TRUMP-14"
    if not (state.cards[unveil_id] and state.cards[target_trump_id]) then
        return nil, "missing_unveil_or_target_trump"
    end

    local excluded = {
        [unveil_id] = true,
        [target_trump_id] = true,
    }
    local target_known_minor = first_minor(state, excluded)
    local target_hidden_minor = first_minor(state, excluded)
    local refill_a = first_minor(state, excluded)
    local refill_b = first_minor(state, excluded)
    local top_minor = first_minor(state, excluded)
    if not (target_known_minor and target_hidden_minor and refill_a and refill_b and top_minor) then
        return nil, "missing_unveil_target_minors"
    end

    stage_card_to_slot(state, target_known_minor, "targets", 1, "known")
    stage_card_to_slot(state, target_trump_id, "targets", 2, "hidden")
    stage_card_to_slot(state, target_hidden_minor, "targets", 3, "hidden")

    for slot = 1, state.zones.latent.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_unveil_latent_minors"
        end
        stage_card_to_slot(state, minor_id, "latent", slot, slot % 2 == 0 and "known" or "hidden")
    end

    stage_card_to_deck_top(state, top_minor, "hidden")
    stage_card_to_deck_top(state, refill_b, "hidden")
    stage_card_to_deck_top(state, refill_a, "hidden")
    stage_card_to_deck_top(state, unveil_id, "hidden")

    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "unveil_draw_error"
    end

    if state.cards[target_known_minor].zone ~= "grave" then
        return nil, "unveil_known_target_minor_should_go_grave"
    end
    if state.cards[target_hidden_minor].zone ~= "grave" then
        return nil, "unveil_hidden_target_minor_should_go_grave"
    end
    if state.zones.targets.cards[2] ~= target_trump_id then
        return nil, "unveil_target_trump_should_remain_installed"
    end
    if not state_lib.is_revealed(state, target_trump_id) then
        return nil, "unveil_target_trump_should_be_revealed"
    end
    if state.zones.targets.cards[1] ~= refill_a or state.zones.targets.cards[3] ~= refill_b then
        return nil, "unveil_target_refill_order_mismatch"
    end
    if state_lib.is_revealed(state, refill_a) or state_lib.is_revealed(state, refill_b) then
        return nil, "unveil_refills_should_remain_hidden"
    end
    if state.zones.deck.cards[#state.zones.deck.cards] ~= top_minor then
        return nil, "unveil_topdeck_should_remain_on_top"
    end
    if not state_lib.is_revealed(state, top_minor) then
        return nil, "unveil_topdeck_should_be_revealed"
    end
    for slot = 1, state.zones.latent.slot_count do
        local card_id = state.zones.latent.cards[slot]
        if card_id and not state_lib.is_revealed(state, card_id) then
            return nil, "unveil_latent_minor_should_be_revealed"
        end
    end

    return {
        name = "unveil_reveals_known_targets_and_topdeck",
        known_target = target_known_minor,
        target_trump = target_trump_id,
        topdeck = top_minor,
        trump_1 = state.zones.trump.cards[1],
        trump_2 = state.zones.trump.cards[2],
    }
end

function M.unveil_latent_trump_resolves_after_unveil_zone(state)
    local unveil_id = "TRUMP-21"
    local shuffle_id = "TRUMP-14"
    if not (state.cards[unveil_id] and state.cards[shuffle_id]) then
        return nil, "missing_unveil_or_shuffle"
    end

    local excluded = {
        [unveil_id] = true,
        [shuffle_id] = true,
    }
    local grave_minor = first_minor(state, excluded)
    local top_minor = first_minor(state, excluded)
    if not (grave_minor and top_minor) then
        return nil, "missing_unveil_latent_minors"
    end

    for slot = 1, state.zones.targets.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_unveil_target_padding"
        end
        stage_card_to_slot(state, minor_id, "targets", slot, "revealed")
    end

    stage_card_to_slot(state, shuffle_id, "latent", 1, "hidden")
    for slot = 2, state.zones.latent.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_unveil_latent_padding"
        end
        stage_card_to_slot(state, minor_id, "latent", slot, "hidden")
    end

    move_card_to_zone_tail(state, grave_minor, "grave", "revealed")
    stage_card_to_deck_top(state, top_minor, "hidden")
    stage_card_to_deck_top(state, unveil_id, "hidden")

    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "unveil_latent_draw_error"
    end

    if state.zones.trump.cards[1] ~= unveil_id then
        return nil, "unveil_should_enter_trump_zone_before_latent_trump"
    end
    if state.zones.trump.cards[2] ~= shuffle_id then
        return nil, "unveil_latent_trump_should_resolve_after_unveil"
    end
    if state.cards[shuffle_id].zone ~= "trump" then
        return nil, "unveil_latent_shuffle_should_end_in_trump_zone"
    end
    if state.zones.latent.cards[1] == shuffle_id then
        return nil, "unveil_latent_slot_should_be_repaired"
    end
    if state_lib.zone_count(state, "grave") ~= 0 then
        return nil, "unveil_latent_shuffle_should_empty_grave"
    end
    if state.pending_trump ~= nil or #state.zones.trump_flow.cards ~= 0 then
        return nil, "unveil_latent_flow_should_be_drained"
    end

    return {
        name = "unveil_latent_trump_resolves_after_unveil_zone",
        unveil = unveil_id,
        latent_trump = shuffle_id,
        trump_1 = state.zones.trump.cards[1],
        trump_2 = state.zones.trump.cards[2],
        deck_after = #state.zones.deck.cards,
    }
end

function M.unveil_soft_visibility_stand(state)
    local unveil_id = "TRUMP-21"
    if not state.cards[unveil_id] then
        return nil, "missing_unveil"
    end

    local excluded = {
        [unveil_id] = true,
    }
    local top_minor = first_minor(state, excluded)
    local refill_1 = first_minor(state, excluded)
    local refill_2 = first_minor(state, excluded)
    local refill_3 = first_minor(state, excluded)
    if not (top_minor and refill_1 and refill_2 and refill_3) then
        return nil, "missing_unveil_soft_top_or_refill_minor"
    end

    for slot = 1, state.zones.targets.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_unveil_soft_target_minor"
        end
        stage_card_to_slot(state, minor_id, "targets", slot, slot == 2 and "known" or "hidden")
    end
    for slot = 1, state.zones.latent.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_unveil_soft_latent_minor"
        end
        stage_card_to_slot(state, minor_id, "latent", slot, slot % 2 == 0 and "known" or "hidden")
    end

    stage_card_to_deck_top(state, top_minor, "hidden")
    stage_card_to_deck_top(state, refill_3, "hidden")
    stage_card_to_deck_top(state, refill_2, "hidden")
    stage_card_to_deck_top(state, refill_1, "hidden")
    stage_card_to_deck_top(state, unveil_id, "hidden")

    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "unveil_soft_draw_error"
    end

    if state.zones.trump.cards[1] ~= unveil_id or state.zones.trump.cards[2] ~= nil then
        return nil, "unveil_soft_should_only_place_unveil"
    end
    if #state.zones.trump_flow.cards ~= 0 or state.pending_trump ~= nil then
        return nil, "unveil_soft_should_not_leave_flow"
    end
    if state.zones.deck.cards[#state.zones.deck.cards] ~= top_minor or not state_lib.is_revealed(state, top_minor) then
        return nil, "unveil_soft_topdeck_should_be_revealed"
    end
    for slot = 1, state.zones.latent.slot_count do
        local card_id = state.zones.latent.cards[slot]
        if not card_id or not state_lib.is_revealed(state, card_id) then
            return nil, "unveil_soft_latent_should_be_revealed"
        end
    end

    return {
        name = "unveil_soft_visibility_stand",
        topdeck = top_minor,
        grave_after = #state.zones.grave.cards,
        trump_1 = state.zones.trump.cards[1],
    }
end

function M.unveil_topdeck_trump_pressure_stand(state)
    local unveil_id = "TRUMP-21"
    local shuffle_id = "TRUMP-14"
    if not (state.cards[unveil_id] and state.cards[shuffle_id]) then
        return nil, "missing_unveil_or_shuffle"
    end

    local excluded = {
        [unveil_id] = true,
        [shuffle_id] = true,
    }
    local grave_minor = first_minor(state, excluded)
    if not grave_minor then
        return nil, "missing_unveil_topdeck_grave_minor"
    end

    for slot = 1, state.zones.targets.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_unveil_topdeck_target_padding"
        end
        stage_card_to_slot(state, minor_id, "targets", slot, "revealed")
    end
    for slot = 1, state.zones.latent.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_unveil_topdeck_latent_padding"
        end
        stage_card_to_slot(state, minor_id, "latent", slot, "revealed")
    end

    move_card_to_zone_tail(state, grave_minor, "grave", "revealed")
    stage_card_to_deck_top(state, shuffle_id, "hidden")
    stage_card_to_deck_top(state, unveil_id, "hidden")

    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "unveil_topdeck_draw_error"
    end

    if state.zones.trump.cards[1] ~= unveil_id or state.zones.trump.cards[2] ~= shuffle_id then
        return nil, "unveil_topdeck_trump_order_mismatch"
    end
    if state_lib.zone_count(state, "grave") ~= 0 then
        return nil, "unveil_topdeck_shuffle_should_empty_grave"
    end
    if #state.zones.trump_flow.cards ~= 0 or state.pending_trump ~= nil then
        return nil, "unveil_topdeck_flow_should_be_drained"
    end

    return {
        name = "unveil_topdeck_trump_pressure_stand",
        unveil = unveil_id,
        topdeck_trump = shuffle_id,
        trump_1 = state.zones.trump.cards[1],
        trump_2 = state.zones.trump.cards[2],
    }
end

function M.unveil_overflow_storm_stand(state)
    local unveil_id = "TRUMP-21"
    local shuffle_id = "TRUMP-14"
    local oracle_id = "TRUMP-3"
    if not (state.cards[unveil_id] and state.cards[shuffle_id] and state.cards[oracle_id]) then
        return nil, "missing_unveil_shuffle_or_oracle"
    end

    local excluded = {
        [unveil_id] = true,
        [shuffle_id] = true,
        [oracle_id] = true,
    }
    local refill_minor = first_minor(state, excluded)
    if not refill_minor then
        return nil, "missing_unveil_storm_refill_minor"
    end

    for slot = 1, state.zones.targets.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_unveil_storm_target_padding"
        end
        stage_card_to_slot(state, minor_id, "targets", slot, "revealed")
    end
    stage_card_to_slot(state, shuffle_id, "latent", 1, "hidden")
    for slot = 2, state.zones.latent.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_unveil_storm_latent_padding"
        end
        stage_card_to_slot(state, minor_id, "latent", slot, "revealed")
    end

    local oracle_view = {}
    for _ = 1, 6 do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_unveil_storm_oracle_view"
        end
        oracle_view[#oracle_view + 1] = minor_id
        stage_card_to_deck_top(state, minor_id, "hidden")
    end
    stage_card_to_deck_top(state, oracle_id, "hidden")
    stage_card_to_deck_top(state, refill_minor, "hidden")
    stage_card_to_deck_top(state, unveil_id, "hidden")

    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "unveil_storm_draw_error"
    end

    if state.zones.trump.cards[1] ~= nil or state.zones.trump.cards[2] ~= nil then
        return nil, "unveil_storm_should_overflow_trump_zone"
    end
    if state.cards[unveil_id].zone ~= "deck" or state.cards[shuffle_id].zone ~= "deck" or state.cards[oracle_id].zone ~= "deck" then
        return nil, "unveil_storm_overflowed_trumps_should_return_deck"
    end
    if state.cards[shuffle_id].info_state ~= "hidden" or state.cards[oracle_id].info_state ~= "hidden" then
        return nil, "unveil_storm_flushed_trumps_should_be_hidden"
    end
    if #state.zones.trump_flow.cards ~= 0 or state.pending_trump ~= nil then
        return nil, "unveil_storm_flow_should_be_drained"
    end

    return {
        name = "unveil_overflow_storm_stand",
        oracle_view = oracle_view,
        hand_after = #state.zones.hand.cards,
        grave_after = #state.zones.grave.cards,
        deck_after = #state.zones.deck.cards,
    }
end

function M.purge_topdeck_first_and_targets_untouched(state)
    local purge_id = "TRUMP-19"
    local target_trump_id = "TRUMP-14"
    if not (state.cards[purge_id] and state.cards[target_trump_id]) then
        return nil, "missing_purge_or_target_trump"
    end

    local excluded = {
        [purge_id] = true,
        [target_trump_id] = true,
    }
    local top_minor = first_minor(state, excluded)
    local target_minor = first_minor(state, excluded)
    if not (top_minor and target_minor) then
        return nil, "missing_purge_topdeck_target_minors"
    end

    stage_card_to_slot(state, target_minor, "targets", 1, "revealed")
    stage_card_to_slot(state, target_trump_id, "targets", 2, "revealed")

    for slot = 1, state.zones.latent.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_purge_latent_padding"
        end
        stage_card_to_slot(state, minor_id, "latent", slot, "hidden")
    end

    for _ = 1, 6 do
        local refill_id = first_minor(state, excluded)
        if not refill_id then
            return nil, "missing_purge_refill_padding"
        end
        stage_card_to_deck_top(state, refill_id, "hidden")
    end
    stage_card_to_deck_top(state, top_minor, "revealed")
    stage_card_to_deck_top(state, purge_id, "hidden")

    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "purge_draw_error"
    end

    if state.cards[top_minor].zone ~= "grave" then
        return nil, "purge_should_process_revealed_topdeck_first"
    end
    if state.zones.targets.cards[1] ~= target_minor or state.cards[target_minor].zone ~= "targets" then
        return nil, "purge_should_not_touch_target_minor"
    end
    if state.zones.targets.cards[2] ~= target_trump_id or state.cards[target_trump_id].zone ~= "targets" then
        return nil, "purge_should_not_touch_target_trump"
    end
    if state.zones.trump.cards[1] ~= purge_id then
        return nil, "purge_should_enter_trump_zone"
    end
    if state.zones.trump.cards[2] ~= nil then
        return nil, "purge_should_not_activate_target_trump"
    end

    return {
        name = "purge_topdeck_first_and_targets_untouched",
        topdeck = top_minor,
        target_minor = target_minor,
        target_trump = target_trump_id,
        trump_1 = state.zones.trump.cards[1],
    }
end

function M.purge_column_revealed_latent_repairs_before_manifest(state)
    local purge_id = "TRUMP-19"
    if not state.cards[purge_id] then
        return nil, "missing_purge"
    end

    local excluded = {
        [purge_id] = true,
    }
    local latent_revealed = first_minor(state, excluded)
    local latent_refill = first_minor(state, excluded)
    local repair_refill = first_minor(state, excluded)
    if not (latent_revealed and latent_refill and repair_refill) then
        return nil, "missing_purge_column_minors"
    end

    for slot = 1, state.zones.targets.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_purge_target_padding"
        end
        stage_card_to_slot(state, minor_id, "targets", slot, "hidden")
    end
    stage_card_to_slot(state, latent_revealed, "latent", 1, "revealed")
    for slot = 2, state.zones.latent.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_purge_latent_padding"
        end
        stage_card_to_slot(state, minor_id, "latent", slot, "hidden")
    end

    local original_manifest = state.zones.manifest.cards[1]
    if not original_manifest then
        return nil, "missing_purge_manifest_card"
    end

    for _ = 1, 12 do
        local refill_id = first_minor(state, excluded)
        if not refill_id then
            return nil, "missing_purge_extra_refills"
        end
        stage_card_to_deck_top(state, refill_id, "hidden")
    end
    stage_card_to_deck_top(state, repair_refill, "hidden")
    stage_card_to_deck_top(state, latent_refill, "hidden")
    stage_card_to_deck_top(state, purge_id, "hidden")

    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "purge_column_draw_error"
    end

    if state.cards[latent_revealed].zone ~= "grave" then
        return nil, "purge_revealed_latent_should_go_grave"
    end
    if state.cards[original_manifest].zone ~= "grave" then
        return nil, "purge_manifest_should_go_grave_after_latent"
    end
    if state.zones.manifest.cards[1] ~= latent_refill then
        return nil, "purge_manifest_repair_should_promote_latent_refill"
    end
    if state.zones.latent.cards[1] ~= repair_refill then
        return nil, "purge_manifest_repair_should_refill_latent"
    end
    if not state_lib.is_revealed(state, latent_refill) then
        return nil, "purge_promoted_latent_refill_should_be_revealed"
    end
    if state_lib.is_revealed(state, repair_refill) then
        return nil, "purge_new_latent_refill_should_stay_hidden"
    end

    return {
        name = "purge_column_revealed_latent_repairs_before_manifest",
        purged_latent = latent_revealed,
        purged_manifest = original_manifest,
        promoted = latent_refill,
        new_latent = repair_refill,
    }
end

function M.purge_topdeck_trump_resolves_after_purge_zone(state)
    local purge_id = "TRUMP-19"
    local shuffle_id = "TRUMP-14"
    if not (state.cards[purge_id] and state.cards[shuffle_id]) then
        return nil, "missing_purge_or_shuffle"
    end

    local excluded = {
        [purge_id] = true,
        [shuffle_id] = true,
    }
    for slot = 1, state.zones.targets.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_purge_target_padding"
        end
        stage_card_to_slot(state, minor_id, "targets", slot, "hidden")
    end
    for slot = 1, state.zones.latent.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_purge_latent_padding"
        end
        stage_card_to_slot(state, minor_id, "latent", slot, "hidden")
    end

    for _ = 1, 6 do
        local refill_id = first_minor(state, excluded)
        if not refill_id then
            return nil, "missing_purge_refill_padding"
        end
        stage_card_to_deck_top(state, refill_id, "hidden")
    end
    stage_card_to_deck_top(state, shuffle_id, "revealed")
    stage_card_to_deck_top(state, purge_id, "hidden")

    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "purge_topdeck_trump_draw_error"
    end

    if state.zones.trump.cards[1] ~= purge_id then
        return nil, "purge_should_enter_trump_zone_before_topdeck_trump"
    end
    if state.zones.trump.cards[2] ~= shuffle_id then
        return nil, "purge_topdeck_trump_should_resolve_after_purge"
    end
    if state.cards[shuffle_id].zone ~= "trump" then
        return nil, "purge_shuffle_should_end_in_trump_zone"
    end
    if #state.zones.trump_flow.cards ~= 0 or state.pending_trump ~= nil then
        return nil, "purge_topdeck_flow_should_be_drained"
    end

    return {
        name = "purge_topdeck_trump_resolves_after_purge_zone",
        purge = purge_id,
        topdeck_trump = shuffle_id,
        trump_1 = state.zones.trump.cards[1],
        trump_2 = state.zones.trump.cards[2],
    }
end

function M.error_grave_returns_to_hand_in_order(state)
    local error_id = "TRUMP-15"
    if not state.cards[error_id] then
        return nil, "missing_error"
    end

    local excluded = {
        [error_id] = true,
    }
    local grave_cards = {}
    for _ = 1, 5 do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_error_grave_minor"
        end
        grave_cards[#grave_cards + 1] = minor_id
        move_card_to_zone_tail(state, minor_id, "grave", "revealed")
    end

    move_card_to_deck_top(state, error_id)

    local hand_before = #state.zones.hand.cards
    local drawn = core.draw_to_hand(state)
    if drawn.summary.error then
        return nil, "error_draw_error"
    end

    if #state.zones.grave.cards ~= 0 then
        return nil, "error_should_empty_grave"
    end
    if #state.zones.hand.cards ~= hand_before + #grave_cards then
        return nil, "error_should_return_whole_grave_to_hand"
    end
    for i, card_id in ipairs(grave_cards) do
        local hand_index = hand_before + i
        if state.zones.hand.cards[hand_index] ~= card_id then
            return nil, "error_should_preserve_grave_order"
        end
        if state.cards[card_id].zone ~= "hand" or not state_lib.is_revealed(state, card_id) then
            return nil, "error_returned_card_should_be_revealed_in_hand"
        end
    end
    if state.zones.trump.cards[1] ~= error_id then
        return nil, "error_should_enter_trump_zone"
    end
    if state.cards[error_id].zone == "hand" then
        return nil, "error_itself_should_not_enter_hand"
    end

    return {
        name = "error_grave_returns_to_hand_in_order",
        returned = grave_cards,
        hand_before = hand_before,
        hand_after = #state.zones.hand.cards,
        trump_1 = state.zones.trump.cards[1],
    }
end

function M.purge_then_error_table_stand(state)
    local purge_id = "TRUMP-19"
    local error_id = "TRUMP-15"
    if not (state.cards[purge_id] and state.cards[error_id]) then
        return nil, "missing_purge_or_error"
    end

    local excluded = {
        [purge_id] = true,
        [error_id] = true,
    }
    local visible_top = first_minor(state, excluded)
    if not visible_top then
        return nil, "missing_purge_error_top_minor"
    end

    for slot = 1, state.zones.targets.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_purge_error_target_padding"
        end
        stage_card_to_slot(state, minor_id, "targets", slot, "revealed")
    end
    for slot = 1, state.zones.latent.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_purge_error_latent_padding"
        end
        stage_card_to_slot(state, minor_id, "latent", slot, slot <= 3 and "revealed" or "hidden")
    end

    stage_card_to_deck_top(state, error_id, "hidden")
    for _ = 1, 18 do
        local refill_id = first_minor(state, excluded)
        if not refill_id then
            return nil, "missing_purge_error_refills"
        end
        stage_card_to_deck_top(state, refill_id, "hidden")
    end
    stage_card_to_deck_top(state, visible_top, "revealed")
    stage_card_to_deck_top(state, purge_id, "hidden")

    local hand_before = #state.zones.hand.cards
    local deck_before = #state.zones.deck.cards
    local first = core.draw_to_hand(state)
    if first.summary.error then
        return nil, "purge_then_error_purge_draw_error"
    end

    local grave_after_purge = #state.zones.grave.cards
    local deck_after_purge = #state.zones.deck.cards
    local hand_after_purge = #state.zones.hand.cards
    local draws_to_error = 0
    while state.cards[error_id].zone ~= "trump" and draws_to_error < 30 do
        draws_to_error = draws_to_error + 1
        local next_draw = core.draw_to_hand(state)
        if next_draw.summary.error then
            return nil, "purge_then_error_error_draw_error"
        end
    end

    if grave_after_purge <= 0 then
        return nil, "purge_then_error_purge_should_create_grave"
    end
    if state.cards[error_id].zone ~= "trump" then
        return nil, "purge_then_error_should_reach_error"
    end
    if #state.zones.grave.cards ~= 0 then
        return nil, "purge_then_error_error_should_empty_grave"
    end
    if #state.zones.hand.cards < hand_after_purge + grave_after_purge then
        return nil, "purge_then_error_error_should_import_purge_residue"
    end
    if not (state.zones.trump.cards[1] == purge_id or state.zones.trump.cards[2] == purge_id) then
        return nil, "purge_then_error_purge_should_resolve"
    end
    if not (state.zones.trump.cards[1] == error_id or state.zones.trump.cards[2] == error_id) then
        return nil, "purge_then_error_error_should_resolve"
    end

    return {
        name = "purge_then_error_table_stand",
        hand_before = hand_before,
        hand_after_purge = hand_after_purge,
        hand_after_error = #state.zones.hand.cards,
        draws_to_error = draws_to_error,
        grave_after_purge = grave_after_purge,
        deck_before = deck_before,
        deck_after_purge = deck_after_purge,
        deck_after_error = #state.zones.deck.cards,
    }
end

function M.error_then_purge_table_stand(state)
    local error_id = "TRUMP-15"
    local purge_id = "TRUMP-19"
    if not (state.cards[error_id] and state.cards[purge_id]) then
        return nil, "missing_error_or_purge"
    end

    local excluded = {
        [error_id] = true,
        [purge_id] = true,
    }
    local preload = {}
    for _ = 1, 8 do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_error_purge_grave_minor"
        end
        preload[#preload + 1] = minor_id
        move_card_to_zone_tail(state, minor_id, "grave", "revealed")
    end

    for slot = 1, state.zones.targets.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_error_purge_target_padding"
        end
        stage_card_to_slot(state, minor_id, "targets", slot, "revealed")
    end
    for slot = 1, state.zones.latent.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_error_purge_latent_padding"
        end
        stage_card_to_slot(state, minor_id, "latent", slot, slot <= 2 and "revealed" or "hidden")
    end

    for _ = 1, 18 do
        local refill_id = first_minor(state, excluded)
        if not refill_id then
            return nil, "missing_error_purge_refills"
        end
        stage_card_to_deck_top(state, refill_id, "hidden")
    end
    stage_card_to_deck_top(state, purge_id, "hidden")
    move_card_to_deck_top(state, error_id)

    local hand_before = #state.zones.hand.cards
    local first = core.draw_to_hand(state)
    if first.summary.error then
        return nil, "error_then_purge_error_draw_error"
    end
    local hand_after_error = #state.zones.hand.cards
    local grave_after_error = #state.zones.grave.cards

    local second = core.draw_to_hand(state)
    if second.summary.error then
        return nil, "error_then_purge_purge_draw_error"
    end

    if hand_after_error ~= hand_before + #preload then
        return nil, "error_then_purge_error_should_import_preload"
    end
    if grave_after_error ~= 0 then
        return nil, "error_then_purge_error_should_empty_grave"
    end
    if #state.zones.grave.cards <= 0 then
        return nil, "error_then_purge_purge_should_recreate_grave"
    end
    if #state.zones.hand.cards ~= hand_after_error then
        return nil, "error_then_purge_purge_should_not_change_hand"
    end

    return {
        name = "error_then_purge_table_stand",
        preload = #preload,
        hand_before = hand_before,
        hand_after_error = hand_after_error,
        hand_after_purge = #state.zones.hand.cards,
        grave_after_purge = #state.zones.grave.cards,
    }
end

function M.unveil_purge_error_table_stand(state)
    local unveil_id = "TRUMP-21"
    local purge_id = "TRUMP-19"
    local error_id = "TRUMP-15"
    if not (state.cards[unveil_id] and state.cards[purge_id] and state.cards[error_id]) then
        return nil, "missing_unveil_purge_or_error"
    end

    local excluded = {
        [unveil_id] = true,
        [purge_id] = true,
        [error_id] = true,
    }
    local visible_after_unveil = first_minor(state, excluded)
    if not visible_after_unveil then
        return nil, "missing_unveil_purge_error_visible_top"
    end

    for slot = 1, state.zones.targets.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_unveil_purge_error_target_padding"
        end
        stage_card_to_slot(state, minor_id, "targets", slot, "revealed")
    end
    for slot = 1, state.zones.latent.slot_count do
        local minor_id = first_minor(state, excluded)
        if not minor_id then
            return nil, "missing_unveil_purge_error_latent_padding"
        end
        stage_card_to_slot(state, minor_id, "latent", slot, "hidden")
    end

    stage_card_to_deck_top(state, error_id, "hidden")
    for _ = 1, 24 do
        local refill_id = first_minor(state, excluded)
        if not refill_id then
            return nil, "missing_unveil_purge_error_refills"
        end
        stage_card_to_deck_top(state, refill_id, "hidden")
    end
    stage_card_to_deck_top(state, visible_after_unveil, "revealed")
    stage_card_to_deck_top(state, purge_id, "hidden")
    stage_card_to_deck_top(state, unveil_id, "hidden")

    local hand_before = #state.zones.hand.cards
    local first = core.draw_to_hand(state)
    if first.summary.error then
        return nil, "unveil_purge_error_unveil_draw_error"
    end
    if state.cards[purge_id].zone ~= "trump" and state.cards[purge_id].zone ~= "deck" then
        return nil, "unveil_purge_error_purge_should_have_resolved_or_overflowed"
    end
    local grave_after_purge = #state.zones.grave.cards

    if state.cards[error_id].zone ~= "trump" then
        move_card_to_deck_top(state, error_id)
        if state.zones.deck.cards[#state.zones.deck.cards] ~= error_id then
            return nil, "unveil_purge_error_error_should_be_staged_topdeck"
        end
    end

    local draws_to_error = 0
    while state.cards[error_id].zone ~= "trump" and draws_to_error < 40 do
        draws_to_error = draws_to_error + 1
        local next_draw = core.draw_to_hand(state)
        if next_draw.summary.error then
            return nil, "unveil_purge_error_error_draw_error"
        end
    end

    if grave_after_purge <= 0 then
        return nil, "unveil_purge_error_purge_should_create_grave"
    end
    local reached_error = state.cards[error_id].zone == "trump"
    if reached_error then
        if #state.zones.grave.cards ~= 0 then
            return nil, "unveil_purge_error_error_should_empty_grave"
        end
        if #state.zones.hand.cards <= hand_before then
            return nil, "unveil_purge_error_error_should_expand_hand"
        end
    end

    return {
        name = "unveil_purge_error_table_stand",
        grave_after_purge = grave_after_purge,
        draws_to_error = draws_to_error,
        reached_error = reached_error,
        hand_before = hand_before,
        hand_after_error = #state.zones.hand.cards,
        deck_after = #state.zones.deck.cards,
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
        elseif state.pending_flow_choice then
            local target_card_id = state.pending_flow_choice.legal_card_ids[1]
            if not target_card_id then
                return nil, "no_flow_target"
            end
            core.arm_flow_target(state, target_card_id)
            core.arm_flow_direction(state, "left")
            choose_result = core.confirm_flow_target(state)
        elseif state.pending_encode_choice then
            local first_card_id = state.pending_encode_choice.legal_card_ids[1]
            local second_card_id = state.pending_encode_choice.legal_card_ids[2]
            if not first_card_id or not second_card_id then
                return nil, "no_encode_target_pair"
            end
            core.arm_encode_target(state, first_card_id)
            core.arm_encode_target(state, second_card_id)
            choose_result = core.confirm_encode_target(state)
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

local function first_direction_action(interaction)
    local directions = interaction.legal and interaction.legal.directions or {}
    if directions[1] then
        return {
            kind = "arm_direction",
            direction = directions[1],
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
                local action = first_direction_action(ix) or first_target_action(ix)
                if not action then
                    return nil, "no_target_action"
                end
                local result = core.apply_action(state, action)
                if result.summary and result.summary.error then
                    return nil, result.summary.error
                end
                local target_desc = action.direction or action.target.card_id or action.target.slot
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

local function prepare_named_operator_turn(state, wanted)
    local info, err = M.one_turn_setup_only(state)
    if not info then
        return nil, err
    end

    local choose_result, choose_err = arm_named_operator_choice(state, wanted)
    if not choose_result then
        return nil, choose_err
    end

    return {
        slot = info.slot,
        hand_card_id = info.hand_card_id,
        choose_result = choose_result,
    }
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

function M.dissolve_field_card(state)
    local slot
    local hand_card_id
    local manifest_before
    local latent_before

    for i = 1, 6 do
        local manifest_id = state.zones.manifest.cards[i]
        local latent_id = state.zones.latent.cards[i]
        if manifest_id and latent_id then
            local legal = rules.legal_hand_ids(state, manifest_id)
            for _, candidate in ipairs(legal) do
                local card = state.cards[candidate]
                if card.op_a == "DISSOLVE" or card.op_b == "DISSOLVE" then
                    slot = i
                    hand_card_id = candidate
                    manifest_before = manifest_id
                    latent_before = latent_id
                    break
                end
            end
        end
        if hand_card_id then
            break
        end
    end

    if not hand_card_id then
        return nil, "missing_operator_DISSOLVE"
    end

    core.commit_manifest(state, slot)
    core.arm_hand(state, hand_card_id)
    core.resolve_turn(state, slot, hand_card_id)
    local _, choose_err = arm_named_operator_choice(state, "DISSOLVE")
    if choose_err then
        return nil, choose_err
    end
    local result = core.confirm_operator_phase(state)
    local latent_card = state.cards[latent_before]

    if latent_card.class == "minor" then
        if latent_card.zone ~= "grave" then
            return nil, "dissolved_latent_minor_not_in_grave"
        end
    else
        local zone = latent_card.zone
        if zone ~= "trump_flow" and zone ~= "trump" then
            return nil, "dissolved_latent_trump_not_in_trump_branch"
        end
    end

    if state.cards[manifest_before].zone ~= "grave" then
        return nil, "committed_manifest_not_in_grave"
    end
    if not state.zones.manifest.cards[slot] then
        return nil, "manifest_not_repaired_after_dissolve"
    end
    if not state.zones.latent.cards[slot] then
        return nil, "latent_not_refilled_after_dissolve"
    end

    return {
        name = "dissolve_field_card",
        slot = slot,
        hand_card_id = hand_card_id,
        manifest_before = manifest_before,
        latent_before = latent_before,
        result = result,
    }
end

function M.flow_structure_step(state)
    local prep, err = prepare_named_operator_turn(state, "FLOW")
    if not prep then
        return nil, err
    end
    if not state.pending_flow_choice then
        return nil, "no_pending_flow_choice"
    end

    local target_card_id = state.pending_flow_choice.legal_card_ids[1]
    if not target_card_id then
        return nil, "no_flow_target"
    end
    local target_zone = state.cards[target_card_id].zone
    core.arm_flow_target(state, target_card_id)
    core.arm_flow_direction(state, "left")
    local result = core.confirm_flow_target(state)

    if state.pending_flow_choice or state.pending_operator_choice then
        return nil, "flow_not_resolved"
    end

    return {
        name = "flow_structure_step",
        target_card_id = target_card_id,
        target_zone = target_zone,
        result = result,
    }
end

function M.encode_concealed_swap(state)
    local prep, err = prepare_named_operator_turn(state, "ENCODE")
    if not prep then
        return nil, err
    end
    if not state.pending_encode_choice then
        return nil, "no_pending_encode_choice"
    end

    local first_card_id = state.pending_encode_choice.legal_card_ids[1]
    local second_card_id = state.pending_encode_choice.legal_card_ids[2]
    if not first_card_id or not second_card_id then
        return nil, "no_encode_target_pair"
    end

    local first_before = {zone = state.cards[first_card_id].zone, slot = state.cards[first_card_id].slot}
    local second_before = {zone = state.cards[second_card_id].zone, slot = state.cards[second_card_id].slot}

    core.arm_encode_target(state, first_card_id)
    core.arm_encode_target(state, second_card_id)
    local result = core.confirm_encode_target(state)

    if state.cards[first_card_id].zone ~= second_before.zone then
        return nil, "encode_first_not_swapped"
    end
    if state.cards[second_card_id].zone ~= first_before.zone then
        return nil, "encode_second_not_swapped"
    end

    return {
        name = "encode_concealed_swap",
        first_card_id = first_card_id,
        second_card_id = second_card_id,
        result = result,
    }
end

function M.runtime_install_choice(state)
    local prep, err = prepare_named_operator_turn(state, "RUNTIME")
    if not prep then
        return nil, err
    end

    local play_card_id = state.zones.play.cards[1]
    local result = core.confirm_operator_phase(state)
    if result and result.summary and result.summary.error then
        return nil, result.summary.error
    end
    if state.zones.runtime.cards[1] ~= play_card_id then
        return nil, "runtime_install_failed"
    end
    if state.pending_operator_choice then
        return nil, "runtime_pending_operator_not_cleared"
    end

    return {
        name = "runtime_install_choice",
        installed_card_id = play_card_id,
        result = result,
    }
end

function M.runtime_granted_choice_visible(state)
    local install, err = M.runtime_install_choice(state)
    if not install then
        return nil, err
    end

    local next_turn, next_err = M.one_turn_setup_only(state)
    if not next_turn then
        return nil, next_err
    end
    if not state.pending_operator_choice then
        return nil, "missing_operator_phase_after_runtime"
    end

    local runtime_card = state.cards[install.installed_card_id]
    local choices = state.pending_operator_choice.choices or {}
    local granted = {}
    if runtime_card.op_a == "RUNTIME" and runtime_card.op_b == "RUNTIME" then
        granted = {"RUNTIME"}
    elseif runtime_card.op_a == "RUNTIME" then
        granted = {runtime_card.op_b}
    elseif runtime_card.op_b == "RUNTIME" then
        granted = {runtime_card.op_a}
    else
        granted = {runtime_card.op_a, runtime_card.op_b}
    end

    for _, op_name in ipairs(granted) do
        local found = false
        for _, choice in ipairs(choices) do
            if choice == op_name then
                found = true
                break
            end
        end
        if not found then
            return nil, "runtime_granted_choice_missing"
        end
    end

    return {
        name = "runtime_granted_choice_visible",
        installed_card_id = install.installed_card_id,
        granted = granted,
        choices = choices,
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

function M.start_game_without_trumps()
    local state = core.new()
    local result = core.start_game(state, {
        rng = function(n) return math.random(n) end,
        trump_mode = "none",
        enabled_trumps = {},
    })
    local trumps = created_trump_ids(state)
    if #trumps ~= 0 then
        return nil, "unexpected_trumps_created"
    end
    if #state.zones.deck.cards ~= 79 then
        return nil, "unexpected_no_trump_deck_count"
    end
    return {
        name = "start_game_without_trumps",
        result = result,
        deck = #state.zones.deck.cards,
    }
end

function M.start_game_foolrush_only()
    local state = core.new()
    local result = core.start_game(state, {
        rng = function(n) return math.random(n) end,
        trump_mode = "foolrush",
        enabled_trumps = {"FOOL", "RUSH"},
    })
    local trumps = created_trump_ids(state)
    if #trumps ~= 2 then
        return nil, "unexpected_foolrush_trump_count"
    end
    if not (state.cards["TRUMP-1"] and state.cards["TRUMP-8"]) then
        return nil, "missing_fool_or_rush"
    end
    if #state.zones.deck.cards ~= 81 then
        return nil, "unexpected_foolrush_deck_count"
    end
    return {
        name = "start_game_foolrush_only",
        result = result,
        deck = #state.zones.deck.cards,
        trumps = trumps,
    }
end

function M.trump_flow_runaway_guard(state)
    local card_id = "TRUMP-1"
    if not state.cards[card_id] then
        return nil, "missing_guard_trump"
    end

    local moved, err = relocate_existing_card(state, card_id)
    if err then
        return nil, err
    end

    state.trump_guard = {
        max_trump_chain_steps = 0,
        max_repair_attempts = 128,
    }
    state_lib.reveal_card(state, card_id)
    state_lib.place_card(state, card_id, "trump_flow", nil)
    state.pending_trump = card_id

    local result = core.resolve_pending_trump(state)
    local summary = result and result.summary or {}
    if summary.error ~= "trump_flow_runaway" then
        return nil, "expected_trump_flow_runaway"
    end
    if not summary.trump_runaway then
        return nil, "missing_trump_runaway_diagnostic"
    end
    if state.zones.trump_flow.cards[1] ~= card_id then
        return nil, "runaway_guard_should_keep_flow_head"
    end
    if state.pending_trump ~= card_id then
        return nil, "runaway_guard_should_keep_pending_trump"
    end

    return {
        name = "trump_flow_runaway_guard",
        moved = moved,
        error = summary.error,
        diagnostic = summary.trump_runaway,
    }
end

return M
