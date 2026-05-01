local theme = require("src.manifest.theme")

local M = {}

local function scale()
    local w, h = love.graphics.getDimensions()
    return math.min(w / theme.BASE_W, h / theme.BASE_H)
end

function M.make_layout()
    local s = scale()
    local w, h = love.graphics.getDimensions()
    local m = math.floor(16 * s)
    local gap = math.floor(14 * s)
    local left_w = math.floor(188 * s)
    local right_w = math.floor(240 * s)
    local top_bar_h = math.floor(34 * s)
    local top_h = math.floor(116 * s)
    local deck_h = math.floor(286 * s)
    local status_h = math.floor(78 * s)
    local grave_h = math.floor(146 * s)
    local hand_h = math.floor(164 * s)
    local bottom_h = hand_h
    local center_x = m + left_w + gap
    local center_w = w - center_x - right_w - m - gap
    local left_x = m
    local right_x = w - m - right_w
    local flow_w = math.floor(244 * s)
    local target_w = math.floor(300 * s)
    local trump_w = math.floor(190 * s)
    local table_w = math.floor(670 * s)
    local table_x = center_x + math.floor((center_w - table_w) / 2) - math.floor(10 * s)
    local top_group_gap = math.floor(18 * s)
    local top_group_w = flow_w + top_group_gap + target_w + top_group_gap + trump_w
    local flow_x = center_x + math.floor((center_w - top_group_w) / 2)
    local target_x = flow_x + flow_w + top_group_gap
    local trump_x = target_x + target_w + top_group_gap
    local combined_h = math.floor(298 * s)
    local manifest_h = math.floor(140 * s)
    local divider_h = math.floor(18 * s)
    local latent_h = combined_h - manifest_h - divider_h
    local y1 = m + top_bar_h
    local y2 = y1 + top_h + gap
    local footer_h = math.floor(44 * s)
    local y3 = h - m - footer_h - gap - bottom_h
    local right_mid_y = y1 + status_h + gap
    local right_log_h = y3 - gap - right_mid_y
    local runtime_w = math.floor(170 * s)
    local play_y = y1 + deck_h + gap
    local play_h = y3 - gap - play_y

    return {
        scale = s,
        w = w,
        h = h,
        margin = m,
        gap = gap,
        card_w = math.floor(82 * s),
        card_h = math.floor(118 * s),
        top_bar_h = top_bar_h,
        left = {
            deck = {x = left_x, y = y1, w = left_w, h = deck_h},
            play = {x = left_x, y = play_y, w = left_w, h = play_h},
            runtime = {x = left_x, y = y3, w = runtime_w, h = bottom_h},
        },
        center = {
            trump_flow = {x = flow_x, y = y1, w = flow_w, h = top_h},
            targets = {x = target_x, y = y1, w = target_w, h = top_h},
            trump = {x = trump_x, y = y1, w = trump_w, h = top_h},
            combined = {x = table_x, y = y2, w = table_w, h = combined_h},
            manifest = {x = table_x, y = y2, w = table_w, h = manifest_h},
            divider = {x = table_x, y = y2 + manifest_h, w = table_w, h = divider_h},
            latent = {x = table_x, y = y2 + manifest_h + divider_h, w = table_w, h = latent_h},
            hand = {x = left_x + runtime_w + gap, y = y3, w = right_x - gap - (left_x + runtime_w + gap), h = hand_h},
        },
        right = {
            system = {x = right_x, y = y1, w = right_w, h = status_h},
            log = {x = right_x, y = right_mid_y, w = right_w, h = right_log_h},
            grave = {x = right_x, y = y3, w = right_w, h = grave_h},
        },
        footer = {x = m, y = h - m - footer_h, w = w - m * 2, h = footer_h},
    }
end

