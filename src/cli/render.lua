local glyphs = require("src.cli.glyphs")

local M = {}

local CSI = string.char(0x1b) .. "["

local COLORS = {
    reset  = CSI .. "0m",
    dim    = CSI .. "2m",
    bold   = CSI .. "1m",
    white  = CSI .. "37m",
    cyan   = CSI .. "36m",
    green  = CSI .. "32m",
    yellow = CSI .. "33m",
    red    = CSI .. "31m",
}

local CARD_W = 11
local CARD_H = 5
local HAND_LABELS = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l"}

local function g(name)
    return COLORS[name] or ""
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

local function zone_name_line(name)
    return g("white") .. g("bold") .. name .. g("reset") .. " " .. g("dim") .. string.rep("─", 24) .. g("reset")
end

local function list_contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end
    return false
end

local function push_row(rows, line_idx, text)
    rows[line_idx] = (rows[line_idx] or "") .. text
end

local function hidden_placeholder(label)
    local inner = CARD_W - 2
    return {
        "┌" .. string.rep("─", inner) .. "┐",
        "│" .. pad_center("?", inner) .. "│",
        "│" .. pad_center(label or "HIDDEN", inner) .. "│",
        "│" .. pad_center("???", inner) .. "│",
        "└" .. string.rep("─", inner) .. "┘",
    }
end

local function visible_minor(card)
    local inner = CARD_W - 2
    return {
        "┌" .. string.rep("─", inner) .. "┐",
        "│" .. pad_right(glyphs.glyph(card.op_a), inner) .. "│",
        "│" .. pad_right("  " .. glyphs.name(card.op_a), inner) .. "│",
        "│" .. pad_right("    " .. glyphs.name(card.op_b), inner) .. "│",
        "└" .. string.rep("─", inner) .. "┘",
    }
end

local function visible_trump(card)
    local inner = CARD_W - 2
    return {
        "┌" .. string.rep("─", inner) .. "┐",
        "│" .. pad_right(glyphs.glyph(card.op_a) .. " " .. glyphs.glyph(card.op_b), inner) .. "│",
        "│" .. pad_right("  " .. glyphs.name(card.op_a), inner) .. "│",
        "│" .. pad_right("    " .. glyphs.name(card.op_b), inner) .. "│",
        "└" .. string.rep("─", inner) .. "┘",
    }
end

local function empty_slot()
    local inner = CARD_W - 2
    return {
        "┌" .. string.rep("─", inner) .. "┐",
        "│" .. pad_center("·", inner) .. "│",
        "│" .. string.rep(" ", inner) .. "│",
        "│" .. string.rep(" ", inner) .. "│",
        "└" .. string.rep("─", inner) .. "┘",
    }
end

local function colorize_box(lines, flags)
    local color = g("dim")
    if flags.armed then
        color = g("yellow") .. g("bold")
    elseif flags.committed then
        color = g("cyan") .. g("bold")
    elseif flags.legal then
        color = g("green") .. g("bold")
    end

    local out = {}
    for i, line in ipairs(lines) do
        out[i] = color .. line .. g("reset")
    end
    return out
end

local function slot_label_line(text)
    return g("dim") .. pad_center(text or "", CARD_W) .. g("reset")
end

local function make_card_box(card, flags, hidden_label)
    if not card then
        return colorize_box(empty_slot(), flags)
    end
    if card.info_state == "hidden" then
        return colorize_box(hidden_placeholder(hidden_label), flags)
    end
    if card.class == "trump" then
        return colorize_box(visible_trump(card), flags)
    end
    return colorize_box(visible_minor(card), flags)
end

local function make_card_ref_set(refs)
    local set = {}
    for _, ref in ipairs(refs or {}) do
        if ref.card_id then
            set[ref.card_id] = true
        end
    end
    return set
end

local function make_slot_set(slots)
    local set = {}
    for _, slot in ipairs(slots or {}) do
        set[slot] = true
    end
    return set
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

