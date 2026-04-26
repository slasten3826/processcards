-- ProcessCards layer 1 runtime
-- Documented sources:
-- docs/crystall/LAYER1_BOARD_SKELETON_SPEC.md
-- docs/crystall/BOARD_ENGINE_SKELETON_TZ.md
-- docs/crystall/LAYERED_PROJECT_POLICY.md
-- docs/crystall/PLATFORM_REQUIREMENTS.md
-- docs/crystall/PORTABILITY_CONSTRAINTS.md
-- docs/crystall/FIRST_PROTOTYPE_VISUAL_TARGET.md
-- docs/table/DECK_AND_SETUP_LAW.md
-- docs/crystall/START_GAME_FLOW.md
-- docs/table/HAND_AND_PLAY_LAW.md
-- docs/table/CHAIN_SURFACE_LAW.md
-- docs/table/RESOLUTION_ORDER_LAW.md
-- docs/table/GRAVE_LAW.md
-- docs/table/TRUMP_EVENT_MINIMAL_LAW.md
-- docs/crystall/GAMEPLAY_ANIMATION_LAYER.md
-- docs/crystall/NEXT_GAMEPLAY_SLICE.md

local glyphs = require("src.glyphs")
local glyph_layout = require("src.glyph_layout")

local BASE_W = 1280
local BASE_H = 720

local COLORS = {
    bg = {0.05, 0.08, 0.10},
    panel = {0.09, 0.12, 0.15},
    panel_alt = {0.11, 0.14, 0.17},
    outline = {0.28, 0.31, 0.35},
    muted = {0.55, 0.59, 0.63},
    text = {0.92, 0.92, 0.90},
    accent = {0.95, 0.46, 0.20},
    accent_soft = {0.78, 0.47, 0.28},
    success = {0.32, 0.72, 0.46},
    danger = {0.80, 0.34, 0.30},
    card = {0.90, 0.87, 0.80},
    card_text = {0.14, 0.16, 0.18},
    card_back = {0.13, 0.16, 0.18},
    card_back_alt = {0.22, 0.26, 0.29},
    select = {0.35, 0.68, 0.96},
    drop = {0.92, 0.60, 0.24},
}

local OPERATORS = {
    "FLOW",
    "CONNECT",
    "DISSOLVE",
    "ENCODE",
    "CHOOSE",
    "OBSERVE",
    "LOGIC",
    "CYCLE",
    "RUNTIME",
    "MANIFEST",
}

local TRUMP_CANON = {
    {"FLOW", "CONNECT"},
    {"FLOW", "DISSOLVE"},
    {"FLOW", "OBSERVE"},
    {"CONNECT", "DISSOLVE"},
    {"CONNECT", "OBSERVE"},
    {"CONNECT", "ENCODE"},
    {"DISSOLVE", "OBSERVE"},
    {"DISSOLVE", "CHOOSE"},
    {"OBSERVE", "ENCODE"},
    {"OBSERVE", "CHOOSE"},
    {"OBSERVE", "RUNTIME"},
    {"ENCODE", "CHOOSE"},
    {"ENCODE", "RUNTIME"},
    {"ENCODE", "CYCLE"},
    {"CHOOSE", "RUNTIME"},
    {"CHOOSE", "LOGIC"},
    {"LOGIC", "CYCLE"},
    {"LOGIC", "RUNTIME"},
    {"LOGIC", "MANIFEST"},
    {"CYCLE", "RUNTIME"},
    {"CYCLE", "MANIFEST"},
    {"RUNTIME", "MANIFEST"},
}

local TRUMP_NAMES = {
    [1] = "FOOL",
    [2] = "EJECT",
    [14] = "SHUFFLE",
    [16] = "RECAST",
    [17] = "RESET",
    [21] = "UNVEIL",
    [22] = "HALT",
}

local OP_COLORS = {
    FLOW = {0.22, 0.82, 0.82},
    CONNECT = {0.90, 0.78, 0.22},
    DISSOLVE = {0.63, 0.44, 0.88},
    ENCODE = {0.25, 0.49, 0.90},
    CHOOSE = {0.82, 0.26, 0.26},
    OBSERVE = {0.86, 0.86, 0.84},
    LOGIC = {0.34, 0.68, 0.32},
    CYCLE = {0.84, 0.49, 0.18},
    RUNTIME = {0.18, 0.20, 0.24},
    MANIFEST = {0.86, 0.68, 0.26},
}

local TOPOLOGY_ADJ = {}
for _, op in ipairs(OPERATORS) do
    TOPOLOGY_ADJ[op] = {[op] = true}
end
for _, pair in ipairs(TRUMP_CANON) do
    local a, b = pair[1], pair[2]
    TOPOLOGY_ADJ[a][b] = true
    TOPOLOGY_ADJ[b][a] = true
end

local state = {
    mode = "DEV",
    selected = nil,
    pending_play = nil,
    hints_enabled = true,
    committed = nil,
    legal_hints = {},
    hover_target = nil,
    drag = nil,
    cards = {},
    zones = {},
    log = {},
    message = "DEV mode: free structural card manipulation.",
    layout = nil,
    layout_w = nil,
    layout_h = nil,
    fonts = {},
    ui = {
        buttons = {},
    },
    anim = {
        queue = {},
        active = nil,
        locked = false,
        ghost = nil,
    },
}

local ZONE_META = {
    deck = {title = "DECK", kind = "stack"},
    runtime = {title = "RUNTIME", kind = "slots", slot_count = 1},
    trump = {title = "TRUMP ZONE", kind = "slots", slot_count = 2},
    targets = {title = "TARGETS", kind = "slots", slot_count = 3},
    manifest = {title = "MANIFEST", kind = "slots", slot_count = 5},
    latent = {title = "LATENT", kind = "slots", slot_count = 5},
    hand = {title = "HAND", kind = "fan"},
    grave = {title = "GRAVE", kind = "stack"},
}

local minor_pair_from_index
local trump_pair_from_index

local function push_log(text)
    table.insert(state.log, 1, text)
    if #state.log > 24 then
        table.remove(state.log)
    end
end

local function init_fonts()
    state.fonts.small = love.graphics.newFont(11)
    state.fonts.body = love.graphics.newFont(15)
    state.fonts.title = love.graphics.newFont(18)
    state.fonts.big = love.graphics.newFont(22)
end

local function scale()
    local w, h = love.graphics.getDimensions()
    return math.min(w / BASE_W, h / BASE_H)
end

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

local function new_zone(name, cards)
    local meta = ZONE_META[name]
    return {
        name = name,
        title = meta.title,
        kind = meta.kind,
        slot_count = meta.slot_count or 0,
        cards = cards or {},
    }
end