function M.get_zone_rect(layout, name)
    if name == "deck" then return layout.left.deck end
    if name == "play" then return layout.left.play end
    if name == "runtime" then return layout.left.runtime end
    if name == "trump_flow" then return layout.center.trump_flow end
    if name == "trump" then return layout.center.trump end
    if name == "targets" then return layout.center.targets end
    if name == "manifest" then return layout.center.manifest end
    if name == "latent" then return layout.center.latent end
    if name == "hand" then return layout.center.hand end
    if name == "grave" then return layout.right.grave end
    return nil
end

function M.slot_rects_for_zone(layout, zones, name)
    local zone = zones[name]
    if not zone or zone.kind ~= "slots" then
        return {}
    end

    local rect = M.get_zone_rect(layout, name)
    local cw = layout.card_w
    local ch = layout.card_h
    local gap = math.floor(14 * layout.scale)
    if name == "manifest" or name == "latent" then
        gap = math.floor(20 * layout.scale)
    elseif name == "targets" or name == "trump" then
        gap = math.floor(12 * layout.scale)
    end
    local total_w = zone.slot_count * cw + (zone.slot_count - 1) * gap
    local start_x = rect.x + math.floor((rect.w - total_w) / 2)
    local y = rect.y + rect.h - ch - math.floor(10 * layout.scale)
    local result = {}

    if name == "targets" then
        y = rect.y + math.floor((rect.h - ch) / 2)
    elseif name == "latent" then
        y = rect.y + math.floor((rect.h - ch) / 2) + math.floor(2 * layout.scale)
    elseif name == "trump" or name == "runtime" or name == "play" then
        y = rect.y + math.floor((rect.h - ch) / 2)
        start_x = rect.x + math.floor((rect.w - total_w) / 2)
    elseif name == "manifest" then
        y = rect.y + math.floor((rect.h - ch) / 2) + math.floor(6 * layout.scale)
    end

    for i = 1, zone.slot_count do
        result[i] = {x = start_x + (i - 1) * (cw + gap), y = y, w = cw, h = ch}
    end
    return result
end

function M.card_views(layout, zones)
    local views = {}
    local cw = layout.card_w
    local ch = layout.card_h

    local deck_rect = M.get_zone_rect(layout, "deck")
    local deck_count = #zones.deck.cards
    for i, card_id in ipairs(zones.deck.cards) do
        local stack_idx = math.min(deck_count - i, 4)
        views[card_id] = {
            x = deck_rect.x + math.floor(24 * layout.scale) + stack_idx * math.floor(2 * layout.scale),
            y = deck_rect.y + math.floor(28 * layout.scale) + stack_idx * math.floor(2 * layout.scale),
            w = cw,
            h = ch,
        }
    end

    local grave_rect = M.get_zone_rect(layout, "grave")
    local grave_count = #zones.grave.cards
    for i, card_id in ipairs(zones.grave.cards) do
        local stack_idx = math.min(grave_count - i, 4)
        views[card_id] = {
            x = grave_rect.x + math.floor(20 * layout.scale) + stack_idx * math.floor(2 * layout.scale),
            y = grave_rect.y + math.floor(12 * layout.scale) + stack_idx * math.floor(2 * layout.scale),
            w = cw,
            h = ch,
        }
    end

    for _, zone_name in ipairs({"runtime", "play", "trump", "targets", "manifest", "latent"}) do
        local rects = M.slot_rects_for_zone(layout, zones, zone_name)
        local zone = zones[zone_name]
        for slot = 1, zone.slot_count do
            local card_id = zone.cards[slot]
            if card_id then
                local r = rects[slot]
                views[card_id] = {x = r.x, y = r.y, w = r.w, h = r.h}
            end
        end
    end

    local flow_rect = M.get_zone_rect(layout, "trump_flow")
    local flow = zones.trump_flow.cards
    local count = #flow
    local visible_slots = 3
    local slot_gap = math.floor(12 * layout.scale)
    local slot_total = visible_slots * cw + (visible_slots - 1) * slot_gap
    local slot_start = flow_rect.x + math.floor((flow_rect.w - slot_total) / 2)
    local y = flow_rect.y + math.floor((flow_rect.h - ch) / 2)
    local overlap_gap = math.floor(22 * layout.scale)
    local used_gap = count <= visible_slots and slot_gap or overlap_gap
    local total_w = count > 0 and (cw + (count - 1) * used_gap) or 0
    local start_x = count <= visible_slots and slot_start or (flow_rect.x + math.floor((flow_rect.w - total_w) / 2))
    for i, card_id in ipairs(flow) do
        views[card_id] = {x = start_x + (i - 1) * used_gap, y = y, w = cw, h = ch}
    end

    local hand_rect = M.get_zone_rect(layout, "hand")
    count = #zones.hand.cards
    local gap = math.floor(12 * layout.scale)
    local max_total = hand_rect.w - math.floor(28 * layout.scale)
    local used_gap = gap
    if count > 1 then
        local natural_total = count * cw + (count - 1) * gap
        if natural_total > max_total then
            used_gap = math.max(math.floor((max_total - count * cw) / math.max(count - 1, 1)), math.floor(-cw * 0.35))
        end
    end
    local total_w2 = count > 0 and (count * cw + (count - 1) * used_gap) or 0
    local start_x2 = hand_rect.x + math.floor((hand_rect.w - total_w2) / 2)
    local y2 = hand_rect.y + hand_rect.h - ch - math.floor(14 * layout.scale)
    for i, card_id in ipairs(zones.hand.cards) do
        views[card_id] = {x = start_x2 + (i - 1) * (cw + used_gap), y = y2, w = cw, h = ch}
    end

    return views
