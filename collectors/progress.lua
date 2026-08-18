local CD = CharacterDump
local array = CD.json.array

-- Las misiones completadas NO están en el cliente: hay que pedírselas al servidor con
-- QueryQuestsCompleted() y esperar su respuesta. Sin eso GetQuestsCompleted no rellena
-- nada y la sección salía vacía con el personaje teniendo misiones hechas.
CD.register("quest", {
  events = { "QUEST_QUERY_COMPLETE" },
  arm = function() QueryQuestsCompleted() end,
  capture = function()
    local done = {}
    GetQuestsCompleted(done)
    local out = array({})
    for id in pairs(done) do out[#out + 1] = id end
    table.sort(out)   -- orden estable: dos volcados del mismo personaje se pueden comparar
    return out
  end,
})

CD.register("questlog", {
  capture = function()
    local out = array({})
    for i = 1, GetNumQuestLogEntries() do
      local title, level, _, isHeader = GetQuestLogTitle(i)
      if not isHeader then
        local link = GetQuestLink(i)
        out[#out + 1] = {
          id    = link and tonumber(link:match("Hquest:(%d+)")),
          title = title,
          level = level,
        }
      end
    end
    return out
  end,
})

-- En PLAYER_LOGIN GetNumFactions() devuelve 0: la lista de reputaciones llega después.
CD.register("reputation", {
  events = { "PLAYER_ENTERING_WORLD", "UPDATE_FACTION" },
  capture = function()
    -- GetNumFactions solo cuenta las filas visibles, así que con una cabecera
    -- plegada sus facciones no existen para la API. Hay que desplegarlas todas
    -- y volver a dejarlas como estaban: el addon es un invitado.
    local collapsed = {}
    local i = 1
    while i <= GetNumFactions() do
      local _, _, _, _, _, _, _, _, isHeader, isCollapsed = GetFactionInfo(i)
      if isHeader and isCollapsed then
        collapsed[#collapsed + 1] = i
        ExpandFactionHeader(i)
      end
      i = i + 1
    end

    -- Por nombre, no por id: el cliente no expone el faction id. El importador
    -- mapea contra faction_dbc usando source.locale.
    local out = array({})
    for j = 1, GetNumFactions() do
      local name, _, standing, _, _, value, _, _, isHeader = GetFactionInfo(j)
      if not isHeader then
        out[#out + 1] = { name = name, standing = standing, value = value }
      end
    end

    -- Restaurar de atrás hacia delante: plegar una cabecera mueve los índices
    -- de las que vienen después.
    for k = #collapsed, 1, -1 do CollapseFactionHeader(collapsed[k]) end
    return out
  end,
})

-- Con PLAYER_ENTERING_WORLD entran bastantes más que capturando en el login.
CD.register("achievement", {
  events = { "PLAYER_ENTERING_WORLD" },
  capture = function()
    if not IsAddOnLoaded("Blizzard_AchievementUI") then LoadAddOn("Blizzard_AchievementUI") end
    local out = array({})
    for _, category in ipairs(GetCategoryList()) do
      for i = 1, GetCategoryNumAchievements(category) do
        local id, _, _, completed, month, day, year = GetAchievementInfo(category, i)
        if completed then
          out[#out + 1] = { id = id, y = year, m = month, d = day }
        end
      end
    end
    return out
  end,
})

CD.register("statistic", {
  capture = function()
    if not IsAddOnLoaded("Blizzard_AchievementUI") then LoadAddOn("Blizzard_AchievementUI") end
    local out = array({})
    for _, category in ipairs(GetStatisticsCategoryList()) do
      for i = 1, GetCategoryNumAchievements(category) do
        local id = GetAchievementInfo(category, i)
        local value = GetStatistic(id)
        if value and value ~= "--" then
          out[#out + 1] = { id = id, value = value }
        end
      end
    end
    return out
  end,
})
