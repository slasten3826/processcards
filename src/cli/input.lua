local M = {}

local HAND_KEYS = {
    a = 1, b = 2, c = 3, d = 4, e = 5, f = 6,
    g = 7, h = 8, i = 9, j = 10, k = 11, l = 12,
}

local OPERATOR_ALIASES = {
    flw = "FLOW", flow = "FLOW",
    con = "CONNECT", connect = "CONNECT",
    dis = "DISSOLVE", dissolve = "DISSOLVE",
    enc = "ENCODE", encode = "ENCODE",
    cho = "CHOOSE", choose = "CHOOSE",
    obs = "OBSERVE", observe = "OBSERVE",
    log = "LOGIC", logic = "LOGIC",
    cyc = "CYCLE", cycle = "CYCLE",
    run = "RUNTIME", runtime = "RUNTIME",
    man = "MANIFEST", manifest = "MANIFEST",
}

local function trim(s)
    return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function list_contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end
    return false
end

local function first_best_clear(interaction)
    local clears = interaction.legal and interaction.legal.clears or {}
    if clears.selection then
        return { kind = "clear_selection" }
    end
    if clears.committed then
        return { kind = "clear_committed" }
    end
    if clears.armed then
        return { kind = "clear_armed" }
    end
    return nil
end

local function hand_card_by_key(state, raw)
    local idx = HAND_KEYS[raw]
    if not idx then
        return nil
    end
    return state.zones.hand.cards[idx]
end

local function grave_card_by_index(state, idx)
    local grave = state.zones.grave.cards
    if idx < 1 or idx > #grave then
        return nil
    end
    return grave[#grave - idx + 1]
end

local function topdeck_card(state)
    local deck = state.zones.deck.cards
    return deck[#deck]
end

local function zone_slot_card(state, zone_name, slot)
    local zone = state.zones[zone_name]
    if not zone then
        return nil
    end
    return zone.cards[slot]
end

local function parse_zone_target_ref(state, raw)
    local zone_key, num = raw:match("^([mltrpgd])(%d+)$")
    if not zone_key or not num then
        return nil
    end
    local slot = tonumber(num)
    if not slot then
        return nil
    end

    if zone_key == "m" then
        return { zone = "manifest", slot = slot, card_id = zone_slot_card(state, "manifest", slot) }
    end
    if zone_key == "l" then
        return { zone = "latent", slot = slot, card_id = zone_slot_card(state, "latent", slot) }
    end
    if zone_key == "t" then
        return { zone = "targets", slot = slot, card_id = zone_slot_card(state, "targets", slot) }
    end
    if zone_key == "r" then
        return { zone = "runtime", slot = slot, card_id = zone_slot_card(state, "runtime", slot) }
    end
    if zone_key == "p" then
        return { zone = "play", slot = slot, card_id = zone_slot_card(state, "play", slot) }
    end
    if zone_key == "g" then
        return { zone = "grave", slot = slot, card_id = grave_card_by_index(state, slot) }
    end
    if zone_key == "d" then
        if slot ~= 1 then
            return nil
        end
        return { zone = "deck", slot = 1, card_id = topdeck_card(state) }
    end
    return nil
end

local function parse_operator(interaction, raw)
    if raw == "none" or raw == "discharge" or raw == "skip" or raw == "on" then
        return { kind = "arm_operator", operator = nil }
    end

    local op_index = raw:match("^o(%d)$")
    if op_index then
        local idx = tonumber(op_index)
        local op_name = interaction.legal.operators[idx]
        if op_name then
            return { kind = "arm_operator", operator = op_name }
        end
    end

    if raw:match("^op%s+") then
        raw = trim(raw:gsub("^op%s+", ""))
    end

    local op_name = OPERATOR_ALIASES[raw]
    if op_name and list_contains(interaction.legal.operators, op_name) then
        return { kind = "arm_operator", operator = op_name }
    end

    return nil
end

local function parse_target(state, interaction, raw)
    local target_kind = interaction.legal and interaction.legal.targets and interaction.legal.targets.kind or nil

    if target_kind == "manifest_slot" then
        local slot = tonumber(raw) or tonumber(raw:match("^m(%d+)$"))
        if slot and list_contains(interaction.legal.targets.slots, slot) then
            return { kind = "arm_target", target = { zone = "manifest", slot = slot } }
        end
        return nil
    end

    if target_kind == "hand_card" then
        local card_id = hand_card_by_key(state, raw)
        if card_id and list_contains(interaction.legal.targets.cards, card_id) then
            return { kind = "arm_target", target = { zone = "hand", card_id = card_id } }
        end
        return nil
    end

    if target_kind == "pair_card" then
        local hand_card_id = hand_card_by_key(state, raw)
        if hand_card_id and list_contains(interaction.legal.targets.cards, hand_card_id) then
            return { kind = "arm_target", target = { zone = "hand", card_id = hand_card_id } }
        end
    end

    local ref = parse_zone_target_ref(state, raw)
    if ref then
        if target_kind == "pair_card" or list_contains(interaction.legal.targets.cards, ref.card_id) then
            return {
                kind = "arm_target",
                target = {
                    zone = ref.zone,
                    slot = ref.slot,
                    card_id = ref.card_id,
                },
            }
        end
    end

    return nil
end

function M.parse(state, interaction, raw)
    raw = trim(raw):lower()

    if raw == "" then
        if interaction.advance and interaction.advance.enabled then
            return { kind = "advance" }
        end
        return nil
    end

    if raw == "q" or raw == "quit" then
        os.exit(0)
    end

    if raw == "s" or raw == "start" or raw == "restart" then
        return { kind = "start" }
    end

    if raw == "d" or raw == "draw" then
        return { kind = "draw" }
    end

    if raw == "go" or raw == "cast" or raw == "advance" then
        return { kind = "advance" }
    end

    if raw == "x" or raw == "clear" or raw == "back" then
        return first_best_clear(interaction)
    end

    if interaction.phase == "await_operator" then
        local operator_action = parse_operator(interaction, raw)
        if operator_action then
            return operator_action
        end
    end

    if interaction.phase == "await_target" and #interaction.legal.directions > 0 then
        if raw == "left" or raw == "l" then
            return { kind = "arm_direction", direction = "left" }
        end
        if raw == "right" or raw == "r" then
            return { kind = "arm_direction", direction = "right" }
        end
    end

    local slot = tonumber(raw)
    if slot and slot >= 1 and slot <= 6 then
        if interaction.phase == "await_start" or interaction.phase == "await_complete" or interaction.phase == "await_ready" then
            return { kind = "commit_manifest", slot = slot }
        end
    end

    local hand_card_id = hand_card_by_key(state, raw)
    if hand_card_id then
        if interaction.phase == "await_start" or interaction.phase == "await_complete" or interaction.phase == "await_ready" then
            return { kind = "arm_hand", card_id = hand_card_id }
        end
        if interaction.phase == "await_target" then
            local hand_target = parse_target(state, interaction, raw)
            if hand_target then
                return hand_target
            end
        end
    end

    if interaction.phase == "await_target" then
        return parse_target(state, interaction, raw)
    end

    return nil
end

return M
