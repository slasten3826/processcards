local glyphs = require("src.glyphs")
local glyph_layout = require("src.glyph_layout")
local layout_lib = require("src.manifest.layout")
local theme = require("src.manifest.theme")

local M = {}

local COLORS = theme.COLORS
local OP_COLORS = theme.OP_COLORS

local function rounded(mode, x, y, w, h, r)
    love.graphics.rectangle(mode, x, y, w, h, r, r)
end

local function set_color(c, alpha)
    love.graphics.setColor(c[1], c[2], c[3], alpha or 1)
end

local function lerp_color(a, b, t)
    return {
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
    }
end

local function draw_with_rounded_mask(rect, radius, draw_fn)
    love.graphics.stencil(function()
        rounded("fill", rect.x, rect.y, rect.w, rect.h, radius)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    draw_fn()
    love.graphics.setStencilTest()
end

local function frame_breath_phase()
    return 0.5 + 0.5 * math.sin(love.timer.getTime() * 2.2)
end

local function draw_breath_halo(rect, color, phase, scale)
    local pulse = 0.40 + 0.60 * phase
    local prev_blend = {love.graphics.getBlendMode()}
    love.graphics.setBlendMode("add")
    local steps = 12
    local inner = 4
    local outer = 42
    for i = 1, steps do
        local t = (i - 1) / (steps - 1)
        local spread = inner + (outer - inner) * t
        local fade = (1 - t)
        local alpha = 0.11 * pulse * fade * fade
        set_color(color, alpha)
        rounded(
            "fill",
            rect.x - spread,
            rect.y - spread,
            rect.w + spread * 2,
            rect.h + spread * 2,
            10 + spread * 0.8
        )
    end
    love.graphics.setBlendMode(prev_blend[1], prev_blend[2])
    love.graphics.setLineWidth(math.max(2, scale * 2))
end

local function draw_perimeter_segment(x, y, w, h, d1, d2)
    local perimeter = 2 * (w + h)
    if perimeter <= 0 then
        return
    end

    local function point_at(d)
        d = d % perimeter
        if d <= w then
            return x + d, y
        end
        d = d - w
        if d <= h then
            return x + w, y + d
        end
        d = d - h
        if d <= w then
            return x + w - d, y + h
        end
        d = d - w
        return x, y + h - d
    end

    local p1x, p1y = point_at(d1)
    local p2x, p2y = point_at(d2)
    if d2 >= d1 and (
        (d1 <= w and d2 <= w)
        or (d1 > w and d1 <= w + h and d2 <= w + h)
        or (d1 > w + h and d1 <= 2 * w + h and d2 <= 2 * w + h)
        or (d1 > 2 * w + h and d2 <= perimeter)
    ) then
        love.graphics.line(p1x, p1y, p2x, p2y)
        return
    end

    local side_breaks = {w, w + h, 2 * w + h, perimeter}
    local start_d = d1
    for _, edge_d in ipairs(side_breaks) do
        if start_d < edge_d then
            local end_d = math.min(d2, edge_d)
            local sx, sy = point_at(start_d)
            local ex, ey = point_at(end_d)
            love.graphics.line(sx, sy, ex, ey)
            start_d = end_d
        end
    end
end

local function draw_segmented_frame(rect, colors, phase, opts)
    opts = opts or {}
    local inset = opts.inset or 0
    local width = opts.width or 2
    local segment_count = opts.segment_count or 14
    local duty = opts.duty or 0.52
    local x = rect.x + inset
    local y = rect.y + inset
    local w = rect.w - inset * 2
    local h = rect.h - inset * 2
    local perimeter = 2 * (w + h)
    if w <= 0 or h <= 0 or perimeter <= 0 then
        return
    end

    love.graphics.setLineWidth(width)
    local step = perimeter / segment_count
    local seg_len = step * duty
    local shift = (phase % 1) * perimeter

    for i = 0, segment_count - 1 do
        local color = colors[(i % #colors) + 1]
        local start_d = (i * step + shift) % perimeter
        local end_d = start_d + seg_len
        set_color(color, 0.98)
        if end_d <= perimeter then
            draw_perimeter_segment(x, y, w, h, start_d, end_d)
        else
            draw_perimeter_segment(x, y, w, h, start_d, perimeter)
            draw_perimeter_segment(x, y, w, h, 0, end_d - perimeter)
        end
    end
end

local function draw_panel(app, rect, title, subtitle)
    set_color(COLORS.panel)
    rounded("fill", rect.x, rect.y, rect.w, rect.h, 12)
    set_color(COLORS.outline)
    rounded("line", rect.x, rect.y, rect.w, rect.h, 12)
    love.graphics.setFont(app.fonts.title)
    set_color(COLORS.text)
    love.graphics.print(title, rect.x + 14 * app.layout.scale, rect.y + 9 * app.layout.scale)
    if subtitle then
        love.graphics.setFont(app.fonts.small)
        set_color(COLORS.muted)
        love.graphics.print(subtitle, rect.x + 14 * app.layout.scale, rect.y + 32 * app.layout.scale)
    end
end

local function draw_panel_counter(app, rect, text, opts)
    opts = opts or {}
    love.graphics.setFont(opts.font or app.fonts.small)
    set_color(opts.color or COLORS.muted, opts.alpha or 0.92)
    if opts.align == "right" then
        love.graphics.printf(
            text,
            rect.x + rect.w - (opts.width or (72 * app.layout.scale)) - 14 * app.layout.scale,
            opts.y or (rect.y + 16 * app.layout.scale),
            opts.width or (72 * app.layout.scale),
            "right"
        )
    else
        love.graphics.print(text, opts.x or (rect.x + 14 * app.layout.scale), opts.y or (rect.y + 16 * app.layout.scale))
    end
end

local function draw_slot_placeholder(app, rect, label)
    set_color(COLORS.outline, 0.8)
    love.graphics.setLineWidth(math.max(1, app.layout.scale * 2))
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 10, 10)
    love.graphics.setFont(app.fonts.small)
    set_color(COLORS.muted)
    love.graphics.printf(label, rect.x, rect.y + rect.h + 4 * app.layout.scale, rect.w, "center")
end

local function card_state_flags(app, card_id)
    local card = app.game.cards[card_id]
    local ix = app.interaction
    local legal_target_cards = {}
    for _, id in ipairs(ix.legal.targets.cards or {}) do
        legal_target_cards[id] = true
    end
    local legal_target_slots = {}
    for _, slot in ipairs(ix.legal.targets.slots or {}) do
        legal_target_slots[slot] = true
    end
    local legal_hand = {}
    for _, id in ipairs(ix.legal.hand_cards or {}) do
        legal_hand[id] = true
    end
    local legal_commit_slots_set = {}
    for _, slot in ipairs(ix.legal.commit_slots or {}) do
        legal_commit_slots_set[slot] = true
    end
    local armed_target_cards = {}
    local armed_target_manifest_slots = {}
    for _, ref in ipairs(ix.armed.targets or {}) do
        if ref.kind == "card" and ref.card_id then
            armed_target_cards[ref.card_id] = true
        elseif ref.kind == "slot" and ref.zone == "manifest" and ref.slot then
            armed_target_manifest_slots[ref.slot] = true
        end
    end

    return {
        legal_hand = (ix.phase == "await_complete" or ix.phase == "await_ready") and legal_hand[card_id] or false,
        armed_hand = ix.armed.hand_card_id == card_id,
        legal_commit_slot = (ix.phase == "await_complete" or ix.phase == "await_ready")
            and ix.armed.hand_card_id ~= nil
            and card.zone == "manifest" and card.slot and legal_commit_slots_set[card.slot]
            and (ix.phase ~= "await_ready" or card.slot == (app.game.committed and app.game.committed.slot))
            or false,
        legal_target_card = ix.phase == "await_target" and legal_target_cards[card_id] or false,
        armed_target_card = armed_target_cards[card_id] or false,
        legal_target_slot = ix.phase == "await_target" and ix.legal.targets.kind == "manifest_slot"
            and card.zone == "manifest" and legal_target_slots[card.slot] or false,
        armed_target_slot = card.zone == "manifest" and armed_target_manifest_slots[card.slot] or false,
    }
end

local function draw_card(app, card_id, rect)
    local card = app.game.cards[card_id]
    local flags = card_state_flags(app, card_id)
    local ca = OP_COLORS[card.op_a] or COLORS.card
    local cb = OP_COLORS[card.op_b] or COLORS.card
    local selected = flags.armed_hand or flags.armed_target_card or flags.armed_target_slot

    if selected then
        local phase = frame_breath_phase()
        local halo = lerp_color(ca, cb, phase)
        draw_breath_halo(rect, halo, phase, app.layout.scale)
    end

    if card.face_up then
        local dark_a = lerp_color(ca, COLORS.bg, 0.90)
        local dark_b = lerp_color(cb, COLORS.bg, 0.90)
        draw_with_rounded_mask(rect, 10, function()
            if card.class == "trump" then
                set_color(dark_a)
                love.graphics.rectangle("fill", rect.x, rect.y, rect.w * 0.5, rect.h)
                set_color(dark_b)
                love.graphics.rectangle("fill", rect.x + rect.w * 0.5, rect.y, rect.w * 0.5, rect.h)
                set_color(lerp_color(ca, cb, 0.5), 0.18)
                love.graphics.rectangle("fill", rect.x + rect.w * 0.47, rect.y + 4, rect.w * 0.06, rect.h - 8)
            else
                set_color(dark_a)
                love.graphics.polygon("fill", rect.x, rect.y, rect.x + rect.w, rect.y, rect.x, rect.y + rect.h)
                set_color(dark_b)
                love.graphics.polygon("fill", rect.x + rect.w, rect.y, rect.x + rect.w, rect.y + rect.h, rect.x, rect.y + rect.h)
            end
        end)
        set_color(selected and COLORS.select or lerp_color(ca, cb, 0.5))
        rounded("line", rect.x, rect.y, rect.w, rect.h, 10)
        set_color(COLORS.outline, 0.40)
        rounded("line", rect.x + 4, rect.y + 4, rect.w - 8, rect.h - 8, 8)

        love.graphics.setFont(app.fonts.small)
        set_color(COLORS.muted)
        love.graphics.printf(card.id, rect.x + 6, rect.y + 3 * app.layout.scale, rect.w - 12, "center")

        local gs = math.floor(15 * app.layout.scale)
        if card.class == "trump" then
            local pos = glyph_layout.trump_pos(rect)
            set_color(OP_COLORS[card.op_a] or COLORS.text)
            glyphs[card.op_a](pos.ax, pos.ay, gs)
            set_color(OP_COLORS[card.op_b] or COLORS.text)
            glyphs[card.op_b](pos.bx, pos.by, gs)
        else
            local pos = glyph_layout.minor_pos(rect)
            set_color(OP_COLORS[card.op_a] or COLORS.text)
            glyphs[card.op_a](pos.ax, pos.ay, gs)
            set_color(OP_COLORS[card.op_b] or COLORS.text)
            glyphs[card.op_b](pos.bx, pos.by, gs)
        end
    else
        set_color(COLORS.card_back)
        rounded("fill", rect.x, rect.y, rect.w, rect.h, 10)
        set_color(selected and COLORS.select or COLORS.card_back_alt)
        rounded("line", rect.x, rect.y, rect.w, rect.h, 10)
        if card.info_state == "known" then
            local gs = math.floor(15 * app.layout.scale)
            local pos = card.class == "trump" and glyph_layout.trump_pos(rect) or glyph_layout.minor_pos(rect)
            set_color(ca, 0.26)
            glyphs[card.op_a](pos.ax, pos.ay, gs)
            set_color(cb, 0.26)
            glyphs[card.op_b](pos.bx, pos.by, gs)
            set_color(lerp_color(ca, cb, 0.5), 0.42)
            rounded("line", rect.x + 3, rect.y + 3, rect.w - 6, rect.h - 6, 9)
        end
        love.graphics.setFont(app.fonts.body)
        set_color(COLORS.muted)
        love.graphics.printf(card.id, rect.x, rect.y + rect.h * 0.42, rect.w, "center")
    end

    if flags.legal_hand then
        set_color(COLORS.success, 0.95)
        rounded("line", rect.x - 3, rect.y - 3, rect.w + 6, rect.h + 6, 12)
    end
    if flags.legal_commit_slot then
        set_color(COLORS.drop, 0.95)
        love.graphics.setLineWidth(math.max(2, app.layout.scale * 2.5))
        rounded("line", rect.x - 3, rect.y - 3, rect.w + 6, rect.h + 6, 12)
        love.graphics.setLineWidth(1)
    end
    if flags.legal_target_card or flags.legal_target_slot then
        local op = app.interaction.armed.operator or "MANIFEST"
        local cc = OP_COLORS[op] or COLORS.accent
        local hot = lerp_color(cc, COLORS.text, 0.18)
        local frame = {
            x = rect.x - 5,
            y = rect.y - 5,
            w = rect.w + 10,
            h = rect.h + 10,
        }
        set_color(cc, 0.18)
        rounded("line", frame.x, frame.y, frame.w, frame.h, 14)
        draw_segmented_frame(frame, {cc, hot}, love.timer.getTime() / 3.04, {
            width = math.max(2, app.layout.scale * 2.35),
            segment_count = 14,
            duty = 0.56,
        })
    end
end

local function draw_zone_contents(app)
    local views = layout_lib.card_views(app.layout, app.game.zones)

    for _, zone_name in ipairs({"deck", "runtime", "play", "trump_flow", "trump", "targets", "manifest", "latent", "hand", "grave"}) do
        local zone = app.game.zones[zone_name]
        if zone.kind == "slots" then
            local rects = layout_lib.slot_rects_for_zone(app.layout, app.game.zones, zone_name)
            for slot, rect in ipairs(rects) do
                draw_slot_placeholder(app, rect, (zone_name == "runtime" or zone_name == "play") and "slot" or tostring(slot))
            end
        end

        if zone.kind == "slots" then
            for slot = 1, zone.slot_count do
                local card_id = zone.cards[slot]
                if card_id then
                    draw_card(app, card_id, views[card_id])
                end
            end
        else
            for _, card_id in ipairs(zone.cards) do
                if card_id then
                    draw_card(app, card_id, views[card_id])
                end
            end
        end
    end
end

local function draw_operator_buttons(app)
    if #app.ui.operator_buttons == 0 then
        return
    end
    for _, button in ipairs(app.ui.operator_buttons) do
        local armed = app.interaction.armed.operator == button.op_name
        local op_color = OP_COLORS[button.op_name] or COLORS.text
        set_color(armed and COLORS.panel or COLORS.panel_alt)
        rounded("fill", button.rect.x, button.rect.y, button.rect.w, button.rect.h, 12)
        set_color(armed and op_color or COLORS.accent_soft)
        rounded("line", button.rect.x, button.rect.y, button.rect.w, button.rect.h, 12)
        set_color(op_color)
        love.graphics.setLineWidth(math.max(2, app.layout.scale * 2))
        glyphs[button.op_name](
            button.rect.x + button.rect.w * 0.5,
            button.rect.y + button.rect.h * 0.5 + math.floor(6 * app.layout.scale),
            math.floor(18 * app.layout.scale)
        )
    end
end

local function draw_grave_viewer(app)
    if not app.ui.grave_open then
        return
    end
    local viewer = app.ui.grave_viewer
    local rect = viewer.rect
    local content = viewer.content_rect
    if not rect or not content then
        return
    end
    set_color(COLORS.panel_alt)
    rounded("fill", rect.x, rect.y, rect.w, rect.h, 14)
    set_color(COLORS.outline)
    rounded("line", rect.x, rect.y, rect.w, rect.h, 14)
    love.graphics.setFont(app.fonts.title)
    set_color(COLORS.text)
    love.graphics.print("GRAVE", rect.x + 18 * app.layout.scale, rect.y + 12 * app.layout.scale)
    love.graphics.setFont(app.fonts.small)
    set_color(COLORS.muted)
    love.graphics.print("Newest first. Click outside to close.", rect.x + 18 * app.layout.scale, rect.y + 32 * app.layout.scale)
    for _, card_id in ipairs(viewer.ordered_cards or {}) do
        local card_rect = viewer.card_rects[card_id]
        if card_rect then
            draw_card(app, card_id, card_rect)
            love.graphics.setFont(app.fonts.small)
            set_color(COLORS.muted, 0.92)
            love.graphics.printf(tostring(card_rect.order), card_rect.x, card_rect.y + card_rect.h - 16 * app.layout.scale, card_rect.w - 4 * app.layout.scale, "right")
        end
    end
end

local function draw_system_panel(app)
    local rect = app.layout.right.system
    draw_panel(app, rect, "SYSTEM", nil)
    love.graphics.setFont(app.fonts.small)
    set_color(COLORS.text)
    local lines = {
        "Phase: " .. tostring(app.interaction.phase),
        "Deck: " .. #app.game.zones.deck.cards,
        "Hand: " .. #app.game.zones.hand.cards,
        "Grave: " .. #app.game.zones.grave.cards,
        "TrumpFlow: " .. #app.game.zones.trump_flow.cards,
        "Advance: " .. ((app.interaction.advance and app.interaction.advance.enabled) and "yes" or "no"),
    }
    local y = rect.y + 18 * app.layout.scale
    for _, line in ipairs(lines) do
        love.graphics.print(line, rect.x + 14 * app.layout.scale, y)
        y = y + 11 * app.layout.scale
    end
end

local function draw_log_panel(app)
    local rect = app.layout.right.log
    draw_panel(app, rect, "LOG", nil)
    love.graphics.setScissor(rect.x, rect.y, rect.w, rect.h)
    love.graphics.setFont(app.fonts.small)
    local y = rect.y + 20 * app.layout.scale
    for _, line in ipairs(app.log) do
        set_color(COLORS.text)
        love.graphics.printf(line, rect.x + 12 * app.layout.scale, y, rect.w - 24 * app.layout.scale, "left")
        y = y + 15 * app.layout.scale
        if y > rect.y + rect.h - 16 * app.layout.scale then
            break
        end
    end
    love.graphics.setScissor()
end

local function draw_footer(app)
    for _, button in ipairs(app.ui.footer_buttons) do
        local active = button.id == "start" or button.id == "reset" or button.id == "draw"
        local tint = active and COLORS.accent_soft or COLORS.outline
        set_color(active and COLORS.panel_alt or COLORS.panel)
        rounded("fill", button.rect.x, button.rect.y, button.rect.w, button.rect.h, 12)
        set_color(tint)
        rounded("line", button.rect.x, button.rect.y, button.rect.w, button.rect.h, 12)
        love.graphics.setFont(app.fonts.body)
        set_color(COLORS.text)
        love.graphics.printf(button.label, button.rect.x, button.rect.y + 8 * app.layout.scale, button.rect.w, "center")
        love.graphics.setFont(app.fonts.small)
        set_color(COLORS.muted)
        love.graphics.printf(button.hint, button.rect.x, button.rect.y + 24 * app.layout.scale, button.rect.w, "center")
    end

    love.graphics.setFont(app.fonts.small)
    set_color(COLORS.muted)
    local help = "S Start Game  1 Draw  Space △ advance  G open grave  R reset"
    love.graphics.print(help, app.layout.footer.x + math.floor(760 * app.layout.scale), app.layout.footer.y + 14 * app.layout.scale)
end

local function draw_top_header(app)
    love.graphics.setFont(app.fonts.big)
    set_color(COLORS.text)
    love.graphics.print("PROCESSCARDS", app.layout.margin, 2 * app.layout.scale)
    set_color(COLORS.accent)
    love.graphics.print("GAME", app.layout.margin + 182 * app.layout.scale, 2 * app.layout.scale)
    love.graphics.setFont(app.fonts.small)
    set_color(COLORS.muted)
    love.graphics.print(app.message or app.interaction.prompt or "", app.layout.margin + 240 * app.layout.scale, 7 * app.layout.scale)
end

local function build_footer_buttons(app)
    local footer = app.layout.footer
    local s = app.layout.scale
    local labels = {
        {id = "start", label = "Start Game", hint = "[S]"},
        {id = "draw", label = "Draw", hint = "[1]"},
        {id = "reset", label = "Reset", hint = "[R]"},
    }
    local buttons = {}
    local bw = math.floor(176 * s)
    local bh = math.floor(42 * s)
    local gap = math.floor(10 * s)
    local x = footer.x
    for _, spec in ipairs(labels) do
        buttons[#buttons + 1] = {
            id = spec.id,
            label = spec.label,
            hint = spec.hint,
            rect = {x = x, y = footer.y, w = bw, h = bh},
        }
        x = x + bw + gap
    end
    app.ui.footer_buttons = buttons
end

local function build_operator_buttons(app)
    app.ui.operator_buttons = {}
    local ix = app.interaction
    local ops = {}
    if ix.phase == "await_operator" then
        ops = ix.legal.operators or {}
    elseif ix.armed.operator then
        ops = {ix.armed.operator}
    end
    if #ops == 0 then
        return
    end
    local anchor = app.layout.left.play
    local bw = math.floor(72 * app.layout.scale)
    local bh = math.floor(82 * app.layout.scale)
    local gap = math.floor(12 * app.layout.scale)
    local total = #ops * bw + (#ops - 1) * gap
    local x = anchor.x + math.floor((anchor.w - total) / 2)
    local y = anchor.y - bh - math.floor(18 * app.layout.scale)
    for _, op_name in ipairs(ops) do
        app.ui.operator_buttons[#app.ui.operator_buttons + 1] = {
            op_name = op_name,
            rect = {x = x, y = y, w = bw, h = bh},
        }
        x = x + bw + gap
    end
end

function M.draw(app)
    app.ui.grave_viewer = layout_lib.compute_grave_viewer(app.layout, app.game.zones)
    build_footer_buttons(app)
    build_operator_buttons(app)

    love.graphics.setBackgroundColor(COLORS.bg)
    love.graphics.clear()

    draw_top_header(app)
    draw_panel(app, app.layout.left.deck, "DECK", nil)
    draw_panel_counter(app, app.layout.left.deck, tostring(#app.game.zones.deck.cards), {
        align = "right",
        width = 88 * app.layout.scale,
        y = app.layout.left.deck.y + 54 * app.layout.scale,
        font = app.fonts.body,
        alpha = 0.96,
    })
    draw_panel(app, app.layout.left.play, "PLAY", "1 slot")
    draw_panel(app, app.layout.left.runtime, "RUNTIME", "1 slot")
    draw_panel(app, app.layout.center.trump_flow, "TRUMP FLOW", "3 visible slots")
    draw_panel(app, app.layout.center.targets, "TARGETS", "3 slots")
    draw_panel(app, app.layout.center.trump, "TRUMP ZONE", "2 slots")
    draw_panel(app, app.layout.center.combined, "MANIFEST / LATENT", nil)
    draw_panel(app, app.layout.center.hand, "HAND", nil)
    draw_panel(app, app.layout.right.grave, "GRAVE", "Ordered discard pile")
    draw_panel_counter(app, app.layout.right.grave, tostring(#app.game.zones.grave.cards), {
        align = "right",
        width = 88 * app.layout.scale,
        y = app.layout.right.grave.y + app.layout.right.grave.h - 34 * app.layout.scale,
        font = app.fonts.body,
        alpha = 0.96,
    })

    local divider = app.layout.center.divider
    set_color(COLORS.outline)
    love.graphics.line(divider.x + 14 * app.layout.scale, divider.y + divider.h * 0.5, divider.x + divider.w - 14 * app.layout.scale, divider.y + divider.h * 0.5)
    love.graphics.setFont(app.fonts.small)
    set_color(COLORS.muted)
    love.graphics.print("Manifest", divider.x + 12 * app.layout.scale, app.layout.center.manifest.y + 24 * app.layout.scale)
    love.graphics.print("Latent", divider.x + 12 * app.layout.scale, app.layout.center.latent.y + 14 * app.layout.scale)

    draw_zone_contents(app)
    draw_system_panel(app)
    draw_log_panel(app)
    draw_footer(app)
    draw_operator_buttons(app)
    if app.ui.grave_open then
        draw_grave_viewer(app)
    end
end

return M
