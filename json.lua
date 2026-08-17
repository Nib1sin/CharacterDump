-- Serializador JSON mínimo. Solo encode: el addon escribe, nunca lee.

local M = {}

-- Marca de array. Una tabla vacía en Lua es a la vez [] y {}, y aquí la
-- diferencia importa: "capturado y vacío" tiene que salir como [].
local ARRAY = {}

function M.array(t)
  return setmetatable(t or {}, ARRAY)
end

local function is_array(t)
  return getmetatable(t) == ARRAY or #t > 0
end

local ESCAPES = {
  ['"'] = '\\"', ['\\'] = '\\\\', ['\b'] = '\\b', ['\f'] = '\\f',
  ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t',
}

local function escape(c)
  return ESCAPES[c] or string.format("\\u%04x", string.byte(c))
end

local function encode_string(s)
  -- Los bytes > 127 pasan tal cual: SavedVariables se escribe en UTF-8.
  return '"' .. s:gsub('[%c"\\]', escape) .. '"'
end

local function encode_number(n)
  if n ~= n or n == math.huge or n == -math.huge then return "null" end
  -- %.0f y no %d: %d con un float revienta en Lua 5.3+, y esto tiene que
  -- correr igual en el cliente (5.1) y en el intérprete de las pruebas.
  if n == math.floor(n) then return string.format("%.0f", n) end
  return string.format("%.14g", n)
end

local encode

local function encode_table(t, out)
  if is_array(t) then
    out[#out + 1] = "["
    for i = 1, #t do
      if i > 1 then out[#out + 1] = "," end
      encode(t[i], out)
    end
    out[#out + 1] = "]"
    return
  end

  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

  out[#out + 1] = "{"
  for i = 1, #keys do
    if i > 1 then out[#out + 1] = "," end
    out[#out + 1] = encode_string(tostring(keys[i]))
    out[#out + 1] = ":"
    encode(t[keys[i]], out)
  end
  out[#out + 1] = "}"
end

encode = function(v, out)
  local kind = type(v)
  if v == nil then out[#out + 1] = "null"
  elseif kind == "boolean" then out[#out + 1] = tostring(v)
  elseif kind == "number" then out[#out + 1] = encode_number(v)
  elseif kind == "string" then out[#out + 1] = encode_string(v)
  elseif kind == "table" then encode_table(v, out)
  else out[#out + 1] = "null" end  -- function, userdata: no tienen sitio en un dump
end

-- ponytail: sin detección de ciclos. Los colectores construyen tablas nuevas a
-- partir de lo que devuelve la API del cliente, así que no puede haber uno; y si
-- lo hubiera, el desbordamiento de pila lo caza el pcall del núcleo y la sección
-- queda marcada como fallida en vez de colgar el cliente.
function M.encode(value)
  local out = {}
  encode(value, out)
  return table.concat(out)
end

CharacterDump = CharacterDump or {}
CharacterDump.json = M
return M
