-- Textos del addon. Las claves son el inglés: un cliente en un idioma sin tabla
-- se queda en inglés sin una línea más de código. Añadir un idioma es una tabla
-- y una entrada en byLocale.

CharacterDump = CharacterDump or {}
local CD = CharacterDump

local es = {
  ["talk to a banker and leave the window open"] =
    "habla con un banquero y deja la ventana abierta",
  ["talk to a flight master and leave the map open"] =
    "habla con un maestro de vuelo y deja el mapa abierto",

  ["sealed, %d bytes"] = "sellado, %d bytes",
  ["%d sections not captured"] = "%d secciones sin capturar",
  ["type /cdump status to see them"] = "escribe /cdump status para verlas",
  ["Now type %s and upload %s"] = "Ahora haz %s y sube %s",
  ["It is in %s"] = "Está en %s",
  ["WTF\\Account\\<YOUR ACCOUNT>\\SavedVariables\\"] =
    "WTF\\Account\\<TU CUENTA>\\SavedVariables\\",

  ["nothing sealed yet. Type /cdump first."] =
    "todavía no has sellado nada. Haz /cdump primero.",
  ["the dump is %d KB, too big to copy and paste."] =
    "el volcado son %d KB, demasiado para copiar y pegar.",
  ["Type %s and upload the CharacterDump.lua file."] =
    "Haz %s y sube el fichero CharacterDump.lua.",
  ["Ctrl+C to copy, Escape to close."] = "Ctrl+C para copiar, Escape para cerrar.",
}

-- ponytail: esMX apunta a la misma tabla. Si algún día hace falta separarlas,
-- es copiar la tabla, no cambiar esto.
local byLocale = { esES = es, esMX = es }

CD.L = setmetatable(byLocale[GetLocale and GetLocale() or ""] or {}, {
  __index = function(_, key) return key end,
})

return CD.L
