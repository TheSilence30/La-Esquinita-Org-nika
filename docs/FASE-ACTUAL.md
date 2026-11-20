# Fase actual: 1 — Fundamentos

Estado: **en curso** (desde 2026-11-19). Plan aprobado: `docs/planes/fase-1.md`. La bitácora de la Fase 0 está en `docs/informes/fase-0-bitacora.md`. Actualiza esta lista al terminar cada tarea.

## Tareas (cada una con pruebas y un PR pequeño)

- [x] 1. Migraciones (usuarios, roles, permisos, dispositivos, series, ajustes, auditoría, refresh, conflictos, log, estado de equipos) y seed: roles Administrador y Trabajo, permisos de `docs/modelo-datos.md` §4, ajustes del negocio (RUC 10409288419, "Gracias por su preferencia"). Pruebas contra PostgreSQL. Los **usuarios** se crean en la tarea 2: sus contraseñas necesitan Argon2id
- [x] 2. Autenticación en el servidor: login Argon2id, JWT de 15 min, refresh rotativo, logout, `/me`, middleware de permisos. **PR abierto para revisión del usuario** (autenticación)
- [x] 3. Registro de dispositivos, series y `GET /sync/pull` con cursor. **PR abierto para revisión del usuario** (sincronización)
- [ ] 4. Permisos en el core (misma regla en el servidor y en el equipo); Riverpod y drift (réplicas)
- [ ] 5. App: primer arranque (servidor y registro del equipo), login con contraseña, PIN sin conexión, sesión de 7 días
- [ ] 6. Motor de sincronización completo (push por lotes, pull, reintentos, recuperación) e indicador real
- [ ] 7. Pantallas de Usuarios y Ajustes del negocio (solo Administrador)
- [ ] 8. Prueba de aceptación en la tablet y la PC con el usuario; informe en `docs/informes/fase-1.md`

## Pendientes heredados de la Fase 0

- [ ] Prueba en dispositivo del escáner de venta con la cámara real (prototipo)
- [ ] Spike 2 (lector USB), antes de la Fase 3
- [ ] Spike 5 (A4 para reportes), con la Fase 6
- [ ] Regenerar el token de decolecta antes de producción

## Bitácora

### 2026-11-19 — Inicio

- Decisiones del usuario:
  - sesión sin conexión de 7 días;
  - PIN de 4 a 6 dígitos;
  - dos usuarios (`Administrador` y uno de Trabajo);
  - ticket con RUC 10409288419 y "Gracias por su preferencia", sin teléfono ni WhatsApp.
- APK del prototipo (último commit de la app, `b096c44`) instalado en el celular SM-A576B; la tablet ya lo tenía.

### 2026-11-19 — Tarea 1: esquema y seed

- Migración `apps/server/migrations/20261119000001_auth_devices_settings.sql`. Tablas de `docs/modelo-datos.md` §2.8–§2.9:
  - con `active` y `version` en los maestros;
  - una sola secuencia `sync_version_seq` con trigger en cada insert/update, que es el cursor de `GET /sync/pull`.
- Seed:
  - roles **Administrador** (34 permisos, todos) y **Trabajo** (19 permisos, según §4);
  - ajustes: nombre, dirección, **RUC 10409288419**, **"Gracias por su preferencia"**, sin teléfono ni WhatsApp; pagos mixtos activos, sin reserva en notas de pedido y aviso de vencimiento a 30 días.
- Columnas agregadas al modelo:
  - `users.must_change_password`;
  - `refresh_tokens.family_id` y `created_at`, para detectar un refresh robado;
  - `created_at` en `sync_conflicts`;
  - columnas de `sync_log`.
- Las pruebas del servidor corren **una por archivo** (`dart_test.yaml`), porque comparten la base de pruebas.
- Pruebas: servidor 18 en verde contra PostgreSQL 16 local, 9 de ellas nuevas (roles, permisos por rol, ajustes, versión, usuario único sin importar mayúsculas, restricciones de equipos, permisos y conflictos). Migración aplicada a la base de desarrollo con `dbmate up`.

### 2026-11-19 — Tarea 2: autenticación (PR abierto para revisión)

- Reglas del usuario anotadas en `docs/planes/fase-1.md`:
  - fusión de PR;
  - columnas explícitas al bajar `users`;
  - `pin_hash` explicado antes;
  - transacciones concurrentes en `/sync/pull`.
- **Argon2id** en el core (`PasswordHasher`, paquete `cryptography` en Dart puro), porque la tablet lo usará para el PIN sin conexión:
  - formato PHC;
  - el mismo hash, byte a byte, que la implementación de referencia (argon2-cffi);
  - unos 90 ms por hash en la PC, con los parámetros mínimos de OWASP (19 MiB, t=2).
- **JWT HS256** propio (unas 40 líneas con `crypto`):
  - acepta un único encabezado, así que un token no puede elegir su algoritmo;
  - dura 15 min;
  - los permisos se leen de la base en cada pedido, así que desactivar a alguien corta su acceso al instante.
- **Refresh rotativo** de 30 días:
  - en la base solo se guarda su SHA-256;
  - reusar un token ya rotado revoca toda la sesión.
