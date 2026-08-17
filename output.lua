local CD = CharacterDump
local L = CD.L

-- Los EditBox de 3.3.5 se arrastran con volcados grandes, así que por encima
-- del tope no se abre la caja y se manda al fichero.
-- Medido en un 3.3.5a real, personaje con las 22 secciones capturadas: 22 KB.
-- El tope sobra por 4x y /cdump show abrió sin arrastrarse. Subirlo solo si
-- aparece un personaje que lo roce.
local MAX_PASTE_BYTES = 100 * 1024

function CD.dump()
  local out = CD.seal()
  local pending = 0
  for _, name in ipairs(CD.order) do
    local s = CharacterDumpDB.chars[CD.key()].sections[name]
    if not (s and s.captured) then pending = pending + 1 end
  end

  print("|cff33ff99CharacterDump|r — " .. string.format(L["sealed, %d bytes"], #out))
  if pending > 0 then
    print("  |cffffff00" .. string.format(L["%d sections not captured"], pending) ..
          "|r — " .. L["type /cdump status to see them"])
  end
  -- SavedVariables no se escribe al disco hasta salir o recargar. Sin este
  -- aviso el jugador sube el fichero de la sesión anterior y no entiende por
  -- qué le falta el banco al que acaba de ir.
  print("  " .. string.format(L["Now type %s and upload %s"],
        "|cff00ff00/reload|r", "|cff00ff00CharacterDump.lua|r"))
  print("  " .. string.format(L["It is in %s"], L["WTF\\Account\\<YOUR ACCOUNT>\\SavedVariables\\"]))
end

local frame

function CD.show()
  local text = CharacterDumpDB and CharacterDumpDB.export
  if not text then
    print("|cff33ff99CharacterDump|r — " .. L["nothing sealed yet. Type /cdump first."])
    return
  end
  if #text > MAX_PASTE_BYTES then
    print("|cff33ff99CharacterDump|r — " ..
          string.format(L["the dump is %d KB, too big to copy and paste."],
                        math.floor(#text / 1024)))
    print("  " .. string.format(L["Type %s and upload the CharacterDump.lua file."],
          "|cff00ff00/reload|r"))
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
  print("|cff33ff99CharacterDump|r — " .. L["Ctrl+C to copy, Escape to close."])
end
