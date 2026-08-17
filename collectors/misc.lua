local CD = CharacterDump
local array = CD.json.array

-- Monturas y mascotas de compañía son hechizos en 3.3.5, así que el importador
-- las aplica con LearnSpell y no hace falta nada especial para ellas.
local function companions(kind)
  return function()
    local out = array({})
    for i = 1, GetNumCompanions(kind) do
      local _, _, spell = GetCompanionInfo(kind, i)
      if spell then out[#out + 1] = spell end
    end
    return out
  end
end

CD.register("mount",   { capture = companions("MOUNT") })
CD.register("critter", { capture = companions("CRITTER") })

CD.register("taxi", {
  events = { "TAXIMAP_OPENED" },
  hint = CD.L["talk to a flight master and leave the map open"],
  capture = function()
    -- Por nombre: el cliente da el índice dentro del mapa abierto, que no es el
    -- id de TaxiNodes.dbc. El importador mapea con source.locale, igual que las
    -- habilidades y las reputaciones.
    local out = array({})
    for i = 1, NumTaxiNodes() do
      out[#out + 1] = { name = TaxiNodeName(i), kind = TaxiNodeGetType(i) }
    end
    return out
  end,
})

CD.register("action", {
  capture = function()
    local out = array({})
    for slot = 1, 120 do
      local kind, id, subType = GetActionInfo(slot)
      if kind then
        out[#out + 1] = { slot = slot, kind = kind, id = id, sub = subType }
      end
    end
    return out
  end,
})

CD.register("bind", {
  capture = function()
    local out = array({})
    for i = 1, GetNumBindings() do
      local command, key1, key2 = GetBinding(i)
      if key1 then
        out[#out + 1] = { command = command, key1 = key1, key2 = key2 }
      end
    end
    return out
  end,
})

CD.register("pmacro", {
  capture = function()
    -- Las de cuenta ocupan 1-120 y las del personaje empiezan en 121, siempre,
    -- aunque las de cuenta no lleguen a 120.
    local accountCount, charCount = GetNumMacros()
    local out = array({})

    local function take(index, perChar)
      local name, icon, body = GetMacroInfo(index)
      if name then
        out[#out + 1] = { name = name, icon = icon, body = body, perChar = perChar }
      end
    end

    for i = 1, accountCount do take(i, false) end
    for i = 121, 120 + charCount do take(i, true) end
    return out
  end,
})
