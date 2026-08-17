local CD = CharacterDump
local array = CD.json.array
local parse = CD.hitem.parse

-- Recoge un contenedor entero. bag -1 es la bolsa principal del banco.
local function sweep(bag, out)
  for slot = 1, GetContainerNumSlots(bag) do
    local item = parse(GetContainerItemLink(bag, slot))
    if item then
      local _, count = GetContainerItemInfo(bag, slot)
      item.bag, item.slot, item.count = bag, slot, count or 1
      out[#out + 1] = item
    end
  end
end

CD.register("equipped", {
  capture = function()
    local out = array({})
    for slot = 1, 19 do   -- 1 cabeza … 19 tabardo
      local item = parse(GetInventoryItemLink("player", slot))
      if item then
        item.slot = slot
        out[#out + 1] = item
      end
    end
    return out
  end,
})

CD.register("bag", {
  events = { "BAG_UPDATE" },
  capture = function()
    local out = array({})
    -- Las bolsas en sí: ranuras de inventario 20-23. Sin ellas el jugador
    -- llega con cuatro huecos de mochila y los objetos sin dónde caber.
    for slot = 20, 23 do
      local item = parse(GetInventoryItemLink("player", slot))
      if item then
        item.slot, item.container = slot, true
        out[#out + 1] = item
      end
    end
    for bag = 0, 4 do sweep(bag, out) end
    return out
  end,
})

CD.register("bank", {
  events = { "BANKFRAME_OPENED" },
  hint = CD.L["talk to a banker and leave the window open"],
  capture = function()
    -- No se puede leer sin la ventana abierta, y por eso la sección nace
    -- sin capturar en vez de salir vacía: [] y "no fui al banco" no son lo mismo.
    local out = array({})
    -- Las bolsas compradas del banco: ranuras de inventario 68-74, siete.
    for slot = 68, 74 do
      local item = parse(GetInventoryItemLink("player", slot))
      if item then
        item.slot, item.container = slot, true
        out[#out + 1] = item
      end
    end
    sweep(BANK_CONTAINER, out)          -- -1: las 28 ranuras del banco en sí
    for bag = 5, 11 do sweep(bag, out) end   -- el contenido de esas siete bolsas
    return out
  end,
})

CD.register("equipmentset", {
  events = { "EQUIPMENT_SETS_CHANGED" },
  capture = function()
    local out = array({})
    for i = 1, GetNumEquipmentSets() do
      local name = GetEquipmentSetInfo(i)
      -- La tabla que devuelve el cliente viene indexada por ranura y con huecos,
      -- que como array daría un JSON truncado. Se pasa a objeto con la ranura
      -- por clave.
      local items = {}
      for slot, id in pairs(GetEquipmentSetItemIDs(name) or {}) do
        items[tostring(slot)] = id
      end
      out[#out + 1] = { name = name, items = items }
    end
    return out
  end,
})

CD.register("currency", {
  events = { "CURRENCY_DISPLAY_UPDATE" },
  capture = function()
    local out = array({})
    for i = 1, GetCurrencyListSize() do
      local name, isHeader, _, _, _, count = GetCurrencyListInfo(i)
      if not isHeader then
        out[#out + 1] = { name = name, count = count }
      end
    end
    return out
  end,
})
