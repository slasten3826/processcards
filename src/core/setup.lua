local cards = require("src.core.cards")
local constants = require("src.core.constants")
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

local function normalize_enabled_trumps(enabled_trumps)
    if enabled_trumps == nil then
        return nil
    end

    local out = {}
    for _, item in ipairs(enabled_trumps) do
        local idx = nil
        if type(item) == "number" then
            idx = item
        elseif type(item) == "string" then
            local upper = item:upper()
            idx = constants.TRUMP_NAME_TO_INDEX[upper]
                or tonumber(upper:match("^TRUMP%-(%d+)$"))
                or tonumber(upper)
        end
        if idx and idx >= 1 and idx <= #constants.TRUMP_CANON then
            out[idx] = true
        end
    end
    return out
end

-- Second, independent axis. enabled_trumps decides whether a trump is IN THE
-- DECK; enabled_effects decides whether its effect body RUNS. Removing a trump
-- from the deck changes composition, density and the shuffle oscillator, so it
-- tests a different game. Stubbing the effect leaves the economy untouched and
-- tests the minor machine in the presence of trumps.
local function normalize_enabled_effects(enabled_effects)
    if enabled_effects == nil then
        return nil
    end
    return normalize_enabled_trumps(enabled_effects)
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
    local enabled_trumps = normalize_enabled_trumps(opts.enabled_trumps)
    state.rng = rng
    local enabled_effects = normalize_enabled_effects(opts.enabled_effects)
    state.setup_options = {
        enabled_trumps = enabled_trumps,
        enabled_effects = enabled_effects,
        trump_mode = opts.trump_mode or (enabled_trumps and "custom" or "full"),
        -- DEV_CLI_LAW §8: drawing outside a turn is a cheat, so the axis that
        -- turns it on changes the game and lives in the journal header. The
        -- default is the real game, exactly like effects=all.
        free_draw = opts.free_draw and true or false,
        guard = opts.guard,
    }
    state.trump_guard = opts.guard
    state.trump_runaway = nil
    state.trump_flow_draining = nil
    state.trump_chain_steps = nil
    state.trump_repair_attempts = nil
    state.max_transition_events_per_action = opts.max_transition_events_per_action

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

    cards.append_trump_deck(state.cards, state.zones.deck.cards, enabled_trumps)
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
    local trump_count = 0
    if enabled_trumps == nil then
        trump_count = 22
    else
        for _ in pairs(enabled_trumps) do
            trump_count = trump_count + 1
        end
    end
    state_lib.push_log(state, string.format("Phase B: +%d trumps shuffled into deck -> 3 targets, 6 latent.", trump_count))
    state_lib.push_log(state, string.format("Deck now holds %d cards.", #state.zones.deck.cards))
end

return M