local function card_summary(card)
    if not card then
        return "-"
    end
    if card.class == "trump" then
        return string.format("%s %s", glyphs.pair(card.op_a, card.op_b), card.trump_name or card.id)
    end
    return string.format("%s %s", glyphs.pair(card.op_a, card.op_b), card.id)
end

local function current_flags(state, interaction)
    local ix = interaction
    local legal_targets = make_slot_set(ix.legal.targets.slots)
    local legal_target_cards = make_slot_set(ix.legal.targets.cards)
    local legal_commit_slots = make_slot_set(ix.legal.commit_slots)
    local legal_hand_cards = make_slot_set(ix.legal.hand_cards)
    local armed_target_cards = make_card_ref_set(ix.armed.targets)

    local function manifest(slot, card_id)
        return {
            legal = legal_commit_slots[slot] or legal_target_cards[card_id] or legal_targets[slot],
            committed = state.committed and state.committed.slot == slot or false,
            armed = armed_target_cards[card_id] or false,
        }
    end

    local function latent(slot, card_id)
        return {
            legal = legal_target_cards[card_id] or false,
            committed = false,
            armed = armed_target_cards[card_id] or false,
        }
    end

    local function hand(card_id)
        return {
            legal = legal_hand_cards[card_id] or legal_target_cards[card_id] or false,
            committed = false,
            armed = state.armed_hand == card_id or armed_target_cards[card_id] or false,
        }
    end

    local function targets(card_id)
        return {
            legal = legal_target_cards[card_id] or false,
            committed = false,
            armed = armed_target_cards[card_id] or false,
        }
    end

    local function single(card_id)
        return {
            legal = legal_target_cards[card_id] or false,
            committed = false,
            armed = armed_target_cards[card_id] or false,
        }
    end

    return {
        manifest = manifest,
        latent = latent,
        hand = hand,
        targets = targets,
        single = single,
    }
end

local function render_slot_row(state, zone_name, labels, flag_fn, hidden_prefix)
    local zone = state.zones[zone_name]
    local rows = {}
    for i = 1, CARD_H + 1 do
        rows[i] = ""
    end
    for slot = 1, zone.slot_count do
        local card_id = zone.cards[slot]
        local card = card_id and state.cards[card_id] or nil
        local flags = flag_fn and flag_fn(slot, card_id, card) or {}
        local box = make_card_box(card, flags, hidden_prefix and (hidden_prefix .. slot) or nil)
        for i = 1, CARD_H do
            push_row(rows, i, box[i] .. " ")
        end
        push_row(rows, CARD_H + 1, slot_label_line(labels[slot] or tostring(slot)) .. " ")
    end
    return rows
end

local function render_hand(state, flag_fn)
    local rows = {}
    for i = 1, CARD_H + 1 do
        rows[i] = ""
    end
    for idx, card_id in ipairs(state.zones.hand.cards) do
        local card = state.cards[card_id]
        local box = make_card_box(card, flag_fn(card_id, card), nil)
        for i = 1, CARD_H do
            push_row(rows, i, box[i] .. " ")
        end
        push_row(rows, CARD_H + 1, slot_label_line(HAND_LABELS[idx] or tostring(idx)) .. " ")
    end
    return rows
end

local function render_single_zone(state, zone_name, label, card_id, flags)
    local card = card_id and state.cards[card_id] or nil
    local box = make_card_box(card, flags or {}, label)
    local rows = {}
    for i = 1, CARD_H do
        rows[i] = box[i]
    end
    rows[CARD_H + 1] = slot_label_line(label)
    return rows
end

