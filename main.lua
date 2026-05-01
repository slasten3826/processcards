-- ProcessCards layer 1 runtime
-- Documented sources:
-- docs/crystall/LAYER1_BOARD_SKELETON_SPEC.md
-- docs/crystall/BOARD_ENGINE_SKELETON_TZ.md
-- docs/crystall/LAYERED_PROJECT_POLICY.md
-- docs/crystall/PLATFORM_REQUIREMENTS.md
-- docs/crystall/PORTABILITY_CONSTRAINTS.md
-- docs/table/DECK_AND_SETUP_LAW.md
-- docs/table/CURRENT_CANON_SUMMARY.md
-- docs/table/CHAIN_SURFACE_LAW.md
-- docs/table/CARD_INFORMATION_STATE_LAW.md
-- docs/table/DRAW_PROCEDURE_LAW.md
-- docs/table/MOVE_FIT_LAW.md
-- docs/table/RESOLUTION_ORDER_LAW.md
-- docs/table/GRAVE_LAW.md
-- docs/table/TRUMP_EVENT_MINIMAL_LAW.md
-- docs/table/TURN_LAW_V2.md
-- docs/table/TURN_SEQUENCE_LAW_V2.md
-- docs/table/WIN_CHECK_LAW.md
-- docs/crystall/GAMEPLAY_ANIMATION_LAYER.md
-- docs/crystall/NEXT_GAMEPLAY_SLICE_V2.md

local glyphs = require("src.glyphs")
local glyph_layout = require("src.glyph_layout")
local core = require("src.core.api")

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
    RUNTIME = {0.40, 0.46, 0.52},
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
    armed_hand = nil,
    pending_operator_choice = nil,
    pending_public_choice = nil,
    pending_hidden_choice = nil,
    pending_hand_choice = nil,
    pending_manifest_choice = nil,
    pending_unrevealed_choice = nil,
    pending_trump = nil,
    hover_target = nil,
    drag = nil,
    cards = {},
    zones = {},
    core = nil,
    log = {},
    message = "DEV mode: free structural card manipulation.",
    layout = nil,
    layout_w = nil,
    layout_h = nil,
    fonts = {},
    ui = {
        buttons = {},
        operator_buttons = {},
        grave_viewer = {
            open = false,
            rect = nil,
            content_rect = nil,
            card_rects = {},
            ordered_cards = {},
        },
        armed_target = {
            kind = nil,
            card_id = nil,
            slot = nil,
        },
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
    play = {title = "PLAY", kind = "slots", slot_count = 1},
    trump_flow = {title = "TRUMP FLOW", kind = "row"},
    trump = {title = "TRUMP ZONE", kind = "slots", slot_count = 2},
    targets = {title = "TARGETS", kind = "slots", slot_count = 3},
    manifest = {title = "MANIFEST", kind = "slots", slot_count = 6},
    latent = {title = "LATENT", kind = "slots", slot_count = 6},
    hand = {title = "HAND", kind = "fan"},
    grave = {title = "GRAVE", kind = "stack"},
}

local minor_pair_from_index
local trump_pair_from_index
local enqueue_move
local enqueue_flip
local enqueue_callback
local start_next_anim
local update_buttons
local TRACE_PATH = "love_trace.log"

local function trace_line(tag, details)
    local file = io.open(TRACE_PATH, "a")
    if not file then
        return
    end
    local play_card = state.zones and state.zones.play and state.zones.play.cards and state.zones.play.cards[1] or "-"
    local armed_operator = state.pending_operator_choice and state.pending_operator_choice.armed_operator or "-"
    local armed_target = "-"
    local armed_target_id = "-"
    if state.pending_public_choice and state.pending_public_choice.armed_card_id then
        armed_target = "public"
        armed_target_id = state.pending_public_choice.armed_card_id
    elseif state.pending_hidden_choice and state.pending_hidden_choice.armed_card_id then
        armed_target = "hidden"
        armed_target_id = state.pending_hidden_choice.armed_card_id
    elseif state.pending_hand_choice and state.pending_hand_choice.armed_card_id then
        armed_target = "hand"
        armed_target_id = state.pending_hand_choice.armed_card_id
    elseif state.pending_manifest_choice and state.pending_manifest_choice.armed_slot then
        armed_target = "manifest"
        armed_target_id = state.pending_manifest_choice.armed_slot
    elseif state.pending_unrevealed_choice and state.pending_unrevealed_choice.armed_card_id then
        armed_target = "unrevealed"
        armed_target_id = state.pending_unrevealed_choice.armed_card_id
    end
    file:write(string.format(
        "%s | mode=%s msg=%s pending_op=%s armed_op=%s pending_public=%s pending_hidden=%s pending_hand=%s pending_manifest=%s pending_unrevealed=%s pending_trump=%s play=%s armed_target=%s:%s | %s\n",
        tag,
        tostring(state.mode),
        tostring(state.message),
        state.pending_operator_choice and "yes" or "no",
        tostring(armed_operator),
        state.pending_public_choice and "yes" or "no",
        state.pending_hidden_choice and "yes" or "no",
        state.pending_hand_choice and "yes" or "no",
        state.pending_manifest_choice and "yes" or "no",
        state.pending_unrevealed_choice and "yes" or "no",
        state.pending_trump and "yes" or "no",
        tostring(play_card),
        tostring(armed_target),
        tostring(armed_target_id),
        details or ""
    ))
    file:close()
end

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

