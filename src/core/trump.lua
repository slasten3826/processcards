local state_lib = require("src.core.state")
local transition = require("src.core.transition")

local M = {}

local function shuffle_in_place(list, rng)
    local roll = rng or math.random
    for i = #list, 2, -1 do
        local j = roll(i)
        list[i], list[j] = list[j], list[i]
    end
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
    M.resolve_trump_zone_entry(state, card_id)
    return card_id
end

return M
