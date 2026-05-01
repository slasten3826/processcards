local core = require("src.core.api")
local input = require("src.manifest.input")
local layout_lib = require("src.manifest.layout")
local playback = require("src.manifest.playback")
local render = require("src.manifest.render")

local TRACE_PATH = "love_trace.log"

local App = {}
App.__index = App

local app = setmetatable({
    core = core,
    game = nil,
    interaction = nil,
    layout = nil,
    fonts = {},
    ui = {
        grave_open = false,
        grave_viewer = {
            rect = nil,
            content_rect = nil,
            card_rects = {},
            ordered_cards = {},
        },
        operator_buttons = {},
        footer_buttons = {},
    },
    log = {},
    message = "",
}, App)

local function safe_tostring(value)
    if value == nil then
        return "-"
    end
    return tostring(value)
end

local function action_desc(action)
    if not action then
        return "-"
    end
    local desc = action.kind or "-"
    if action.slot then
        return desc .. ":" .. tostring(action.slot)
    end
    if action.card_id then
        return desc .. ":" .. tostring(action.card_id)
    end
    if action.operator then
        return desc .. ":" .. tostring(action.operator)
    end
    if action.target then
        return desc .. ":" .. tostring(action.target.card_id or action.target.slot or "-")
    end
    return desc
end

function App:trace(tag, details)
    local file = io.open(TRACE_PATH, "a")
    if not file then
        return
    end

    local ix = self.interaction or {}
    local armed = ix.armed or {}
    local target = armed.target
    local target_bits = {}
    local advance = ix.advance or {}
    local play_card = self.game and self.game.zones and self.game.zones.play and self.game.zones.play.cards[1] or nil
    local targets = ix.legal and ix.legal.targets or {}

    for _, ref in ipairs(armed.targets or {}) do
        target_bits[#target_bits + 1] = string.format(
            "%s:%s:%s",
            safe_tostring(ref.kind),
            safe_tostring(ref.zone),
            safe_tostring(ref.card_id or ref.slot)
        )
    end

    file:write(string.format(
        "%s | phase=%s prompt=%s advance=%s:%s hand=%s op=%s target=%s:%s:%s targets=%s target_kind=%s target_cards=%d target_slots=%d play=%s | %s\n",
        tag,
        safe_tostring(ix.phase),
        safe_tostring(ix.prompt),
        advance.enabled and "yes" or "no",
        safe_tostring(advance.reason),
        safe_tostring(armed.hand_card_id),
        safe_tostring(armed.operator),
        target and safe_tostring(target.kind) or "-",
        target and safe_tostring(target.zone) or "-",
        target and safe_tostring(target.card_id or target.slot) or "-",
        #target_bits > 0 and table.concat(target_bits, ",") or "-",
        safe_tostring(targets.kind),
        #(targets.cards or {}),
        #(targets.slots or {}),
        safe_tostring(play_card),
        details or ""
    ))
    file:close()
end

function App:push_log(line)
    table.insert(self.log, 1, line)
    if #self.log > 24 then
        table.remove(self.log)
    end
end

function App:set_message(text)
    self.message = text or ""
end

function App:refresh()
    self.interaction = self.core.interaction(self.game)
    local grave_mode = self.interaction
        and self.interaction.phase == "await_target"
        and self.interaction.legal
        and self.interaction.legal.targets
        and self.interaction.legal.targets.zones
        and self.interaction.legal.targets.zones.grave
    if not grave_mode then
        self.ui.grave_open = false
    end
end

function App:apply_action(action, message)
    self:trace("apply_action:before", string.format("action=%s message=%s", action_desc(action), safe_tostring(message)))
    local result = self.core.apply_action(self.game, action)
    self:refresh()
    local summary = result and result.summary or nil
    self:trace("apply_action:after", string.format(
        "action=%s error=%s kind=%s",
        action_desc(action),
        safe_tostring(summary and summary.error),
        safe_tostring(result and result.kind)
    ))
    playback.handle_result(self, result, message)
end

function App:start_game()
    self.game = self.core.new()
    self.core.start_game(self.game, {
        rng = function(max_n)
            return love.math.random(max_n)
        end,
    })
    self.log = {}
    self:set_message("Start Game complete.")
    self:refresh()
    self:trace("start_game", "new core game started")
end

function App:load()
    local file = io.open(TRACE_PATH, "w")
    if file then
        file:write("")
        file:close()
    end
    self.fonts.small = love.graphics.newFont(11)
    self.fonts.body = love.graphics.newFont(15)
    self.fonts.title = love.graphics.newFont(18)
    self.fonts.big = love.graphics.newFont(22)
    self.layout = layout_lib.make_layout()
    self:start_game()
    self:trace("load", "manifest app loaded")
end

function App:resize()
    self.layout = layout_lib.make_layout()
    self:trace("resize", string.format("w=%s h=%s", love.graphics.getWidth(), love.graphics.getHeight()))
end

function App:update()
    self.layout = layout_lib.make_layout()
end

function App:draw()
    render.draw(self)
end

function App:mousepressed(x, y, button)
    if button ~= 1 then
        return
    end
    self:trace("mousepressed", string.format("x=%d y=%d button=%d", x, y, button))
    input.click(self, x, y)
end

function App:mousereleased()
end

function App:mousemoved()
end

function App:keypressed(key)
    self:trace("keypressed", "key=" .. safe_tostring(key))
    if key == "space" then
        self:apply_action({kind = "advance"}, "Advance")
    elseif key == "s" then
        self:start_game()
    elseif key == "1" then
        self:apply_action({kind = "draw"}, "Draw")
    elseif key == "g" then
        self.ui.grave_open = not self.ui.grave_open
    elseif key == "r" then
        self:start_game()
    end
end

return app
