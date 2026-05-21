local constants = require("src.core.constants")
local state_lib = require("src.core.state")
local transition = require("src.core.transition")

local M = {}
local resolve_trump_card

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

local function halt_trump(state, card_id, reason, parent_id)
    remember_chain_participant(state, card_id, parent_id)
    state.trump_chain_halted = state.trump_chain_halted or {}
    state.trump_chain_halted[#state.trump_chain_halted + 1] = card_id
    state_lib.reveal_card(state, card_id)
    transition.emit(state, "halted_trump", {
        card_id = card_id,
        reason = reason,
    })
end

local function handle_revealed_trump(state, card_id, reason, mode)
    local parent_id = state.current_resolving_trump
    local name = trump_name(state, card_id)
    if (state.trump_chain_halt_pending or state.trump_chain_halt_active) and name ~= "HALT" then
        halt_trump(state, card_id, reason, parent_id)
        return "halted"
    end
    if name == "HALT" then
        state.trump_chain_halt_pending = true
        state.trump_chain_halt_card_id = state.trump_chain_halt_card_id or card_id
    end
    M.enter_trump_flow(state, card_id, reason)
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
    state.trump_chain_halted = {}
    state.trump_chain_halt_pending = false
    state.trump_chain_halt_active = false
    state.trump_chain_halt_card_id = nil
    state.trump_parent = {}
    return true
end

local function flush_trumps_to_deck(state, card_ids, event_name)
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

    if state.trump_chain_halt_active then
        local halt_id = state.trump_chain_halt_card_id
        local flushed = {}
        for _, card_id in ipairs(state.trump_chain_halted or {}) do
            flushed[#flushed + 1] = card_id
        end
        flush_trumps_to_deck(state, flushed, "halted_chain_flush")
        if halt_id and state.cards[halt_id].zone ~= "trump" then
            M.resolve_trump_zone_entry(state, halt_id)
        end
    end

    state.trump_chain_depth = 0
    state.trump_chain_participants = nil
    state.trump_chain_seen = nil
    state.trump_chain_halted = nil
    state.trump_chain_halt_pending = nil
    state.trump_chain_halt_active = nil
    state.trump_chain_halt_card_id = nil
    state.trump_parent = nil
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

function M.enter_trump_flow(state, card_id, reason)
    state_lib.place_card(state, card_id, "trump_flow", nil)
    state_lib.reveal_card(state, card_id)
    state_lib.push_log(state, card_id .. " -> trump flow" .. (reason and (" (" .. reason .. ")") or "") .. ".")
    transition.emit(state, "trump_flow_entry", {
        card_id = card_id,
        reason = reason,
    })
end

resolve_trump_card = function(state, card_id)
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

    if name == "FOOL" then
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
    elseif name == "HALT" then
        state.trump_chain_halt_pending = false
        state.trump_chain_halt_active = true
        state.trump_chain_halt_card_id = state.trump_chain_halt_card_id or card_id
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
            elseif parent_name == "RESET" then
                discard_hand_to_grave(state, "RESET")
                draw_revealed_steps(state, 6, "RESET draw")
            elseif parent_name == "SHUFFLE" then
                shuffle_grave_into_deck(state, "SHUFFLE")
            end
        end
    end

    transition.emit(state, "trump_effect_end", {
        card_id = card_id,
        trump = name,
    })

    if name ~= "HALT" or not state.trump_chain_halt_active then
        M.resolve_trump_zone_entry(state, card_id)
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
    local card_id = state.pending_trump
    if not card_id then
        return nil, "no_pending_trump"
    end
    if not state_lib.is_board_closed(state) then
        return nil, "board_not_closed"
    end
    state.pending_trump = nil
    state_lib.remove_from_current_zone(state, card_id)
    resolve_trump_card(state, card_id)
    return card_id
end

return M
