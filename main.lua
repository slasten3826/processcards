local CANON_PATH = "/home/slasten/Документы/stack/stack-core/ProcessLang/canon.lua"
local TEXT_FONT_CANDIDATES = {
  "/usr/share/fonts/TTF/DejaVuSans.ttf",
  "/usr/share/fonts/dejavu/DejaVuSans.ttf",
  "/usr/share/fonts/liberation/LiberationSans-Regular.ttf",
}
local SYMBOL_FONT_CANDIDATES = {
  "/usr/share/fonts/noto/NotoSansSymbols2-Regular.ttf",
  "/usr/share/fonts/TTF/DejaVuSans.ttf",
  "/usr/share/fonts/dejavu/DejaVuSans.ttf",
}

local palette = {
  bg = {0.07, 0.08, 0.09},
  panel = {0.11, 0.12, 0.14},
  panel2 = {0.13, 0.14, 0.16},
  line = {0.24, 0.25, 0.28},
  lineSoft = {0.18, 0.19, 0.22},
  text = {0.88, 0.84, 0.79},
  dim = {0.63, 0.61, 0.57},
  accent = {0.84, 0.43, 0.22},
  accentSoft = {0.84, 0.43, 0.22, 0.20},
  bad = {0.74, 0.34, 0.29},
  ok = {0.71, 0.61, 0.42},
  card = {0.91, 0.88, 0.82},
  ink = {0.10, 0.10, 0.10},
  back = {0.10, 0.11, 0.12},
}

local operators = {
  { index = 1, glyph = "▽", name = "FLOW" },
  { index = 2, glyph = "☰", name = "CONNECT" },
  { index = 3, glyph = "☷", name = "DISSOLVE" },
  { index = 4, glyph = "☵", name = "ENCODE" },
  { index = 5, glyph = "☳", name = "CHOOSE" },
  { index = 6, glyph = "☴", name = "OBSERVE" },
  { index = 7, glyph = "☲", name = "CYCLE" },
  { index = 8, glyph = "☶", name = "LOGIC" },
  { index = 9, glyph = "☱", name = "RUNTIME" },
  { index = 10, glyph = "△", name = "MANIFEST" },
}

local operatorByGlyph = {}
for _, operator in ipairs(operators) do
  operatorByGlyph[operator.glyph] = operator
end

local actionDefs = {
  { id = "play", title = "Play", description = "auto weak / strong" },
  { id = "discard", title = "Discard", description = "hand -> grave" },
  { id = "pass", title = "Pass", description = "end turn" },
}

local canon = nil
local nextInstanceId = 1
local ui = {
  topbar = {},
  actionButtons = {},
  handCards = {},
  manifestCards = {},
  latentCards = {},
  targetCards = {},
  promptButtons = {},
  deck = {},
}

local fonts = {}
local state = nil

local function loadFontWithFallback(size, candidates)
  for _, path in ipairs(candidates or {}) do
    local ok, font = pcall(love.graphics.newFont, path, size)
    if ok and font then
      return font
    end
  end
  return love.graphics.newFont(size)
end

local function loadCanon()
  local ok, result = pcall(dofile, CANON_PATH)
  if ok and type(result) == "table" and type(result.is_adjacent) == "function" then
    return result
  end

  local fallback = {
    ["▽"] = {"☰", "☷", "☴"},
    ["☰"] = {"▽", "☷", "☴", "☵"},
    ["☷"] = {"▽", "☰", "☴", "☳"},
    ["☴"] = {"▽", "☰", "☷", "☵", "☳", "☱"},
    ["☵"] = {"☰", "☴", "☱", "☳", "☲"},
    ["☳"] = {"☷", "☴", "☱", "☵", "☶"},
    ["☶"] = {"☳", "☲", "☱", "△"},
    ["☲"] = {"☵", "☶", "△", "☱"},
    ["☱"] = {"☴", "△", "☵", "☳", "☶", "☲"},
    ["△"] = {"☱", "☲", "☶"},
  }

  return {
    is_adjacent = function(left, right)
      local list = fallback[left]
      if not list then
        return false
      end
      for _, glyph in ipairs(list) do
        if glyph == right then
          return true
        end
      end
      return false
    end,
  }
end

local function newCard(a, b)
  local card = {
    kind = "minor",
    instanceId = nextInstanceId,
    id = string.format("M-%03d", nextInstanceId),
    a = a,
    b = b,
    title = a.glyph .. b.glyph,
    label = a.name .. " + " .. b.name,
  }
  nextInstanceId = nextInstanceId + 1
  return card
end

local function newHiddenSlot(card)
  return {
    card = card,
    publicRevealed = false,
    observed = false,
  }
end

local function shuffle(array)
  for i = #array, 2, -1 do
    local j = love.math.random(i)
    array[i], array[j] = array[j], array[i]
  end
  return array
end

