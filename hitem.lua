-- Parseo del link de objeto de 3.3.5a.
--   item:id:enchant:gem1:gem2:gem3:gem4:suffix:seed:level
-- chardumps se queda en los cinco primeros. Los cuatro que faltan no son adorno:
-- suffix y seed juntos son los que reproducen la tirada del sufijo aleatorio.

local M = {}

-- Devuelve la tabla de campos, o nil si la cadena no es un link de objeto.
-- Acepta el link entero ("|cff..|Hitem:..|h[Nombre]|h|r") y la forma pelada ("item:..").
function M.parse(link)
  if type(link) ~= "string" then return nil end

  local body = link:match("|Hitem:([%-%d:]*)|h") or link:match("^item:([%-%d:]*)$")
  if not body then return nil end

  -- El separador final deja que el patrón coja también el último campo.
  local f, n = {}, 0
  for value in (body .. ":"):gmatch("([%-%d]*):") do
    n = n + 1
    f[n] = tonumber(value) or 0
  end

  -- Un objeto con id 0 no es un objeto: es un hueco.
  if not f[1] or f[1] == 0 then return nil end

  return {
    id      = f[1],
    enchant = f[2] or 0,
    gems    = { f[3] or 0, f[4] or 0, f[5] or 0, f[6] or 0 },
    suffix  = f[7] or 0,
    seed    = f[8] or 0,
    level   = f[9] or 0,
  }
end

CharacterDump = CharacterDump or {}
CharacterDump.hitem = M
return M
