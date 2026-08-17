# CharacterDump

Addon de Lua para clientes de World of Warcraft **3.3.5a** que vuelca tus personajes a JSON, para
migrarlos a otro servidor.

## Instalación

Copia la carpeta `CharacterDump` en `Interface\AddOns\` de tu cliente. Si el juego estaba abierto,
`/reload`.

## Uso

El addon **captura solo, mientras juegas**. No hay que ejecutar nada en cada sitio: cuando abres el
banco, guarda el banco; cuando abres el mapa de vuelo, guarda los vuelos.

| Comando | Qué hace |
|---|---|
| `/cdump status` | Qué se ha capturado y qué falta, con la pista de dónde conseguirlo |
| `/cdump` | Sella el volcado |
| `/cdump show` | Abre una caja con el JSON para copiar con Ctrl+C |

Cuando `/cdump status` esté todo en verde:

1. `/cdump`
2. `/reload` — **hace falta**: el juego no escribe el fichero al disco hasta que sales o recargas
3. Sube `WTF\Account\<TU CUENTA>\SavedVariables\CharacterDump.lua`

El fichero lleva **todos los personajes de la cuenta** que hayas volcado. Eliges cuáles migras al
subirlo.

## Qué se vuelca

Personaje, talentos, glifos, hechizos, habilidades, títulos, equipo, bolsas, banco, conjuntos de
equipo, monedas, misiones, reputaciones, logros, estadísticas, monturas, mascotas de compañía,
vuelos, barras de acción, teclas y macros.

Fuera, a propósito: la **mascota de cazador** y el **correo en tránsito**. Fuera porque el cliente
no lo expone: la **apariencia** (pelo, cara, piel).

## Desarrollo

```
scoop bucket add versions
scoop install lua51
lua51 test.lua
```

Tiene que ser **Lua 5.1**, que es el que corre el cliente. Con 5.4, o con LuaJIT, los tests
pasarían con código que el juego no acepta.

Las pruebas cubren `json.lua` y `hitem.lua`, que son funciones puras. Los colectores leen la API
del cliente y se prueban jugando, con `/cdump status`.

### Idiomas

Los mensajes salen en el idioma del cliente. Las claves de `locale.lua` **son el texto en inglés**,
así que un cliente en un idioma sin tabla —deDE, ruRU, frFR…— se queda en inglés y funciona igual.
Traducir a otro idioma es copiar la tabla `es`, traducir sus valores y añadirla a `byLocale`.

## Licencia

Apache-2.0, ver [LICENSE](LICENSE).

La idea viene de [`wowtransfer/chardumps`](https://github.com/wowtransfer/chardumps) —qué secciones
tiene sentido volcar y dónde están las trampas—, pero **no comparte código con él**: `chardumps` es
GPL-2.0 y las dos licencias no se mezclan en esa dirección.