local function draw_with_rounded_mask(rect, radius, draw_fn)
    love.graphics.stencil(function()
        rounded("fill", rect.x, rect.y, rect.w, rect.h, radius)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    draw_fn()
    love.graphics.setStencilTest()
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
    state.armed_hand = nil
    state.pending_operator_choice = nil
    state.pending_public_choice = nil
    state.pending_hidden_choice = nil
    state.pending_hand_choice = nil
    state.pending_manifest_choice = nil
    state.pending_unrevealed_choice = nil
    state.pending_trump = nil
    state.ui.grave_viewer.open = false
    state.ui.grave_viewer.rect = nil
    state.ui.grave_viewer.content_rect = nil
    state.ui.grave_viewer.card_rects = {}
    state.ui.grave_viewer.ordered_cards = {}
    state.ui.armed_target.kind = nil
    state.ui.armed_target.card_id = nil
    state.ui.armed_target.slot = nil
    state.hover_target = nil
    state.drag = nil
    state.cards = {}
    state.zones = {
        deck = new_zone("deck"),
        runtime = new_zone("runtime", {nil}),
        play = new_zone("play", {nil}),
        trump_flow = new_zone("trump_flow"),
        trump = new_zone("trump", {nil, nil}),
        targets = new_zone("targets", {nil, nil, nil}),
        manifest = new_zone("manifest", {nil, nil, nil, nil, nil, nil}),
        latent = new_zone("latent", {nil, nil, nil, nil, nil, nil}),
        hand = new_zone("hand"),
        grave = new_zone("grave"),
    }
    state.anim.queue = {}
    state.anim.active = nil
    state.anim.locked = false
    state.anim.ghost = nil
end

local function sync_from_core(message)
    local core_state = state.core
    if not core_state then
        return
    end

    state.cards = {}
    for card_id, card in pairs(core_state.cards) do
        state.cards[card_id] = {
            id = card.id,
            class = card.class,
            op_a = card.op_a,
            op_b = card.op_b,
            trump_name = card.trump_name,
            info_state = card.info_state,
            face_up = card.face_up,
            zone = card.zone,
            slot = card.slot,
        }
    end

    state.zones = {}
    for zone_name, zone in pairs(core_state.zones) do
        local clone = new_zone(zone_name)
        if zone.kind == "slots" then
            clone.cards = {}
            for i = 1, zone.slot_count do
                clone.cards[i] = zone.cards[i]
            end
        else
            clone.cards = {}
            for i, card_id in ipairs(zone.cards) do
                clone.cards[i] = card_id
            end
        end
        state.zones[zone_name] = clone
    end

    state.committed = core_state.committed and {
        card_id = core_state.committed.card_id,
        slot = core_state.committed.slot,
    } or nil
    state.legal_hints = {}
    for card_id, legal in pairs(core_state.legal_hints or {}) do
        if legal then
            state.legal_hints[card_id] = true
        end
    end
    state.armed_hand = core_state.armed_hand
    state.pending_operator_choice = core_state.pending_operator_choice and {
        card_id = core_state.pending_operator_choice.card_id,
        choices = {
            core_state.pending_operator_choice.choices[1],
            core_state.pending_operator_choice.choices[2],
        },
        armed_operator = core_state.pending_operator_choice.armed_operator,
    } or nil
    state.pending_public_choice = core_state.pending_public_choice and {
        card_id = core_state.pending_public_choice.card_id,
        operator = core_state.pending_public_choice.operator,
        legal_card_ids = core_state.pending_public_choice.legal_card_ids,
        armed_card_id = core_state.pending_public_choice.armed_card_id,
    } or nil
    state.pending_hidden_choice = core_state.pending_hidden_choice and {
        card_id = core_state.pending_hidden_choice.card_id,
        operator = core_state.pending_hidden_choice.operator,
        legal_card_ids = core_state.pending_hidden_choice.legal_card_ids,
        armed_card_id = core_state.pending_hidden_choice.armed_card_id,
    } or nil
    state.pending_hand_choice = core_state.pending_hand_choice and {
        card_id = core_state.pending_hand_choice.card_id,
        operator = core_state.pending_hand_choice.operator,
        legal_card_ids = core_state.pending_hand_choice.legal_card_ids,
        armed_card_id = core_state.pending_hand_choice.armed_card_id,
    } or nil
    state.pending_manifest_choice = core_state.pending_manifest_choice and {
        card_id = core_state.pending_manifest_choice.card_id,
        operator = core_state.pending_manifest_choice.operator,
        legal_slots = core_state.pending_manifest_choice.legal_slots,
        armed_slot = core_state.pending_manifest_choice.armed_slot,
    } or nil
    state.pending_unrevealed_choice = core_state.pending_unrevealed_choice and {
        card_id = core_state.pending_unrevealed_choice.card_id,
        operator = core_state.pending_unrevealed_choice.operator,
        legal_card_ids = core_state.pending_unrevealed_choice.legal_card_ids,
        armed_card_id = core_state.pending_unrevealed_choice.armed_card_id,
    } or nil
    state.pending_trump = core_state.pending_trump
    state.log = {}
    for i = #core_state.log, 1, -1 do
        state.log[#state.log + 1] = core_state.log[i]
    end
    state.anim.queue = {}
    state.anim.active = nil
    state.anim.locked = false
    state.anim.ghost = nil
    state.selected = nil
    state.drag = nil
    state.hover_target = nil
    state.ui.armed_target.kind = nil
    state.ui.armed_target.card_id = nil
    state.ui.armed_target.slot = nil
    update_buttons()
    if message then
        state.message = message
    end
end

local function inspect_rect()
    return {
        x = state.layout.center.combined.x + math.floor((state.layout.center.combined.w - state.layout.card_w) / 2),
        y = state.layout.center.combined.y + math.floor((state.layout.center.combined.h - state.layout.card_h) / 2),
        w = state.layout.card_w,
        h = state.layout.card_h,
    }
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
        info_state = "hidden",
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

local function insert_hand_card_at(card_id, index, reason)
    if state.mode == "GAMEPLAY" and state.core then
        local result = core.reorder_hand(state.core, card_id, index)
        if result and not result.summary.error then
            sync_from_core(card_id .. " -> hand[" .. result.summary.index .. "]" .. (reason and (" (" .. reason .. ")") or ""))
            return true
        end
        state.message = "Hand reorder rejected."
        return false
    end

    local hand = state.zones.hand
    remove_from_current_zone(card_id)
    local insert_at = math.max(1, math.min(index or (#hand.cards + 1), #hand.cards + 1))
    table.insert(hand.cards, insert_at, card_id)
    sync_zone_cards("hand")

    local label = card_id .. " -> hand[" .. insert_at .. "]"
    if reason then
        label = label .. " (" .. reason .. ")"
    end
    state.message = label
    push_log(label)
    return true
end

local function build_empty_surface()
    state.log = {}
    state.message = "DEV mode: free structural card manipulation."
    state.mode = "DEV"
    state.core = nil
    clear_runtime_state()

    push_log("Layer 1 board skeleton booted.")
    push_log("DEV mode active. Gameplay legality is deferred.")
    trace_line("build_empty_surface", "")
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
    state.mode = "GAMEPLAY"
    state.selected = nil
    state.hover_target = nil
    state.drag = nil
    state.hints_enabled = true
    state.core = core.new()
    core.start_game(state.core, {
        rng = function(max_n)
            return love.math.random(max_n)
        end,
    })
    sync_from_core("Start Game complete: two-phase opening board ready.")
    trace_line("start_game", "core.start_game complete")
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
    local flow_w = math.floor(244 * s)
    local target_w = math.floor(300 * s)
    local trump_w = math.floor(190 * s)
    local table_w = math.floor(670 * s)
    local table_x = center_x + math.floor((center_w - table_w) / 2) - math.floor(10 * s)
    local top_group_gap = math.floor(18 * s)
    local top_group_w = flow_w + top_group_gap + target_w + top_group_gap + trump_w
    local flow_x = center_x + math.floor((center_w - top_group_w) / 2)
    local target_x = flow_x + flow_w + top_group_gap
    local trump_x = right_x - trump_w - math.floor(20 * s)
    trump_x = target_x + target_w + top_group_gap
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

local function get_zone_rect(name)
    local l = state.layout
    if name == "deck" then return l.left.deck end
    if name == "play" then return l.left.play end
    if name == "runtime" then return l.left.runtime end
    if name == "trump_flow" then return l.center.trump_flow end
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
    elseif name == "trump" or name == "runtime" or name == "play" then
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

    for _, zone_name in ipairs({"runtime", "play", "trump", "targets", "manifest", "latent"}) do
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

    local flow_rect = get_zone_rect("trump_flow")
    if flow_rect then
        local flow = state.zones.trump_flow.cards
        local count = #flow
        local visible_slots = 3
        local slot_gap = math.floor(12 * state.layout.scale)
        local slot_total = visible_slots * cw + (visible_slots - 1) * slot_gap
        local slot_start = flow_rect.x + math.floor((flow_rect.w - slot_total) / 2)
        local y = flow_rect.y + math.floor((flow_rect.h - ch) / 2)
        local overlap_gap = math.floor(22 * state.layout.scale)
        local used_gap = count <= visible_slots and slot_gap or overlap_gap
        local total_w = count > 0 and (cw + (count - 1) * used_gap) or 0
        local start_x = count <= visible_slots
            and slot_start
            or (flow_rect.x + math.floor((flow_rect.w - total_w) / 2))
        for i, card_id in ipairs(flow) do
            views[card_id] = {x = start_x + (i - 1) * used_gap, y = y, w = cw, h = ch}
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
    state.armed_hand = nil
end

local function zone_is_closed(zone_name)
    local zone = state.zones[zone_name]
    if zone.kind == "slots" then
        for slot = 1, zone.slot_count do
            if zone.cards[slot] == nil then
                return false
            end
        end
        return true
    end
    return #zone.cards > 0
end

local function is_board_closed()
    return zone_is_closed("manifest")
        and zone_is_closed("latent")
        and zone_is_closed("targets")
end

local function first_trump_flow_card()
    return state.zones.trump_flow.cards[1]
end

local function refresh_pending_trump()
    if state.core then
        state.pending_trump = state.core.pending_trump
        return
    end
    if state.pending_trump then
        return
    end
    if state.anim.locked or not is_board_closed() then
        return
    end
    local card_id = first_trump_flow_card()
    if not card_id then
        return
    end
    state.pending_trump = card_id
    state.message = card_id .. " pending in trump flow. Press △ to resolve."
    push_log(card_id .. " pending trump event.")
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
    if state.core then
        local result = core.commit_manifest(state.core, slot)
        sync_from_core((result and result.summary and result.summary.error)
            and ("Commit rejected: " .. result.summary.error .. ".")
            or (card_id .. " committed."))
        return
    end

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
    state.armed_hand = nil

    state.message = card_id .. " committed. Legal hand cards: " .. count .. "."
    push_log(card_id .. " commit -> " .. count .. " legal hand cards.")
end

local function arm_hand_card(card_id)
    if state.core then
        local result = core.arm_hand(state.core, card_id)
        local message
        if result and result.summary and result.summary.error then
            message = card_id .. " is not legal for the committed manifest card."
        elseif state.core.armed_hand == card_id then
            message = card_id .. " armed for △."
        else
            message = card_id .. " unarmed."
        end
        sync_from_core(message)
        return not (result and result.summary and result.summary.error)
    end

    if not state.committed then
        state.message = "Commit one manifest card first."
        return false
    end
    if not state.legal_hints[card_id] then
        state.message = card_id .. " is not legal for the committed manifest card."
        return false
    end
    if state.armed_hand == card_id then
        state.armed_hand = nil
        state.message = card_id .. " unarmed."
        push_log(card_id .. " unarmed.")
        return true
    end
    state.armed_hand = card_id
    state.message = card_id .. " armed for △."
    push_log(card_id .. " -> armed hand-card.")
    return true
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

local function hand_insert_index_for_x(x, dragged_card_id)
    local views = card_views()
    local ordered = {}
    for _, hand_card_id in ipairs(state.zones.hand.cards) do
        if hand_card_id ~= dragged_card_id then
            table.insert(ordered, hand_card_id)
        end
    end

    for i, hand_card_id in ipairs(ordered) do
        local rect = views[hand_card_id]
        local mid_x = rect.x + rect.w * 0.5
        if x < mid_x then
            return i
        end
    end

    return #ordered + 1
end

local function queue_trump_flow_entry(card_id, from_rect, reason)
    local flow_rect = get_zone_rect("trump_flow")
    local count = #state.zones.trump_flow.cards + 1
    local gap = math.floor(12 * state.layout.scale)
    local total_w = count > 0 and (count * state.layout.card_w + (count - 1) * gap) or 0
    local start_x = flow_rect.x + math.floor((flow_rect.w - total_w) / 2)
    local y = flow_rect.y + math.floor((flow_rect.h - state.layout.card_h) / 2)
    local to_rect = {
        x = start_x + (count - 1) * (state.layout.card_w + gap),
        y = y,
        w = state.layout.card_w,
        h = state.layout.card_h,
    }

    enqueue_move(card_id, from_rect, to_rect, {
        face_before = true,
        face_after = true,
        arc = math.floor(18 * state.layout.scale),
        on_finish = function()
            place_card(card_id, "trump_flow", nil)
            push_log(card_id .. " -> trump flow" .. (reason and (" (" .. reason .. ")") or "") .. ".")
        end,
    })
end

local function queue_deck_reveal_to_manifest(card_id, slot)
    local from_rect = current_card_rect(card_id)
    local inspect = inspect_rect()
    local manifest_slot_rect = slot_rects_for_zone("manifest")[slot]
    enqueue_flip(card_id, from_rect, false, true, 0.22, function()
        state.cards[card_id].face_up = true
        enqueue_move(card_id, inspect, manifest_slot_rect, {
            face_before = true,
            face_after = true,
            arc = math.floor(20 * state.layout.scale),
            on_finish = function()
                place_card(card_id, "manifest", slot)
            end,
        })
        start_next_anim()
    end)
end

local function queue_deck_reveal_to_flow(card_id, reason)
    local from_rect = current_card_rect(card_id)
    local inspect = inspect_rect()
    enqueue_flip(card_id, from_rect, false, true, 0.22, function()
        state.cards[card_id].face_up = true
        queue_trump_flow_entry(card_id, inspect, reason)
        start_next_anim()
    end)
end

local function queue_deck_to_hand(card_id)
    local from_rect = current_card_rect(card_id)
    local inspect = inspect_rect()
    local hand_to = predicted_hand_rect(1)
    enqueue_flip(card_id, from_rect, false, true, 0.22, function()
        state.cards[card_id].face_up = true
        enqueue_move(card_id, inspect, hand_to, {
            face_before = true,
            face_after = true,
            on_finish = function()
                place_card(card_id, "hand", nil)
            end,
        })
        start_next_anim()
    end)
end

local function queue_concealed_refill_event(card_id, zone_name, slot)
    local from_rect = current_card_rect(card_id)
    local to_rect = slot_rects_for_zone(zone_name)[slot]
    enqueue_move(card_id, from_rect, to_rect, {
        face_before = false,
        face_after = false,
        arc = math.floor(18 * state.layout.scale),
        on_start = function()
            remove_from_current_zone(card_id)
        end,
        on_finish = function()
            state.cards[card_id].face_up = false
            place_card(card_id, zone_name, slot)
        end,
    })
end

local function queue_sync_from_core(message)
    enqueue_callback(function()
        sync_from_core(message)
    end)
end

local function animate_core_draw(result, message)
    local events = result and result.events or {}
    local summary = result and result.summary or {}

    for _, event in ipairs(events) do
        if event.type == "draw_to_hand" then
            queue_deck_to_hand(event.payload.card_id)
        elseif event.type == "trump_flow_entry" then
            queue_deck_reveal_to_flow(event.payload.card_id, event.payload.reason)
        end
    end

    queue_sync_from_core(message)
    start_next_anim()
    if summary.pending_trump then
        state.message = summary.pending_trump .. " pending in trump flow. Press △ to resolve."
    else
        state.message = message
    end
end

local function animate_core_turn(result, message)
    local events = result and result.events or {}
    local latent_inspect_by_card = {}
    local play_slot_rect = slot_rects_for_zone("play")[1]

    for _, event in ipairs(events) do
        local payload = event.payload or {}
        if event.type == "hand_to_play" then
            local from_rect = current_card_rect(payload.card_id)
            enqueue_move(payload.card_id, from_rect, play_slot_rect, {
                face_before = true,
                face_after = true,
                arc = math.floor(18 * state.layout.scale),
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    place_card(payload.card_id, "play", payload.slot or 1)
                end,
            })
        elseif event.type == "manifest_to_grave" then
            local from_rect = current_card_rect(payload.card_id)
            local grave_to = predicted_stack_rect("grave", #state.zones.grave.cards + 1)
            enqueue_move(payload.card_id, from_rect, grave_to, {
                face_before = state.cards[payload.card_id].face_up,
                face_after = true,
                flip = not state.cards[payload.card_id].face_up,
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    state.cards[payload.card_id].face_up = true
                    place_card(payload.card_id, "grave", nil)
                end,
            })
        elseif event.type == "latent_to_manifest" then
            local from_rect = current_card_rect(payload.card_id)
            local to_rect = slot_rects_for_zone("manifest")[payload.slot]
            local face_before = state.cards[payload.card_id].face_up
            enqueue_move(payload.card_id, from_rect, to_rect, {
                face_before = face_before,
                face_after = true,
                flip = not face_before,
                arc = math.floor(30 * state.layout.scale),
                duration = 0.26,
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    state.cards[payload.card_id].face_up = true
                    place_card(payload.card_id, "manifest", payload.slot)
                end,
            })
        elseif event.type == "latent_trump_revealed" then
            local from_rect = current_card_rect(payload.card_id)
            local inspect = inspect_rect()
            latent_inspect_by_card[payload.card_id] = inspect
            local face_before = state.cards[payload.card_id].face_up
            enqueue_move(payload.card_id, from_rect, inspect, {
                face_before = face_before,
                face_after = true,
                flip = not face_before,
                arc = math.floor(30 * state.layout.scale),
                duration = 0.26,
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    state.cards[payload.card_id].face_up = true
                end,
            })
        elseif event.type == "trump_flow_entry" then
            if payload.reason == "latent ascent" and latent_inspect_by_card[payload.card_id] then
                queue_trump_flow_entry(payload.card_id, latent_inspect_by_card[payload.card_id], payload.reason)
            elseif payload.reason == "open closure" then
                queue_deck_reveal_to_flow(payload.card_id, payload.reason)
            end
        elseif event.type == "manifest_closure" then
            queue_deck_reveal_to_manifest(payload.card_id, payload.slot)
        elseif event.type == "concealed_refill" then
            queue_concealed_refill_event(payload.card_id, payload.zone, payload.slot)
        elseif event.type == "play_to_grave" then
            local from_rect = current_card_rect(payload.card_id)
            local grave_to = predicted_stack_rect("grave", #state.zones.grave.cards + 1)
            enqueue_move(payload.card_id, from_rect, grave_to, {
                face_before = true,
                face_after = true,
                arc = math.floor(18 * state.layout.scale),
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    place_card(payload.card_id, "grave", nil)
                end,
            })
        end
    end

    queue_sync_from_core(message)
    start_next_anim()
    state.message = message
end

local function animate_core_pending_trump(result, message)
    local events = result and result.events or {}

    for _, event in ipairs(events) do
        if event.type == "trump_zone_entry" then
            local payload = event.payload or {}
            local from_rect = current_card_rect(payload.card_id)
            local to_rect = slot_rects_for_zone("trump")[payload.slot or 1]
            enqueue_move(payload.card_id, from_rect, to_rect, {
                face_before = true,
                face_after = true,
                arc = math.floor(16 * state.layout.scale),
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    place_card(payload.card_id, "trump", payload.slot or 1)
                end,
            })
        end
    end

    queue_sync_from_core(message)
    start_next_anim()
    state.message = message
end

local function animate_core_operator_choice(result, message)
    local events = result and result.events or {}
    for _, event in ipairs(events) do
        local payload = event.payload or {}
        if event.type == "draw_to_hand" then
            queue_deck_to_hand(payload.card_id)
        elseif event.type == "trump_flow_entry" then
            queue_deck_reveal_to_flow(payload.card_id, payload.reason)
        elseif event.type == "play_to_grave" then
            local from_rect = current_card_rect(payload.card_id)
            local grave_to = predicted_stack_rect("grave", #state.zones.grave.cards + 1)
            enqueue_move(payload.card_id, from_rect, grave_to, {
                face_before = true,
                face_after = true,
                arc = math.floor(18 * state.layout.scale),
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    place_card(payload.card_id, "grave", nil)
                end,
            })
        end
    end
    queue_sync_from_core(message)
    start_next_anim()
    state.message = message
end

local function animate_core_hand_choice(result, message)
    local events = result and result.events or {}
    local grave_offset = 0
    for _, event in ipairs(events) do
        local payload = event.payload or {}
        if event.type == "hand_to_grave" then
            local from_rect = current_card_rect(payload.card_id)
            grave_offset = grave_offset + 1
            local grave_to = predicted_stack_rect("grave", #state.zones.grave.cards + grave_offset)
            enqueue_move(payload.card_id, from_rect, grave_to, {
                face_before = true,
                face_after = true,
                arc = math.floor(18 * state.layout.scale),
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    place_card(payload.card_id, "grave", nil)
                end,
            })
        elseif event.type == "play_to_grave" then
            local from_rect = current_card_rect(payload.card_id)
            grave_offset = grave_offset + 1
            local grave_to = predicted_stack_rect("grave", #state.zones.grave.cards + grave_offset)
            enqueue_move(payload.card_id, from_rect, grave_to, {
                face_before = true,
                face_after = true,
                arc = math.floor(18 * state.layout.scale),
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    place_card(payload.card_id, "grave", nil)
                end,
            })
        end
    end
    queue_sync_from_core(message)
    start_next_anim()
    state.message = message
end

local function animate_core_hidden_choice(result, message)
    local events = result and result.events or {}
    local latent_inspect_by_card = {}
    for _, event in ipairs(events) do
        local payload = event.payload or {}
        if event.type == "card_became_known" then
            enqueue_callback(function()
                local card = state.cards[payload.card_id]
                if card then
                    card.info_state = "known"
                    card.face_up = false
                end
            end)
        elseif event.type == "latent_trump_revealed" then
            local from_rect = current_card_rect(payload.card_id)
            local inspect = inspect_rect()
            latent_inspect_by_card[payload.card_id] = inspect
            local face_before = state.cards[payload.card_id].face_up
            enqueue_move(payload.card_id, from_rect, inspect, {
                face_before = face_before,
                face_after = true,
                flip = not face_before,
                arc = math.floor(30 * state.layout.scale),
                duration = 0.26,
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    state.cards[payload.card_id].face_up = true
                    state.cards[payload.card_id].info_state = "revealed"
                end,
            })
        elseif event.type == "trump_flow_entry" then
            if latent_inspect_by_card[payload.card_id] then
                queue_trump_flow_entry(payload.card_id, latent_inspect_by_card[payload.card_id], payload.reason)
            end
        elseif event.type == "card_revealed_in_place" then
            enqueue_callback(function()
                local card = state.cards[payload.card_id]
                if card then
                    card.info_state = "revealed"
                    card.face_up = true
                end
            end)
        elseif event.type == "concealed_refill" then
            queue_concealed_refill_event(payload.card_id, payload.zone, payload.slot)
        elseif event.type == "play_to_grave" then
            local from_rect = current_card_rect(payload.card_id)
            local grave_to = predicted_stack_rect("grave", #state.zones.grave.cards + 1)
            enqueue_move(payload.card_id, from_rect, grave_to, {
                face_before = true,
                face_after = true,
                arc = math.floor(18 * state.layout.scale),
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    place_card(payload.card_id, "grave", nil)
                end,
            })
        end
    end
    queue_sync_from_core(message)
    start_next_anim()
    state.message = message
end

local function animate_core_unrevealed_choice(result, message)
    local events = result and result.events or {}
    local latent_inspect_by_card = {}
    for _, event in ipairs(events) do
        local payload = event.payload or {}
        if event.type == "card_revealed_in_place" then
            enqueue_callback(function()
                local card = state.cards[payload.card_id]
                if card then
                    card.info_state = "revealed"
                    card.face_up = true
                end
            end)
        elseif event.type == "latent_trump_revealed" then
            local from_rect = current_card_rect(payload.card_id)
            local inspect = inspect_rect()
            latent_inspect_by_card[payload.card_id] = inspect
            local face_before = state.cards[payload.card_id].face_up
            enqueue_move(payload.card_id, from_rect, inspect, {
                face_before = face_before,
                face_after = true,
                flip = not face_before,
                arc = math.floor(30 * state.layout.scale),
                duration = 0.26,
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    state.cards[payload.card_id].face_up = true
                    state.cards[payload.card_id].info_state = "revealed"
                end,
            })
        elseif event.type == "trump_flow_entry" then
            if latent_inspect_by_card[payload.card_id] then
                queue_trump_flow_entry(payload.card_id, latent_inspect_by_card[payload.card_id], payload.reason)
            else
                local from_rect = current_card_rect(payload.card_id)
                if from_rect then
                    queue_trump_flow_entry(payload.card_id, from_rect, payload.reason)
                end
            end
        elseif event.type == "concealed_refill" then
            queue_concealed_refill_event(payload.card_id, payload.zone, payload.slot)
        elseif event.type == "target_minor_to_grave" then
            local from_rect = current_card_rect(payload.card_id)
            local grave_to = predicted_stack_rect("grave", #state.zones.grave.cards + 1)
            enqueue_move(payload.card_id, from_rect, grave_to, {
                face_before = state.cards[payload.card_id].face_up,
                face_after = true,
                flip = not state.cards[payload.card_id].face_up,
                arc = math.floor(18 * state.layout.scale),
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    state.cards[payload.card_id].face_up = true
                    state.cards[payload.card_id].info_state = "revealed"
                    place_card(payload.card_id, "grave", nil)
                end,
            })
        elseif event.type == "play_to_grave" then
            local from_rect = current_card_rect(payload.card_id)
            local grave_to = predicted_stack_rect("grave", #state.zones.grave.cards + 1)
            enqueue_move(payload.card_id, from_rect, grave_to, {
                face_before = true,
                face_after = true,
                arc = math.floor(18 * state.layout.scale),
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    place_card(payload.card_id, "grave", nil)
                end,
            })
        end
    end
    queue_sync_from_core(message)
    start_next_anim()
    state.message = message
end

local function animate_core_manifest_choice(result, message)
    local events = result and result.events or {}
    local latent_inspect_by_card = {}

    for _, event in ipairs(events) do
        local payload = event.payload or {}
        if event.type == "manifest_to_hand" then
            local from_rect = current_card_rect(payload.card_id)
            local hand_to = predicted_hand_rect(1)
            enqueue_move(payload.card_id, from_rect, hand_to, {
                face_before = true,
                face_after = true,
                arc = math.floor(18 * state.layout.scale),
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    place_card(payload.card_id, "hand", nil)
                end,
            })
        elseif event.type == "latent_to_manifest" then
            local from_rect = current_card_rect(payload.card_id)
            local to_rect = slot_rects_for_zone("manifest")[payload.slot]
            local face_before = state.cards[payload.card_id].face_up
            enqueue_move(payload.card_id, from_rect, to_rect, {
                face_before = face_before,
                face_after = true,
                flip = not face_before,
                arc = math.floor(30 * state.layout.scale),
                duration = 0.26,
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    state.cards[payload.card_id].face_up = true
                    place_card(payload.card_id, "manifest", payload.slot)
                end,
            })
        elseif event.type == "latent_trump_revealed" then
            local from_rect = current_card_rect(payload.card_id)
            local inspect = inspect_rect()
            latent_inspect_by_card[payload.card_id] = inspect
            local face_before = state.cards[payload.card_id].face_up
            enqueue_move(payload.card_id, from_rect, inspect, {
                face_before = face_before,
                face_after = true,
                flip = not face_before,
                arc = math.floor(30 * state.layout.scale),
                duration = 0.26,
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    state.cards[payload.card_id].face_up = true
                end,
            })
        elseif event.type == "trump_flow_entry" then
            if payload.reason == "latent ascent" and latent_inspect_by_card[payload.card_id] then
                queue_trump_flow_entry(payload.card_id, latent_inspect_by_card[payload.card_id], payload.reason)
            elseif payload.reason == "open closure" then
                queue_deck_reveal_to_flow(payload.card_id, payload.reason)
            end
        elseif event.type == "manifest_closure" then
            queue_deck_reveal_to_manifest(payload.card_id, payload.slot)
        elseif event.type == "concealed_refill" then
            queue_concealed_refill_event(payload.card_id, payload.zone, payload.slot)
        elseif event.type == "play_to_grave" then
            local from_rect = current_card_rect(payload.card_id)
            local grave_to = predicted_stack_rect("grave", #state.zones.grave.cards + 1)
            enqueue_move(payload.card_id, from_rect, grave_to, {
                face_before = true,
                face_after = true,
                arc = math.floor(18 * state.layout.scale),
                on_start = function()
                    remove_from_current_zone(payload.card_id)
                end,
                on_finish = function()
                    place_card(payload.card_id, "grave", nil)
                end,
            })
        end
    end
    queue_sync_from_core(message)
    start_next_anim()
    state.message = message
end

local function queue_manifest_closure_from_deck(slot)
    local deck = state.zones.deck.cards
    if #deck == 0 then
        push_log("Manifest[" .. slot .. "] closure skipped: deck empty.")
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
    local manifest_slot_rect = slot_rects_for_zone("manifest")[slot]

    enqueue_flip(card_id, from_rect, false, true, 0.22, function()
        local card = state.cards[card_id]
        card.face_up = true
        if card.class == "trump" then
            queue_trump_flow_entry(card_id, inspect_rect, "open closure")
            queue_manifest_closure_from_deck(slot)
        else
            enqueue_move(card_id, inspect_rect, manifest_slot_rect, {
                face_before = true,
                face_after = true,
                arc = math.floor(20 * state.layout.scale),
                on_finish = function()
                    place_card(card_id, "manifest", slot)
                    push_log(card_id .. " -> manifest[" .. slot .. "] (closure).")
                end,
            })
        end
        start_next_anim()
    end)
end

local function point_in_rect(x, y, rect)
    return rect and x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

local function ordered_grave_cards()
    local ordered = {}
    for i = #state.zones.grave.cards, 1, -1 do
        ordered[#ordered + 1] = state.zones.grave.cards[i]
    end
    return ordered
end

local function compute_grave_viewer_layout()
    local s = state.layout.scale
    local overlay = {
        x = state.layout.margin + math.floor(72 * s),
        y = state.layout.margin + state.layout.top_bar_h + math.floor(18 * s),
        w = state.layout_w - (state.layout.margin + math.floor(72 * s)) * 2,
        h = state.layout_h - (state.layout.margin + state.layout.top_bar_h + math.floor(18 * s)) - (state.layout.footer.h + state.layout.margin + math.floor(18 * s)),
    }
    local content = {
        x = overlay.x + math.floor(18 * s),
        y = overlay.y + math.floor(54 * s),
        w = overlay.w - math.floor(36 * s),
        h = overlay.h - math.floor(72 * s),
    }

    local ordered = ordered_grave_cards()
    local count = #ordered
    local card_rects = {}

    if count > 0 then
        local aspect = state.layout.card_w / state.layout.card_h
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
                        best = {
                            cols = cols,
                            rows = rows,
                            card_w = math.floor(card_w),
                            card_h = math.floor(card_h),
                            gap = gap,
                            area = area,
                        }
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

    state.ui.grave_viewer.rect = overlay
    state.ui.grave_viewer.content_rect = content
    state.ui.grave_viewer.card_rects = card_rects
    state.ui.grave_viewer.ordered_cards = ordered
end

local function open_grave_viewer()
    state.ui.grave_viewer.open = true
    compute_grave_viewer_layout()
    state.message = "Grave viewer opened."
end

local function close_grave_viewer()
    state.ui.grave_viewer.open = false
    state.ui.grave_viewer.rect = nil
    state.ui.grave_viewer.content_rect = nil
    state.ui.grave_viewer.card_rects = {}
    state.ui.grave_viewer.ordered_cards = {}
    state.message = "Grave viewer closed."
end

local function pick_card(x, y)
    local views = card_views()
    local ordered = {}
    for _, zone_name in ipairs({"hand", "manifest", "latent", "targets", "play", "runtime", "trump", "grave", "deck"}) do
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
    {id = "move", label = "△", hint = "[Space]"},
    {id = "flip", label = "Flip", hint = "[2 / F]"},
    {id = "discard", label = "Discard", hint = "[3 / Del]"},
    {id = "reset", label = "Reset", hint = "[R]"},
}

local BUTTON_WIDTHS = {
    start = 176,
    draw = 118,
    hints = 118,
    move = 94,
    flip = 146,
    discard = 152,
    reset = 152,
}

update_buttons = function()
    if not state.layout then
        return
    end

    local s = state.layout.scale
    local footer = state.layout.footer
    local gap = math.floor(12 * s)
    local bh = footer.h
    local x = footer.x
    state.ui.buttons = {}
    state.ui.operator_buttons = {}

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

    local button_choices = nil
    if state.pending_operator_choice and state.pending_operator_choice.choices then
        button_choices = state.pending_operator_choice.choices
    else
        local play_card_id = state.zones.play.cards[1]
        local play_card = play_card_id and state.cards[play_card_id] or nil
        if play_card then
            local active_operator = (state.pending_public_choice and state.pending_public_choice.operator)
                or (state.pending_hidden_choice and state.pending_hidden_choice.operator)
                or (state.pending_hand_choice and state.pending_hand_choice.operator)
                or (state.pending_manifest_choice and state.pending_manifest_choice.operator)
                or (state.pending_unrevealed_choice and state.pending_unrevealed_choice.operator)
            if active_operator then
                button_choices = {play_card.op_a, play_card.op_b}
            end
        end
    end

    if button_choices then
        local play_rect = state.layout.left.play
        local bs = math.floor(74 * s)
        local bh = math.floor(96 * s)
        local ogap = math.floor(18 * s)
        local total_w = bs * 2 + ogap
        local ox = play_rect.x + math.floor((play_rect.w - total_w) / 2)
        local oy = state.layout.center.combined.y + math.floor(56 * s)
        for i, op_name in ipairs(button_choices) do
            state.ui.operator_buttons[#state.ui.operator_buttons + 1] = {
                op_name = op_name,
                rect = {
                    x = ox + (i - 1) * (bs + ogap),
                    y = oy,
                    w = bs,
                    h = bh,
                },
            }
        end
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
    if state.ui.grave_viewer.open then
        compute_grave_viewer_layout()
    end
end

local function enqueue_anim(step)
    table.insert(state.anim.queue, step)
    state.anim.locked = true
end

start_next_anim = function()
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

    if step.kind == "callback" then
        state.anim.ghost = nil
        state.anim.active = nil
        if step.on_finish then
            step.on_finish()
        end
        start_next_anim()
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

local function start_pending_trump_resolution()
    if state.pending_hidden_choice then
        state.message = "Choose one hidden card on board first."
        return
    end
    if state.pending_unrevealed_choice then
        state.message = "Choose one not-revealed card on board first."
        return
    end
    if state.pending_hand_choice then
        state.message = "Choose one hand card to discard first."
        return
    end
    if state.pending_public_choice then
        state.message = "Choose one revealed minor card first."
        return
    end
    if state.pending_operator_choice or state.pending_manifest_choice then
        state.message = "Choose one operator first."
        return
    end
    if state.core then
        local result = core.resolve_pending_trump(state.core)
        local message = (result and result.summary and result.summary.error)
            and "Board must close before trump resolution."
            or "Trump event resolved."
        if result and result.summary and result.summary.error then
            sync_from_core(message)
        else
            animate_core_pending_trump(result, message)
        end
        return
    end

    local card_id = state.pending_trump
    if not card_id then
        state.message = "No pending trump event."
        return
    end
    if not is_board_closed() then
        state.message = "Board must close before trump resolution."
        return
    end

    local from_rect = current_card_rect(card_id)
    local to_rect = slot_rects_for_zone("trump")[math.max(first_open_slot("trump") or 1, 1)]
    state.pending_trump = nil

    enqueue_move(card_id, from_rect, to_rect, {
        face_before = true,
        face_after = true,
        arc = math.floor(16 * state.layout.scale),
        on_start = function()
            remove_from_current_zone(card_id)
        end,
        on_finish = function()
            resolve_trump_zone_entry(card_id)
            state.message = card_id .. " resolved from trump flow."
        end,
    })
    start_next_anim()
end

enqueue_move = function(card_id, from_rect, to_rect, opts)
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

enqueue_flip = function(card_id, rect, face_before, face_after, duration, on_finish)
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

enqueue_callback = function(fn)
    enqueue_anim({
        kind = "callback",
        duration = 0,
        on_finish = fn,
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
    local inspect_rect = {
        x = state.layout.center.combined.x + math.floor((state.layout.center.combined.w - state.layout.card_w) / 2),
        y = state.layout.center.combined.y + math.floor((state.layout.center.combined.h - state.layout.card_h) / 2),
        w = state.layout.card_w,
        h = state.layout.card_h,
    }
    local manifest_slot_rect = slot_rects_for_zone("manifest")[slot]
    local face_before = state.cards[latent_id].face_up

    if state.cards[latent_id].class == "trump" then
        enqueue_move(latent_id, from_rect, inspect_rect, {
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
                push_log(latent_id .. " revealed on latent ascent.")
            end,
        })
        queue_trump_flow_entry(latent_id, inspect_rect, "latent ascent")
        queue_manifest_closure_from_deck(slot)
        queue_refill_latent(slot)
        return
    end

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
        state.message = "Only hand cards can start a cast."
        return
    end

    local target_id = state.zones.manifest.cards[slot]
    if not target_id then
        state.message = "Manifest target required."
        return
    end

    local from_hand = current_card_rect(card_id)
    local from_manifest = current_card_rect(target_id)
    local play_slot_rect = slot_rects_for_zone("play")[1]
    local grave_to = predicted_stack_rect("grave", #state.zones.grave.cards + 1)
    local grave_to_played = predicted_stack_rect("grave", #state.zones.grave.cards + 2)

    state.selected = nil
    state.pending_play = nil
    clear_commit_state()

    enqueue_move(card_id, from_hand, play_slot_rect, {
        face_before = true,
        face_after = true,
        arc = math.floor(18 * state.layout.scale),
        on_start = function()
            remove_from_current_zone(card_id)
        end,
        on_finish = function()
            place_card(card_id, "play", 1)
            push_log(card_id .. " -> play[1] (staged hand-card).")
        end,
    })

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
            push_log(target_id .. " -> grave (committed world-node).")
        end,
    })

    queue_chain_repair(slot)

    enqueue_move(card_id, play_slot_rect, grave_to_played, {
        face_before = true,
        face_after = true,
        arc = math.floor(18 * state.layout.scale),
        on_start = function()
            remove_from_current_zone(card_id)
        end,
        on_finish = function()
            place_card(card_id, "grave", nil)
            push_log(card_id .. " -> grave (played hand-card discharge).")
            state.message = card_id .. " cast against manifest[" .. slot .. "]."
        end,
    })

    start_next_anim()
end

local function choose_pending_operator(op_name)
    if not state.pending_operator_choice then
        state.message = "No pending operator choice."
        return
    end
    if state.core then
        local result = core.arm_operator(state.core, op_name)
        local summary = result and result.summary or {}
        local armed = summary.pending_operator_choice and summary.pending_operator_choice.armed_operator or nil
        local message = summary.error and ("Operator arm rejected: " .. summary.error .. ".")
            or (summary.pending_public_choice and "Choose one revealed minor card.")
            or (summary.pending_manifest_choice and "Choose one revealed manifest card.")
            or (summary.pending_unrevealed_choice and "Choose one not-revealed card on board.")
            or (summary.pending_hidden_choice and "Choose one hidden card on board.")
            or (armed and ("Armed " .. armed .. ". Press △ to confirm.") or "No operator armed. Press △ to discharge.")
        trace_line("arm_operator", "op=" .. tostring(op_name) .. " error=" .. tostring(summary.error) .. " armed=" .. tostring(armed))
        if summary.error then
            sync_from_core(message)
        else
            sync_from_core(message)
        end
        return
    end
end

local function confirm_pending_operator_phase()
    if not state.pending_operator_choice then
        state.message = "No pending operator choice."
        return
    end
    if state.core then
        local result = core.confirm_operator_phase(state.core)
        local summary = result and result.summary or {}
        local message = summary.error and ("Operator confirm rejected: " .. summary.error .. ".")
            or ((summary.pending_public_choice and "Choose one revealed minor card.")
                or (summary.pending_manifest_choice and "Choose one revealed manifest card.")
                or (summary.pending_unrevealed_choice and "Choose one not-revealed card on board.")
                or (summary.pending_hidden_choice and "Choose one hidden card on board.")
                or (summary.pending_hand_choice and "Choose one hand card.")
                or (summary.operator and ("Operator " .. summary.operator .. " confirmed."))
                or "Played card discharged.")
        trace_line("confirm_operator_phase", "error=" .. tostring(summary.error) .. " operator=" .. tostring(summary.operator))
        if summary.error then
            sync_from_core(message)
        elseif summary.pending_public_choice or summary.pending_manifest_choice or summary.pending_unrevealed_choice or summary.pending_hidden_choice then
            sync_from_core(message)
        elseif summary.pending_hand_choice then
            animate_core_operator_choice(result, message)
        else
            animate_core_operator_choice(result, message)
        end
        return
    end
end

local function choose_pending_unrevealed_target(card_id)
    if not state.pending_unrevealed_choice then
        state.message = "No pending unrevealed choice."
        return
    end
    if state.core then
        local result = core.choose_unrevealed_target(state.core, card_id)
        local summary = result and result.summary or {}
        local message = summary.error and ("Manifest choice rejected: " .. summary.error .. ".")
            or (card_id .. " manifested.")
        if summary.error then
            sync_from_core(message)
        else
            animate_core_unrevealed_choice(result, message)
        end
        return
    end
end

local function arm_pending_unrevealed_target(card_id)
    if not state.pending_unrevealed_choice then
        state.message = "No pending unrevealed choice."
        return
    end
    if state.core then
        local result = core.arm_unrevealed_target(state.core, card_id)
        local summary = result and result.summary or {}
        local armed = summary.pending_unrevealed_choice and summary.pending_unrevealed_choice.armed_card_id or nil
        local message = summary.error and ("MANIFEST target rejected: " .. summary.error .. ".")
            or (armed and (card_id .. " armed for MANIFEST. Press △ to confirm.") or "MANIFEST target cleared.")
        trace_line("arm_unrevealed_target", "card=" .. tostring(card_id) .. " error=" .. tostring(summary.error) .. " armed=" .. tostring(armed))
        if summary.error then
            sync_from_core(message)
        else
            sync_from_core(message)
        end
        return
    end
end

local function confirm_pending_unrevealed_target()
    if not state.pending_unrevealed_choice then
        state.message = "No pending unrevealed choice."
        return
    end
    if state.core then
        local result = core.confirm_unrevealed_target(state.core)
        local summary = result and result.summary or {}
        local message = summary.error and ("Manifest choice rejected: " .. summary.error .. ".")
            or "MANIFEST confirmed."
        trace_line("confirm_unrevealed_target", "error=" .. tostring(summary.error))
        if summary.error then
            sync_from_core(message)
        else
            animate_core_unrevealed_choice(result, message)
        end
        return
    end
end

local function arm_pending_hidden_target(card_id)
    if not state.pending_hidden_choice then
        state.message = "No pending hidden choice."
        return
    end
    if state.core then
        local result = core.arm_hidden_target(state.core, card_id)
        local summary = result and result.summary or {}
        local armed = summary.pending_hidden_choice and summary.pending_hidden_choice.armed_card_id or nil
        local message = summary.error and ("Hidden target rejected: " .. summary.error .. ".")
            or (armed and (card_id .. " armed for OBSERVE. Press △ to confirm.") or "OBSERVE target cleared.")
        if summary.error then
            sync_from_core(message)
        else
            sync_from_core(message)
        end
        return
    end
end

local function confirm_pending_hidden_target()
    if not state.pending_hidden_choice then
        state.message = "No pending hidden choice."
        return
    end
    if state.core then
        local result = core.confirm_hidden_target(state.core)
        local summary = result and result.summary or {}
        local message = summary.error and ("Hidden choice rejected: " .. summary.error .. ".")
            or "Target observed."
        if summary.error then
            sync_from_core(message)
        else
            animate_core_hidden_choice(result, message)
        end
        return
    end
end

local function arm_pending_hand_target(card_id)
    if not state.pending_hand_choice then
        state.message = "No pending hand choice."
        return
    end
    if state.core then
        local result = core.arm_hand_target(state.core, card_id)
        local summary = result and result.summary or {}
        local armed = summary.pending_hand_choice and summary.pending_hand_choice.armed_card_id or nil
        local operator = state.pending_hand_choice and state.pending_hand_choice.operator or nil
        local verb = operator == "LOGIC" and "LOGIC" or "CYCLE"
        local message = summary.error and ("Hand target rejected: " .. summary.error .. ".")
            or (armed and (card_id .. " armed for " .. verb .. ". Press △ to confirm.") or (verb .. " target cleared."))
        if summary.error then
            sync_from_core(message)
        else
            sync_from_core(message)
        end
        return
    end
end

local function confirm_pending_hand_target()
    if not state.pending_hand_choice then
        state.message = "No pending hand choice."
        return
    end
    if state.core then
        local result = core.confirm_hand_target(state.core)
        local summary = result and result.summary or {}
        local operator = state.pending_hand_choice and state.pending_hand_choice.operator or nil
        local message = summary.error and ("Hand choice rejected: " .. summary.error .. ".")
            or ((operator == "LOGIC" and "LOGIC swap confirmed.")
                or "CYCLE discard confirmed.")
        if summary.error then
            sync_from_core(message)
        else
            animate_core_hand_choice(result, message)
        end
        return
    end
end

local function arm_pending_manifest_target(slot)
    if not state.pending_manifest_choice then
        state.message = "No pending manifest choice."
        return
    end
    if state.core then
        local result = core.arm_manifest_target(state.core, slot)
        local summary = result and result.summary or {}
        local armed = summary.pending_manifest_choice and summary.pending_manifest_choice.armed_slot or nil
        local message = summary.error and ("Manifest target rejected: " .. summary.error .. ".")
            or (armed and ("manifest[" .. slot .. "] armed for CHOOSE. Press △ to confirm.") or "CHOOSE target cleared.")
        if summary.error then
            sync_from_core(message)
        else
            sync_from_core(message)
        end
        return
    end
end

local function confirm_pending_manifest_target()
    if not state.pending_manifest_choice then
        state.message = "No pending manifest choice."
        return
    end
    if state.core then
        local result = core.confirm_manifest_target(state.core)
        local summary = result and result.summary or {}
        local message = summary.error and ("Manifest choice rejected: " .. summary.error .. ".")
            or "CHOOSE confirmed."
        if summary.error then
            sync_from_core(message)
        else
            animate_core_manifest_choice(result, message)
        end
        return
    end
end

local function arm_pending_public_target(card_id)
    if not state.pending_public_choice then
        state.message = "No pending public choice."
        return
    end
    if state.core then
        local result = core.arm_public_target(state.core, card_id)
        local summary = result and result.summary or {}
        local armed = summary.pending_public_choice and summary.pending_public_choice.armed_card_id or nil
        local message = summary.error and ("Public target rejected: " .. summary.error .. ".")
            or (armed and (card_id .. " armed for LOGIC. Press △ to confirm.") or "LOGIC target cleared.")
        trace_line("arm_public_target", "card=" .. tostring(card_id) .. " error=" .. tostring(summary.error) .. " armed=" .. tostring(armed))
        if summary.error then
            sync_from_core(message)
        else
            sync_from_core(message)
        end
        return
    end
end

local function confirm_pending_public_target()
    if not state.pending_public_choice then
        state.message = "No pending public choice."
        return
    end
    if state.core then
        local result = core.confirm_public_target(state.core)
        local summary = result and result.summary or {}
        local message = summary.error and ("Public choice rejected: " .. summary.error .. ".")
            or (summary.pending_hand_choice and "Choose one hand card for LOGIC.")
            or "LOGIC public target confirmed."
        trace_line("confirm_public_target", "error=" .. tostring(summary.error))
        if summary.error then
            sync_from_core(message)
        else
            sync_from_core(message)
        end
        return
    end
end

local function start_draw_sequence()
    if state.pending_hidden_choice then
        state.message = "Choose one hidden card on board first."
        return
    end
    if state.pending_unrevealed_choice then
        state.message = "Choose one not-revealed card on board first."
        return
    end
    if state.pending_hand_choice then
        state.message = "Choose one hand card to discard first."
        return
    end
    if state.pending_public_choice then
        state.message = "Choose one revealed minor card first."
        return
    end
    if state.pending_operator_choice or state.pending_manifest_choice then
        state.message = "Choose one operator first."
        return
    end
    if state.core then
        local result = core.draw_to_hand(state.core)
        local summary = result and result.summary or {}
        local message
        if summary.error == "deck_empty" then
            message = "Deck is empty."
        elseif summary.error == "trump_burn" then
            message = (summary.pending_trump or state.core.pending_trump or "Trump") .. " entered trump flow."
        elseif summary.card_id then
            message = summary.card_id .. " drawn."
        else
            message = "Draw resolved."
        end
        if summary.error == "deck_empty" then
            sync_from_core(message)
        else
            animate_core_draw(result, message)
        end
        return
    end

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
            queue_trump_flow_entry(card_id, inspect_rect, "draw")
            state.message = card_id .. " entered trump flow."
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

local function launch_committed_play()
    if state.pending_hidden_choice then
        state.message = "Choose one hidden card on board first."
        return
    end
    if state.pending_unrevealed_choice then
        state.message = "Choose one not-revealed card on board first."
        return
    end
    if state.pending_hand_choice then
        state.message = "Choose one hand card to discard first."
        return
    end
    if state.pending_public_choice then
        state.message = "Choose one revealed minor card first."
        return
    end
    if state.pending_operator_choice or state.pending_manifest_choice then
        state.message = "Choose one operator first."
        return
    end
    if state.anim.locked then
        state.message = "Animation in progress."
        return
    end
    if not state.committed then
        state.message = "Commit one manifest card first."
        return
    end
    local hand_card_id = state.armed_hand
    if not hand_card_id then
        state.message = "Choose one legal hand card first."
        return
    end

    if state.core then
        local result = core.resolve_turn(state.core, state.committed.slot, hand_card_id)
        local summary = result and result.summary or {}
        local message = summary.error and ("Turn rejected: " .. summary.error .. ".")
            or (hand_card_id .. " cast against manifest[" .. state.committed.slot .. "].")
        if summary.error then
            sync_from_core(message)
        else
            animate_core_turn(result, message)
        end
        return
    end

    start_hand_manifest_play(hand_card_id, state.committed.slot)
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

local function draw_panel_counter(rect, text, opts)
    opts = opts or {}
    love.graphics.setFont(opts.font or state.fonts.small)
    set_color(opts.color or COLORS.muted, opts.alpha or 0.92)
    if opts.align == "right" then
        love.graphics.printf(
            text,
            rect.x + rect.w - (opts.width or (72 * state.layout.scale)) - 14 * state.layout.scale,
            opts.y or (rect.y + 16 * state.layout.scale),
            opts.width or (72 * state.layout.scale),
            "right"
        )
    else
        love.graphics.print(
            text,
            opts.x or (rect.x + 14 * state.layout.scale),
            opts.y or (rect.y + 16 * state.layout.scale)
        )
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
    return OP_COLORS[op_name]
end

local function frame_color_mix(ca, cb, t)
    local u = 0.5 + 0.5 * math.sin(t)
    return lerp_color(ca, cb, u)
end

local function frame_breath_phase()
    return 0.5 + 0.5 * math.sin(love.timer.getTime() * 2.2)
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
    local width = opts.width or math.max(2, state.layout.scale * 2.2)
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

local function draw_breath_halo(rect, color, phase)
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
end

local function trump_flow_train_colors()
    local colors = {}
    for _, card_id in ipairs(state.zones.trump_flow.cards) do
        local card = state.cards[card_id]
        if card then
            table.insert(colors, OP_COLORS[card.op_a] or COLORS.card)
            table.insert(colors, OP_COLORS[card.op_b] or COLORS.card)
        end
    end
    return colors
end

local function draw_hand_frame_mode(card, draw_rect, legal_hint, armed, selected)
    local ca = OP_COLORS[card.op_a] or COLORS.card
    local cb = OP_COLORS[card.op_b] or COLORS.card
    local line_w = math.max(2, state.layout.scale * 2)
    love.graphics.setLineWidth(line_w)

    if armed then
        local phase = frame_breath_phase()
        local border_color = lerp_color(ca, cb, phase)
        set_color(border_color, 0.98)
        rounded("line", draw_rect.x, draw_rect.y, draw_rect.w, draw_rect.h, 10)
        return
    end

    local border_color
    if legal_hint then
        local base = lerp_color(ca, cb, 0.5)
        set_color(base, 0.20)
        rounded("line", draw_rect.x, draw_rect.y, draw_rect.w, draw_rect.h, 10)
        draw_segmented_frame(draw_rect, {ca, cb}, love.timer.getTime() / 6.08, {
            width = math.max(2, state.layout.scale * 2.25),
            segment_count = 14,
            duty = 0.54,
        })
        return
    elseif selected then
        border_color = COLORS.select
    else
        border_color = lerp_color(ca, cb, 0.5)
    end
    set_color(border_color, legal_hint and 0.98 or 0.92)
    rounded("line", draw_rect.x, draw_rect.y, draw_rect.w, draw_rect.h, 10)
end

local function draw_card(card_id, rect, dragged, opts)
    local card = state.cards[card_id]
    opts = opts or {}
    local effect_target_pending = state.pending_public_choice ~= nil
        or state.pending_hidden_choice ~= nil
        or state.pending_hand_choice ~= nil
        or state.pending_manifest_choice ~= nil
        or state.pending_unrevealed_choice ~= nil
    local effect_phase_active = state.pending_operator_choice ~= nil
        or effect_target_pending
    local selected = (not effect_phase_active) and state.selected == card_id
    local committed = (not effect_phase_active)
        and state.committed
        and state.committed.card_id == card_id
        and card.zone == "manifest"
    local legal_hint = (not effect_phase_active) and state.legal_hints[card_id] == true
    local armed = (not effect_phase_active) and state.armed_hand == card_id
    local choose_target = false
    if state.pending_manifest_choice and card.zone == "manifest" and card.slot then
        for _, legal_slot in ipairs(state.pending_manifest_choice.legal_slots or {}) do
            if legal_slot == card.slot then
                choose_target = true
                break
            end
        end
    end
    local cycle_target = false
    if state.pending_hand_choice and card.zone == "hand" then
        for _, legal_card_id in ipairs(state.pending_hand_choice.legal_card_ids or {}) do
            if legal_card_id == card_id then
                cycle_target = true
                break
            end
        end
    end
    local observe_target = false
    if state.pending_hidden_choice then
        for _, legal_card_id in ipairs(state.pending_hidden_choice.legal_card_ids or {}) do
            if legal_card_id == card_id then
                observe_target = true
                break
            end
        end
    end
    local manifest_target = false
    if state.pending_unrevealed_choice then
        for _, legal_card_id in ipairs(state.pending_unrevealed_choice.legal_card_ids or {}) do
            if legal_card_id == card_id then
                manifest_target = true
                break
            end
        end
    end
    local armed_choose_target = state.pending_manifest_choice
        and state.pending_manifest_choice.armed_slot == card.slot
    local armed_cycle_target = state.pending_hand_choice
        and state.pending_hand_choice.armed_card_id == card_id
    local armed_observe_target = state.pending_hidden_choice
        and state.pending_hidden_choice.armed_card_id == card_id
    local armed_unrevealed_target = state.pending_unrevealed_choice
        and state.pending_unrevealed_choice.armed_card_id == card_id
    local logic_target = false
    if state.pending_public_choice then
        for _, legal_card_id in ipairs(state.pending_public_choice.legal_card_ids or {}) do
            if legal_card_id == card_id then
                logic_target = true
                break
            end
        end
    end
    if state.pending_operator_choice and not state.pending_public_choice then
        local armed_operator = state.pending_operator_choice.armed_operator
        local is_topdeck = card.zone == "deck" and state.zones.deck.cards[#state.zones.deck.cards] == card_id
        if armed_operator == "CHOOSE" then
            choose_target = card.zone == "manifest" and card.slot ~= nil and card.face_up
        elseif armed_operator == "OBSERVE" then
            observe_target = card.info_state == "hidden"
                and (card.zone ~= "deck" or is_topdeck)
        elseif armed_operator == "MANIFEST" then
            manifest_target = not card.face_up
                and (card.zone ~= "deck" or is_topdeck)
        elseif armed_operator == "LOGIC" then
            logic_target = card.class == "minor"
                and card.face_up
                and (card.zone == "manifest"
                    or card.zone == "latent"
                    or card.zone == "grave"
                    or (card.zone == "deck" and is_topdeck))
        end
    end
    if armed_choose_target then
        choose_target = false
    end
    if armed_cycle_target then
        cycle_target = false
    end
    if armed_observe_target then
        observe_target = false
    end
    if armed_unrevealed_target then
        manifest_target = false
    end
    local armed_logic_target = state.pending_public_choice
        and state.pending_public_choice.armed_card_id == card_id
    if armed_logic_target then
        logic_target = false
    end
    local scale_x = opts.scale_x or 1
    local face_up = opts.face_up
    if face_up == nil then
        face_up = card.face_up
    end
    local cx = rect.x + rect.w * 0.5
    local draw_w = rect.w * scale_x
    local draw_x = cx - draw_w * 0.5
    local draw_rect = {x = draw_x, y = rect.y, w = draw_w, h = rect.h}
    local gameplay_hand = state.mode == "GAMEPLAY"
        and card.zone == "hand"
        and not effect_phase_active
    if gameplay_hand and armed then
        local ca = OP_COLORS[card.op_a] or COLORS.card
        local cb = OP_COLORS[card.op_b] or COLORS.card
        local phase = frame_breath_phase()
        local halo_color = lerp_color(ca, cb, phase)
        draw_breath_halo(draw_rect, halo_color, phase)
    end

    if face_up then
        local ca = OP_COLORS[card.op_a] or COLORS.card
        local cb = OP_COLORS[card.op_b] or COLORS.card
        local dark_a = lerp_color(ca, COLORS.bg, 0.90)
        local dark_b = lerp_color(cb, COLORS.bg, 0.90)

        draw_with_rounded_mask(draw_rect, 10, function()
            if card.class == "trump" then
                set_color(dark_a)
                love.graphics.rectangle("fill", draw_rect.x, draw_rect.y, draw_rect.w * 0.5, draw_rect.h)
                set_color(dark_b)
                love.graphics.rectangle("fill", draw_rect.x + draw_rect.w * 0.5, draw_rect.y, draw_rect.w * 0.5, draw_rect.h)
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
        end)

        -- Outer border
        if gameplay_hand then
            draw_hand_frame_mode(card, draw_rect, legal_hint, armed, selected)
        else
            set_color(selected and COLORS.select or lerp_color(ca, cb, 0.5))
            rounded("line", draw_rect.x, draw_rect.y, draw_rect.w, draw_rect.h, 10)
        end
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
        if card.info_state == "known" then
            local ca = OP_COLORS[card.op_a] or COLORS.card
            local cb = OP_COLORS[card.op_b] or COLORS.card
            local gs = math.floor(15 * state.layout.scale)
            if card.class == "trump" then
                local pos = glyph_layout.trump_pos(draw_rect)
                set_color(ca, 0.26)
                glyphs[card.op_a](pos.ax, pos.ay, gs)
                set_color(cb, 0.26)
                glyphs[card.op_b](pos.bx, pos.by, gs)
            else
                local pos = glyph_layout.minor_pos(draw_rect)
                set_color(ca, 0.26)
                glyphs[card.op_a](pos.ax, pos.ay, gs)
                set_color(cb, 0.26)
                glyphs[card.op_b](pos.bx, pos.by, gs)
            end
            set_color(lerp_color(ca, cb, 0.5), 0.42)
            rounded("line", draw_rect.x + 3, draw_rect.y + 3, draw_rect.w - 6, draw_rect.h - 6, 9)
        end
        love.graphics.setFont(state.fonts.body)
        love.graphics.printf(card.id, draw_rect.x, draw_rect.y + draw_rect.h * 0.42, draw_rect.w, "center")
    end

    if committed then
        local commit_rect = {
            x = draw_rect.x - 3,
            y = draw_rect.y - 3,
            w = draw_rect.w + 6,
            h = draw_rect.h + 6,
        }
        local ca = OP_COLORS[card.op_a] or COLORS.drop
        local cb = OP_COLORS[card.op_b] or COLORS.drop
        local base = lerp_color(ca, cb, 0.5)
        set_color(base, 0.22)
        rounded("line", commit_rect.x, commit_rect.y, commit_rect.w, commit_rect.h, 12)
        draw_segmented_frame(commit_rect, {ca, cb}, love.timer.getTime() / 6.08, {
            width = math.max(2, state.layout.scale * 2.15),
            segment_count = 14,
            duty = 0.54,
        })
    end

    if choose_target then
        local cc = OP_COLORS.CHOOSE or COLORS.danger
        local hot = lerp_color(cc, COLORS.accent, 0.22)
        local choose_rect = {
            x = draw_rect.x - 5,
            y = draw_rect.y - 5,
            w = draw_rect.w + 10,
            h = draw_rect.h + 10,
        }
        set_color(cc, 0.18)
        rounded("line", choose_rect.x, choose_rect.y, choose_rect.w, choose_rect.h, 14)
        draw_segmented_frame(choose_rect, {cc, hot}, love.timer.getTime() / 3.04, {
            width = math.max(2, state.layout.scale * 2.35),
            segment_count = 14,
            duty = 0.56,
        })
    end

    if cycle_target then
        local cc = OP_COLORS.CYCLE or COLORS.drop
        local hot = lerp_color(cc, COLORS.accent, 0.22)
        local cycle_rect = {
            x = draw_rect.x - 5,
            y = draw_rect.y - 5,
            w = draw_rect.w + 10,
            h = draw_rect.h + 10,
        }
        set_color(cc, 0.18)
        rounded("line", cycle_rect.x, cycle_rect.y, cycle_rect.w, cycle_rect.h, 14)
        draw_segmented_frame(cycle_rect, {cc, hot}, love.timer.getTime() / 3.04, {
            width = math.max(2, state.layout.scale * 2.35),
            segment_count = 14,
            duty = 0.56,
        })
    end

    if observe_target then
        local cc = OP_COLORS.OBSERVE or COLORS.text
        local hot = lerp_color(cc, COLORS.accent, 0.18)
        local observe_rect = {
            x = draw_rect.x - 5,
            y = draw_rect.y - 5,
            w = draw_rect.w + 10,
            h = draw_rect.h + 10,
        }
        set_color(cc, 0.18)
        rounded("line", observe_rect.x, observe_rect.y, observe_rect.w, observe_rect.h, 14)
        draw_segmented_frame(observe_rect, {cc, hot}, love.timer.getTime() / 3.04, {
            width = math.max(2, state.layout.scale * 2.35),
            segment_count = 14,
            duty = 0.56,
        })
    end

    if manifest_target then
        local cc = OP_COLORS.MANIFEST or COLORS.accent
        local hot = lerp_color(cc, COLORS.text, 0.18)
        local manifest_rect = {
            x = draw_rect.x - 5,
            y = draw_rect.y - 5,
            w = draw_rect.w + 10,
            h = draw_rect.h + 10,
        }
        set_color(cc, 0.18)
        rounded("line", manifest_rect.x, manifest_rect.y, manifest_rect.w, manifest_rect.h, 14)
        draw_segmented_frame(manifest_rect, {cc, hot}, love.timer.getTime() / 3.04, {
            width = math.max(2, state.layout.scale * 2.35),
            segment_count = 14,
            duty = 0.56,
        })
    end

    if logic_target then
        local cc = OP_COLORS.LOGIC or COLORS.success
        local hot = lerp_color(cc, COLORS.text, 0.18)
        local logic_rect = {
            x = draw_rect.x - 5,
            y = draw_rect.y - 5,
            w = draw_rect.w + 10,
            h = draw_rect.h + 10,
        }
        set_color(cc, 0.18)
        rounded("line", logic_rect.x, logic_rect.y, logic_rect.w, logic_rect.h, 14)
        draw_segmented_frame(logic_rect, {cc, hot}, love.timer.getTime() / 3.04, {
            width = math.max(2, state.layout.scale * 2.35),
            segment_count = 14,
            duty = 0.56,
        })
    end

    if armed_choose_target or armed_cycle_target or armed_observe_target or armed_unrevealed_target or armed_logic_target then
        local ca = OP_COLORS[card.op_a] or COLORS.card
        local cb = OP_COLORS[card.op_b] or COLORS.card
        local phase = frame_breath_phase()
        local halo_color = lerp_color(ca, cb, phase)
        draw_breath_halo(draw_rect, halo_color, phase)
        local border_color = lerp_color(ca, cb, phase)
        set_color(border_color, 0.98)
        rounded("line", draw_rect.x, draw_rect.y, draw_rect.w, draw_rect.h, 10)
    end

    if legal_hint then
        if not (state.mode == "GAMEPLAY" and card.zone == "hand") then
            set_color(COLORS.success, 0.80)
            rounded("line", draw_rect.x - 3, draw_rect.y - 3, draw_rect.w + 6, draw_rect.h + 6, 12)
        end
    end

    if armed then
        if not (state.mode == "GAMEPLAY" and card.zone == "hand") then
            set_color(COLORS.drop, 0.90)
            rounded("line", draw_rect.x - 6, draw_rect.y - 6, draw_rect.w + 12, draw_rect.h + 12, 14)
        end
    end

    if selected or dragged then
        set_color(selected and COLORS.select or COLORS.drop, 0.35)
        rounded("line", draw_rect.x - 2, draw_rect.y - 2, draw_rect.w + 4, draw_rect.h + 4, 12)
    end
end

local function draw_zone_contents()
    local views = card_views()
    local drag_card = state.drag and state.drag.card_id or nil

    for _, zone_name in ipairs({"deck", "runtime", "play", "trump_flow", "trump", "targets", "manifest", "latent", "hand", "grave"}) do
        local zone = state.zones[zone_name]
        if zone.kind == "slots" then
            local rects = slot_rects_for_zone(zone_name)
            for slot, rect in ipairs(rects) do
                local hl = state.hover_target and state.hover_target.zone == zone_name and state.hover_target.slot == slot
                draw_slot_placeholder(rect, (zone_name == "runtime" or zone_name == "play") and "slot" or tostring(slot), hl)
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
        "TrumpFlow: " .. #state.zones.trump_flow.cards,
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
    draw_panel(state.layout.left.deck, "DECK", nil)
    draw_panel_counter(state.layout.left.deck, tostring(#state.zones.deck.cards), {
        align = "right",
        width = 88 * state.layout.scale,
        y = state.layout.left.deck.y + 54 * state.layout.scale,
        font = state.fonts.body,
        alpha = 0.96,
    })
    draw_panel(state.layout.left.play, "PLAY", "1 slot")
    draw_panel(state.layout.left.runtime, "RUNTIME", "1 slot")
end

local function draw_center()
    local flow_rect = state.layout.center.trump_flow
    draw_panel(flow_rect, "TRUMP FLOW", "3 visible slots")
    draw_panel(state.layout.center.targets, "TARGETS", "3 slots")
    draw_panel(state.layout.center.trump, "TRUMP ZONE", "2 slots")
    draw_panel(state.layout.center.combined, "MANIFEST / LATENT", nil)
    draw_panel(state.layout.center.hand, "HAND", nil)

    if #state.zones.trump_flow.cards > 0 then
        local train_colors = trump_flow_train_colors()
        if #train_colors > 0 then
            local speed = 6.08 / 2
            local frame_rect = {
                x = flow_rect.x - 3,
                y = flow_rect.y - 3,
                w = flow_rect.w + 6,
                h = flow_rect.h + 6,
            }
            local base = train_colors[1]
            set_color(base, 0.18)
            rounded("line", frame_rect.x, frame_rect.y, frame_rect.w, frame_rect.h, 12)
            draw_segmented_frame(frame_rect, train_colors, love.timer.getTime() / speed, {
                width = math.max(2, state.layout.scale * 2.5),
                segment_count = math.max(12, #train_colors * 4),
                duty = 0.56,
            })
        end
        love.graphics.setFont(state.fonts.small)
        set_color(COLORS.muted)
        local subtitle = is_board_closed() and "Pending event" or "Waiting for board closure"
        love.graphics.print(subtitle, flow_rect.x + 14 * state.layout.scale, flow_rect.y + 32 * state.layout.scale)
    else
        love.graphics.setFont(state.fonts.small)
        set_color(COLORS.muted)
        love.graphics.print("Idle", flow_rect.x + 14 * state.layout.scale, flow_rect.y + 32 * state.layout.scale)
    end

    local cw = state.layout.card_w
    local ch = state.layout.card_h
    local gap = math.floor(12 * state.layout.scale)
    local total_w = 3 * cw + 2 * gap
    local start_x = flow_rect.x + math.floor((flow_rect.w - total_w) / 2)
    local y = flow_rect.y + math.floor((flow_rect.h - ch) / 2)
    for slot = 1, 3 do
        local rect = {x = start_x + (slot - 1) * (cw + gap), y = y, w = cw, h = ch}
        draw_slot_placeholder(rect, tostring(slot), false)
    end

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
        local active = false
        if button.id == "start" or button.id == "reset" then
            active = true
        elseif button.id == "draw" then
            active = not state.anim.locked
        elseif button.id == "move" then
            active = state.pending_operator_choice ~= nil
                or state.pending_trump ~= nil
                or (state.committed and state.armed_hand ~= nil)
        elseif state.mode == "DEV" then
            active = button.id == "hints"
                or button.id == "flip"
                or button.id == "discard"
                or (state.selected ~= nil)
        elseif state.mode == "GAMEPLAY" then
            active = button.id == "hints"
        end
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
    local help
    if state.mode == "GAMEPLAY" then
        help = "S Start Game  1 draw  Space △ move/confirm  Esc clear selection  R reset"
    else
        help = "S Start Game  1 draw  V hints  Space △ move/confirm  2/F flip  3/Delete discard  R reset  H/M/L/T/U/P/G/K move to zone"
    end
    love.graphics.print(help, footer.x + math.floor(760 * state.layout.scale), footer.y + 14 * state.layout.scale)
end

local function draw_operator_buttons()
    if #state.ui.operator_buttons == 0 then
        return
    end
    local armed_operator = state.pending_operator_choice and state.pending_operator_choice.armed_operator or nil
    if not armed_operator then
        armed_operator = (state.pending_public_choice and state.pending_public_choice.operator)
            or (state.pending_hidden_choice and state.pending_hidden_choice.operator)
            or (state.pending_hand_choice and state.pending_hand_choice.operator)
            or (state.pending_manifest_choice and state.pending_manifest_choice.operator)
            or (state.pending_unrevealed_choice and state.pending_unrevealed_choice.operator)
    end
    for _, button in ipairs(state.ui.operator_buttons or {}) do
        local armed = armed_operator == button.op_name
        local op_color = OP_COLORS[button.op_name] or COLORS.text
        set_color(armed and COLORS.panel or COLORS.panel_alt)
        rounded("fill", button.rect.x, button.rect.y, button.rect.w, button.rect.h, 12)
        set_color(armed and op_color or COLORS.accent_soft)
        rounded("line", button.rect.x, button.rect.y, button.rect.w, button.rect.h, 12)
        set_color(op_color)
        love.graphics.setLineWidth(math.max(2, state.layout.scale * 2))
        glyphs[button.op_name](
            button.rect.x + button.rect.w * 0.5,
            button.rect.y + button.rect.h * 0.5 + math.floor(6 * state.layout.scale),
            math.floor(18 * state.layout.scale)
        )
        if armed then
            draw_segmented_frame(button.rect, {op_color}, love.timer.getTime() / 1.4, {
                width = math.max(2, state.layout.scale * 2.1),
                segment_count = 12,
                duty = 0.58,
                inset = 2,
            })
        end
    end
end

local function draw_grave_viewer()
    if not state.ui.grave_viewer.open then
        return
    end

    local rect = state.ui.grave_viewer.rect
    local content = state.ui.grave_viewer.content_rect
    if not rect or not content then
        return
    end

    set_color(COLORS.panel_alt)
    rounded("fill", rect.x, rect.y, rect.w, rect.h, 14)
    set_color(COLORS.outline)
    rounded("line", rect.x, rect.y, rect.w, rect.h, 14)

    love.graphics.setFont(state.fonts.title)
    set_color(COLORS.text)
    love.graphics.print("GRAVE", rect.x + 18 * state.layout.scale, rect.y + 12 * state.layout.scale)

    love.graphics.setFont(state.fonts.small)
    set_color(COLORS.muted)
    love.graphics.print("Newest first. Click outside to close.", rect.x + 18 * state.layout.scale, rect.y + 32 * state.layout.scale)

    for _, card_id in ipairs(state.ui.grave_viewer.ordered_cards or {}) do
        local card_rect = state.ui.grave_viewer.card_rects[card_id]
        if card_rect then
            draw_card(card_id, card_rect, false)
            love.graphics.setFont(state.fonts.small)
            set_color(COLORS.muted, 0.92)
            love.graphics.printf(
                tostring(card_rect.order),
                card_rect.x,
                card_rect.y + card_rect.h - 16 * state.layout.scale,
                card_rect.w - 4 * state.layout.scale,
                "right"
            )
        end
    end
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
    trace_line("trigger_button", "id=" .. tostring(id))
    if id == "start" then
        start_game()
        return
    end

    if id == "draw" then
        if state.pending_trump then
            state.message = "Resolve pending trump event first."
            return
        end
        if state.anim.locked then
            state.message = "Animation in progress."
            return
        end
        start_draw_sequence()
        return
    end

    if id == "hints" then
        if state.mode == "GAMEPLAY" then
            state.hints_enabled = true
            state.message = "Hints are always on in gameplay."
            return
        end
        state.hints_enabled = not state.hints_enabled
        if not state.hints_enabled then
            clear_commit_state()
        end
        state.message = "Hints " .. (state.hints_enabled and "enabled." or "disabled.")
        push_log("Hints -> " .. (state.hints_enabled and "on" or "off") .. ".")
        return
    end

    if id == "move" then
        if state.pending_public_choice then
            confirm_pending_public_target()
        elseif state.pending_manifest_choice then
            confirm_pending_manifest_target()
        elseif state.pending_hidden_choice then
            confirm_pending_hidden_target()
        elseif state.pending_unrevealed_choice then
            confirm_pending_unrevealed_target()
        elseif state.pending_hand_choice then
            confirm_pending_hand_target()
        elseif state.pending_operator_choice then
            confirm_pending_operator_phase()
        elseif state.pending_trump then
            start_pending_trump_resolution()
        else
            launch_committed_play()
        end
        return
    end

    if id == "flip" then
        if state.mode ~= "DEV" then
            state.message = "Manual flip is DEV-only."
            return
        end
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
        if state.mode ~= "DEV" then
            state.message = "Manual discard is DEV-only."
            return
        end
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
    local reset = io.open(TRACE_PATH, "w")
    if reset then
        reset:write("")
        reset:close()
    end
    init_fonts()
    build_empty_surface()
    refresh_layout(true)
    trace_line("love_load", "")
end

function love.resize()
    refresh_layout(true)
end

function love.update(dt)
    refresh_layout()
    update_active_anim(dt or 0)
    start_next_anim()
    refresh_pending_trump()
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
    draw_panel_counter(state.layout.right.grave, tostring(#state.zones.grave.cards), {
        align = "right",
        width = 88 * state.layout.scale,
        y = state.layout.right.grave.y + state.layout.right.grave.h - 34 * state.layout.scale,
        font = state.fonts.body,
        alpha = 0.96,
    })
    if state.pending_public_choice or (state.pending_operator_choice and state.pending_operator_choice.armed_operator == "LOGIC") then
        local rect = state.layout.right.grave
        local cc = OP_COLORS.LOGIC or COLORS.success
        local hot = lerp_color(cc, COLORS.text, 0.18)
        local logic_rect = {
            x = rect.x - 4,
            y = rect.y - 4,
            w = rect.w + 8,
            h = rect.h + 8,
        }
        set_color(cc, 0.16)
        rounded("line", logic_rect.x, logic_rect.y, logic_rect.w, logic_rect.h, 14)
        draw_segmented_frame(logic_rect, {cc, hot}, love.timer.getTime() / 3.04, {
            width = math.max(2, state.layout.scale * 2.25),
            segment_count = 14,
            duty = 0.56,
        })
    end
    draw_zone_contents()
    draw_grave_viewer()
    draw_footer()
    draw_operator_buttons()
end

function love.mousepressed(x, y, button)
    trace_line("mousepressed", string.format("x=%d y=%d button=%d", x, y, button))
    if state.anim.locked then
        state.message = "Animation in progress."
        return
    end

    if button == 1 then
        if state.ui.grave_viewer.open then
            if not point_in_rect(x, y, state.ui.grave_viewer.rect) then
                close_grave_viewer()
                return
            end
            if state.pending_public_choice then
                for card_id, rect in pairs(state.ui.grave_viewer.card_rects or {}) do
                    if point_in_rect(x, y, rect) then
                        arm_pending_public_target(card_id)
                        return
                    end
                end
            end
            return
        end

        for _, op_button in ipairs(state.ui.operator_buttons or {}) do
            if point_in_rect(x, y, op_button.rect) then
                choose_pending_operator(op_button.op_name)
                return
            end
        end
        for _, spec in ipairs(state.ui.buttons) do
            if point_in_rect(x, y, spec.rect) then
                trigger_button(spec.id)
                return
            end
        end

        if point_in_rect(x, y, state.layout.right.grave) then
            open_grave_viewer()
            return
        end

        if state.pending_public_choice then
            local card_id = pick_card(x, y)
            if card_id then
                local clicked = state.cards[card_id]
                if clicked and (clicked.zone == "manifest" or clicked.zone == "latent" or clicked.zone == "deck") then
                    arm_pending_public_target(card_id)
                    return
                end
            end
            state.message = "Choose one revealed minor card."
            return
        end

        if state.pending_manifest_choice then
            local card_id = pick_card(x, y)
            if card_id then
                local clicked = state.cards[card_id]
                if clicked and clicked.zone == "manifest" and clicked.slot then
                    arm_pending_manifest_target(clicked.slot)
                    return
                end
            end
            state.message = "Choose one revealed manifest card."
            return
        end

        if state.pending_hidden_choice then
            local card_id = pick_card(x, y)
            if card_id then
                arm_pending_hidden_target(card_id)
                return
            end
            state.message = "Choose one hidden card on board."
            return
        end

        if state.pending_unrevealed_choice then
            local card_id = pick_card(x, y)
            if card_id then
                arm_pending_unrevealed_target(card_id)
                return
            end
            state.message = "Choose one not-revealed card on board."
            return
        end

        if state.pending_hand_choice then
            local card_id = pick_card(x, y)
            if card_id then
                local clicked = state.cards[card_id]
                if clicked and clicked.zone == "hand" then
                    arm_pending_hand_target(card_id)
                    return
                end
            end
            state.message = "Choose one hand card to discard."
            return
        end

        if state.pending_operator_choice then
            state.message = "Arm an operator or none, then press △."
            return
        end

        if state.mode == "GAMEPLAY" and state.pending_trump then
            state.message = "Resolve pending trump event first."
            return
        end

        local card_id, rect = pick_card(x, y)
        if card_id then
            local clicked = state.cards[card_id]
            if state.mode == "GAMEPLAY"
                and state.hints_enabled
                and clicked
                and clicked.zone == "manifest"
                and clicked.slot
            then
                state.selected = nil
                state.drag = nil
                commit_manifest_card(card_id, clicked.slot)
                return
            end
            if state.mode == "GAMEPLAY" and clicked.zone == "hand" then
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
                state.selected = nil
                state.message = "Click a legal hand card to arm it, or drag within hand to reorder."
                return
            end
            state.selected = card_id
            if state.mode ~= "GAMEPLAY" then
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
            else
                state.drag = nil
            end
            state.message = "Selected " .. card_id .. "."
            return
        end

        local target = pick_drop_target(x, y)
        if target and state.selected then
            if state.mode == "GAMEPLAY" then
                state.message = "Free zone manipulation is disabled in gameplay."
                return
            end
            local selected_card = state.cards[state.selected]
            if state.mode == "GAMEPLAY"
                and selected_card
                and selected_card.zone == "hand"
                and target.zone == "manifest"
                and target.slot
            then
                state.message = "Use △ to cast against the committed manifest slot."
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
        if state.mode == "GAMEPLAY" then
            state.message = "Manual flip is disabled in gameplay."
            return
        end
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

    if state.mode == "GAMEPLAY" then
        local card_id = state.drag.card_id
        if state.cards[card_id] and state.cards[card_id].zone == "hand" and not state.drag.moved then
            state.drag = nil
            state.hover_target = nil
            arm_hand_card(card_id)
            return
        end
        if state.cards[card_id] and state.cards[card_id].zone == "hand" and state.drag.moved then
            local target = pick_drop_target(x, y)
            if target and target.zone == "hand" then
                local insert_index = hand_insert_index_for_x(x, card_id)
                state.drag = nil
                state.hover_target = nil
                insert_hand_card_at(card_id, insert_index, "hand-reorder")
                return
            end
        end
        state.drag = nil
        state.hover_target = nil
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
            state.message = "Use △ to cast against the committed manifest slot."
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
    trace_line("keypressed", "key=" .. tostring(key))
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
    elseif key == "space" then
        trigger_button("move")
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
    elseif state.mode ~= "DEV" and (key == "h" or key == "m" or key == "l" or key == "t" or key == "u" or key == "p" or key == "g" or key == "k") then
        state.message = "Zone shortcuts are DEV-only."
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