local function append_rows(lines, rows)
    for _, row in ipairs(rows) do
        lines[#lines + 1] = row
    end
end

local function operator_lines(interaction)
    if interaction.phase ~= "await_operator" then
        return {}
    end
    local lines = { zone_name_line("OPERATORS") }
    for idx, op_name in ipairs(interaction.legal.operators or {}) do
        local armed = interaction.armed.operator == op_name
        local prefix = armed and (g("yellow") .. g("bold")) or g("green")
        lines[#lines + 1] = string.format(
            "%s[o%d]%s %s %s",
            prefix, idx, g("reset"),
            glyphs.glyph(op_name),
            op_name
        )
    end
    lines[#lines + 1] = g("dim") .. "[on] none / discharge" .. g("reset")
    lines[#lines + 1] = ""
    return lines
end

local function grave_lines(state, interaction)
    local lines = { zone_name_line("GRAVE") }
    local count = #state.zones.grave.cards
    if count == 0 then
        lines[#lines + 1] = g("dim") .. "(empty)" .. g("reset")
        lines[#lines + 1] = ""
        return lines
    end
    local max_show = math.min(count, 8)
    for i = 1, max_show do
        local card_id = grave_card_by_index(state, i)
        local card = state.cards[card_id]
        local legal = list_contains(interaction.legal.targets.cards, card_id)
        local armed = false
        for _, ref in ipairs(interaction.armed.targets or {}) do
            if ref.card_id == card_id then
                armed = true
                break
            end
        end
        local color = armed and (g("yellow") .. g("bold")) or (legal and (g("green") .. g("bold")) or g("dim"))
        lines[#lines + 1] = string.format("%s[g%d]%s %s", color, i, g("reset"), card_summary(card))
    end
    lines[#lines + 1] = ""
    return lines
end

local function trump_lines(state)
    local lines = {}
    local flow = state.zones.trump_flow.cards
    local zone = state.zones.trump.cards
    if #flow == 0 and not zone[1] and not zone[2] then
        return lines
    end
    lines[#lines + 1] = zone_name_line("TRUMPS")
    if #flow > 0 then
        local flow_bits = {}
        for idx, card_id in ipairs(flow) do
            local card = state.cards[card_id]
            flow_bits[#flow_bits + 1] = string.format("f%d=%s", idx, card_summary(card))
        end
        lines[#lines + 1] = "FLOW  " .. table.concat(flow_bits, "  ")
    end
    local zone_bits = {}
    for slot = 1, 2 do
        local card_id = zone[slot]
        if card_id then
            zone_bits[#zone_bits + 1] = string.format("z%d=%s", slot, card_summary(state.cards[card_id]))
        else
            zone_bits[#zone_bits + 1] = string.format("z%d=-", slot)
        end
    end
    lines[#lines + 1] = "ZONE  " .. table.concat(zone_bits, "  ")
    lines[#lines + 1] = ""
    return lines
end

local function topdeck_lines(state, interaction)
    local card_id = topdeck_card(state)
    if not card_id then
        return {}
    end
    local card = state.cards[card_id]
    local legal = list_contains(interaction.legal.targets.cards, card_id)
    local armed = false
    for _, ref in ipairs(interaction.armed.targets or {}) do
        if ref.card_id == card_id then
            armed = true
            break
        end
    end
    local flags = { legal = legal, committed = false, armed = armed }
    local rows = render_single_zone(state, "deck", "d1", card_id, flags)
    local out = { zone_name_line("TOPDECK") }
    append_rows(out, rows)
    out[#out + 1] = ""
    return out
end

local function system_line(state, interaction)
    local function zone_filled(zone)
        local n = 0
        for i = 1, (zone.slot_count or 0) do
            if zone.cards[i] then
                n = n + 1
            end
        end
        return n
    end

    local parts = {
        string.format("DECK:%3d", #state.zones.deck.cards),
        string.format("HAND:%2d", #state.zones.hand.cards),
        string.format("GRAVE:%2d", #state.zones.grave.cards),
        string.format("FLOW:%2d", #state.zones.trump_flow.cards),
        string.format("TZ:%d/2", zone_filled(state.zones.trump)),
        string.format("PHASE:%s", interaction.phase or "?"),
    }
    if interaction.advance and interaction.advance.enabled then
        parts[#parts + 1] = g("green") .. g("bold") .. (interaction.advance.label or "ADVANCE") .. g("reset")
    end
    return table.concat(parts, "  " .. g("dim") .. "|" .. g("reset") .. "  ")
end

local function event_lines(ui)
    local lines = {}
    if ui and ui.message and ui.message ~= "" then
        lines[#lines + 1] = g("cyan") .. ui.message .. g("reset")
    end
    for _, item in ipairs((ui and ui.events) or {}) do
        lines[#lines + 1] = g("dim") .. item .. g("reset")
    end
    if #lines > 0 then
        lines[#lines + 1] = ""
    end
    return lines
end

local function command_hints(interaction)
    local lines = { zone_name_line("COMMANDS") }
    lines[#lines + 1] = "[enter] advance/confirm   [x] clear   [s] restart   [q] quit"

    if interaction.phase == "await_start" or interaction.phase == "await_complete" or interaction.phase == "await_ready" then
        lines[#lines + 1] = "[1-6] commit manifest   [a-l] arm hand"
    elseif interaction.phase == "await_operator" then
        lines[#lines + 1] = "[o1/o2] arm operator   [on] none/discharge"
    elseif interaction.phase == "await_target" then
        lines[#lines + 1] = "[m1..m6] manifest   [l1..l6] latent   [t1..t3] targets   [g1..] grave   [r1] runtime   [d1] topdeck"
        lines[#lines + 1] = "[a-l] hand target"
        if #interaction.legal.directions > 0 then
            lines[#lines + 1] = "[left/right] direction"
        end
    end

    lines[#lines + 1] = ""
    return lines
end

function M.render(state, interaction, ui)
    local flags = current_flags(state, interaction)
    local lines = {}

    lines[#lines + 1] = system_line(state, interaction)
    lines[#lines + 1] = g("dim") .. (interaction.prompt or "") .. g("reset")
    lines[#lines + 1] = ""

    local events = event_lines(ui)
    for _, line in ipairs(events) do
        lines[#lines + 1] = line
    end

    lines[#lines + 1] = zone_name_line("MANIFEST")
    append_rows(lines, render_slot_row(state, "manifest", {"1", "2", "3", "4", "5", "6"}, function(slot, card_id)
        return flags.manifest(slot, card_id)
    end))
    lines[#lines + 1] = ""

    lines[#lines + 1] = zone_name_line("HAND")
    append_rows(lines, render_hand(state, function(card_id)
        return flags.hand(card_id)
    end))
    lines[#lines + 1] = ""

    lines[#lines + 1] = zone_name_line("TARGETS")
    append_rows(lines, render_slot_row(state, "targets", {"t1", "t2", "t3"}, function(_, card_id)
        return flags.targets(card_id)
    end, "T"))
    lines[#lines + 1] = ""

    lines[#lines + 1] = zone_name_line("LATENT")
    append_rows(lines, render_slot_row(state, "latent", {"l1", "l2", "l3", "l4", "l5", "l6"}, function(slot, card_id)
        return flags.latent(slot, card_id)
    end, "L"))
    lines[#lines + 1] = ""

    local play_card_id = state.zones.play.cards[1]
    if play_card_id or interaction.phase == "await_operator" then
        lines[#lines + 1] = zone_name_line("PLAY")
        append_rows(lines, render_single_zone(state, "play", "p1", play_card_id, flags.single(play_card_id)))
        lines[#lines + 1] = ""
    end

    local runtime_card_id = state.zones.runtime.cards[1]
    if runtime_card_id then
        lines[#lines + 1] = zone_name_line("RUNTIME")
        append_rows(lines, render_single_zone(state, "runtime", "r1", runtime_card_id, flags.single(runtime_card_id)))
        lines[#lines + 1] = ""
    end

    for _, line in ipairs(operator_lines(interaction)) do
        lines[#lines + 1] = line
    end
    for _, line in ipairs(topdeck_lines(state, interaction)) do
        lines[#lines + 1] = line
    end
    for _, line in ipairs(trump_lines(state)) do
        lines[#lines + 1] = line
    end
    for _, line in ipairs(grave_lines(state, interaction)) do
        lines[#lines + 1] = line
    end
    for _, line in ipairs(command_hints(interaction)) do
        lines[#lines + 1] = line
    end

    return table.concat(lines, "\n")
end

return M
