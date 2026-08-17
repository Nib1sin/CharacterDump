local CD = CharacterDump
local array = CD.json.array

CD.register("player", {
  capture = function()
    local _, class = UnitClass("player")
    local _, race = UnitRace("player")
    local hk, dk = GetPVPLifetimeStats()
    return {
      name         = UnitName("player"),
      class        = class,              -- "WARRIOR", "MAGE"…: constante, no traducida
      race         = race,               -- "Human", "Orc"…: ídem
      level        = UnitLevel("player"),
      sex          = UnitSex("player"),  -- 2 hombre, 3 mujer
      money        = GetMoney(),
      xp           = UnitXP("player"),
      honorKills   = hk,
      dishonorable = dk,
      honorPoints  = GetHonorCurrency(),
      arenaPoints  = GetArenaCurrency(),
      talentGroups = GetNumTalentGroups(),   -- 2 si tiene doble espec desbloqueada
      activeGroup  = GetActiveTalentGroup(),
    }
  end,
})

CD.register("talent", {
  capture = function()
    -- La interfaz de talentos es de carga diferida; sin ella GetTalentInfo no responde.
    if not IsAddOnLoaded("Blizzard_TalentUI") then LoadAddOn("Blizzard_TalentUI") end

    -- Por posición y no por spellId: Player:LearnTalent de ALE pide el talentId de
    -- Talent.dbc más el rango, y el cliente no expone el talentId. El importador
    -- cruza (tab, tier, column) contra talent_dbc / talenttab_dbc.
    local out = array({})
    for group = 1, GetNumTalentGroups() do
      for tab = 1, GetNumTalentTabs() do
        for index = 1, GetNumTalents(tab) do
          local _, _, tier, column, rank = GetTalentInfo(tab, index, false, false, group)
          if rank and rank > 0 then
            out[#out + 1] = { tab = tab, tier = tier, column = column, rank = rank, spec = group }
          end
        end
      end
    end
    return out
  end,
})

CD.register("glyph", {
  capture = function()
    local out = array({})
    for group = 1, GetNumTalentGroups() do
      for slot = 1, 6 do
        local enabled, kind, _, spell = GetGlyphSocketInfo(slot, group)
        if enabled and spell then
          out[#out + 1] = { slot = slot, spec = group, spell = spell, kind = kind }
        end
      end
    end
    return out
  end,
})

CD.register("spell", {
  capture = function()
    -- El id no sale del libro directamente: se saca del link. GetSpellName
    -- devuelve nil pasado el final, que es lo que corta el bucle.
    local out = array({})
    local index = 1
    while GetSpellName(index, BOOKTYPE_SPELL) do
      local link = GetSpellLink(index, BOOKTYPE_SPELL)
      local id = link and tonumber(link:match("Hspell:(%d+)"))
      if id then out[#out + 1] = id end
      index = index + 1
    end
    return out
  end,
})

CD.register("skill", {
  capture = function()
    -- Por nombre, no por id: el cliente 3.3.5a no expone el SkillLine. El
    -- importador mapea contra skillline_dbc usando source.locale de la cabecera.
    local out = array({})
    for i = 1, GetNumSkillLines() do
      local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)
      if not isHeader then
        out[#out + 1] = { name = name, rank = rank, max = maxRank }
      end
    end
    return out
  end,
})

CD.register("title", {
  capture = function()
    local out = array({})
    for i = 1, GetNumTitles() do
      if IsTitleKnown(i) then out[#out + 1] = i end
    end
    return out
  end,
})
