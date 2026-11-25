# ADR-0005 — El PIN renueva la sesión con el servidor

Fecha: 2026-11-25 · Estado: **aceptada** (decisión del usuario del 2026-11-25: «que el PIN también pueda hacer eso, para no trabarnos tanto, queremos agilidad y operabilidad»)

## Contexto

- El equipo sincroniza con un **refresh rotativo**: cada renovación entrega un token nuevo y el anterior deja de servir. Si se presenta un token ya rotado, el servidor lo toma como una copia y revoca toda la sesión (CLAUDE.md §3).
- Si la respuesta de una renovación no llega (la app se cerró en ese momento, se cortó la Wi-Fi o venció el tiempo máximo), la app se queda con el token anterior. Al usarlo, el servidor revoca la sesión.
- Hasta ahora, la sincronización pedía entonces **la contraseña** (decisión del 2026-11-22). En la prueba de aceptación de la Fase 1 ocurrió al cerrar la app a mitad de un envío. El usuario lo consideró una traba: no siempre se recuerdan el PIN y la contraseña.

## Decisión

- Nueva ruta **`POST /auth/pin`** `{user_id, pin, device_id}`, que entrega una sesión nueva (otra familia de refresh) **solo si**:
  - el equipo está registrado y en servicio (si está de baja: 403 `device_blocked`, y solo después del PIN correcto);
  - el usuario está activo, tiene PIN y no debe cambiar su contraseña;
  - ese usuario **ya entró con contraseña en ese equipo** (la misma condición con la que baja su `pin_hash`, ADR-0004).
- Los PIN fallidos cuentan **junto con las contraseñas fallidas**: 5 en 15 minutos bloquean al usuario (429).
- En la app, el PIN **se comprueba primero en el equipo** (con su límite de 5 intentos). Solo si es correcto y la sesión guardada se perdió, se pide la sesión nueva al servidor, con 3 s como máximo. Sin conexión o si el servidor la rechaza, el PIN sigue abriendo la app como siempre.
- Con la sesión perdida, el indicador dice «PIN · pendientes N». Al tocarlo pide el PIN y vuelve a sincronizar, sin salir de la pantalla.
- **No cambia**: el refresh sigue siendo rotativo y un token reutilizado sigue revocando la sesión; los 7 días sin conexión siguen contando desde el último ingreso con contraseña; el PIN nunca se guarda en el equipo en texto plano ni en el servidor.

## Consecuencias

- Una sesión perdida ya no traba el trabajo: basta el PIN.
- El PIN (4 a 6 dígitos) pasa a viajar al servidor, por HTTP en la red local de la tienda (TLS llega con Caddy en la Fase 7). Lo protegen el límite de 5 intentos por usuario y que solo sirve en un equipo registrado, en servicio y donde ese usuario ya entró con contraseña.
- shortcut: el contador de intentos fallidos vive en la memoria del servidor y se pierde al reiniciarlo (como el de las contraseñas, tarea 2). Pasarlo a PostgreSQL si el servidor llega a tener más de un proceso o antes de exponerlo fuera de la tienda (Fase 7).
