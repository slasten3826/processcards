local glyphs = require("src.cli.glyphs")

local M = {}

local CSI = string.char(0x1b) .. "["

local COLORS = {
    reset  = CSI .. "0m",
    green  = CSI .. "32m",
    orange = CSI .. "33m",
    cyan   = CSI .. "36m",
    white  = CSI .. "37m",
    dim    = CSI .. "2m",
    bold   = CSI .. "1m",
}

local function g(col)
    return COLORS[col] or ""
end

local function pad_right(s, n)
    s = s or ""
    if #s >= n then
        return s:sub(1, n)
    end
    return s .. string.rep(" ", n - #s)
end

local function pad_center(s, n)
    s = s or ""
    if #s >= n then
        return s:sub(1, n)
    end
    local left = math.floor((n - #s) / 2)
    return string.rep(" ", left) .. s .. string.rep(" ", n - left - #s)
end

local CARD_W = 9
local CARD_H = 5

local function frame_color(flags)
    if flags.committed and flags.legal then
        return g("orange") .. g("bold")
    end
    if flags.legal then
        return g("green") .. g("bold")
    end
    if flags.committed then
        return g("orange") .. g("bold")
    end
    return g("dim")
end

local function draw_card_border(lines, flags)
    local fc = frame_color(flags)
    local top = fc .. "┌" .. string.rep("─", CARD_W - 2) .. "┐" .. g("reset")
    local bot = fc .. "└" .. string.rep("─", CARD_W - 2) .. "┘" .. g("reset")
    local mid_pre  = fc .. "│" .. g("reset")
    local mid_post = fc .. "│" .. g("reset")

    table.insert(lines, 1, top)
    for i = 2, CARD_H - 1 do
        lines[i] = mid_pre .. (lines[i] or "") .. mid_post
    end
    lines[#lines + 1] = bot
end

local function draw_minor_card(card, flags)
    local op_a = glyphs.glyph(card.op_a)
    local op_b = glyphs.glyph(card.op_b)
    local a_name = glyphs.name(card.op_a)
    local b_name = glyphs.name(card.op_b)

    local inner_w = CARD_W - 2
    local lines = {
        pad_right(op_a, inner_w),
        pad_right("  " .. a_name, inner_w),
        pad_right("    " .. b_name, inner_w),
    }
    draw_card_border(lines, flags)

    if flags.committed then
        for i = 1, #lines do
            lines[i] = g("orange") .. g("bold") .. lines[i] .. g("reset")
        end
    elseif flags.legal then
        for i = 1, #lines do
            lines[i] = g("green") .. g("bold") .. lines[i] .. g("reset")
        end
    end

    return lines
end

local function draw_trump_card(card, flags)
    local op_a = glyphs.glyph(card.op_a)
    local op_b = glyphs.glyph(card.op_b)
    local name = card.trump_name or (glyphs.name(card.op_a) .. "-" .. glyphs.name(card.op_b))
    name = pad_center(name, CARD_W - 3)

    local lines = {
        pad_right(op_a .. " " .. op_b, CARD_W - 3),
        pad_center("", CARD_W - 3),
        name,
    }
    draw_card_border(lines, flags)

    if flags.legal then
        lines[3] = g("green") .. g("bold") .. lines[3] .. g("reset")
    end

    return lines
end

local function draw_empty_card(flags)
    local lines = {
        pad_right("·", CARD_W - 3),
        pad_right("", CARD_W - 3),
        pad_right("", CARD_W - 3),
    }
    local fc = g("dim")
    local top = fc .. "┌" .. string.rep("─", CARD_W - 2) .. "┐" .. g("reset")
    local bot = fc .. "└" .. string.rep("─", CARD_W - 2) .. "┘" .. g("reset")
    local side = fc .. "│" .. g("reset")

    return { top, side .. pad_right("·", CARD_W - 3) .. side, side .. pad_right("", CARD_W - 3) .. side, side .. pad_right("", CARD_W - 3) .. side, bot }
end

local function draw_slot(slot_num, card, flags, extra)
    local lines = {}
    if card then
        if card.class == "trump" then
            lines = draw_trump_card(card, flags)
        else
            lines = draw_minor_card(card, flags)
        end
    else
        lines = draw_empty_card(flags)
    end

    local slot_label
    if extra then
        slot_label = extra
    else
        slot_label = tostring(slot_num or "")
    end
    slot_label = pad_center(slot_label, CARD_W)

    table.insert(lines, g("dim") .. slot_label .. g("reset"))
    return lines
end

local function zone_name_line(name)
    local pre = g("white") .. g("bold") .. name .. g("reset")
    local post = g("dim") .. "───────────────" .. g("reset")
    return pre .. " " .. post
end

local function draw_zone_row(zone, slot_labels, flags_for_card, extra_labels)
    local cards = {}
    for i, card_id in ipairs(zone.cards) do
        if card_id then
            cards[#cards + 1] = card_id
        end
    end

    local rows = {}
    for line_idx = 1, CARD_H + 1 do
        rows[line_idx] = ""
    end

    local draw_order = {}
    for slot = 1, zone.slot_count do
        draw_order[#draw_order + 1] = slot
    end

    for _, slot in ipairs(draw_order) do
        local card_id = zone.cards[slot]
        local card = card_id and M.state.cards[card_id] or nil
        local label = slot_labels and slot_labels[slot] or nil
        local flags = flags_for_card and flags_for_card(card_id, slot) or {}
        local extra = extra_labels and extra_labels[slot] or nil
        local lines = draw_slot(slot, card, flags, extra)
        for line_idx = 1, CARD_H + 1 do
            rows[line_idx] = rows[line_idx] .. lines[line_idx] .. " "
        end
    end

    return rows
end

local function hand_rows()
    local hand = M.state.zones.hand
    local rows = {}
    for line_idx = 1, CARD_H + 1 do
        rows[line_idx] = ""
    end

    local labels = {"a", "b", "c", "d", "e", "f"}
    for idx, card_id in ipairs(hand.cards) do
        local card = M.state.cards[card_id]
        local ix = M.interaction
        local flags = {
            legal = ix.legal.hand_cards and (function()
                for _, id in ipairs(ix.legal.hand_cards) do
                    if id == card_id then return true end
                end
                return false
            end)(),
            committed = false,
        }
        if ix.armed.hand_card_id == card_id then
            flags.committed = true
        end
        local lines = draw_slot(nil, card, flags, labels[idx])
        for line_idx = 1, CARD_H + 1 do
            rows[line_idx] = rows[line_idx] .. lines[line_idx] .. " "
        end
    end

    return rows
end

local function manifest_rows()
    local manifest = M.state.zones.manifest
    local ix = M.interaction
    local rows = {}
    for line_idx = 1, CARD_H + 1 do
        rows[line_idx] = ""
    end

    local commit_slots = {}
    for _, slot in ipairs(ix.legal.commit_slots or {}) do
        commit_slots[slot] = true
    end

    for slot = 1, manifest.slot_count do
        local card_id = manifest.cards[slot]
        local card = card_id and M.state.cards[card_id] or nil
        local flags = {
            legal = commit_slots[slot] and ix.armed.hand_card_id ~= nil,
            committed = M.state.committed and M.state.committed.slot == slot,
        }
        local lines = draw_slot(slot, card, flags, nil)
        for line_idx = 1, CARD_H + 1 do
            rows[line_idx] = rows[line_idx] .. lines[line_idx] .. " "
        end
    end

    return rows
end

local function targets_rows()
    local targets = M.state.zones.targets
    local rows = {}
    for line_idx = 1, CARD_H + 1 do
        rows[line_idx] = ""
    end

    for slot = 1, targets.slot_count do
        local card_id = targets.cards[slot]
        local card = card_id and M.state.cards[card_id] or nil
        local label = "T" .. tostring(slot)
        local lines = draw_slot(slot, card, {}, label)
        for line_idx = 1, CARD_H + 1 do
            rows[line_idx] = rows[line_idx] .. lines[line_idx] .. " "
        end
    end

    return rows
end

local function hidden_card_rows(zone_name, title)
    local zone = M.state.zones[zone_name]
    local rows = {}
    for line_idx = 1, CARD_H + 1 do
        rows[line_idx] = ""
    end

    for slot = 1, zone.slot_count do
        local card_id = zone.cards[slot]
        local lines
        if card_id then
            local label = title:sub(1,1) .. tostring(slot)
            lines = draw_slot(slot, {op_a = "HIDDEN", op_b = "HIDDEN", class = "minor"}, {}, label)
        else
            local label = title:sub(1,1) .. tostring(slot)
            lines = draw_slot(slot, nil, {}, label)
        end
        for line_idx = 1, CARD_H + 1 do
            rows[line_idx] = rows[line_idx] .. lines[line_idx] .. " "
        end
    end

    return rows
end

local function system_line()
    local s = M.state
    local ix = M.interaction
    local parts = {
        string.format("DECK: %-4d", #s.zones.deck.cards),
        string.format("GRAVE: %-4d", #s.zones.grave.cards),
        string.format("FLOW: %-4d", #s.zones.trump_flow.cards),
        string.format("TZONE: %d/2", M._zone_filled(s.zones.trump)),
        string.format("PHASE: %s", ix.phase or "?"),
    }
    if ix.advance and ix.advance.enabled then
        parts[#parts + 1] = g("green") .. g("bold") .. "△ CAST" .. g("reset")
    end
    return table.concat(parts, "  " .. g("dim") .. "|" .. g("reset") .. "  ")
end

function M._zone_filled(zone)
    local n = 0
    for i = 1, (zone.slot_count or 0) do
        if zone.cards[i] then n = n + 1 end
    end
    return n
end

function M.render(state, interaction)
    M.state = state
    M.interaction = interaction

    local lines = {}

    table.insert(lines, zone_name_line("MANIFEST"))
    for _, row in ipairs(manifest_rows()) do
        table.insert(lines, row)
    end
    table.insert(lines, "")

    table.insert(lines, zone_name_line("HAND"))
    for _, row in ipairs(hand_rows()) do
        table.insert(lines, row)
    end
    table.insert(lines, "")

    table.insert(lines, zone_name_line("TARGETS"))
    for _, row in ipairs(targets_rows()) do
        table.insert(lines, row)
    end
    table.insert(lines, "")

    if M._zone_filled(M.state.zones.latent) > 0 then
        table.insert(lines, zone_name_line("LATENT"))
        local latent_rows = hidden_card_rows("latent", "L")
        for _, row in ipairs(latent_rows) do
            table.insert(lines, row)
        end
        table.insert(lines, "")
    end

    local flow_count = #M.state.zones.trump_flow.cards
    local zone_count = M._zone_filled(M.state.zones.trump)
    if flow_count > 0 or zone_count > 0 then
        table.insert(lines, zone_name_line("TRUMP"))
        if flow_count > 0 then
            local flow_ids = {}
            for _, card_id in ipairs(M.state.zones.trump_flow.cards) do
                table.insert(flow_ids, card_id)
            end
            table.insert(lines, "  FLOW: " .. table.concat(flow_ids, ", "))
        end
        if zone_count > 0 then
            local zone_ids = {}
            for slot = 1, M.state.zones.trump.slot_count do
                local card_id = M.state.zones.trump.cards[slot]
                if card_id then
                    table.insert(zone_ids, card_id)
                end
            end
            table.insert(lines, "  ZONE: " .. table.concat(zone_ids, ", "))
        end
        table.insert(lines, "")
    end

    table.insert(lines, g("dim") .. string.rep("─", 72) .. g("reset"))
    table.insert(lines, system_line())

    if interaction.prompt then
        table.insert(lines, g("dim") .. interaction.prompt .. g("reset"))
    end

    table.insert(lines, "")

    return table.concat(lines, "\n")
end

return M
