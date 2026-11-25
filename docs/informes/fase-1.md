# Informe de Fase 1 — Fundamentos

Estado: **aprobada por el usuario (2026-11-25)**. Prueba de aceptación completa. Plan: `docs/planes/fase-1.md`. Detalle día a día: bitácora de `docs/FASE-ACTUAL.md`.

## Qué se construyó

| Tarea | Contenido | PR |
| --- | --- | --- |
| 1 | Migraciones y seed: usuarios, roles (Administrador y Trabajo), permisos, dispositivos, series, ajustes, auditoría, refresh, conflictos, log y estado de equipos | — |
| 2 | Autenticación en el servidor: Argon2id, JWT de 15 min, refresh rotativo, logout, `/me` y middleware de permisos | #12 |
| 3 | Registro de equipos con su serie (`T1`, `P1`…) y `GET /sync/pull` con cursor, sin saltarse transacciones concurrentes | #13 |
| 4 | Permisos en el core (misma regla en el servidor y en el equipo), Riverpod, réplicas en drift con **SQLCipher** (llave en Keystore / DPAPI) | #15 |
| 5 | Primer arranque, ingreso con contraseña, PIN sin conexión (5 fallos exigen contraseña), sesión de 7 días, selector de usuarios | #16 |
| 5b | Reloj atrasado: hora más alta vista (`last_seen_at`) y hora del servidor al entrar con contraseña, con aviso si el reloj del equipo no coincide | #18 |
| 6 | Motor de sincronización: envío por lotes, bajada, reintentos (hasta 60 s), recuperación tras reinicio e indicador real | #17 |
| 7 | *Ajustes* (solo Administrador) en PC, tablet y celular: datos del ticket (RUC con dígito verificador), usuarios y equipos («Dar de baja» solo bloquea); «Entrar con contraseña» en la pantalla del PIN | #19 |
| 8 | Hallazgo de la aceptación: el equipo baja los cambios del Administrador cada 60 s y antes de comprobar el PIN | #20 |
| — | El PIN renueva una sesión perdida, sin contraseña (ADR-0005) | #21 |
| — | Ocultar usuarios y equipos desactivados; cambiar el nombre de un equipo | #22 |

## Criterios de aceptación

| # | Criterio | Resultado |
| --- | --- | --- |
| 1 | Ingreso en la tablet y la PC: con contraseña cuando hay conexión y con PIN cuando no la hay, con sesión guardada y vencimiento | ✅ Probado (pasos 1 a 3) |
| 2 | Operaciones de prueba hechas sin conexión en los dos equipos se sincronizan sin duplicados, también cerrando la app a mitad del envío | ✅ Probado (pasos 4 a 6) |
| 3 | Indicador de sincronización real y siempre visible | ✅ Probado («Error · pendientes N» → «Sincronizado») |
| 4 | Pruebas automáticas de sincronización, autenticación y permisos en verde, en la CI y en local | ✅ Core 69, servidor 83 (contra PostgreSQL), app 236 |

## Prueba de aceptación (2026-11-25, con el usuario)

Equipos: tablet **K70_PRO_US_A** (Android 16, serie `T2`) y la PC de caja (`P1`), en la Wi-Fi de la tienda, con el servidor de desarrollo en la PC (`192.168.18.12:8080`). Punto de partida: 131 operaciones en el servidor, todas distintas.

| Paso | Qué se hizo | Resultado |
| --- | --- | --- |
| 1–2 | Contraseña en la PC (Administrador) y en la tablet (`Leandro`); luego PIN | ✅ |
| 3 | Servidor apagado (14:39): PIN en los dos equipos; la contraseña dice que no hay conexión | ✅ |
| 4–5 | Sin conexión: 10 operaciones en la tablet y 3 en la PC. Servidor encendido a las 14:42:29: la tablet las envió a las 14:42:35 y la PC a las 14:43:12, **solas** | ✅ 144 en el servidor, todas distintas; 0 pendientes |
| 6 | «Envío lento» y app cerrada a mitad del envío | ✅ 30 de 30, ninguna repetida (174 en total, todas distintas). Pidió la contraseña una vez: ver «Decisiones» |
| 7 | PIN cambiado desde la PC | ✅ Tras el PR #20 funciona al momento en la tablet (antes no llegaba: hallazgo de esta prueba) |
| 8 | Trabajo en la tablet: entra a Vender y no ve Ajustes | ✅ |

También probado en dispositivo durante la fase: reloj atrasado (5b), crear usuario desde la PC y entrar con él en la tablet, dar de baja y reactivar la tablet varias veces (7).

## Decisiones del usuario en esta fase

- Sesión sin conexión de 7 días; PIN de 4 a 6 dígitos; Argon2id de ~1 s en la tablet, aceptado (ADR-0004).
- `pin_hash` baja solo a los equipos donde el usuario entró con contraseña; base local cifrada con SQLCipher (ADR-0004).
- Reintentos hasta 60 s; sincronizar después de cada operación y al volver la app al primer plano.
- **Refresh perdido**: si se pierde la respuesta de una renovación, el servidor revoca la sesión (el refresh sigue siendo rotativo). Desde el 2026-11-25 (ADR-0005), **el PIN la renueva** en el servidor, solo en un equipo en servicio donde ese usuario ya entró con contraseña y con el límite de 5 intentos. Antes pedía la contraseña. Probado en la tablet.
- Reloj: hora del servidor al entrar con contraseña; PIN bloqueado si el reloj retrocede más de 5 min.
- «Dar de baja» un equipo solo lo bloquea (403 `device_blocked`); al reactivarlo vuelve a sincronizar solo con el PIN. Ningún equipo se desactiva por no conectarse.
- Usuarios y equipos **no se borran**: se desactivan o se dan de baja (CLAUDE.md §6.3).
- Ajustes en PC, tablet y celular, con una sola página que se adapta a cada pantalla.

## Pendientes y riesgos conocidos

- El PIN viaja al servidor por HTTP en la red de la tienda hasta que llegue TLS con Caddy (Fase 7). El contador de intentos fallidos vive en la memoria del servidor (ADR-0005).
- **Límite de 10 equipos registrados** en total, uno por dígito del código de barras interno (0–9), y los de baja no se reutilizan. Revisar antes de registrar muchos celulares.
- Un equipo dado de baja **sin conexión** sigue aceptando el PIN hasta 7 días o hasta que se conecte.
- La bajada previa al PIN espera como máximo 3 s por pedido. Si el servidor tarda más justo al renovar, la sesión se pierde y el PIN la renueva.
- Heredados de la Fase 0: prueba del escáner de venta con la cámara real, Spike 2 (lector USB) antes de la Fase 3, Spike 5 (A4) con la Fase 6, y regenerar el token de decolecta antes de producción.
- El servidor corre en la PC de la tienda (desarrollo). VPS, respaldos e instaladores: Fase 7.
