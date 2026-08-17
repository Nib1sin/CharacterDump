-- Corre fuera del juego:  lua51 test.lua
-- Stubs de la API del cliente: solo lo que tocan los módulos que se prueban aquí.

local failed, total = 0, 0

function check(name, fn)
  total = total + 1
  local ok, err = pcall(fn)
  if not ok then
    failed = failed + 1
    -- print_real: a partir de la tarea 4 el stub se traga print, y un fallo
    -- invisible no sirve de nada.
    local out = print_real or print
    out("FALLO  " .. name)
    out("       " .. tostring(err))
  end
end

function eq(actual, expected, what)
  if actual ~= expected then
    error((what or "valor") .. ": esperaba " .. tostring(expected) ..
          ", llegó " .. tostring(actual), 2)
  end
end

-- ---------------------------------------------------------------- stubs
-- Solo lo que core.lua toca. Un colector de verdad necesita el juego delante.

CreateFrame = function()
  local f = { _events = {} }
  function f:RegisterEvent(e) self._events[e] = true end
  function f:UnregisterEvent(e) self._events[e] = nil end
  function f:SetScript(_, fn) self._onEvent = fn end
  _G.TEST_FRAME = f
  return f
end

UnitName      = function() return "Amduscia" end
GetRealmName  = function() return "Reino" end
GetBuildInfo  = function() return "3.3.5a", "12340" end
GetLocale     = function() return "esES" end
time          = function() return 1755399000 end
SlashCmdList  = {}

