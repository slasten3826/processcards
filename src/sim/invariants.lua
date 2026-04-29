local state_lib = require("src.core.state")

local M = {}

local function fail(name, details)
    return false, {
        name = name,
        details = details,
    }
end

function M.setup_board_closed(state)
    if not state_lib.is_board_closed(state) then
        return fail("setup_board_closed", "board must be closed after setup")
    end
    return true
end

function M.no_holes_in_zone(state, zone_name)
    local zone = state.zones[zone_name]
    if zone.kind ~= "slots" then
        return true
    end
    for i = 1, zone.slot_count do
        if zone.cards[i] == nil then
            return fail("no_holes_in_" .. zone_name, zone_name .. "[" .. i .. "] is empty")
        end
    end
    return true
end

function M.pending_trump_consistency(state)
    local flow_head = state.zones.trump_flow.cards[1]
    if state.pending_trump and not flow_head then
        return fail("pending_trump_consistency", "pending_trump set while trump_flow is empty")
    end
    if state.pending_trump and state.pending_trump ~= flow_head then
        return fail("pending_trump_consistency", "pending_trump must match trump_flow head")
    end
    return true
end

function M.flow_cards_are_trumps(state)
    for i, card_id in ipairs(state.zones.trump_flow.cards) do
        local card = state.cards[card_id]
        if not card or card.class ~= "trump" then
            return fail("flow_cards_are_trumps", "trump_flow[" .. i .. "] is not a trump")
        end
    end
    return true
end

function M.trump_zone_cards_are_trumps(state)
    for i = 1, state.zones.trump.slot_count do
        local card_id = state.zones.trump.cards[i]
        if card_id then
            local card = state.cards[card_id]
            if not card or card.class ~= "trump" then
                return fail("trump_zone_cards_are_trumps", "trump[" .. i .. "] is not a trump")
            end
        end
    end
    return true
end

function M.run_all(state)
    local checks = {
        M.setup_board_closed,
        function(s) return M.no_holes_in_zone(s, "manifest") end,
        function(s) return M.no_holes_in_zone(s, "latent") end,
        function(s) return M.no_holes_in_zone(s, "targets") end,
        M.pending_trump_consistency,
        M.flow_cards_are_trumps,
        M.trump_zone_cards_are_trumps,
    }

    for _, check in ipairs(checks) do
        local ok, err = check(state)
        if not ok then
            return ok, err
        end
    end
    return true
end

return M