local function clear_runtime_state()
    state.selected = nil
    state.pending_play = nil
    state.committed = nil
    state.legal_hints = {}
    state.hover_target = nil
    state.drag = nil
    state.cards = {}
    state.zones = {
        deck = new_zone("deck"),
        runtime = new_zone("runtime", {nil}),
        trump = new_zone("trump", {nil, nil}),
        targets = new_zone("targets", {nil, nil, nil}),
        manifest = new_zone("manifest", {nil, nil, nil, nil, nil}),
        latent = new_zone("latent", {nil, nil, nil, nil, nil}),
        hand = new_zone("hand"),
        grave = new_zone("grave"),
    }
    state.anim.queue = {}
    state.anim.active = nil
    state.anim.locked = false
    state.anim.ghost = nil
end

local function sync_zone_cards(zone_name)
    local zone = state.zones[zone_name]
    if zone.kind == "slots" then
        for slot = 1, zone.slot_count do
            local card_id = zone.cards[slot]
            if card_id then
                local card = state.cards[card_id]
                card.zone = zone_name
                card.slot = slot
            end
        end
    else
        for index, card_id in ipairs(zone.cards) do
            local card = state.cards[card_id]
            card.zone = zone_name
            card.slot = index
        end
    end
end

local function create_card(id, class, op_a, op_b)
    state.cards[id] = {
        id = id,
        class = class or "minor",
        op_a = op_a,
        op_b = op_b,
        face_up = false,
        zone = nil,
        slot = nil,
    }
    return id
end

local function create_minor_card(index)
    local id = string.format("MINOR-%d", index)
    local op_a, op_b = minor_pair_from_index(index)
    create_card(id, "minor", op_a, op_b)
    return id
end

local function create_trump_card(index)
    local id = string.format("TRUMP-%d", index)
    local op_a, op_b = trump_pair_from_index(index)
    create_card(id, "trump", op_a, op_b)
    state.cards[id].trump_name = TRUMP_NAMES[index]
    return id
end

local function append_minor_deck(target)
    for i = 1, 100 do
        table.insert(target, create_minor_card(i))
    end
end

local function append_trump_deck(target)
    for i = 1, 22 do
        table.insert(target, create_trump_card(i))
    end
end

local function remove_from_current_zone(card_id)
    local card = state.cards[card_id]
    if not card.zone then
        return
    end

    local zone = state.zones[card.zone]
    if zone.kind == "slots" then
        zone.cards[card.slot] = nil
    else
        table.remove(zone.cards, card.slot)
    end

    card.zone = nil
    card.slot = nil
    sync_zone_cards(zone.name)
end

local function structural_accepts(zone_name, slot)
    local zone = state.zones[zone_name]
    if zone.kind == "slots" then
        if not slot or slot < 1 or slot > zone.slot_count then
            return false
        end
        return zone.cards[slot] == nil
    end
    return true
end

local function first_open_slot(zone_name)
    local zone = state.zones[zone_name]
    if zone.kind ~= "slots" then
        return nil
    end
    for i = 1, zone.slot_count do
        if zone.cards[i] == nil then
            return i
        end
    end
    return nil
end

local function place_card(card_id, zone_name, slot)
    local zone = state.zones[zone_name]
    if zone.kind == "slots" then
        zone.cards[slot] = card_id
    else
        table.insert(zone.cards, card_id)
    end
    sync_zone_cards(zone_name)
end

local function move_card(card_id, zone_name, slot, reason)
    if not structural_accepts(zone_name, slot) then
        state.message = "Invalid structural placement."
        push_log("Rejected move for " .. card_id .. " -> " .. zone_name .. ".")
        return false
    end

    local from_zone = state.cards[card_id].zone
    remove_from_current_zone(card_id)
    place_card(card_id, zone_name, slot)

    local label = card_id .. " -> " .. zone_name
    if slot then
        label = label .. "[" .. slot .. "]"
    end
    if reason then
        label = label .. " (" .. reason .. ")"
    end
    state.message = label
    push_log(label)

    if from_zone == "deck" and zone_name == "hand" then
        state.cards[card_id].face_up = true
    elseif zone_name == "grave" then
        state.cards[card_id].face_up = true
    end

    return true
end

local function build_empty_surface()
    state.log = {}
    state.message = "DEV mode: free structural card manipulation."
    state.mode = "DEV"
    clear_runtime_state()

    push_log("Layer 1 board skeleton booted.")
    push_log("DEV mode active. Gameplay legality is deferred.")
end

local function shuffle_in_place(list)
    for i = #list, 2, -1 do
        local j = love.math.random(i)
        list[i], list[j] = list[j], list[i]
    end
end

