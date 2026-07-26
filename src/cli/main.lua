local script_dir = (arg and arg[0] and arg[0]:match("^(.*)/[^/]+$")) or "."

local project_root = script_dir
if project_root:match("/src/cli$") then
    project_root = project_root:gsub("/src/cli$", "")
elseif project_root:match("/cli$") then
    project_root = project_root:gsub("/cli$", "")
elseif project_root == "." then
    project_root = "."
end

package.path = table.concat({
    project_root .. "/src/?.lua",
    project_root .. "/src/?/init.lua",
    project_root .. "/src/?/?.lua",
    package.path,
}, ";")

local core = require("src.core.api")
local render = require("src.cli.render")
local input = require("src.cli.input")
local glyphs = require("src.cli.glyphs")
local sim_rng = require("src.sim.rng")

local DEV_TRUMP_PRESETS = {
    none = {},
    foolrush = {"FOOL", "RUSH"},
    full = nil,
}

local CONTEXT_PRESETS = {
    compact = {
        event_limit = 8,
        zone_limit = 10,
        transition_limit = 12,
    },
    default = {
        event_limit = 16,
        zone_limit = 20,
        transition_limit = 24,
    },
    max = {
        event_limit = 40,
        zone_limit = 80,
        transition_limit = 80,
    },
}

local function clear_screen()
    io.write(string.char(0x1b) .. "[2J")
    io.write(string.char(0x1b) .. "[H")
end

local function describe_event(event)
    if not event then
        return nil
    end
    local payload = event.payload or {}
    if event.type == "commit_manifest" then
        return string.format("commit manifest[%s] -> %s", tostring(payload.slot or "-"), tostring(payload.card_id or "-"))
    end
    if event.type == "arm_hand" then
        return string.format("arm hand -> %s", tostring(payload.card_id or "-"))
    end
    if event.type == "arm_operator" then
        return string.format("arm operator -> %s", tostring(payload.operator or "none"))
    end
    if event.type == "operator_resolve" then
        return string.format("resolve %s", tostring(payload.operator or "-"))
    end
    if event.type == "repair_manifest" then
        return string.format("repair manifest[%s]", tostring(payload.slot or "-"))
    end
    if event.type == "draw_to_hand" then
        return string.format("draw -> %s", tostring(payload.card_id or "-"))
    end
    if event.type == "start_game" or event.type == "setup_complete" then
        return event.type
    end
    return event.type
end

local function summarize_result(result)
    if not result then
        return ""
    end
    if result.summary and result.summary.error then
        return "ERROR: " .. result.summary.error
    end
    if result.kind then
        return "OK: " .. result.kind
    end
    return "OK"
end

