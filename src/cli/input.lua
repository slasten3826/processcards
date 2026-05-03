local M = {}

local HAND_KEYS = {
    a = 1, b = 2, c = 3, d = 4, e = 5, f = 6,
}

function M.parse(state, interaction, raw)
    raw = raw:gsub("^%s+", ""):gsub("%s+$", "")

    if raw == "" then
        if interaction.advance and interaction.advance.enabled then
            return {kind = "advance"}
        end
        return nil
    end

    if raw == "q" or raw == "quit" then
        os.exit(0)
    end

    if raw == "x" or raw == "clear" then
        return {kind = "clear_selection"}
    end

    if raw == "d" or raw == "draw" then
        return {kind = "draw"}
    end

    if raw == "s" or raw == "start" then
        return {kind = "start"}
    end

    local slot = tonumber(raw)
    if slot and slot >= 1 and slot <= 6 then
        if interaction.phase == "await_start" or interaction.phase == "await_complete" or interaction.phase == "await_ready" then
            return {kind = "commit_manifest", slot = slot}
        end
        return nil
    end

    local key = raw:lower()
    local hand_idx = HAND_KEYS[key]
    if hand_idx then
        local hand = state.zones.hand
        if hand_idx <= #hand.cards then
            local card_id = hand.cards[hand_idx]
            if card_id then
                return {kind = "arm_hand", card_id = card_id}
            end
        end
        return nil
    end

    return nil
end

return M