minor_pair_from_index = function(index)
    local zero = index - 1
    local a = math.floor(zero / #OPERATORS) + 1
    local b = (zero % #OPERATORS) + 1
    return OPERATORS[a], OPERATORS[b]
end

trump_pair_from_index = function(index)
    local pair = TRUMP_CANON[index]
    return pair[1], pair[2]
end

local function build_full_temp_deck()
    clear_runtime_state()
    append_minor_deck(state.zones.deck.cards)
    append_trump_deck(state.zones.deck.cards)
    sync_zone_cards("deck")
end

local function deal_from_deck(zone_name, slot, face_up)
    local deck = state.zones.deck.cards
    if #deck == 0 then
        return nil
    end

    local card_id = deck[#deck]
    move_card(card_id, zone_name, slot, "setup")
    state.cards[card_id].face_up = face_up
    return card_id
end

local function start_game()
    state.log = {}
    state.message = "Start Game: building two-phase setup."
    state.mode = "GAMEPLAY"
    clear_runtime_state()

    append_minor_deck(state.zones.deck.cards)

    shuffle_in_place(state.zones.deck.cards)
    sync_zone_cards("deck")

    for slot = 1, 5 do
        deal_from_deck("manifest", slot, true)
    end

    for _ = 1, 5 do
        deal_from_deck("hand", nil, true)
    end

    append_trump_deck(state.zones.deck.cards)

    shuffle_in_place(state.zones.deck.cards)
    sync_zone_cards("deck")

    deal_from_deck("targets", 1, false)
    deal_from_deck("targets", 2, false)
    deal_from_deck("targets", 3, false)

    for slot = 1, 5 do
        deal_from_deck("latent", slot, false)
    end

    state.selected = nil
    state.hover_target = nil
    state.drag = nil
    state.message = "Start Game complete: two-phase opening board ready."
    push_log("Start Game complete.")
    push_log("Phase A: 100 minors -> 5 manifest, 5 hand.")
    push_log("Phase B: +22 trumps -> 3 targets, 5 latent.")
    push_log("Deck now holds 104 cards.")
end

local function zone_counts()
    return {
        deck = #state.zones.deck.cards,
        hand = #state.zones.hand.cards,
        grave = #state.zones.grave.cards,
    }
end

local function rect_copy(rect)
    return {x = rect.x, y = rect.y, w = rect.w, h = rect.h}
end

local function make_layout()
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
    local target_w = math.floor(300 * s)
    local trump_w = math.floor(190 * s)
    local table_w = math.floor(670 * s)
    local table_x = center_x + math.floor((center_w - table_w) / 2) - math.floor(10 * s)
    local target_x = center_x + math.floor((center_w - target_w) / 2)
    local trump_x = right_x - trump_w - math.floor(20 * s)
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

    return {
        scale = s,
        margin = m,
        gap = gap,
        card_w = math.floor(82 * s),
        card_h = math.floor(118 * s),
        top_bar_h = top_bar_h,
        left = {
            deck = {x = left_x, y = y1, w = left_w, h = deck_h},
            runtime = {x = left_x, y = y3, w = runtime_w, h = bottom_h},
        },
        center = {
            top = {x = target_x, y = y1, w = (trump_x + trump_w) - target_x, h = top_h},
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

local function get_zone_rect(name)
    local l = state.layout
    if name == "deck" then return l.left.deck end
    if name == "runtime" then return l.left.runtime end
    if name == "trump" then return l.center.trump end
    if name == "targets" then return l.center.targets end
    if name == "manifest" then return l.center.manifest end
    if name == "latent" then return l.center.latent end
    if name == "hand" then return l.center.hand end
    if name == "grave" then return l.right.grave end
    return nil
end

local function slot_rects_for_zone(name)
    local zone = state.zones[name]
    if zone.kind ~= "slots" then
        return {}
    end

    local rect = get_zone_rect(name)
    local cw = state.layout.card_w
    local ch = state.layout.card_h
    local gap = math.floor(14 * state.layout.scale)
    if name == "manifest" or name == "latent" then
        gap = math.floor(20 * state.layout.scale)
    elseif name == "targets" or name == "trump" then
        gap = math.floor(12 * state.layout.scale)
    end
    local total_w = zone.slot_count * cw + (zone.slot_count - 1) * gap
    local start_x = rect.x + math.floor((rect.w - total_w) / 2)
    local y = rect.y + rect.h - ch - math.floor(10 * state.layout.scale)
    local result = {}

    if name == "targets" then
        y = rect.y + math.floor((rect.h - ch) / 2)
    elseif name == "latent" then
        y = rect.y + math.floor((rect.h - ch) / 2) + math.floor(2 * state.layout.scale)
    elseif name == "trump" or name == "runtime" then
        y = rect.y + math.floor((rect.h - ch) / 2)
        start_x = rect.x + math.floor((rect.w - total_w) / 2)
    elseif name == "manifest" then
        y = rect.y + math.floor((rect.h - ch) / 2) + math.floor(6 * state.layout.scale)
    end

    for i = 1, zone.slot_count do
        result[i] = {x = start_x + (i - 1) * (cw + gap), y = y, w = cw, h = ch}
    end
    return result
end

local function card_views()
    local views = {}
    local cw = state.layout.card_w
    local ch = state.layout.card_h

    local deck_rect = get_zone_rect("deck")
    local deck_count = #state.zones.deck.cards
    for i, card_id in ipairs(state.zones.deck.cards) do
        local stack_idx = math.min(deck_count - i, 4)
        views[card_id] = {
            x = deck_rect.x + math.floor(24 * state.layout.scale) + stack_idx * math.floor(2 * state.layout.scale),
            y = deck_rect.y + math.floor(28 * state.layout.scale) + stack_idx * math.floor(2 * state.layout.scale),
            w = cw,
            h = ch,
        }
    end

    local grave_rect = get_zone_rect("grave")
    local grave_count = #state.zones.grave.cards
    for i, card_id in ipairs(state.zones.grave.cards) do
        local stack_idx = math.min(grave_count - i, 4)
        views[card_id] = {
            x = grave_rect.x + math.floor(20 * state.layout.scale) + stack_idx * math.floor(2 * state.layout.scale),
            y = grave_rect.y + math.floor(12 * state.layout.scale) + stack_idx * math.floor(2 * state.layout.scale),
            w = cw,
            h = ch,
        }
    end

    for _, zone_name in ipairs({"runtime", "trump", "targets", "manifest", "latent"}) do
        local rects = slot_rects_for_zone(zone_name)
        local zone = state.zones[zone_name]
        for slot = 1, zone.slot_count do
            local card_id = zone.cards[slot]
            if card_id then
                local r = rects[slot]
                views[card_id] = {x = r.x, y = r.y, w = r.w, h = r.h}
            end
        end
    end

    local hand_rect = get_zone_rect("hand")
    local count = #state.zones.hand.cards
    local gap = math.floor(12 * state.layout.scale)
    local max_total = hand_rect.w - math.floor(28 * state.layout.scale)
    local used_gap = gap
    if count > 1 then
        local natural_total = count * cw + (count - 1) * gap
        if natural_total > max_total then
            used_gap = math.max(math.floor((max_total - count * cw) / math.max(count - 1, 1)), math.floor(-cw * 0.35))
        end
    end
    local total_w = count > 0 and (count * cw + (count - 1) * used_gap) or 0
    local start_x = hand_rect.x + math.floor((hand_rect.w - total_w) / 2)
    local y = hand_rect.y + hand_rect.h - ch - math.floor(14 * state.layout.scale)
    for i, card_id in ipairs(state.zones.hand.cards) do
        views[card_id] = {x = start_x + (i - 1) * (cw + used_gap), y = y, w = cw, h = ch}
    end

    return views
end

local function current_card_rect(card_id)
    if state.anim.ghost and state.anim.ghost.card_id == card_id then
        return state.anim.ghost.rect
    end
    return card_views()[card_id]
end

local function clear_commit_state()
    state.committed = nil
    state.legal_hints = {}
end

local function topology_adjacent(op_a, op_b)
    return TOPOLOGY_ADJ[op_a] and TOPOLOGY_ADJ[op_a][op_b] or false
end

local function full_pair_fit(manifest_card_id, hand_card_id)
    local manifest = state.cards[manifest_card_id]
    local hand = state.cards[hand_card_id]
    if not manifest or not hand then
        return false
    end
    if hand.zone ~= "hand" then
        return false
    end
    return (
        topology_adjacent(manifest.op_a, hand.op_a) and topology_adjacent(manifest.op_b, hand.op_b)
    ) or (
        topology_adjacent(manifest.op_a, hand.op_b) and topology_adjacent(manifest.op_b, hand.op_a)
    )
end

local function commit_manifest_card(card_id, slot)
    if not state.hints_enabled then
        state.message = "Hints are off."
        return
    end

    if state.committed and state.committed.card_id == card_id then
        clear_commit_state()
        state.message = "Commit cleared."
        return
    end

    state.committed = {
        card_id = card_id,
        slot = slot,
    }
    state.legal_hints = {}

    local count = 0
    for _, hand_card_id in ipairs(state.zones.hand.cards) do
        if full_pair_fit(card_id, hand_card_id) then
            state.legal_hints[hand_card_id] = true
            count = count + 1
        end
    end

    state.message = card_id .. " committed. Legal hand cards: " .. count .. "."
    push_log(card_id .. " commit -> " .. count .. " legal hand cards.")
end

local function predicted_stack_rect(zone_name, count_after_insert)
    local rect = get_zone_rect(zone_name)
    local stack_idx = math.min(math.max((count_after_insert or 1) - 1, 0), 4)
    return {
        x = rect.x + math.floor(20 * state.layout.scale) + stack_idx * math.floor(2 * state.layout.scale),
        y = rect.y + math.floor(12 * state.layout.scale) + stack_idx * math.floor(2 * state.layout.scale),
        w = state.layout.card_w,
        h = state.layout.card_h,
    }
end

local function predicted_hand_rect(extra_cards)
    local hand_rect = get_zone_rect("hand")
    local count = #state.zones.hand.cards + (extra_cards or 0)
    local cw = state.layout.card_w
    local ch = state.layout.card_h
    local gap = math.floor(12 * state.layout.scale)
    local max_total = hand_rect.w - math.floor(28 * state.layout.scale)
    local used_gap = gap

    if count > 1 then
        local natural_total = count * cw + (count - 1) * gap
        if natural_total > max_total then
            used_gap = math.max(math.floor((max_total - count * cw) / math.max(count - 1, 1)), math.floor(-cw * 0.35))
        end
    end

    local total_w = count > 0 and (count * cw + (count - 1) * used_gap) or 0
    local start_x = hand_rect.x + math.floor((hand_rect.w - total_w) / 2)
    local y = hand_rect.y + hand_rect.h - ch - math.floor(14 * state.layout.scale)
    return {
        x = start_x + (count - 1) * (cw + used_gap),
        y = y,
        w = cw,
        h = ch,
    }
end

local function point_in_rect(x, y, rect)
    return rect and x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

local function pick_card(x, y)
    local views = card_views()
    local ordered = {}
    for _, zone_name in ipairs({"hand", "manifest", "latent", "targets", "runtime", "trump", "grave", "deck"}) do
        local zone = state.zones[zone_name]
        if zone.kind == "slots" then
            for i = zone.slot_count, 1, -1 do
                local card_id = zone.cards[i]
                if card_id then
                    table.insert(ordered, card_id)
                end
            end
        else
            local cards = zone.cards
            for i = #cards, 1, -1 do
                local card_id = cards[i]
                if card_id then
                    table.insert(ordered, card_id)
                end
            end
        end
    end
    for _, card_id in ipairs(ordered) do
        local rect = views[card_id]
        if point_in_rect(x, y, rect) then
            return card_id, rect
        end
    end
    return nil, nil
end

local function pick_drop_target(x, y)
    for _, zone_name in ipairs({"manifest", "latent", "targets", "runtime", "trump"}) do
        local rects = slot_rects_for_zone(zone_name)
        for slot, rect in ipairs(rects) do
            if point_in_rect(x, y, rect) then
                return {zone = zone_name, slot = slot}
            end
        end
    end
    for _, zone_name in ipairs({"deck", "hand", "grave"}) do
        local rect = get_zone_rect(zone_name)
        if point_in_rect(x, y, rect) then
            return {zone = zone_name, slot = nil}
        end
    end
    return nil
end

local BUTTON_ORDER = {
    {id = "start", label = "Start Game", hint = "[S]"},
    {id = "draw", label = "Draw", hint = "[1]"},
    {id = "hints", label = "Hints", hint = "[V]"},
    {id = "flip", label = "Flip", hint = "[2 / F]"},
    {id = "discard", label = "Discard", hint = "[3 / Del]"},
    {id = "reset", label = "Reset", hint = "[R]"},
}

local BUTTON_WIDTHS = {
    start = 176,
    draw = 118,
    hints = 118,
    flip = 146,
    discard = 152,
    reset = 152,
}

local function update_buttons()
    if not state.layout then
        return
    end

    local s = state.layout.scale
    local footer = state.layout.footer
    local gap = math.floor(12 * s)
    local bh = footer.h
    local x = footer.x
    state.ui.buttons = {}

    for _, spec in ipairs(BUTTON_ORDER) do
        local bw = math.floor((BUTTON_WIDTHS[spec.id] or 152) * s)
        local button = {
            id = spec.id,
            label = spec.label,
            hint = spec.hint,
        }
        button.rect = {x = x, y = footer.y, w = bw, h = bh}
        x = x + bw + gap
        table.insert(state.ui.buttons, button)
    end
end

local function refresh_layout(force)
    local w, h = love.graphics.getDimensions()
    if not force and state.layout and state.layout_w == w and state.layout_h == h then
        return
    end

    state.layout = make_layout()
    state.layout_w = w
    state.layout_h = h
    update_buttons()
end

local function enqueue_anim(step)
    table.insert(state.anim.queue, step)
    state.anim.locked = true
end

local function start_next_anim()
    if state.anim.active or #state.anim.queue == 0 then
        if not state.anim.active and #state.anim.queue == 0 then
            state.anim.locked = false
        end
        return
    end

    local step = table.remove(state.anim.queue, 1)
    step.elapsed = 0
    step.duration = step.duration or 0.22
    if step.on_start then
        step.on_start()
    end
    state.anim.active = step
end

local function ease_out_cubic(t)
    local inv = 1 - t
    return 1 - inv * inv * inv
end

local function update_active_anim(dt)
    local step = state.anim.active
    if not step then
        return
    end

    step.elapsed = math.min(step.elapsed + dt, step.duration)
    local t = step.duration > 0 and (step.elapsed / step.duration) or 1
    local e = ease_out_cubic(t)

    if step.kind == "move" then
        local face_up = step.face_before
        local sx = 1
        if step.flip then
            sx = math.max(0.05, math.abs(1 - 2 * t))
            if t >= 0.5 then
                face_up = step.face_after
            end
        end

        state.anim.ghost = {
            card_id = step.card_id,
            rect = {
                x = step.from_rect.x + (step.to_rect.x - step.from_rect.x) * e,
                y = step.from_rect.y + (step.to_rect.y - step.from_rect.y) * e - math.sin(t * math.pi) * (step.arc or 0),
                w = step.from_rect.w,
                h = step.from_rect.h,
            },
            face_up = face_up,
            scale_x = sx,
            dragged = false,
        }
    elseif step.kind == "flip" then
        local face_up = step.face_before
        if t >= 0.5 then
            face_up = step.face_after
        end
        state.anim.ghost = {
            card_id = step.card_id,
            rect = step.rect,
            face_up = face_up,
            scale_x = math.max(0.05, math.abs(1 - 2 * t)),
            dragged = false,
        }
    end

    if t >= 1 then
        state.anim.ghost = nil
        state.anim.active = nil
        if step.on_finish then
            step.on_finish()
        end
        start_next_anim()
    end
end

local function send_card_to_grave(card_id)
    remove_from_current_zone(card_id)
    state.cards[card_id].face_up = true
    place_card(card_id, "grave", nil)
end

local function refill_slot_from_deck(zone_name, slot, face_up)
    local deck = state.zones.deck.cards
    if #deck == 0 then
        return nil
    end
    local card_id = deck[#deck]
    remove_from_current_zone(card_id)
    state.cards[card_id].face_up = face_up
    place_card(card_id, zone_name, slot)
    return card_id
end

local function resolve_trump_zone_entry(card_id)
    local zone = state.zones.trump
    local open_slot = first_open_slot("trump")
    if open_slot then
        place_card(card_id, "trump", open_slot)
        state.cards[card_id].face_up = true
        push_log(card_id .. " -> trump[" .. open_slot .. "] (TRUMP event).")
        return
    end

    local flushed = {card_id}
    for slot = 1, zone.slot_count do
        local resident = zone.cards[slot]
        if resident then
            table.insert(flushed, resident)
            remove_from_current_zone(resident)
        end
    end
    for _, flushed_id in ipairs(flushed) do
        state.cards[flushed_id].face_up = false
        place_card(flushed_id, "deck", nil)
    end
    shuffle_in_place(state.zones.deck.cards)
    sync_zone_cards("deck")
    push_log("TRUMP zone overflow flush -> deck.")
end

local function enqueue_move(card_id, from_rect, to_rect, opts)
    opts = opts or {}
    enqueue_anim({
        kind = "move",
        card_id = card_id,
        from_rect = rect_copy(from_rect),
        to_rect = rect_copy(to_rect),
        face_before = opts.face_before,
        face_after = opts.face_after or opts.face_before,
        flip = opts.flip or false,
        arc = opts.arc or math.floor(24 * state.layout.scale),
        duration = opts.duration or 0.24,
        on_start = opts.on_start,
        on_finish = opts.on_finish,
    })
end

local function enqueue_flip(card_id, rect, face_before, face_after, duration, on_finish)
    enqueue_anim({
        kind = "flip",
        card_id = card_id,
        rect = rect_copy(rect),
        face_before = face_before,
        face_after = face_after,
        duration = duration or 0.22,
        on_start = function()
            remove_from_current_zone(card_id)
        end,
        on_finish = on_finish,
    })
end

local function queue_refill_latent(slot)
    local deck = state.zones.deck.cards
    if #deck == 0 then
        push_log("Latent[" .. slot .. "] refill skipped: deck empty.")
        return
    end

    local card_id = deck[#deck]
    local from_rect = current_card_rect(card_id)
    local latent_slot_rect = slot_rects_for_zone("latent")[slot]
    enqueue_move(card_id, from_rect, latent_slot_rect, {
        face_before = false,
        face_after = false,
        arc = math.floor(18 * state.layout.scale),
        on_start = function()
            remove_from_current_zone(card_id)
        end,
        on_finish = function()
            state.cards[card_id].face_up = false
            place_card(card_id, "latent", slot)
            push_log(card_id .. " -> latent[" .. slot .. "] (refill).")
        end,
    })
end

local function queue_chain_repair(slot)
    local latent_id = state.zones.latent.cards[slot]
    if not latent_id then
        push_log("Chain repair skipped for column " .. slot .. ": latent empty.")
        return
    end

    local from_rect = current_card_rect(latent_id)
    local manifest_slot_rect = slot_rects_for_zone("manifest")[slot]
    local face_before = state.cards[latent_id].face_up
    enqueue_move(latent_id, from_rect, manifest_slot_rect, {
        face_before = face_before,
        face_after = true,
        flip = not face_before,
        arc = math.floor(30 * state.layout.scale),
        duration = 0.26,
        on_start = function()
            remove_from_current_zone(latent_id)
        end,
        on_finish = function()
            state.cards[latent_id].face_up = true
            place_card(latent_id, "manifest", slot)
            push_log(latent_id .. " latent[" .. slot .. "] -> manifest[" .. slot .. "] (lift).")
        end,
    })

    queue_refill_latent(slot)
end

local function start_hand_manifest_play(card_id, slot)
    local hand_card = state.cards[card_id]
    if hand_card.zone ~= "hand" then
        state.message = "Only hand cards can start a play."
        return
    end

    local target_id = state.zones.manifest.cards[slot]
    if not target_id then
        state.message = "Manifest target required."
        return
    end

    local from_hand = current_card_rect(card_id)
    local from_manifest = current_card_rect(target_id)
    local manifest_slot_rect = slot_rects_for_zone("manifest")[slot]
    local grave_to = predicted_stack_rect("grave", #state.zones.grave.cards + 1)

    state.selected = nil
    state.pending_play = nil
    clear_commit_state()

    enqueue_move(target_id, from_manifest, grave_to, {
        face_before = state.cards[target_id].face_up,
        face_after = true,
        flip = not state.cards[target_id].face_up,
        on_start = function()
            remove_from_current_zone(target_id)
        end,
        on_finish = function()
            state.cards[target_id].face_up = true
            place_card(target_id, "grave", nil)
            push_log(target_id .. " -> grave (play).")
        end,
    })

    enqueue_move(card_id, from_hand, manifest_slot_rect, {
        face_before = true,
        face_after = true,
        on_start = function()
            remove_from_current_zone(card_id)
        end,
        on_finish = function()
            place_card(card_id, "manifest", slot)
            push_log(card_id .. " -> manifest[" .. slot .. "] (play).")
            state.message = card_id .. " replaced " .. target_id .. "."
        end,
    })

    start_next_anim()
end

local function start_draw_sequence()
    local deck = state.zones.deck.cards
    if #deck == 0 then
        state.message = "Deck is empty."
        push_log("Draw rejected: deck empty.")
        return
    end

    local card_id = deck[#deck]
    local from_rect = current_card_rect(card_id)
    local inspect_rect = {
        x = state.layout.center.combined.x + math.floor((state.layout.center.combined.w - state.layout.card_w) / 2),
        y = state.layout.center.combined.y + math.floor((state.layout.center.combined.h - state.layout.card_h) / 2),
        w = state.layout.card_w,
        h = state.layout.card_h,
    }

    enqueue_flip(card_id, from_rect, false, true, 0.22, function()
        local card = state.cards[card_id]
        card.face_up = true
        local is_trump = card.class == "trump"

        if is_trump then
            clear_commit_state()
            enqueue_move(card_id, inspect_rect, slot_rects_for_zone("trump")[math.max(first_open_slot("trump") or 1, 1)], {
                face_before = true,
                face_after = true,
                on_finish = function()
                    resolve_trump_zone_entry(card_id)
                    state.message = card_id .. " triggered TRUMP event."
                end,
            })
        else
            local hand_to = predicted_hand_rect(1)
            enqueue_move(card_id, inspect_rect, hand_to, {
                face_before = true,
                face_after = true,
                on_finish = function()
                    place_card(card_id, "hand", nil)
                    state.message = card_id .. " drawn."
                    push_log(card_id .. " -> hand (draw).")
                end,
            })
        end
        start_next_anim()
    end)

    start_next_anim()
end

local function committed_play_allowed(hand_card_id, manifest_slot)
    if not state.committed then
        return true
    end
    if manifest_slot ~= state.committed.slot then
        state.message = "Play must target the committed manifest slot."
        return false
    end
    if not state.legal_hints[hand_card_id] then
        state.message = "This hand card does not fit the committed manifest card."
        return false
    end
    return true
end

local function start_discard_sequence(card_id)
    local card = state.cards[card_id]
    local from_zone = card.zone
    local from_slot = card.slot
    local from_rect = current_card_rect(card_id)
    local grave_to = predicted_stack_rect("grave", #state.zones.grave.cards + 1)
    local face_before = card.face_up

    state.selected = nil
    clear_commit_state()
    enqueue_move(card_id, from_rect, grave_to, {
        face_before = face_before,
        face_after = true,
        flip = not face_before,
        on_start = function()
            remove_from_current_zone(card_id)
        end,
        on_finish = function()
            state.cards[card_id].face_up = true
            place_card(card_id, "grave", nil)
            push_log(card_id .. " -> grave (discard).")
            state.message = card_id .. " discarded."
            if from_zone == "manifest" and from_slot then
                queue_chain_repair(from_slot)
            elseif from_zone == "latent" and from_slot then
                queue_refill_latent(from_slot)
            end
        end,
    })
    start_next_anim()
end

local function zone_shortcut(zone_name)
    if not state.selected then
        state.message = "Select a card first."
        return
    end
    local slot = first_open_slot(zone_name)
    if state.zones[zone_name].kind == "slots" and not slot then
        state.message = zone_name .. " has no free slot."
        push_log("No free slot in " .. zone_name .. ".")
        return
    end
    move_card(state.selected, zone_name, slot, "shortcut")
end

local function draw_panel(rect, title, subtitle)
    set_color(COLORS.panel)
    rounded("fill", rect.x, rect.y, rect.w, rect.h, 12)
    set_color(COLORS.outline)
    rounded("line", rect.x, rect.y, rect.w, rect.h, 12)
    love.graphics.setFont(state.fonts.title)
    set_color(COLORS.text)
    love.graphics.print(title, rect.x + 14 * state.layout.scale, rect.y + 9 * state.layout.scale)
    if subtitle then
        love.graphics.setFont(state.fonts.small)
        set_color(COLORS.muted)
        love.graphics.print(subtitle, rect.x + 14 * state.layout.scale, rect.y + 32 * state.layout.scale)
    end
end

local function draw_slot_placeholder(rect, label, highlight)
    set_color(highlight and COLORS.drop or COLORS.outline, highlight and 0.55 or 0.8)
    love.graphics.setLineWidth(math.max(1, state.layout.scale * 2))
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 10, 10)
    love.graphics.setFont(state.fonts.small)
    set_color(COLORS.muted)
    love.graphics.printf(label, rect.x, rect.y + rect.h + 4 * state.layout.scale, rect.w, "center")
end

local function glyph_color(op_name)
    if op_name == "RUNTIME" then return {1, 1, 1} end
    return OP_COLORS[op_name]
end

local function draw_card(card_id, rect, dragged, opts)
    local card = state.cards[card_id]
    opts = opts or {}
    local selected = state.selected == card_id
    local committed = state.committed and state.committed.card_id == card_id
    local legal_hint = state.legal_hints[card_id] == true
    local scale_x = opts.scale_x or 1
    local face_up = opts.face_up
    if face_up == nil then
        face_up = card.face_up
    end
    local cx = rect.x + rect.w * 0.5
    local draw_w = rect.w * scale_x
    local draw_x = cx - draw_w * 0.5
    local draw_rect = {x = draw_x, y = rect.y, w = draw_w, h = rect.h}

    if face_up then
        local ca = OP_COLORS[card.op_a] or COLORS.card
        local cb = OP_COLORS[card.op_b] or COLORS.card
        local dark_a = lerp_color(ca, COLORS.bg, 0.90)
        local dark_b = lerp_color(cb, COLORS.bg, 0.90)

        if card.class == "trump" then
            set_color(dark_a)
            rounded("fill", draw_rect.x, draw_rect.y, draw_rect.w * 0.5, draw_rect.h, 10)
            set_color(dark_b)
            love.graphics.rectangle("fill", draw_rect.x + draw_rect.w * 0.5, draw_rect.y, draw_rect.w * 0.5, draw_rect.h, 10, 10)
            set_color(lerp_color(ca, cb, 0.5), 0.18)
            love.graphics.rectangle("fill", draw_rect.x + draw_rect.w * 0.47, draw_rect.y + 4, draw_rect.w * 0.06, draw_rect.h - 8)
        else
            set_color(dark_a)
            love.graphics.polygon("fill",
                draw_rect.x, draw_rect.y,
                draw_rect.x + draw_rect.w, draw_rect.y,
                draw_rect.x, draw_rect.y + draw_rect.h
            )
            set_color(dark_b)
            love.graphics.polygon("fill",
                draw_rect.x + draw_rect.w, draw_rect.y,
                draw_rect.x + draw_rect.w, draw_rect.y + draw_rect.h,
                draw_rect.x, draw_rect.y + draw_rect.h
            )
        end

        -- Outer border
        set_color(selected and COLORS.select or lerp_color(ca, cb, 0.5))
        rounded("line", draw_rect.x, draw_rect.y, draw_rect.w, draw_rect.h, 10)
        -- Inner frame
        set_color(COLORS.outline, 0.40)
        rounded("line", draw_rect.x + 4, draw_rect.y + 4, draw_rect.w - 8, draw_rect.h - 8, 8)

        -- Debug id
        love.graphics.setFont(state.fonts.small)
        set_color(COLORS.muted)
        love.graphics.printf(card.id, draw_rect.x + 6, draw_rect.y + 3 * state.layout.scale, draw_rect.w - 12, "center")

        local gs = math.floor(15 * state.layout.scale)

        if card.class == "trump" then
            local pos = glyph_layout.trump_pos(draw_rect)
            set_color(glyph_color(card.op_a))
            glyphs[card.op_a](pos.ax, pos.ay, gs)
            set_color(glyph_color(card.op_b))
            glyphs[card.op_b](pos.bx, pos.by, gs)
            if card.trump_name then
                love.graphics.setFont(state.fonts.small)
                set_color(COLORS.accent, 0.85)
                love.graphics.printf(card.trump_name, draw_rect.x + 6, draw_rect.y + draw_rect.h - 16 * state.layout.scale, draw_rect.w - 12, "center")
            end
        else
            local pos = glyph_layout.minor_pos(draw_rect)
            set_color(glyph_color(card.op_a))
            glyphs[card.op_a](pos.ax, pos.ay, gs)
            set_color(glyph_color(card.op_b))
            glyphs[card.op_b](pos.bx, pos.by, gs)
        end
    else
        set_color(COLORS.card_back)
        rounded("fill", draw_rect.x, draw_rect.y, draw_rect.w, draw_rect.h, 10)
        set_color(selected and COLORS.select or COLORS.card_back_alt)
        rounded("line", draw_rect.x, draw_rect.y, draw_rect.w, draw_rect.h, 10)
        love.graphics.setFont(state.fonts.body)
        love.graphics.printf(card.id, draw_rect.x, draw_rect.y + draw_rect.h * 0.42, draw_rect.w, "center")
    end

    if committed then
        set_color(COLORS.drop, 0.75)
        rounded("line", draw_rect.x - 3, draw_rect.y - 3, draw_rect.w + 6, draw_rect.h + 6, 12)
    end

    if legal_hint then
        set_color(COLORS.success, 0.80)
        rounded("line", draw_rect.x - 3, draw_rect.y - 3, draw_rect.w + 6, draw_rect.h + 6, 12)
    end

    if selected or dragged then
        set_color(selected and COLORS.select or COLORS.drop, 0.35)
        rounded("line", draw_rect.x - 2, draw_rect.y - 2, draw_rect.w + 4, draw_rect.h + 4, 12)
    end
end

local function draw_zone_contents()
    local views = card_views()
    local drag_card = state.drag and state.drag.card_id or nil

    for _, zone_name in ipairs({"deck", "runtime", "trump", "targets", "manifest", "latent", "hand", "grave"}) do
        local zone = state.zones[zone_name]
        if zone.kind == "slots" then
            local rects = slot_rects_for_zone(zone_name)
            for slot, rect in ipairs(rects) do
                local hl = state.hover_target and state.hover_target.zone == zone_name and state.hover_target.slot == slot
                draw_slot_placeholder(rect, zone_name == "runtime" and "slot" or tostring(slot), hl)
            end
        end

        if zone.kind == "slots" then
            for slot = 1, zone.slot_count do
                local card_id = zone.cards[slot]
                if card_id and card_id ~= drag_card then
                    draw_card(card_id, views[card_id], false)
                end
            end
        else
            for _, card_id in ipairs(zone.cards) do
                if card_id and card_id ~= drag_card then
                    draw_card(card_id, views[card_id], false)
                end
            end
        end
    end

    if state.drag then
        local rect = {
            x = state.drag.x - state.drag.ox,
            y = state.drag.y - state.drag.oy,
            w = state.layout.card_w,
            h = state.layout.card_h,
        }
        draw_card(state.drag.card_id, rect, true)
    end

    if state.anim.ghost then
        draw_card(state.anim.ghost.card_id, state.anim.ghost.rect, false, {
            face_up = state.anim.ghost.face_up,
            scale_x = state.anim.ghost.scale_x,
        })
    end
end

local function draw_system_panel()
    local rect = state.layout.right.system
    draw_panel(rect, "SYSTEM", nil)
    local counts = zone_counts()
    love.graphics.setFont(state.fonts.small)
    set_color(COLORS.text)
    local lines = {
        "Mode: " .. state.mode,
        "Selected: " .. (state.selected or "-"),
        "Deck: " .. counts.deck,
        "Hand: " .. counts.hand,
        "Grave: " .. counts.grave,
    }
    local y = rect.y + 18 * state.layout.scale
    for _, line in ipairs(lines) do
        love.graphics.print(line, rect.x + 14 * state.layout.scale, y)
        y = y + 11 * state.layout.scale
    end
end

local function draw_log_panel()
    local rect = state.layout.right.log
    draw_panel(rect, "LOG", nil)
    love.graphics.setScissor(rect.x, rect.y, rect.w, rect.h)
    love.graphics.setFont(state.fonts.small)
    local y = rect.y + 20 * state.layout.scale
    for _, line in ipairs(state.log) do
        set_color(COLORS.text)
        love.graphics.printf(line, rect.x + 12 * state.layout.scale, y, rect.w - 24 * state.layout.scale, "left")
        y = y + 15 * state.layout.scale
        if y > rect.y + rect.h - 16 * state.layout.scale then
            break
        end
    end
    love.graphics.setScissor()
end

local function draw_left_column()
    draw_panel(state.layout.left.deck, "DECK", "Draw pile")
    draw_panel(state.layout.left.runtime, "RUNTIME", "1 slot")
end

local function draw_center()
    draw_panel(state.layout.center.targets, "TARGETS", "3 slots")
    draw_panel(state.layout.center.trump, "TRUMP ZONE", "2 slots")
    draw_panel(state.layout.center.combined, "MANIFEST / LATENT", nil)
    draw_panel(state.layout.center.hand, "HAND", nil)

    local divider = state.layout.center.divider
    set_color(COLORS.outline)
    love.graphics.line(divider.x + 14 * state.layout.scale, divider.y + divider.h * 0.5, divider.x + divider.w - 14 * state.layout.scale, divider.y + divider.h * 0.5)
    love.graphics.setFont(state.fonts.small)
    set_color(COLORS.muted)
    love.graphics.print("Manifest", divider.x + 12 * state.layout.scale, state.layout.center.manifest.y + 24 * state.layout.scale)
    love.graphics.print("Latent", divider.x + 12 * state.layout.scale, state.layout.center.latent.y + 14 * state.layout.scale)
end

local function draw_footer()
    for _, button in ipairs(state.ui.buttons) do
        local active = button.id == "start"
            or button.id == "draw"
            or button.id == "hints"
            or (state.selected ~= nil)
        local tint = active and COLORS.accent_soft or COLORS.outline
        if button.id == "hints" and state.hints_enabled then
            tint = COLORS.success
        end
        set_color(active and COLORS.panel_alt or COLORS.panel)
        rounded("fill", button.rect.x, button.rect.y, button.rect.w, button.rect.h, 12)
        set_color(tint)
        rounded("line", button.rect.x, button.rect.y, button.rect.w, button.rect.h, 12)
        love.graphics.setFont(state.fonts.body)
        set_color(COLORS.text)
        love.graphics.printf(button.label, button.rect.x, button.rect.y + 8 * state.layout.scale, button.rect.w, "center")
        love.graphics.setFont(state.fonts.small)
        set_color(COLORS.muted)
        love.graphics.printf(button.hint, button.rect.x, button.rect.y + 24 * state.layout.scale, button.rect.w, "center")
    end

    local footer = state.layout.footer
    love.graphics.setFont(state.fonts.small)
    set_color(COLORS.muted)
    local help = "S Start Game  1 draw  V hints  2/F flip  3/Delete discard  R reset  H/M/L/T/U/P/G/K move to zone"
    love.graphics.print(help, footer.x + math.floor(760 * state.layout.scale), footer.y + 14 * state.layout.scale)
end

local function draw_top_header()
    love.graphics.setFont(state.fonts.big)
    set_color(COLORS.text)
    love.graphics.print("PROCESSCARDS", state.layout.margin, 2 * state.layout.scale)
    set_color(COLORS.accent)
    love.graphics.print(state.mode == "GAMEPLAY" and "GAME" or "DEV", state.layout.margin + 182 * state.layout.scale, 2 * state.layout.scale)

    love.graphics.setFont(state.fonts.small)
    set_color(COLORS.muted)
    love.graphics.print(state.message, state.layout.margin + 240 * state.layout.scale, 7 * state.layout.scale)
end

local function trigger_button(id)
    if id == "start" then
        start_game()
        return
    end

    if id == "draw" then
        if state.anim.locked then
            state.message = "Animation in progress."
            return
        end
        start_draw_sequence()
        return
    end

    if id == "hints" then
        state.hints_enabled = not state.hints_enabled
        if not state.hints_enabled then
            clear_commit_state()
        end
        state.message = "Hints " .. (state.hints_enabled and "enabled." or "disabled.")
        push_log("Hints -> " .. (state.hints_enabled and "on" or "off") .. ".")
        return
    end

    if id == "flip" then
        if state.anim.locked then
            state.message = "Animation in progress."
            return
        end
        if not state.selected then
            state.message = "Select a card first."
            return
        end
        local card = state.cards[state.selected]
        local card_id = state.selected
        local zone_name = card.zone
        local slot = card.slot
        local rect = current_card_rect(state.selected)
        enqueue_flip(card_id, rect, card.face_up, not card.face_up, 0.22, function()
            state.cards[card_id].face_up = not card.face_up
            place_card(card_id, zone_name, slot)
            push_log(card_id .. " flip -> " .. (state.cards[card_id].face_up and "face-up" or "face-down") .. ".")
            state.message = card_id .. " flipped."
        end)
        start_next_anim()
        return
    end

    if id == "discard" then
        if state.anim.locked then
            state.message = "Animation in progress."
            return
        end
        if not state.selected then
            state.message = "Select a card first."
            return
        end
        start_discard_sequence(state.selected)
        return
    end

    if id == "reset" then
        build_empty_surface()
        return
    end
end

function love.load()
    love.graphics.setBackgroundColor(COLORS.bg)
    init_fonts()
    build_empty_surface()
    refresh_layout(true)
end

function love.resize()
    refresh_layout(true)
end

function love.update(dt)
    refresh_layout()
    update_active_anim(dt or 0)
    start_next_anim()
    if state.drag then
        local x, y = love.mouse.getPosition()
        state.drag.x = x
        state.drag.y = y
        state.hover_target = pick_drop_target(x, y)
    else
        state.hover_target = nil
    end
end

function love.draw()
    refresh_layout()

    draw_top_header()
    draw_left_column()
    draw_center()
    draw_system_panel()
    draw_log_panel()
    draw_panel(state.layout.right.grave, "GRAVE", "Ordered discard pile")
    draw_zone_contents()
    draw_footer()
end

function love.mousepressed(x, y, button)
    if state.anim.locked then
        state.message = "Animation in progress."
        return
    end

    if button == 1 then
        for _, spec in ipairs(state.ui.buttons) do
            if point_in_rect(x, y, spec.rect) then
                trigger_button(spec.id)
                return
            end
        end

        local card_id, rect = pick_card(x, y)
        if card_id then
            local clicked = state.cards[card_id]
            local selected = state.selected and state.cards[state.selected] or nil
            if state.mode == "GAMEPLAY"
                and state.hints_enabled
                and clicked
                and clicked.zone == "manifest"
                and clicked.slot
                and not (selected and selected.zone == "hand")
            then
                state.selected = nil
                state.drag = nil
                commit_manifest_card(card_id, clicked.slot)
                return
            end
            if state.mode == "GAMEPLAY"
                and selected
                and selected.zone == "hand"
                and clicked
                and clicked.zone == "manifest"
                and clicked.slot
            then
                if not committed_play_allowed(state.selected, clicked.slot) then
                    return
                end
                start_hand_manifest_play(state.selected, clicked.slot)
                return
            end
            state.selected = card_id
            state.drag = {
                card_id = card_id,
                x = x,
                y = y,
                ox = x - rect.x,
                oy = y - rect.y,
                start_x = x,
                start_y = y,
                moved = false,
            }
            state.message = "Selected " .. card_id .. "."
            return
        end

        local target = pick_drop_target(x, y)
        if target and state.selected then
            local selected_card = state.cards[state.selected]
            if state.mode == "GAMEPLAY"
                and selected_card
                and selected_card.zone == "hand"
                and target.zone == "manifest"
                and target.slot
            then
                if not committed_play_allowed(state.selected, target.slot) then
                    return
                end
                start_hand_manifest_play(state.selected, target.slot)
            else
                local slot = target.slot or first_open_slot(target.zone)
                if slot or state.zones[target.zone].kind ~= "slots" then
                    move_card(state.selected, target.zone, slot, "click-place")
                end
            end
            return
        end

        state.selected = nil
    elseif button == 2 then
        local card_id = pick_card(x, y)
        if card_id then
            local card = state.cards[card_id]
            card.face_up = not card.face_up
            state.selected = card_id
            state.message = card_id .. " flipped."
            push_log(card_id .. " flip -> " .. (card.face_up and "face-up" or "face-down") .. ".")
        end
    end
end

function love.mousereleased(x, y, button)
    if button ~= 1 or not state.drag then
        return
    end

    if not state.drag.moved then
        state.drag = nil
        state.hover_target = nil
        return
    end

    local target = pick_drop_target(x, y)
    local card_id = state.drag.card_id
    state.drag = nil
    state.hover_target = nil

    if target then
        local card = state.cards[card_id]
        if state.mode == "GAMEPLAY"
            and card
            and card.zone == "hand"
            and target.zone == "manifest"
            and target.slot
        then
            if not committed_play_allowed(card_id, target.slot) then
                return
            end
            start_hand_manifest_play(card_id, target.slot)
            return
        else
            local slot = target.slot or first_open_slot(target.zone)
            if slot or state.zones[target.zone].kind ~= "slots" then
                if move_card(card_id, target.zone, slot, "drag-drop") then
                    state.selected = card_id
                    return
                end
            end
        end
    end

    state.message = "Move canceled."
    push_log("Canceled drag for " .. card_id .. ".")
end

function love.keypressed(key)
    if state.anim.locked and key ~= "escape" then
        state.message = "Animation in progress."
        return
    end

    if key == "s" then
        trigger_button("start")
    elseif key == "1" then
        trigger_button("draw")
    elseif key == "v" then
        trigger_button("hints")
    elseif key == "2" or key == "f" then
        trigger_button("flip")
    elseif key == "3" or key == "delete" or key == "backspace" then
        trigger_button("discard")
    elseif key == "r" then
        trigger_button("reset")
    elseif key == "escape" then
        state.selected = nil
        state.drag = nil
        clear_commit_state()
        state.message = "Selection cleared."
    elseif key == "h" then
        zone_shortcut("hand")
    elseif key == "m" then
        zone_shortcut("manifest")
    elseif key == "l" then
        zone_shortcut("latent")
    elseif key == "t" then
        zone_shortcut("targets")
    elseif key == "u" then
        zone_shortcut("runtime")
    elseif key == "p" then
        zone_shortcut("trump")
    elseif key == "g" then
        zone_shortcut("grave")
    elseif key == "k" then
        zone_shortcut("deck")
    end
end

function love.mousemoved(x, y)
    if not state.drag then
        return
    end

    local dx = x - state.drag.start_x
    local dy = y - state.drag.start_y
    if dx * dx + dy * dy > 16 then
        state.drag.moved = true
    end
end