local printed = {}
print_real = print
print = function(s) printed[#printed + 1] = tostring(s) end
function last_printed() return printed end
function clear_printed() printed = {} end

-- ---------------------------------------------------------------- casos
check("el arnés funciona", function()
  eq(1 + 1, 2, "suma")
end)

local hitem = dofile("hitem.lua")

check("hitem: link completo con las cuatro gemas", function()
  local i = hitem.parse("|cffa335ee|Hitem:49623:3789:41398:40133:40155:40142:-138:1207:80|h[Shadowmourne]|h|r")
  eq(i.id, 49623, "id")
  eq(i.enchant, 3789, "enchant")
  eq(i.gems[1], 41398, "gema 1")
  eq(i.gems[4], 40142, "gema 4")
  eq(i.suffix, -138, "suffix")
  eq(i.seed, 1207, "seed")
  eq(i.level, 80, "level")
end)

check("hitem: el sufijo negativo no se pierde", function()
  -- suffix < 0 es un sufijo aleatorio de ItemRandomSuffix.dbc.
  -- Si el parser se come el signo, el objeto llega con la propiedad equivocada.
  local i = hitem.parse("|Hitem:12345:0:0:0:0:0:-42:99:70|h[x]|h")
  eq(i.suffix, -42, "suffix")
  eq(i.seed, 99, "seed")
end)

check("hitem: los campos que faltan al final valen 0", function()
  local i = hitem.parse("|Hitem:6948:0:0:0:0:0:0:0:0|h[Hearthstone]|h")
  eq(i.id, 6948, "id")
  eq(i.gems[4], 0, "gema 4")
  eq(i.suffix, 0, "suffix")
end)

check("hitem: acepta la forma pelada sin color ni nombre", function()
  eq(hitem.parse("item:49623:3789:0:0:0:0:0:0:80").id, 49623, "id")
end)

check("hitem: los campos vacíos cuentan como 0", function()
  local i = hitem.parse("|Hitem:12345::::::::|h[x]|h")
  eq(i.id, 12345, "id")
  eq(i.enchant, 0, "enchant")
  eq(i.level, 0, "level")
end)

check("hitem: lo que no es un link da nil", function()
  eq(hitem.parse(nil), nil, "nil")
  eq(hitem.parse(""), nil, "cadena vacía")
  eq(hitem.parse("|Hspell:12345|h[Bola de fuego]|h"), nil, "link de hechizo")
  eq(hitem.parse("|Hitem:0:0:0:0:0:0:0:0:0|h[x]|h"), nil, "id 0")
end)

local json = dofile("json.lua")

check("json: escalares", function()
  eq(json.encode(42), "42", "entero")
  eq(json.encode(-7), "-7", "negativo")
  eq(json.encode(true), "true", "booleano")
  eq(json.encode(nil), "null", "nil")
  eq(json.encode("hola"), '"hola"', "cadena")
end)

check("json: los flotantes no salen en notación científica", function()
  eq(json.encode(80), "80", "entero disfrazado de float")
  eq(json.encode(1.5), "1.5", "decimal")
end)

check("json: escapes", function()
  eq(json.encode('di "hola"'), '"di \\"hola\\""', "comillas")
  eq(json.encode("c:\\ruta"), '"c:\\\\ruta"', "barra invertida")
  eq(json.encode("a\nb"), '"a\\nb"', "salto de línea")
  eq(json.encode("a\1b"), '"a\\u0001b"', "carácter de control")
end)

check("json: las claves salen ordenadas", function()
  -- Sin orden fijo, dos volcados del mismo personaje no se pueden comparar a ojo.
  eq(json.encode({ b = 1, a = 2, c = 3 }), '{"a":2,"b":1,"c":3}', "objeto")
end)

check("json: una lista con elementos es un array", function()
  eq(json.encode({ 1, 2, 3 }), "[1,2,3]", "array")
end)

check("json: una tabla vacía sin marcar es un objeto", function()
  eq(json.encode({}), "{}", "objeto vacío")
end)

check("json: una tabla vacía marcada es un array", function()
  -- Éste es el caso que importa: "capturado y vacío" tiene que ser [], no {}.
  eq(json.encode(json.array({})), "[]", "array vacío")
end)

check("json: array marcado con elementos sigue siendo array", function()
  eq(json.encode(json.array({ 5, 6 })), "[5,6]", "array marcado")
end)

check("json: anidamiento", function()
  eq(json.encode({ a = { b = json.array({ 1 }) } }), '{"a":{"b":[1]}}', "anidado")
end)

check("json: las claves numéricas de un objeto salen como cadena", function()
  local t = {}
  t["16"] = 49623
  eq(json.encode(t), '{"16":49623}', "clave numérica")
end)

dofile("core.lua")
local CD = CharacterDump

local function fresh()
  CharacterDumpDB = nil
  CD.collectors, CD.order = {}, {}
  clear_printed()
end

check("core: un colector capturado guarda su dato y su marca", function()
  fresh()
  CD.register("uno", { capture = function() return { a = 1 } end })
  CD.onLogin()
  local s = CharacterDumpDB.chars[CD.key()].sections["uno"]
  eq(s.captured, true, "captured")
  eq(s.at, 1755399000, "at")
  eq(s.data.a, 1, "data")
end)

check("core: una sección que depende de un evento nace sin capturar", function()
  fresh()
  CD.register("banco", { events = { "BANKFRAME_OPENED" }, capture = function() return {} end })
  CD.onLogin()
  local s = CharacterDumpDB.chars[CD.key()].sections["banco"]
  eq(s.captured, false, "captured")
  eq(s.data, nil, "sin data")
end)

check("core: el evento captura su sección", function()
  fresh()
  CD.register("banco", { events = { "BANKFRAME_OPENED" }, capture = function() return { 7 } end })
  CD.onLogin()
  TEST_FRAME._onEvent(TEST_FRAME, "BANKFRAME_OPENED")
  local s = CharacterDumpDB.chars[CD.key()].sections["banco"]
  eq(s.captured, true, "captured")
  eq(s.data[1], 7, "data")
end)

check("core: un colector que revienta no se lleva a los demás", function()
  fresh()
  CD.register("roto", { capture = function() error("no existe GetLoQueSea") end })
  CD.register("sano", { capture = function() return { ok = true } end })
  CD.onLogin()
  local secciones = CharacterDumpDB.chars[CD.key()].sections
  eq(secciones["roto"].captured, false, "el roto")
  eq(secciones["sano"].captured, true, "el sano")
  if not tostring(secciones["roto"].error):find("GetLoQueSea", 1, true) then
    error("el motivo del fallo no se guardó")
  end
end)

check("core: el sellado lleva versión de formato y cabecera", function()
  fresh()
  CD.register("uno", { capture = function() return { a = 1 } end })
  CD.onLogin()
  local out = CD.seal()
  for _, fragmento in ipairs({ '"format":1', '"locale":"esES"', '"realm":"Reino"',
                               '"key":"Amduscia-Reino"', '"captured":true' }) do
    if not out:find(fragmento, 1, true) then
      error("falta " .. fragmento .. " en:\n" .. out)
    end
  end
end)

check("core: characters es un array aunque haya un solo personaje", function()
  fresh()
  CD.register("uno", { capture = function() return {} end })
  CD.onLogin()
  if not CD.seal():find('"characters":[', 1, true) then
    error("characters no salió como array")
  end
end)

check("core: sellar deja la cadena en export", function()
  fresh()
  CD.register("uno", { capture = function() return {} end })
  CD.onLogin()
  local out = CD.seal()
  eq(CharacterDumpDB.export, out, "export")
end)

check("core: una sección capturada y vacía sale como [] y no como {}", function()
  fresh()
  CD.register("vacia", { capture = function() return CD.json.array({}) end })
  CD.onLogin()
  if not CD.seal():find('"data":[]', 1, true) then
    error("la sección vacía no salió como array:\n" .. CD.seal())
  end
end)

check("core: status dice qué falta y da la pista", function()
  fresh()
  CD.register("banco", { events = { "BANKFRAME_OPENED" }, hint = "ve al banquero",
                         capture = function() return {} end })
  CD.onLogin()
  clear_printed()
  CD.status()
  local todo = table.concat(last_printed(), "\n")
  if not todo:find("banco", 1, true) then error("no nombró la sección") end
  if not todo:find("ve al banquero", 1, true) then error("no dio la pista") end
end)

check("core: lo capturado en una sesión anterior no se pisa al entrar", function()
  fresh()
  CD.register("banco", { events = { "BANKFRAME_OPENED" }, capture = function() return { 1 } end })
  CD.onLogin()
  TEST_FRAME._onEvent(TEST_FRAME, "BANKFRAME_OPENED")
  -- segunda sesión: misma BD, se vuelve a entrar
  CD.collectors, CD.order = {}, {}
  CD.register("banco", { events = { "BANKFRAME_OPENED" }, capture = function() return { 2 } end })
  CD.onLogin()
  local s = CharacterDumpDB.chars[CD.key()].sections["banco"]
  eq(s.captured, true, "sigue capturada")
  eq(s.data[1], 1, "conserva el dato de la sesión anterior")
end)

-- ---------------------------------------------------------------- final
if failed > 0 then
  print_real(failed .. " de " .. total .. " fallaron")
  os.exit(1)
end
print_real("OK (" .. total .. ")")