local function phase_help(ix)
    local lines = {
        "PHASE " .. tostring(ix.phase or "?"),
        "PROMPT " .. tostring(ix.prompt or "-"),
    }

    local legal = ix.legal or {}
    if legal.commit_slots and #legal.commit_slots > 0 then
        lines[#lines + 1] = "commit slots: " .. table.concat(legal.commit_slots, ", ")
    end
    if legal.hand_cards and #legal.hand_cards > 0 then
        lines[#lines + 1] = "hand cards: " .. table.concat(legal.hand_cards, ", ")
    end
    if legal.operators and #legal.operators > 0 then
        lines[#lines + 1] = "operators: " .. table.concat(legal.operators, ", ")
    end
    if legal.directions and #legal.directions > 0 then
        lines[#lines + 1] = "directions: " .. table.concat(legal.directions, ", ")
    end
    if legal.targets then
        lines[#lines + 1] = "target kind: " .. tostring(legal.targets.kind or "-")
        if legal.targets.slots and #legal.targets.slots > 0 then
            local slots = {}
            for _, slot in ipairs(legal.targets.slots) do
                slots[#slots + 1] = tostring(slot)
            end
            lines[#lines + 1] = "target slots: " .. table.concat(slots, ", ")
        end
        if legal.targets.cards and #legal.targets.cards > 0 then
            lines[#lines + 1] = "target cards: " .. table.concat(legal.targets.cards, ", ")
        end
    end
    if legal.clears then
        local clears = {}
        if legal.clears.selection then clears[#clears + 1] = "selection" end
        if legal.clears.committed then clears[#clears + 1] = "committed" end
        if legal.clears.armed then clears[#clears + 1] = "armed" end
        if #clears > 0 then
            lines[#lines + 1] = "clears: " .. table.concat(clears, ", ")
        end
    end
    if ix.advance and ix.advance.enabled then
        lines[#lines + 1] = "advance: " .. tostring(ix.advance.label or "enabled")
    end

    return lines
end

local function transition_lines(transition, limit)
    if not transition then
        return {"(no transition)"}
    end
    local lines = {
        string.format("transition #%s kind=%s", tostring(transition.seq or "-"), tostring(transition.kind or "-")),
    }
    local summary = transition.summary or {}
    if summary.error then
        lines[#lines + 1] = "summary.error=" .. tostring(summary.error)
    else
        local keys = {}
        for key, _ in pairs(summary) do
            keys[#keys + 1] = key
        end
        table.sort(keys)
        if #keys == 0 then
            lines[#lines + 1] = "summary=ok"
        else
            local bits = {}
            for _, key in ipairs(keys) do
                bits[#bits + 1] = key .. "=" .. tostring(summary[key])
            end
            lines[#lines + 1] = "summary " .. table.concat(bits, " ")
        end
    end
    local shown = 0
    for _, event in ipairs(transition.events or {}) do
        shown = shown + 1
        lines[#lines + 1] = "- " .. tostring(describe_event(event) or event.type or "?")
        if limit and shown >= limit then
            local total = #(transition.events or {})
            if shown < total then
                lines[#lines + 1] = string.format("... %d more", total - shown)
            end
            break
        end
    end
    return lines
end

local function split_tokens(raw)
    local out = {}
    for token in string.gmatch(raw or "", "%S+") do
        out[#out + 1] = token
    end
    return out
end

local function trimmed_recent_events(lines, limit)
    if #lines <= limit then
        return lines
    end
    local trimmed = {}
    for i = #lines - limit + 1, #lines do
        trimmed[#trimmed + 1] = lines[i]
    end
    return trimmed
end

local function card_text(state, card_id)
    local card = state.cards[card_id]
    if not card then
        return tostring(card_id)
    end
    if card.class == "trump" then
        return string.format("%s %s", glyphs.pair(card.op_a, card.op_b), card.trump_name or card.id)
    end
    return string.format("%s %s", glyphs.pair(card.op_a, card.op_b), card.id)
end

local function zone_slot_label(zone_name, slot)
    if zone_name == "manifest" then return "m" .. tostring(slot) end
    if zone_name == "latent" then return "l" .. tostring(slot) end
    if zone_name == "targets" then return "t" .. tostring(slot) end
    if zone_name == "trump" then return "z" .. tostring(slot) end
    if zone_name == "runtime" then return "r" .. tostring(slot) end
    if zone_name == "play" then return "p" .. tostring(slot) end
    if zone_name == "deck" then return "d" .. tostring(slot) end
    return tostring(slot)
end

local function zone_lines(state, zone_name, limit)
    local zone = state.zones[zone_name]
    if not zone then
        return {"unknown zone: " .. tostring(zone_name)}
    end

    local lines = {
        string.format("ZONE %s kind=%s", zone_name, zone.kind),
    }

    if zone.kind == "slots" then
        for slot = 1, zone.slot_count do
            local card_id = zone.cards[slot]
            if card_id then
                local card = state.cards[card_id]
                lines[#lines + 1] = string.format(
                    "%s = %s [%s %s]",
                    zone_slot_label(zone_name, slot),
                    card_text(state, card_id),
                    tostring(card.info_state or "-"),
                    tostring(card.class or "-")
                )
            else
                lines[#lines + 1] = string.format("%s = -", zone_slot_label(zone_name, slot))
            end
        end
        return lines
    end

    if #zone.cards == 0 then
        lines[#lines + 1] = "(empty)"
        return lines
    end

    local start_index = 1
    local stop_index = #zone.cards
    local step = 1
    if zone_name == "deck" or zone_name == "grave" then
        start_index = #zone.cards
        stop_index = 1
        step = -1
    end

    local shown = 0
    for i = start_index, stop_index, step do
        local card_id = zone.cards[i]
        local card = state.cards[card_id]
        shown = shown + 1
        lines[#lines + 1] = string.format(
            "%d. %s [%s %s]",
            shown,
            card_text(state, card_id),
            tostring(card.info_state or "-"),
            tostring(card.class or "-")
        )
        if shown >= limit then
            if shown < #zone.cards then
                lines[#lines + 1] = string.format("... %d more", #zone.cards - shown)
            end
            break
        end
    end
    return lines
end

local function where_lines(state, raw_query)
    local query = (raw_query or ""):upper()
    local lines = {}
    for card_id, card in pairs(state.cards) do
        local hay = {
            tostring(card_id),
            tostring(card.trump_name or ""),
            tostring(card.class or ""),
            tostring(card.op_a or ""),
            tostring(card.op_b or ""),
        }
        local match = false
        for _, bit in ipairs(hay) do
            if bit ~= "" and bit:upper():find(query, 1, true) then
                match = true
                break
            end
        end
        if match then
            lines[#lines + 1] = string.format(
                "%s -> zone=%s slot=%s state=%s",
                card_text(state, card_id),
                tostring(card.zone or "-"),
                tostring(card.slot or "-"),
                tostring(card.info_state or "-")
            )
        end
    end
    table.sort(lines)
    if #lines == 0 then
        return {"no match: " .. raw_query}
    end
    return lines
end

local function config_lines(settings)
    return {
        "CONFIG",
        string.format("context=%s", tostring(settings.context_preset or "custom")),
        string.format("events=%d", settings.event_limit),
        string.format("zone=%d", settings.zone_limit),
        string.format("transition=%d", settings.transition_limit),
    }
end

local function legal_lines(ix)
    local lines = {
        "LEGAL",
        "phase=" .. tostring(ix.phase or "?"),
    }
    local legal = ix.legal or {}
    if legal.commit_slots then
        lines[#lines + 1] = "commit_slots=" .. table.concat(legal.commit_slots, ",")
    end
    if legal.hand_cards then
        lines[#lines + 1] = "hand_cards=" .. table.concat(legal.hand_cards, ",")
    end
    if legal.operators then
        lines[#lines + 1] = "operators=" .. table.concat(legal.operators, ",")
    end
    if legal.directions then
        lines[#lines + 1] = "directions=" .. table.concat(legal.directions, ",")
    end
    if legal.targets then
        lines[#lines + 1] = "target_kind=" .. tostring(legal.targets.kind or "-")
        if legal.targets.slots then
            local slots = {}
            for _, slot in ipairs(legal.targets.slots) do
                slots[#slots + 1] = tostring(slot)
            end
            lines[#lines + 1] = "target_slots=" .. table.concat(slots, ",")
        end
        if legal.targets.cards then
            lines[#lines + 1] = "target_cards=" .. table.concat(legal.targets.cards, ",")
        end
    end
    if legal.clears then
        local clears = {}
        if legal.clears.selection then clears[#clears + 1] = "selection" end
        if legal.clears.committed then clears[#clears + 1] = "committed" end
        if legal.clears.armed then clears[#clears + 1] = "armed" end
        lines[#lines + 1] = "clears=" .. table.concat(clears, ",")
    end
    if ix.advance then
        lines[#lines + 1] = "advance=" .. tostring(ix.advance.enabled or false)
        if ix.advance.label then
            lines[#lines + 1] = "advance_label=" .. tostring(ix.advance.label)
        end
    end
    return lines
end

local function history_lines(history, limit)
    if #history == 0 then
        return {"(no history)"}
    end
    local count = math.min(limit or #history, #history)
    local start_index = #history - count + 1
    local lines = {"HISTORY"}
    for i = start_index, #history do
        local item = history[i]
        lines[#lines + 1] = string.format(
            "%d. phase=%s input=%s result=%s",
            i,
            tostring(item.phase or "-"),
            tostring(item.input or "-"),
            tostring(item.result or "-")
        )
    end
    return lines
end

local function apply_context_preset(settings, preset_name)
    local preset = CONTEXT_PRESETS[preset_name]
    if not preset then
        return false
    end
    settings.context_preset = preset_name
    settings.event_limit = preset.event_limit
    settings.zone_limit = preset.zone_limit
    settings.transition_limit = preset.transition_limit
    return true
end

local function main()
    local state = core.new()
    local status_message = ""
    local recent_events = {}
    local debug_lines = {}
    local last_transition = nil
    local current_seed = 1
    local command_history = {}
    local settings = {}
    local start_opts = {
        trump_mode = "full",
        enabled_trumps = DEV_TRUMP_PRESETS.full,
    }
    apply_context_preset(settings, "default")

    local function build_start_opts()
        return {
            rng = sim_rng.from_seed(current_seed),
            trump_mode = start_opts.trump_mode,
            enabled_trumps = start_opts.enabled_trumps,
        }
    end

    local function start_new_game()
        state = core.new()
        local result = core.start_game(state, build_start_opts())
        last_transition = result
        status_message = summarize_result(result)
        recent_events = {}
        debug_lines = {}
        for _, event in ipairs(core.drain_events(state)) do
            local text = describe_event(event)
            if text then
                recent_events[#recent_events + 1] = text
            end
        end
    end

    start_new_game()

    while true do
        clear_screen()
        local ix = core.interaction(state)
        local output = render.render(state, ix, {
            message = status_message,
            events = recent_events,
            debug_lines = debug_lines,
        })
        io.write(output)
        io.write("> ")
        io.flush()

        local raw = io.read()
        if not raw then
            break
        end
        debug_lines = {}

        local preset = raw:match("^%s*dev%s+([%w_%-]+)%s*$")
        if preset then
            preset = preset:lower()
            if preset == "full" or DEV_TRUMP_PRESETS[preset] ~= nil then
                start_opts.trump_mode = preset
                start_opts.enabled_trumps = DEV_TRUMP_PRESETS[preset]
                start_new_game()
                status_message = "OK: dev preset " .. preset
            else
                status_message = "ERROR: unknown dev preset"
            end
            goto continue
        end
        local preset_alias = raw:match("^%s*preset%s+([%w_%-]+)%s*$")
        if preset_alias then
            preset_alias = preset_alias:lower()
            if preset_alias == "full" or DEV_TRUMP_PRESETS[preset_alias] ~= nil then
                start_opts.trump_mode = preset_alias
                start_opts.enabled_trumps = DEV_TRUMP_PRESETS[preset_alias]
                start_new_game()
                status_message = "OK: preset " .. preset_alias
            else
                status_message = "ERROR: unknown preset"
            end
            goto continue
        end
        local seed_value = raw:match("^%s*seed%s+(%-?%d+)%s*$")
        if seed_value then
            current_seed = tonumber(seed_value)
            start_new_game()
            status_message = "OK: seed " .. tostring(current_seed)
            goto continue
        end
        local raw_trimmed = raw:match("^%s*(.-)%s*$")
        if raw_trimmed == "ix" then
            debug_lines = phase_help(core.interaction(state))
            status_message = "INFO: interaction"
            goto continue
        end
        if raw_trimmed == "help" then
            debug_lines = phase_help(core.interaction(state))
            status_message = "INFO: phase help"
            goto continue
        end
        if raw_trimmed == "snap" then
            debug_lines = {}
            for line in string.gmatch(core.snapshot(state), "[^\n]+") do
                debug_lines[#debug_lines + 1] = line
            end
            status_message = "INFO: snapshot"
            goto continue
        end
        if raw_trimmed == "last" then
            debug_lines = transition_lines(last_transition, settings.transition_limit)
            status_message = "INFO: last transition"
            goto continue
        end
        if raw_trimmed == "events" then
            debug_lines = {}
            if #recent_events == 0 then
                debug_lines[1] = "(no recent events)"
            else
                for _, line in ipairs(recent_events) do
                    debug_lines[#debug_lines + 1] = line
                end
            end
            status_message = "INFO: recent events"
            goto continue
        end
        if raw_trimmed == "legal" then
            debug_lines = legal_lines(core.interaction(state))
            status_message = "INFO: legal"
            goto continue
        end
        local history_limit = raw:match("^%s*history%s*(%d*)%s*$")
        if history_limit ~= nil then
            local limit = tonumber(history_limit) or settings.transition_limit
            debug_lines = history_lines(command_history, limit)
            status_message = "INFO: history"
            goto continue
        end
        if raw_trimmed == "config" then
            debug_lines = config_lines(settings)
            status_message = "INFO: config"
            goto continue
        end
        local context_preset = raw:match("^%s*context%s+([%w_%-]+)%s*$")
        if context_preset then
            context_preset = context_preset:lower()
            if apply_context_preset(settings, context_preset) then
                debug_lines = config_lines(settings)
                status_message = "OK: context " .. context_preset
            else
                status_message = "ERROR: unknown context preset"
            end
            goto continue
        end
        local set_key, set_value = raw:match("^%s*set%s+([%w_%-]+)%s+(%d+)%s*$")
        if set_key and set_value then
            local value = tonumber(set_value)
            local map = {
                events = "event_limit",
                event = "event_limit",
                zone = "zone_limit",
                transition = "transition_limit",
                transitions = "transition_limit",
            }
            local field = map[set_key:lower()]
            if field and value and value > 0 then
                settings[field] = value
                settings.context_preset = "custom"
                debug_lines = config_lines(settings)
                status_message = "OK: set " .. set_key:lower() .. " " .. tostring(value)
            else
                status_message = "ERROR: unknown config key"
            end
            goto continue
        end
        local where_query = raw:match("^%s*where%s+(.+)%s*$")
        if where_query then
            debug_lines = where_lines(state, where_query)
            status_message = "INFO: where " .. where_query
            goto continue
        end
        local zone_name = raw:match("^%s*zone%s+([%w_%-]+)%s*$")
        if zone_name then
            zone_name = zone_name:lower()
            debug_lines = zone_lines(state, zone_name, settings.zone_limit)
            status_message = "INFO: zone " .. zone_name
            goto continue
        end

        local tokens = split_tokens(raw)
        if #tokens == 0 then
            tokens = {""}
        end

        recent_events = {}
        for _, token in ipairs(tokens) do
            local current_ix = core.interaction(state)
            local action = input.parse(state, current_ix, token)
            if not action then
                status_message = token == "" and "No action." or ("No action: " .. token)
                break
            end

            if action.kind == "start" then
                start_new_game()
                break
            end

            local result = core.apply_action(state, action)
            last_transition = result
            status_message = summarize_result(result)
            command_history[#command_history + 1] = {
                phase = current_ix.phase,
                input = token,
                result = status_message,
            }
            for _, event in ipairs(core.drain_events(state)) do
                local text = describe_event(event)
                if text then
                    recent_events[#recent_events + 1] = text
                end
            end
            recent_events = trimmed_recent_events(recent_events, settings.event_limit)

            if result.summary and result.summary.error then
                break
            end
            if token ~= tokens[#tokens] and core.interaction(state).phase ~= current_ix.phase then
                status_message = status_message .. " | phase->" .. tostring(core.interaction(state).phase)
            end
        end

        if #tokens > 1 and status_message:match("^No action:") then
            status_message = status_message .. " | stopped in phase " .. tostring(core.interaction(state).phase)
        end

        ::continue::
    end
end

main()