- Usuario inexistente y contraseña incorrecta dan la misma respuesta, con el mismo tiempo; **5 fallos bloquean** ese usuario 15 minutos. shortcut: el contador vive en memoria, alcanza con un solo proceso.
- Rutas: `POST /auth/login`, `/auth/refresh`, `/auth/logout`, `/auth/password` (cambiar la contraseña cierra todas las sesiones) y `GET /me`.
- `POST /sync/push` ahora **exige sesión**, y todos los comandos deben venir del equipo de la sesión.
- **Primeros usuarios**: `Administrador` y `Trabajo` se crean en el primer arranque desde `.env`:
  - `ADMIN_INITIAL_*`, `STAFF_*`, con valores ficticios en `.env.example`;
  - con cambio de contraseña obligatorio;
  - sin esos valores, el servidor no arranca y dice cuál falta.
- Pruebas:
  - servidor 47 en verde, contra PostgreSQL;
  - core 64 y app 160 en verde.
- Prueba manual con el servidor corriendo y curl: 401, login, `/me` (19 permisos, sin hashes), refresh 200 y luego 401 al reusarlo, y 429 tras 5 fallos.
- **Pendiente del usuario**: escribir en su `.env` las contraseñas y los PIN iniciales (`ADMIN_INITIAL_PASSWORD`, `ADMIN_INITIAL_PIN`, `STAFF_INITIAL_PASSWORD`, `STAFF_INITIAL_PIN`) antes del primer arranque del servidor en la base de desarrollo.

### 2026-11-19 (cierre del día) — Estado

- **Tarea 2 (autenticación):** terminada, en el **PR #12**, abierto para que el usuario lo revise. CI en verde. No se fusiona sin su aprobación.
- **Tarea 3 (registro de equipos, series y `GET /sync/pull`):** **sin empezar**; no hay código. Rama `phase-1/devices-pull`, creada sobre `phase-1/auth` porque la necesita, con solo esta nota.
  - Al retomarla:
    - bajada de `users` con columnas explícitas, sin `password_hash`;
    - cursor seguro ante transacciones concurrentes (p. ej. `pg_snapshot_xmin`), con su prueba;
    - PR abierto para revisión, porque es sincronización.
- **Pendientes de decisión del usuario:**
  1. **`pin_hash` en los equipos.** Propuesta de Claude:
     - baja solo a los equipos donde ese usuario ya entró con contraseña;
     - el servidor nunca acepta el PIN;
     - 5 PIN fallidos obligan a entrar con contraseña;
     - el PIN solo abre la sesión guardada de 7 días.
  2. **Cifrado de la base local** (tablet y PC), con SQLCipher y la llave en el almacén seguro del sistema. Cierra el riesgo de que alguien adivine el PIN si roba el equipo. Suma un paquete a la app; se haría en la tarea 4.
  3. **Las cuatro claves iniciales del `.env`** (`ADMIN_INITIAL_PASSWORD`, `ADMIN_INITIAL_PIN`, `STAFF_INITIAL_PASSWORD`, `STAFF_INITIAL_PIN`). Las escribe el usuario; sin ellas, el servidor no arranca en la base de desarrollo.

### 2026-11-20 — Tarea 3: equipos, series y `GET /sync/pull` (PR abierto para revisión)

- **`POST /devices/register`** (solo Administrador, `settings.manage`), con `{name, platform}`:
  - registra el equipo de la sesión (el `device_id` sale del token, no del cuerpo);
  - el **servidor asigna** la serie (`T1`, `T2`… en Android; `P1`… en Windows) y el **dígito de código de barras** libre más bajo (0–9), y crea las series `sale`, `order_note` y `barcode`;
  - nunca reusa series ni dígitos de equipos desactivados (ya hay documentos y códigos con ellos);
  - si el equipo ya estaba registrado, devuelve el mismo (200) sin cambiarlo; nuevo: 201; sin dígitos libres: 409;
  - la primera tablet queda como **equipo de caja de respaldo** (`cash.backup_device_id`);
  - queda en `audit_log` (`devices.register`).
- **`GET /sync/pull?since=N`** (con sesión, cualquier rol): usuarios, roles, permisos, roles por usuario, permisos por rol, equipos y ajustes cambiados después de N, incluidos los desactivados, y el nuevo cursor.
  - Columnas explícitas: `users` baja solo `id`, `username`, `full_name`, `active`, `version`. **Ni `password_hash` ni `pin_hash`** (este último espera la decisión 1).
  - **Transacciones concurrentes** (regla del usuario): la migración `20261120000001` hace que el trigger de versión tome un candado de transacción antes de numerar. Así las escrituras de maestros se numeran en orden de confirmación, y el pull lee todas las tablas en una sola instantánea (`repeatable read`). Se eligió esto en lugar de `pg_snapshot_xmin` porque es más simple y las escrituras de maestros son pocas.
  - Prueba: A escribe y queda abierta; B (escritura posterior) espera a A; un pull a mitad no avanza el cursor; al confirmar, el siguiente pull trae las dos. **Sin el candado, la prueba falla** (comprobado).
  - shortcut: respuesta sin paginar; se pagina cuando el catálogo entre al pull (Fase 2).
- Pruebas: servidor **58 en verde** contra PostgreSQL 16 (11 nuevas). Migración aplicada a la base de desarrollo con dbmate.
- No hecho aquí: `last_pull_at` en `device_sync_status` (con el latido, Fase 4) y el campo `status` del push (tarea 6).
- Siguen pendientes las decisiones 1 y 2 del día anterior, y las cuatro claves del `.env` (el usuario aún no las crea; sin ellas el servidor no arranca, pero las pruebas no las necesitan).
