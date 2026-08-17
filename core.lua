-- Núcleo: registro de colectores, captura oportunista, sellado y comandos.
-- No sabe qué se vuelca. Los colectores no saben nada de esto.

local ADDON, VERSION, FORMAT = "CharacterDump", "0.1.0", 1

CharacterDump = CharacterDump or {}
local CD = CharacterDump

CD.collectors = CD.collectors or {}
CD.order = CD.order or {}   -- para que el orden del status y del JSON sea estable

function CD.register(name, def)
  CD.collectors[name] = def
  CD.order[#CD.order + 1] = name
end

function CD.key()
  return (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
end

local function db()
  CharacterDumpDB = CharacterDumpDB or {}
  CharacterDumpDB.chars = CharacterDumpDB.chars or {}
  local key = CD.key()
  CharacterDumpDB.chars[key] = CharacterDumpDB.chars[key] or { sections = {} }
  return CharacterDumpDB.chars[key]
end

-- Recibe directamente lo que devuelve pcall. Un colector que revienta es una
-- sección sin capturar con su motivo, que es la misma información que "no fui
-- al banco" — y por eso no hace falta un tercer estado.
local function store(name, ok, result)
  if ok then
    db().sections[name] = { captured = true, at = time(), data = result }
  else
    db().sections[name] = { captured = false, error = tostring(result) }
  end
end

function CD.capture(name)
  local def = CD.collectors[name]
  if not def then return end
  store(name, pcall(def.capture))
end

function CD.onLogin()
  local sections = db().sections
  local byEvent = {}

  for _, name in ipairs(CD.order) do
    -- Sembrar sin pisar: lo que se capturó en una sesión anterior se conserva,
    -- que es el sentido de acumular en SavedVariables de cuenta.
    if not sections[name] then
      sections[name] = { captured = false }
    end
    local def = CD.collectors[name]
    if def.events then
      for _, e in ipairs(def.events) do
        byEvent[e] = byEvent[e] or {}
        table.insert(byEvent[e], name)
      end
    else
      CD.capture(name)   -- disponible siempre
    end
  end

  local frame = CreateFrame("Frame")
  frame:SetScript("OnEvent", function(_, event)
    for _, name in ipairs(byEvent[event] or {}) do
      CD.capture(name)
    end
  end)
  for event in pairs(byEvent) do
    frame:RegisterEvent(event)
  end
end

function CD.seal()
  local major, build = GetBuildInfo()
  local characters = CD.json.array({})

  for key, char in pairs(CharacterDumpDB.chars) do
    local sections = {}
    for name, s in pairs(char.sections) do
      -- SavedVariables no conserva metatablas, así que la marca de json.array() se
      -- pierde entre sesiones y una sección capturada y vacía volvía como {}. Solo
      -- pasa con la tabla vacía: con elementos, is_array() acierta por #t > 0. Y
      -- re-marcar una tabla vacía no puede perder nada, así que vale también para
      -- lo ya guardado en disco — nadie tiene que volver al banco.
      if type(s.data) == "table" and next(s.data) == nil then
        s.data = CD.json.array({})
      end
      sections[name] = s
    end
    characters[#characters + 1] = { key = key, sections = sections }
  end

  CharacterDumpDB.export = CD.json.encode({
    format = FORMAT,
    addon  = ADDON .. " " .. VERSION,
    source = {
      realm  = GetRealmName() or "?",
      build  = (major or "?") .. " (" .. (build or "?") .. ")",
      locale = GetLocale() or "?",
    },
    characters = characters,
  })
  return CharacterDumpDB.export
end

function CD.status()
  local sections = db().sections
  print("|cff33ff99" .. ADDON .. "|r — " .. CD.key())
  for _, name in ipairs(CD.order) do
    local s, def = sections[name], CD.collectors[name]
    if s and s.captured then
      print("  |cff00ff00ok |r " .. name)
    elseif s and s.error then
      print("  |cffff0000err|r " .. name .. " — " .. s.error)
    else
      print("  |cffffff00-- |r " .. name .. (def.hint and (" — " .. def.hint) or ""))
    end
  end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function() CD.onLogin() end)

SLASH_CDUMP1 = "/cdump"
SlashCmdList["CDUMP"] = function(msg)
  msg = string.lower(msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "status" then CD.status()
  elseif msg == "show" then CD.show()
  else CD.dump() end
end

return CD
