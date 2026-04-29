local cards = require("src.core.cards")
local state_lib = require("src.core.state")

local M = {}

local function fisher_yates(deck, rng)
    for i = #deck, 2, -1 do
        local j = rng(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

local function default_rng(max_n)
    return math.random(max_n)
end

local function deal_from_deck(state, zone_name, slot, info_state)
    local deck = state.zones.deck.cards
    if #deck == 0 then
        return nil
    end
    local card_id = deck[#deck]
    state_lib.remove_from_current_zone(state, card_id)
    state_lib.set_info_state(state, card_id, info_state)
    state_lib.place_card(state, card_id, zone_name, slot)
    return card_id
end

function M.start_game(state, opts)
    opts = opts or {}
    local rng = opts.rng or default_rng
    state.rng = rng

    state.cards = cards.create_card_store()
    state.log = {}
    state.event_stream = {}
    state.current_transition = state.current_transition
    state.last_transition = state.last_transition
    state_lib.clear_gameplay_selection(state)
    state.pending_trump = nil
    for _, zone in pairs(state.zones) do
        if zone.kind == "slots" then
            for i = 1, zone.slot_count do
                zone.cards[i] = nil
            end
        else
            zone.cards = {}
        end
    end
    local minor_deck = {}
    cards.append_minor_deck(state.cards, minor_deck)
    state.zones.deck.cards = {}
    state_lib.sync_zone_cards(state, "deck")
    fisher_yates(minor_deck, rng)

    for slot = 1, 6 do
        local card_id = minor_deck[#minor_deck]
        minor_deck[#minor_deck] = nil
        state_lib.reveal_card(state, card_id)
        state_lib.place_card(state, card_id, "manifest", slot)
    end
    for _ = 1, 6 do
        local card_id = minor_deck[#minor_deck]
        minor_deck[#minor_deck] = nil
        state_lib.reveal_card(state, card_id)
        state_lib.place_card(state, card_id, "hand", nil)
    end

    cards.append_trump_deck(state.cards, state.zones.deck.cards)
    for _, card_id in ipairs(minor_deck) do
        state.zones.deck.cards[#state.zones.deck.cards + 1] = card_id
    end
    fisher_yates(state.zones.deck.cards, rng)
    state_lib.sync_zone_cards(state, "deck")

    for slot = 1, 3 do
        deal_from_deck(state, "targets", slot, "hidden")
    end
    for slot = 1, 6 do
        deal_from_deck(state, "latent", slot, "hidden")
    end

    state_lib.push_log(state, "Start Game complete.")
    state_lib.push_log(state, "Phase A: 100 minors -> 6 manifest, 6 hand.")
    state_lib.push_log(state, "Phase B: +22 trumps shuffled into deck -> 3 targets, 6 latent.")
    state_lib.push_log(state, "Deck now holds 101 cards.")
end

return M