end

function M.point_in_rect(x, y, rect)
    return rect and x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

function M.compute_grave_viewer(layout, zones)
    local s = layout.scale
    local overlay = {
        x = layout.margin + math.floor(72 * s),
        y = layout.margin + layout.top_bar_h + math.floor(18 * s),
        w = layout.w - (layout.margin + math.floor(72 * s)) * 2,
        h = layout.h - (layout.margin + layout.top_bar_h + math.floor(18 * s)) - (layout.footer.h + layout.margin + math.floor(18 * s)),
    }
    local content = {
        x = overlay.x + math.floor(18 * s),
        y = overlay.y + math.floor(54 * s),
        w = overlay.w - math.floor(36 * s),
        h = overlay.h - math.floor(72 * s),
    }

    local ordered = {}
    for i = #zones.grave.cards, 1, -1 do
        ordered[#ordered + 1] = zones.grave.cards[i]
    end

    local count = #ordered
    local card_rects = {}
    if count > 0 then
        local aspect = layout.card_w / layout.card_h
        local gap = math.max(4, math.floor(8 * s))
        local best = nil
        for cols = 1, count do
            local rows = math.ceil(count / cols)
            local max_w = (content.w - gap * (cols - 1)) / cols
            local max_h = (content.h - gap * (rows - 1)) / rows
            if max_w > 0 and max_h > 0 then
                local card_w = math.min(max_w, max_h * aspect)
                local card_h = card_w / aspect
                if card_w > 0 and card_h > 0 then
                    local area = card_w * card_h
                    if not best or area > best.area then
                        best = {cols = cols, rows = rows, card_w = math.floor(card_w), card_h = math.floor(card_h), gap = gap, area = area}
                    end
                end
            end
        end
        if best then
            local total_w = best.cols * best.card_w + (best.cols - 1) * best.gap
            local total_h = best.rows * best.card_h + (best.rows - 1) * best.gap
            local start_x = content.x + math.floor((content.w - total_w) / 2)
            local start_y = content.y + math.floor((content.h - total_h) / 2)
            for idx, card_id in ipairs(ordered) do
                local col = (idx - 1) % best.cols
                local row = math.floor((idx - 1) / best.cols)
                card_rects[card_id] = {
                    x = start_x + col * (best.card_w + best.gap),
                    y = start_y + row * (best.card_h + best.gap),
                    w = best.card_w,
                    h = best.card_h,
                    order = idx,
                }
            end
        end
    end

    return {
        rect = overlay,
        content_rect = content,
        ordered_cards = ordered,
        card_rects = card_rects,
    }
end

return M