local function buildDeck()
  local deck = {}
  for _, a in ipairs(operators) do
    for _, b in ipairs(operators) do
      deck[#deck + 1] = newCard(a, b)
    end
  end
  return shuffle(deck)
end

local function addLog(text)
  table.insert(state.log, 1, text)
  while #state.log > 18 do
    table.remove(state.log)
  end
end

local function drawCard()
  local card = table.remove(state.deck, 1)
  state.deckObserved = false
  return card
end

local function describeCard(card)
  if not card then
    return "empty"
  end
  return string.format("%s (%s)", card.title, card.label)
end

local function cardOperators(card)
  return { card.a.glyph, card.b.glyph }
end

local function uniqueOperators(card)
  local result = {}
  local seen = {}
  for _, glyph in ipairs(cardOperators(card)) do
    if not seen[glyph] then
      seen[glyph] = true
      result[#result + 1] = glyph
    end
  end
  return result
end

local function hasOperator(card, glyph)
  return card.a.glyph == glyph or card.b.glyph == glyph
end

local function otherOperator(card, glyph)
  if card.a.glyph == glyph then
    return card.b.glyph
  end
  return card.a.glyph
end

local function isWeakRelation(left, right)
  if not left or not right then
    return false
  end
  if hasOperator(left, "☶") then
    return false
  end
  return left.a.glyph == right.a.glyph or left.b.glyph == right.b.glyph
end

local function isStrongRelation(left, right)
  if not left or not right then
    return false
  end
  return canon.is_adjacent(left.b.glyph, right.a.glyph) or canon.is_adjacent(right.b.glyph, left.a.glyph)
end

local function isMirrorRelation(left, right)
  if not left or not right then
    return false
  end
  return left.a.glyph == right.b.glyph and left.b.glyph == right.a.glyph
end

local function countValidMoves(mode)
  local count = 0
  for _, handCard in ipairs(state.hand) do
    for _, target in ipairs(state.manifest) do
      if mode == "weak" and isWeakRelation(handCard, target) then
        count = count + 1
      end
      if mode == "strong" and isStrongRelation(handCard, target) then
        count = count + 1
      end
    end
  end
  return count
end

local function relationType(left, right)
  if isStrongRelation(left, right) then
    return "strong"
  end
  if isWeakRelation(left, right) then
    return "weak"
  end
  return nil
end

local function selectedRelationStats()
  if not state.selectedHandIndex then
    return 0, 0
  end
  local card = state.hand[state.selectedHandIndex]
  local weak = 0
  local strong = 0
  for _, target in ipairs(state.manifest) do
    local relation = relationType(card, target)
    if relation == "strong" then
      strong = strong + 1
    elseif relation == "weak" then
      weak = weak + 1
    end
  end
  return weak, strong
end

local function clearSelection()
  state.selectedHandIndex = nil
  state.selectedManifestIndex = nil
end

local function endTurn()
  state.turn = state.turn + 1
  state.actionMode = "play"
  state.pending = nil
  state.prompt = "Choose Play, then hand card, then manifest slot."
  state.promptButtons = {}
  state.effectSession = nil
  clearSelection()
end

local function drawIntoHand(amount, reason)
  for _ = 1, amount do
    local card = drawCard()
    if not card then
      addLog(reason .. ": deck empty.")
      return
    end
    state.hand[#state.hand + 1] = card
    addLog(reason .. ": draw " .. describeCard(card) .. ".")
  end
end

local function nextColumn(index)
  return (index % 5) + 1
end

local function shiftHiddenLeft(slots)
  local movable = {}
  for index, slot in ipairs(slots) do
    if slot.card and not slot.publicRevealed then
      movable[#movable + 1] = index
    end
  end

  if #movable <= 1 then
    return false
  end

  local snapshot = {}
  for _, index in ipairs(movable) do
    local slot = slots[index]
    snapshot[#snapshot + 1] = {
      card = slot.card,
      observed = slot.observed,
    }
  end

  for i, index in ipairs(movable) do
    local source = snapshot[(i % #snapshot) + 1]
    slots[index].card = source.card
    slots[index].observed = source.observed
  end

  return true
end

local function localObserve(columnIndex)
  local slot = state.latent[columnIndex]
  if not slot or not slot.card then
    addLog("OBSERVE: no latent card in column " .. columnIndex .. ".")
    return
  end
  slot.observed = true
  addLog("OBSERVE: latent " .. columnIndex .. " inspected as " .. describeCard(slot.card) .. ".")
end

local function localManifest(columnIndex)
  local slot = state.latent[columnIndex]
  if not slot or not slot.card then
    addLog("MANIFEST: no latent card in column " .. columnIndex .. ".")
    return
  end
  slot.publicRevealed = true
  slot.observed = false
  addLog("MANIFEST: latent " .. columnIndex .. " became public.")
end

local function localDissolve(columnIndex)
  local slot = state.latent[columnIndex]
  if not slot or not slot.card then
    addLog("DISSOLVE: no latent card in column " .. columnIndex .. ".")
    return
  end
  table.insert(state.grave, 1, slot.card)
  addLog("DISSOLVE: latent " .. columnIndex .. " -> grave (" .. describeCard(slot.card) .. ").")
  slot.card = drawCard()
  slot.publicRevealed = false
  slot.observed = false
end

local function localEncode(columnIndex)
  local j = nextColumn(columnIndex)
  local left = state.latent[columnIndex]
  local right = state.latent[j]
  if not left.card or not right.card then
    addLog("ENCODE: missing latent pair near column " .. columnIndex .. ".")
    return
  end
  if left.publicRevealed or right.publicRevealed then
    addLog("ENCODE: public anchor blocked the swap.")
    return
  end
  state.latent[columnIndex], state.latent[j] = right, left
  addLog("ENCODE: latent " .. columnIndex .. " swapped with latent " .. j .. ".")
end

local function localFlow()
  if shiftHiddenLeft(state.latent) then
    addLog("FLOW: latent ring shifted one step left.")
  else
    addLog("FLOW: legal but no hidden movement available.")
  end
end

local function flowTargets()
  if shiftHiddenLeft(state.targets) then
    addLog("FLOW: target structure advanced one step.")
  else
    addLog("FLOW: target structure stayed anchored.")
  end
end

local function flowDeck()
  if #state.deck <= 1 then
    addLog("FLOW: deck has no meaningful forward motion.")
    return
  end
  local top = table.remove(state.deck, 1)
  table.insert(state.deck, top)
  state.deckObserved = false
  addLog("FLOW: topdeck moved to bottom.")
end

local function beginCycleDiscard()
  state.pending = { type = "cycle_discard" }
  state.prompt = "CYCLE: choose one hand card to discard."
  state.promptButtons = {}
end

local function applyCycle()
  local card = drawCard()
  if card then
    state.hand[#state.hand + 1] = card
    addLog("CYCLE: draw " .. describeCard(card) .. ".")
  else
    addLog("CYCLE: deck empty.")
  end
  beginCycleDiscard()
end

local function startEffectSession(context, options)
  state.effectSession = {
    context = context,
    options = options,
    used = {},
    maxEffects = context.mode == "weak" and 1 or 2,
  }
end

local function finishEffectIfDone()
  local session = state.effectSession
  if not session then
    endTurn()
    return
  end
  if #session.used >= session.maxEffects then
    endTurn()
    return
  end

  local remaining = {}
  local usedMap = {}
  for _, id in ipairs(session.used) do
    usedMap[id] = true
  end
  for _, option in ipairs(session.options) do
    if not usedMap[option.id] then
      remaining[#remaining + 1] = option
    end
  end

  if #remaining == 0 then
    endTurn()
    return
  end

  state.pending = { type = "choose_effect", options = remaining }
  state.promptButtons = {}
  for _, option in ipairs(remaining) do
    state.promptButtons[#state.promptButtons + 1] = {
      id = option.id,
      label = option.label,
      action = function()
        session.used[#session.used + 1] = option.id
        option.resolve()
      end,
    }
  end

  if #session.used > 0 then
    state.promptButtons[#state.promptButtons + 1] = {
      id = "skip",
      label = "Skip",
      action = function()
        endTurn()
      end,
    }
  end

  state.prompt = #session.used == 0 and "Choose effect branch." or "Choose second effect or skip."
end

local function chooseHidden(prompt, allow, callback)
  state.pending = { type = "choose_hidden", allow = allow, callback = callback }
  state.prompt = prompt
  state.promptButtons = {}
end

local function chooseFlowSpace()
  state.pending = { type = "choose_flow_space" }
  state.prompt = "Choose flow space."
  state.promptButtons = {
    { id = "flow_latent", label = "Flow Latent", action = function() localFlow(); finishEffectIfDone() end },
    { id = "flow_targets", label = "Flow Targets", action = function() flowTargets(); finishEffectIfDone() end },
    { id = "flow_deck", label = "Flow Deck", action = function() flowDeck(); finishEffectIfDone() end },
  }
end

local function chooseDissolveLatent()
  state.pending = { type = "choose_dissolve_latent" }
  state.prompt = "Choose latent card to dissolve."
  state.promptButtons = {}
end

local function chooseEncodePair(step, firstIndex)
  state.pending = { type = step, firstIndex = firstIndex }
  state.prompt = step == "choose_encode_first" and "Choose first latent slot." or "Choose second latent slot."
  state.promptButtons = {}
end

local function operatorOptions(card, mode, columnIndex)
  local options = {}
  local seen = {}
  local list = uniqueOperators(card)

  if mode == "weak" then
    if hasOperator(card, "☶") then
      return {}
    end
    if hasOperator(card, "☰") and #list > 1 then
      local filtered = {}
      for _, glyph in ipairs(list) do
        if glyph ~= "☰" then
          filtered[#filtered + 1] = glyph
        end
      end
      list = filtered
    end
  end

  local function addOption(id, label, fn)
    if seen[id] then
      return
    end
    seen[id] = true
    options[#options + 1] = { id = id, label = label, resolve = fn }
  end

  for _, glyph in ipairs(list) do
    if mode == "strong" and glyph == "☶" then
      local partner = otherOperator(card, "☶")
      addOption("logic_" .. partner, "LOGIC + " .. operatorByGlyph[partner].name, function()
        addLog("LOGIC branch -> " .. operatorByGlyph[partner].name .. ".")
        if partner == "▽" then
          chooseFlowSpace()
        elseif partner == "☴" then
          chooseHidden("LOGIC + OBSERVE: choose hidden card.", { latent = true, targets = true, deck = true }, function(zone, index)
            if zone == "deck" then
              state.deckObserved = true
              addLog("LOGIC + OBSERVE: topdeck inspected.")
            elseif zone == "latent" then
              state.latent[index].observed = true
              addLog("LOGIC + OBSERVE: latent " .. index .. " inspected.")
            elseif zone == "targets" then
              state.targets[index].observed = true
              addLog("LOGIC + OBSERVE: target " .. index .. " inspected.")
            end
            finishEffectIfDone()
          end)
        elseif partner == "△" then
          chooseHidden("LOGIC + MANIFEST: choose hidden card to reveal.", { latent = true, targets = true, deck = false }, function(zone, index)
            local slots = zone == "latent" and state.latent or state.targets
            slots[index].publicRevealed = true
            slots[index].observed = false
            addLog("LOGIC + MANIFEST: " .. zone .. " " .. index .. " became public.")
            finishEffectIfDone()
          end)
        else
          addLog("LOGIC + " .. operatorByGlyph[partner].name .. " is deferred in v0.")
          finishEffectIfDone()
        end
      end)
    elseif glyph ~= "☶" then
      addOption("op_" .. glyph, operatorByGlyph[glyph].name, function()
        addLog(string.upper(mode) .. " effect -> " .. operatorByGlyph[glyph].name .. ".")
        if glyph == "▽" then
          localFlow()
          finishEffectIfDone()
        elseif glyph == "☰" then
          addLog("CONNECT multi-card assembly is deferred in v0.")
          finishEffectIfDone()
        elseif glyph == "☷" then
          localDissolve(columnIndex)
          finishEffectIfDone()
        elseif glyph == "☵" then
          localEncode(columnIndex)
          finishEffectIfDone()
        elseif glyph == "☳" then
          addLog("CHOOSE safe mode: standalone no-op.")
          finishEffectIfDone()
        elseif glyph == "☴" then
          localObserve(columnIndex)
          finishEffectIfDone()
        elseif glyph == "☲" then
          applyCycle()
        elseif glyph == "☱" then
          addLog("RUNTIME install is documented but deferred in v0.")
          finishEffectIfDone()
        elseif glyph == "△" then
          localManifest(columnIndex)
          finishEffectIfDone()
        end
      end)
    end
  end

  if mode == "strong" and hasOperator(card, "☳") and #list > 1 then
    for _, glyph in ipairs(list) do
      if glyph ~= "☳" and glyph ~= "☶" then
        addOption("combo_" .. glyph, "CHOOSE + " .. operatorByGlyph[glyph].name, function()
          addLog("STRONG effect -> CHOOSE + " .. operatorByGlyph[glyph].name .. ".")
          if glyph == "▽" then
            chooseFlowSpace()
          elseif glyph == "☴" then
            chooseHidden("CHOOSE + OBSERVE: choose hidden card.", { latent = true, targets = true, deck = true }, function(zone, index)
              if zone == "deck" then
                state.deckObserved = true
                addLog("CHOOSE + OBSERVE: topdeck inspected.")
              elseif zone == "latent" then
                state.latent[index].observed = true
                addLog("CHOOSE + OBSERVE: latent " .. index .. " inspected.")
              else
                state.targets[index].observed = true
                addLog("CHOOSE + OBSERVE: target " .. index .. " inspected.")
              end
              finishEffectIfDone()
            end)
          elseif glyph == "△" then
            chooseHidden("CHOOSE + MANIFEST: choose hidden card to reveal.", { latent = true, targets = true, deck = false }, function(zone, index)
              local slots = zone == "latent" and state.latent or state.targets
              slots[index].publicRevealed = true
              slots[index].observed = false
              addLog("CHOOSE + MANIFEST: " .. zone .. " " .. index .. " became public.")
              finishEffectIfDone()
            end)
          elseif glyph == "☷" then
            chooseDissolveLatent()
          elseif glyph == "☵" then
            chooseEncodePair("choose_encode_first")
          else
            addLog("CHOOSE + " .. operatorByGlyph[glyph].name .. " is deferred in v0.")
            finishEffectIfDone()
          end
        end)
      end
    end
  end

  return options
end

local function startResolvedAction(mode, handIndex, manifestIndex)
  local played = table.remove(state.hand, handIndex)
  local replaced = state.manifest[manifestIndex]
  table.insert(state.grave, 1, replaced)
  state.manifest[manifestIndex] = played

  addLog(string.upper(mode) .. ": " .. describeCard(played) .. " replaced slot " .. manifestIndex .. ".")

  if mode == "strong" then
    drawIntoHand(2, "Strong")
  end

  clearSelection()
  local options = operatorOptions(played, mode, manifestIndex)
  startEffectSession({ mode = mode, card = played, columnIndex = manifestIndex }, options)
  finishEffectIfDone()
end

local function resetState()
  nextInstanceId = 1
  state = {
    deck = buildDeck(),
    hand = {},
    manifest = {},
    latent = {},
    targets = {},
    runtime = nil,
    grave = {},
    log = {},
    turn = 1,
    actionMode = "play",
    selectedHandIndex = nil,
    selectedManifestIndex = nil,
    prompt = "Choose Play, then hand card, then manifest slot.",
    promptButtons = {},
    pending = nil,
    effectSession = nil,
    deckObserved = false,
  }

  for _ = 1, 3 do
    state.targets[#state.targets + 1] = newHiddenSlot(drawCard())
  end
  for _ = 1, 5 do
    state.manifest[#state.manifest + 1] = drawCard()
  end
  for _ = 1, 5 do
    state.latent[#state.latent + 1] = newHiddenSlot(drawCard())
  end
  for _ = 1, 5 do
    state.hand[#state.hand + 1] = drawCard()
  end

  addLog("LÖVE prototype booted.")
  addLog("Minor-only machine online. No victory conditions yet.")
end

local function pointInRect(x, y, rect)
  return rect and x >= rect.x and y >= rect.y and x <= rect.x + rect.w and y <= rect.y + rect.h
end

local function setColor(color)
  love.graphics.setColor(color)
end

local function drawPanel(rect)
  setColor(palette.panel)
  love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 8, 8)
  setColor(palette.lineSoft)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 8, 8)
  setColor({1, 1, 1, 0.06})
  love.graphics.rectangle("line", rect.x + 6, rect.y + 6, rect.w - 12, rect.h - 12, 6, 6)
end

local function drawTextBlock(font, color, text, x, y, w, align)
  love.graphics.setFont(font)
  setColor(color)
  love.graphics.printf(text, x, y, w, align or "left")
end

local function drawCardFace(card, rect, opts)
  opts = opts or {}
  local fill = opts.faceDown and palette.back or palette.card
  local text = opts.faceDown and palette.text or palette.ink
  setColor(fill)
  love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 8, 8)

  if opts.highlight == "good" then
    setColor(palette.accentSoft)
    love.graphics.rectangle("fill", rect.x - 2, rect.y - 2, rect.w + 4, rect.h + 4, 10, 10)
  end
  if opts.highlight == "weak" then
    setColor({palette.ok[1], palette.ok[2], palette.ok[3], 0.18})
    love.graphics.rectangle("fill", rect.x - 2, rect.y - 2, rect.w + 4, rect.h + 4, 10, 10)
  end
  if opts.highlight == "bad" then
    setColor({palette.bad[1], palette.bad[2], palette.bad[3], 0.18})
    love.graphics.rectangle("fill", rect.x - 2, rect.y - 2, rect.w + 4, rect.h + 4, 10, 10)
  end

  setColor(opts.borderColor or palette.line)
  love.graphics.setLineWidth(opts.selected and 3 or 1)
  love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 8, 8)

  drawTextBlock(fonts.monoSmall, {text[1], text[2], text[3], 0.72}, opts.id or card.id, rect.x + 8, rect.y + 8, rect.w - 16)
  if opts.faceDown then
    drawTextBlock(fonts.symbolLarge, text, opts.center or "◎", rect.x + 10, rect.y + rect.h * 0.36, rect.w - 20, "center")
    drawTextBlock(fonts.small, {text[1], text[2], text[3], 0.72}, opts.subtitle or "hidden", rect.x + 8, rect.y + rect.h - 38, rect.w - 16, "center")
  else
    drawTextBlock(fonts.symbolLarge, text, card.title, rect.x + 10, rect.y + 28, rect.w - 20, "center")
    drawTextBlock(fonts.small, {text[1], text[2], text[3], 0.86}, card.label, rect.x + 10, rect.y + 72, rect.w - 20, "center")
    drawTextBlock(fonts.monoSmall, {text[1], text[2], text[3], 0.72}, opts.badge or "MINOR", rect.x + 10, rect.y + rect.h - 28, rect.w - 20, "right")
  end
end

local function layout()
  local w, h = love.graphics.getDimensions()
  local pad = 16
  local topbarH = 90
  local gap = 14
  local leftW = 220
  local rightW = 300
  local centerW = w - pad * 2 - leftW - rightW - gap * 2
  local leftX = pad
  local centerX = leftX + leftW + gap
  local rightX = centerX + centerW + gap
  local bodyY = pad + topbarH + gap
  local bodyH = h - bodyY - pad

  ui.topbar = { x = pad, y = pad, w = w - pad * 2, h = topbarH }
  ui.left = { x = leftX, y = bodyY, w = leftW, h = bodyH }
  ui.center = { x = centerX, y = bodyY, w = centerW, h = bodyH }
  ui.right = { x = rightX, y = bodyY, w = rightW, h = bodyH }

  ui.leftPanels = {
    deck = { x = leftX, y = bodyY, w = leftW, h = 220 },
    runtime = { x = leftX, y = bodyY + 234, w = leftW, h = 180 },
    status = { x = leftX, y = bodyY + 428, w = leftW, h = bodyH - 428 },
  }

  ui.centerPanels = {
    targets = { x = centerX, y = bodyY, w = centerW, h = 150 },
    board = { x = centerX, y = bodyY + 164, w = centerW, h = 340 },
    hand = { x = centerX, y = bodyY + 518, w = centerW, h = bodyH - 518 },
  }

  ui.rightPanels = {
    prompt = { x = rightX, y = bodyY, w = rightW, h = 180 },
    grave = { x = rightX, y = bodyY + 194, w = rightW, h = 260 },
    log = { x = rightX, y = bodyY + 468, w = rightW, h = bodyH - 468 },
  }

  ui.actionButtons = {}
  local bx = ui.topbar.x + ui.topbar.w - 120 * #actionDefs - 12 * (#actionDefs - 1) - 22
  local by = ui.topbar.y + 18
  for i, action in ipairs(actionDefs) do
    ui.actionButtons[i] = { action = action.id, x = bx + (i - 1) * 132, y = by, w = 120, h = 54 }
  end

  local cardW = math.floor((centerW - 32 - 14 * 4) / 5)
  local cardH = math.floor(cardW / 0.70)
  ui.manifestCards = {}
  ui.latentCards = {}
  local startX = ui.centerPanels.board.x + 18
  local manifestY = ui.centerPanels.board.y + 72
  local latentY = manifestY + cardH + 16
  for i = 1, 5 do
    local rect = { x = startX + (i - 1) * (cardW + 14), y = manifestY, w = cardW, h = cardH }
    ui.manifestCards[i] = rect
    ui.latentCards[i] = { x = rect.x, y = latentY, w = cardW, h = cardH }
  end

  ui.targetCards = {}
  local targetW = 110
  local targetH = 154
  local tx = ui.centerPanels.targets.x + 22
  for i = 1, 3 do
    ui.targetCards[i] = { x = tx + (i - 1) * (targetW + 16), y = ui.centerPanels.targets.y + 46, w = targetW, h = targetH }
  end

  ui.handCards = {}
  local handY = ui.centerPanels.hand.y + 58
  for i = 1, math.max(5, #state.hand) do
    ui.handCards[i] = { x = startX + (i - 1) * (cardW + 10), y = handY, w = cardW, h = cardH }
  end

  ui.deck = { x = ui.leftPanels.deck.x + 25, y = ui.leftPanels.deck.y + 44, w = 136, h = 190 }
  ui.runtimeCard = { x = ui.leftPanels.runtime.x + 25, y = ui.leftPanels.runtime.y + 44, w = 136, h = 190 }

  ui.promptButtons = {}
  local px = ui.rightPanels.prompt.x + 18
  local py = ui.rightPanels.prompt.y + 92
  for i, button in ipairs(state.promptButtons) do
    local row = math.floor((i - 1) / 2)
    local col = (i - 1) % 2
    ui.promptButtons[i] = { x = px + col * 130, y = py + row * 42, w = 118, h = 34, action = button.action }
  end
end

local function drawActionButtons()
  for i, def in ipairs(actionDefs) do
    local rect = ui.actionButtons[i]
    local active = state.actionMode == def.id
    setColor(active and palette.panel2 or palette.panel)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 8, 8)
    setColor(active and palette.accent or palette.line)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 8, 8)
    drawTextBlock(fonts.monoSmall, active and palette.text or palette.dim, def.title, rect.x, rect.y + 8, rect.w, "center")
    drawTextBlock(fonts.small, palette.dim, def.description, rect.x + 6, rect.y + 26, rect.w - 12, "center")
  end
end

local function drawTopbar()
  drawPanel(ui.topbar)
  drawTextBlock(fonts.title, palette.text, "PROCESS", ui.topbar.x + 20, ui.topbar.y + 16, 220)
  drawTextBlock(fonts.title, palette.accent, "CARDS", ui.topbar.x + 132, ui.topbar.y + 16, 220)
  drawTextBlock(fonts.small, palette.dim, "LÖVE v0 minor-machine", ui.topbar.x + 22, ui.topbar.y + 52, 240)
  drawActionButtons()
end

local function drawDeckPanel()
  local panel = ui.leftPanels.deck
  drawPanel(panel)
  drawTextBlock(fonts.monoSmall, palette.text, "DECK", panel.x + 16, panel.y + 14, panel.w - 32)
  drawCardFace({ id = "DECK" }, ui.deck, {
    faceDown = true,
    id = "DECK",
    center = tostring(#state.deck),
    subtitle = state.deckObserved and state.deck[1] and state.deck[1].title or "top hidden",
  })
  drawTextBlock(fonts.small, palette.dim, string.format("%d cards remaining", #state.deck), panel.x + 16, panel.y + panel.h - 40, panel.w - 32)
end

local function drawRuntimePanel()
  local panel = ui.leftPanels.runtime
  drawPanel(panel)
  drawTextBlock(fonts.monoSmall, palette.text, "RUNTIME", panel.x + 16, panel.y + 14, panel.w - 32)
  if state.runtime then
    drawCardFace(state.runtime, ui.runtimeCard, { badge = "RUNTIME" })
  else
    drawCardFace({ id = "EMPTY" }, ui.runtimeCard, { faceDown = true, id = "EMPTY", center = "1", subtitle = "slot only" })
  end
  drawTextBlock(fonts.small, palette.dim, "Runtime install is deferred in v0.", panel.x + 16, panel.y + panel.h - 40, panel.w - 32)
end

local function drawStatusPanel()
  local panel = ui.leftPanels.status
  drawPanel(panel)
  drawTextBlock(fonts.monoSmall, palette.text, "SYSTEM", panel.x + 16, panel.y + 14, panel.w - 32)
  local selectedWeak, selectedStrong = selectedRelationStats()
  local rows = {
    { "Turn", tostring(state.turn) },
    { "Mode", string.upper(state.actionMode) },
    { "Weak", tostring(countValidMoves("weak")) },
    { "Strong", tostring(countValidMoves("strong")) },
    { "Hand", tostring(#state.hand) },
    { "Sel Weak", tostring(selectedWeak) },
    { "Sel Strong", tostring(selectedStrong) },
  }
  local y = panel.y + 48
  for _, row in ipairs(rows) do
    drawTextBlock(fonts.small, palette.dim, row[1], panel.x + 16, y, 80)
    drawTextBlock(fonts.monoSmall, palette.text, row[2], panel.x + 90, y, panel.w - 110, "right")
    y = y + 26
  end
end

local function drawTargetsPanel()
  local panel = ui.centerPanels.targets
  drawPanel(panel)
  drawTextBlock(fonts.monoSmall, palette.text, "TARGETS", panel.x + 16, panel.y + 14, panel.w - 32)
  drawTextBlock(fonts.small, palette.dim, "Victory shell only. No win condition yet.", panel.x + 16, panel.y + 32, panel.w - 32)
  for i, slot in ipairs(state.targets) do
    local rect = ui.targetCards[i]
    if slot.publicRevealed then
      drawCardFace(slot.card, rect, { badge = "PUBLIC" })
    elseif slot.observed then
      drawCardFace(slot.card, rect, { badge = "PEEKED" })
    else
      drawCardFace(slot.card or { id = "T" .. i }, rect, { faceDown = true, id = "T-" .. i, subtitle = "hidden target" })
    end
  end
end

local function drawBoardPanel()
  local panel = ui.centerPanels.board
  drawPanel(panel)
  drawTextBlock(fonts.monoSmall, palette.text, "MANIFEST CHAIN", panel.x + 16, panel.y + 14, panel.w - 32)
  drawTextBlock(fonts.small, palette.dim, "Manifest ring is 1-2-3-4-5-1. After hand selection, slots show WEAK or STRONG automatically.", panel.x + 16, panel.y + 32, panel.w - 32)
  drawTextBlock(fonts.monoSmall, palette.dim, "Manifest", panel.x + 18, panel.y + 54, 100)
  drawTextBlock(fonts.monoSmall, palette.dim, "Latent", panel.x + 18, panel.y + 54 + ui.manifestCards[1].h + 16, 100)

  for i, card in ipairs(state.manifest) do
    local highlight = nil
    local badge = "MANIFEST"
    local borderColor = nil
    if state.selectedHandIndex then
      local selected = state.hand[state.selectedHandIndex]
      if state.actionMode == "play" then
        local relation = relationType(selected, card)
        if relation == "strong" then
          highlight = "good"
          borderColor = palette.accent
          badge = "STRONG"
        elseif relation == "weak" then
          highlight = "weak"
          borderColor = palette.ok
          badge = "WEAK"
        else
          highlight = "bad"
        end
      end
    end
    drawCardFace(card, ui.manifestCards[i], {
      badge = isMirrorRelation(state.selectedHandIndex and state.hand[state.selectedHandIndex] or nil, card) and "MIRROR" or badge,
      selected = state.selectedManifestIndex == i,
      highlight = highlight,
      borderColor = borderColor,
    })
  end

  for i, slot in ipairs(state.latent) do
    local rect = ui.latentCards[i]
    if slot.publicRevealed then
      drawCardFace(slot.card, rect, { badge = "PUBLIC" })
    elseif slot.observed then
      drawCardFace(slot.card, rect, { badge = "PEEKED" })
    else
      drawCardFace(slot.card or { id = "L" .. i }, rect, { faceDown = true, id = "L-" .. i, subtitle = "hidden latent" })
    end
  end
end

local function drawHandPanel()
  local panel = ui.centerPanels.hand
  drawPanel(panel)
  drawTextBlock(fonts.monoSmall, palette.text, "HAND", panel.x + 16, panel.y + 14, panel.w - 32)
  drawTextBlock(fonts.small, palette.dim, "Choose card, then manifest target. Weak/Strong is detected automatically.", panel.x + 16, panel.y + 32, panel.w - 32)
  for i, card in ipairs(state.hand) do
    drawCardFace(card, ui.handCards[i], {
      badge = "HAND",
      selected = state.selectedHandIndex == i,
    })
  end
end

local function drawPromptPanel()
  local panel = ui.rightPanels.prompt
  drawPanel(panel)
  drawTextBlock(fonts.monoSmall, palette.text, "RESOLUTION", panel.x + 16, panel.y + 14, panel.w - 32)
  drawTextBlock(fonts.small, palette.dim, state.prompt, panel.x + 16, panel.y + 40, panel.w - 32)
  for i, button in ipairs(state.promptButtons) do
    local rect = ui.promptButtons[i]
    setColor(palette.panel2)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 6, 6)
    setColor(palette.line)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 6, 6)
    drawTextBlock(fonts.monoSmall, palette.text, button.label, rect.x + 4, rect.y + 9, rect.w - 8, "center")
  end
end

local function drawGravePanel()
  local panel = ui.rightPanels.grave
  drawPanel(panel)
  drawTextBlock(fonts.monoSmall, palette.text, "GRAVE", panel.x + 16, panel.y + 14, panel.w - 32)
  drawTextBlock(fonts.small, palette.dim, string.format("Ordered residue: %d cards", #state.grave), panel.x + 16, panel.y + 32, panel.w - 32)
  local y = panel.y + 58
  for i = 1, math.min(5, #state.grave) do
    local card = state.grave[i]
    local rect = { x = panel.x + 18, y = y, w = panel.w - 36, h = 34 }
    setColor(palette.card)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 6, 6)
    setColor(palette.line)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 6, 6)
    drawTextBlock(fonts.monoSmall, palette.ink, card.title, rect.x + 10, rect.y + 8, 60)
    drawTextBlock(fonts.small, {0.1, 0.1, 0.1, 0.85}, card.label, rect.x + 68, rect.y + 9, rect.w - 78)
    y = y + 40
  end
end

local function drawLogPanel()
  local panel = ui.rightPanels.log
  drawPanel(panel)
  drawTextBlock(fonts.monoSmall, palette.text, "LOG", panel.x + 16, panel.y + 14, panel.w - 32)
  local y = panel.y + 40
  for i = 1, math.min(10, #state.log) do
    drawTextBlock(fonts.small, palette.dim, "• " .. state.log[i], panel.x + 16, y, panel.w - 32)
    y = y + 24
  end
end

local function clickActionButtons(x, y)
  for _, rect in ipairs(ui.actionButtons) do
    if pointInRect(x, y, rect) then
      state.actionMode = rect.action
      clearSelection()
      state.pending = nil
      state.effectSession = nil
      state.promptButtons = {}
      if rect.action == "pass" then
        addLog("Pass. No action resolved.")
        endTurn()
      else
        if rect.action == "discard" then
          state.prompt = "Choose hand card to discard."
        else
          state.prompt = "Choose hand card to see WEAK / STRONG targets."
        end
      end
      return true
    end
  end
  return false
end

local function clickPromptButtons(x, y)
  for i, rect in ipairs(ui.promptButtons) do
    if pointInRect(x, y, rect) then
      local button = state.promptButtons[i]
      if button and button.action then
        button.action()
      end
      return true
    end
  end
  return false
end

local function handleHiddenChoice(zoneName, index)
  local pending = state.pending
  if not pending then
    return false
  end

  if pending.type == "choose_hidden" then
    pending.callback(zoneName, index)
    return true
  end

  if pending.type == "choose_dissolve_latent" and zoneName == "latent" then
    local slot = state.latent[index]
    if slot and slot.card then
      table.insert(state.grave, 1, slot.card)
      state.latent[index] = newHiddenSlot(drawCard())
      addLog("CHOOSE + DISSOLVE: latent " .. index .. " -> grave.")
      finishEffectIfDone()
      return true
    end
  end

  if pending.type == "choose_encode_first" and zoneName == "latent" then
    local slot = state.latent[index]
    if slot and slot.card and not slot.publicRevealed then
      chooseEncodePair("choose_encode_second", index)
      return true
    end
  end

  if pending.type == "choose_encode_second" and zoneName == "latent" then
    local slot = state.latent[index]
    local first = state.latent[pending.firstIndex]
    if slot and slot.card and not slot.publicRevealed and first and first.card and index ~= pending.firstIndex then
      state.latent[pending.firstIndex], state.latent[index] = state.latent[index], state.latent[pending.firstIndex]
      addLog("CHOOSE + ENCODE: latent " .. pending.firstIndex .. " swapped with latent " .. index .. ".")
      finishEffectIfDone()
      return true
    end
  end

  return false
end

function love.load()
  love.window.setMode(1440, 900, { resizable = true, minwidth = 1200, minheight = 780 })
  love.math.setRandomSeed(os.time())
  canon = loadCanon()
  fonts.title = loadFontWithFallback(28, TEXT_FONT_CANDIDATES)
  fonts.symbolLarge = loadFontWithFallback(24, SYMBOL_FONT_CANDIDATES)
  fonts.monoSmall = loadFontWithFallback(14, TEXT_FONT_CANDIDATES)
  fonts.small = loadFontWithFallback(13, TEXT_FONT_CANDIDATES)
  resetState()
  layout()
end

function love.resize()
  layout()
end

function love.update()
  layout()
end

function love.draw()
  setColor(palette.bg)
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  drawTopbar()
  drawDeckPanel()
  drawRuntimePanel()
  drawStatusPanel()
  drawTargetsPanel()
  drawBoardPanel()
  drawHandPanel()
  drawPromptPanel()
  drawGravePanel()
  drawLogPanel()
end

function love.mousepressed(x, y, button)
  if button ~= 1 then
    return
  end

  if clickActionButtons(x, y) then
    return
  end
  if clickPromptButtons(x, y) then
    return
  end

  if pointInRect(x, y, ui.deck) then
    if state.pending and state.pending.type == "choose_hidden" and state.pending.allow.deck then
      state.pending.callback("deck", 1)
    elseif state.pending and state.pending.type == "choose_flow_space" then
      flowDeck()
      finishEffectIfDone()
    end
    return
  end

  for i, rect in ipairs(ui.handCards) do
    if pointInRect(x, y, rect) and state.hand[i] then
      if state.pending and state.pending.type == "cycle_discard" then
        local discarded = table.remove(state.hand, i)
        table.insert(state.grave, 1, discarded)
        addLog("CYCLE discard: " .. describeCard(discarded) .. ".")
        finishEffectIfDone()
        return
      end
      if state.actionMode == "discard" then
        local discarded = table.remove(state.hand, i)
        table.insert(state.grave, 1, discarded)
        addLog("Discard: " .. describeCard(discarded) .. ".")
        endTurn()
        return
      end
      state.selectedHandIndex = i
      local weakCount, strongCount = selectedRelationStats()
      state.prompt = string.format("Choose manifest slot. Weak: %d, Strong: %d.", weakCount, strongCount)
      return
    end
  end

  for i, rect in ipairs(ui.manifestCards) do
    if pointInRect(x, y, rect) then
      state.selectedManifestIndex = i
      if not state.selectedHandIndex then
        state.prompt = "Choose hand card first."
        return
      end
      local handCard = state.hand[state.selectedHandIndex]
      local target = state.manifest[i]
      if state.actionMode == "play" then
        local relation = relationType(handCard, target)
        if relation == "strong" then
          startResolvedAction("strong", state.selectedHandIndex, i)
          return
        elseif relation == "weak" then
          startResolvedAction("weak", state.selectedHandIndex, i)
          return
        else
          addLog("Play rejected: no weak or strong relation.")
          return
        end
      elseif state.actionMode == "discard" then
        return
      end
    end
  end

  for i, rect in ipairs(ui.latentCards) do
    if pointInRect(x, y, rect) then
      if handleHiddenChoice("latent", i) then
        return
      end
    end
  end

  for i, rect in ipairs(ui.targetCards) do
    if pointInRect(x, y, rect) then
      if handleHiddenChoice("targets", i) then
        return
      end
    end
  end
end

function love.keypressed(key)
  if key == "r" then
    resetState()
  elseif key == "escape" then
    clearSelection()
    state.pending = nil
    state.promptButtons = {}
    state.prompt = "Choose Play, then hand card, then manifest slot."
  end
end
