local CD = CharacterDump

-- ponytail: tope a ojo, sin medir. Los EditBox de 3.3.5 se arrastran con
-- volcados grandes. Ajustar contra un cliente real con un personaje de mil
-- logros; si aguanta más, subirlo.
local MAX_PASTE_BYTES = 100 * 1024

function CD.dump()
  local out = CD.seal()
  local pending = 0
  for _, name in ipairs(CD.order) do
    local s = CharacterDumpDB.chars[CD.key()].sections[name]
    if not (s and s.captured) then pending = pending + 1 end
  end

  print("|cff33ff99CharacterDump|r — sellado, " .. #out .. " bytes")
  if pending > 0 then
    print("  |cffffff00" .. pending .. " secciones sin capturar|r — /cdump status para verlas")
  end
  -- SavedVariables no se escribe al disco hasta salir o recargar. Sin este
  -- aviso el jugador sube el fichero de la sesión anterior y no entiende por
  -- qué le falta el banco al que acaba de ir.
  print("  Ahora haz |cff00ff00/reload|r y sube |cff00ff00CharacterDump.lua|r")
  print("  Está en WTF\\Account\\<TU CUENTA>\\SavedVariables\\")
end

local frame

function CD.show()
  local text = CharacterDumpDB and CharacterDumpDB.export
  if not text then
    print("|cff33ff99CharacterDump|r — todavía no has sellado nada. Haz /cdump primero.")
    return
  end
  if #text > MAX_PASTE_BYTES then
    print("|cff33ff99CharacterDump|r — el volcado son " .. math.floor(#text / 1024) ..
          " KB, demasiado para copiar y pegar.")
    print("  Haz |cff00ff00/reload|r y sube el fichero CharacterDump.lua.")
    return
  end

  if not frame then
    frame = CreateFrame("Frame", "CharacterDumpFrame", UIParent)
    frame:SetPoint("CENTER")
    frame:SetWidth(520)
    frame:SetHeight(360)
    frame:SetBackdrop({
      bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local scroll = CreateFrame("ScrollFrame", "CharacterDumpScroll", frame,
                               "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -24)
    scroll:SetPoint("BOTTOMRIGHT", -40, 40)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(440)
    edit:SetAutoFocus(false)
    edit:SetScript("OnEscapePressed", function() frame:Hide() end)
    scroll:SetScrollChild(edit)
    frame.edit = edit

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)
  end

  frame.edit:SetText(text)
  frame:Show()
  frame.edit:SetFocus()
  frame.edit:HighlightText()
  print("|cff33ff99CharacterDump|r — Ctrl+C para copiar, Escape para cerrar.")
end
