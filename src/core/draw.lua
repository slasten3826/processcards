local state_lib = require("src.core.state")
local transition = require("src.core.transition")
local trump = require("src.core.trump")

local M = {}

local function pop_topdeck(state)
    local deck = state.zones.deck.cards
    if #deck == 0 then
        return nil
    end
    local card_id = deck[#deck]
    state_lib.remove_from_current_zone(state, card_id)
    return card_id
end

function M.concealed_refill(state, zone_name, slot)
    local card_id = pop_topdeck(state)
    if not card_id then
        return nil
    end
    state_lib.hide_card(state, card_id)
    state_lib.place_card(state, card_id, zone_name, slot)
    transition.emit(state, "concealed_refill", {
        card_id = card_id,
        zone = zone_name,
        slot = slot,
    })
    return card_id
end

function M.open_manifest_closure(state, slot)
    while true do
        local card_id = pop_topdeck(state)
        if not card_id then
            return nil
        end
        state_lib.reveal_card(state, card_id)
        if state.cards[card_id].class == "trump" then
            trump.enter_trump_flow(state, card_id, "open closure")
        else
            state_lib.place_card(state, card_id, "manifest", slot)
            transition.emit(state, "manifest_closure", {
                card_id = card_id,
                slot = slot,
            })
            return card_id
        end
    end
end

function M.draw_to_hand(state)
    local card_id = pop_topdeck(state)
    if not card_id then
        return nil, "deck_empty"
    end
    state_lib.reveal_card(state, card_id)
    if state.cards[card_id].class == "trump" then
        trump.enter_trump_flow(state, card_id, "draw")
        return nil, "trump_burn"
    end
    state_lib.place_card(state, card_id, "hand", nil)
    transition.emit(state, "draw_to_hand", {card_id = card_id})
    return card_id, nil
end

return M
