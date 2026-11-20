# Fase actual: 1 — Fundamentos

Estado: **en curso** (desde 2026-11-19). Plan aprobado: `docs/planes/fase-1.md`. La bitácora de la Fase 0 está en `docs/informes/fase-0-bitacora.md`. Actualiza esta lista al terminar cada tarea.

## Tareas (cada una con pruebas y un PR pequeño)

- [x] 1. Migraciones (usuarios, roles, permisos, dispositivos, series, ajustes, auditoría, refresh, conflictos, log, estado de equipos) y seed: roles Administrador y Trabajo, permisos de `docs/modelo-datos.md` §4, ajustes del negocio (RUC 10409288419, "Gracias por su preferencia"). Pruebas contra PostgreSQL. Los **usuarios** se crean en la tarea 2: sus contraseñas necesitan Argon2id
- [x] 2. Autenticación en el servidor: login Argon2id, JWT de 15 min, refresh rotativo, logout, `/me`, middleware de permisos. PR #12, aprobado y fusionado
- [x] 3. Registro de dispositivos, series y `GET /sync/pull` con cursor. PR #13, aprobado y fusionado
- [x] 4. Permisos en el core (misma regla en el servidor y en el equipo); Riverpod y drift (réplicas) con **SQLCipher** (llave en Keystore en Android, DPAPI en Windows); el pull baja `pin_hash` solo a los equipos donde el usuario entró con contraseña (ADR-0004). **PR #15 abierto para revisión del usuario** (seguridad)
- [ ] 5. **En curso** (PR #16 en borrador). App: primer arranque (servidor y registro del equipo), login con contraseña, PIN sin conexión (5 fallos exigen contraseña; el contador vive en la base local cifrada, sobrevive a reiniciar la app y solo vuelve a cero al entrar bien o con contraseña; medir Argon2id en la tablet, nativo si pasa de 1 s), sesión de 7 días
- [ ] 6. Motor de sincronización completo (push por lotes, pull, reintentos, recuperación) e indicador real
- [ ] 7. Pantallas de Usuarios y Ajustes del negocio (solo Administrador), con cambio de PIN y cierre de sesiones de un equipo perdido (revoca tokens y desactiva el equipo)
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

### 2026-11-20 — PR fusionados y decisiones

- El usuario revisó y aprobó los PR #12 (autenticación) y #13 (equipos y pull). Se fusionaron en `main` en ese orden, con la CI en verde; el #13, contra `main`.
- Decisiones del usuario (ADR-0004), que cierran los pendientes 1 y 2 del 2026-11-19:
  - `pin_hash` baja solo a los equipos donde el usuario ya entró con contraseña; 5 PIN fallidos exigen contraseña; sesión local de 7 días; medir Argon2id en la tablet y pasar a `cryptography_flutter` si tarda más de 1 s;
  - SQLCipher en la tablet (Keystore) y en la PC (DPAPI);
  - desde la PC: cambiar el PIN de un usuario y cerrar las sesiones de un equipo perdido.
- Sigue pendiente del usuario: las cuatro claves iniciales del `.env`.

### 2026-11-20 — Tarea 4: permisos en el core, réplicas y base local cifrada (PR abierto para revisión)

- El usuario agregó al ADR-0004 que el contador de PIN fallidos vive en la base cifrada y sobrevive a reiniciar la app (se implementa en la tarea 5). Aprobó la propuesta de paquetes con condiciones, anotadas en el ADR.
- **Core**: catálogo `Permissions` (34 códigos) y `effectivePermissions`. Un permiso cuenta solo si toda su cadena está activa (rol del usuario, rol, permiso del rol y permiso). El servidor ya calcula los permisos con esta regla, y una prueba verifica que el seed coincide con el catálogo.
- **Servidor**:
  - el pull baja `pin_hash` solo al equipo donde el usuario tiene un ingreso con contraseña (`refresh_tokens`);
  - el login guarda `last_login_at` (migración `20261120000002`), lo que sube la versión del usuario y hace que ese equipo reciba el PIN en su siguiente pull.
- **App**:
  - **SQLCipher** 4.20.0 community, activado en el `sqlite3` existente. Base nueva `local.db`; el archivo sin cifrar de la Fase 0 queda donde estaba, sin tocarlo.
  - **Llaves**: Kotlin propio con Keystore en Android; DPAPI con `win32` en Windows, en `%LOCALAPPDATA%\LaEsquinita`.
  - `allowBackup="false"` y reglas de extracción.
  - **Réplicas drift** de usuarios (sin contraseña), roles, permisos, equipos, ajustes y `sync_state`. `ReplicaStore` aplica un pull en una sola transacción (filas y cursor juntos) y calcula los permisos sin conexión con la regla del core.
  - **Riverpod** (con generador): providers de la base, el outbox y las réplicas. El prototipo sigue con `DemoStore`.
  - **Llave perdida**: pantalla con aviso; nada se borra sin la contraseña de un Administrador verificada en el servidor y una segunda confirmación; descartar renombra.
  - **Aviso al cerrar** con operaciones sin enviar: Windows (cerrar ventana) y Android («Atrás» en el inicio).
  - Paquetes nuevos: solo Riverpod (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`), que ya estaba en el stack. `sqlite3` y `path_provider` pasan a dependencia directa; ya venían con drift.
- Pruebas (todas en verde, en local):
  - core 67, servidor 61 contra PostgreSQL y app 185;
  - cifrado: `PRAGMA cipher_version` tiene valor; el archivo no empieza con «SQLite format 3» ni guarda el texto en claro; no abre sin la llave ni con otra; si la llave falta, no sirve o es otra, no se borra ni se cambia nada;
  - DPAPI real en esta PC: 5 pruebas, que en la CI (Linux) se saltan.
- APK de depuración compilado, con `libsqlcipher.so` para arm64, armeabi-v7a y x86_64. Migración aplicada a la base de desarrollo.
- **Pendiente de prueba en dispositivo**: abrir la base cifrada y la llave del Keystore en la tablet SM-X133; la app Windows completa en la PC; el aviso al cerrar la ventana en Windows.
- El `.env` local quedó completo: `TEST_DATABASE_URL`, `SERVER_HOST` vacío, `sslmode=disable` y un `JWT_SECRET` nuevo. Las claves iniciales ya están; se les quitó un espacio que quedaba al final de las dos contraseñas.

### 2026-11-20 (cierre) — Estado

- **Tareas 1 a 3:** fusionadas en `main` (PR #12 y #13, aprobados por el usuario). La documentación del ADR-0004 entró con el PR #14.
- **Tarea 4:** terminada, en el **PR #15**, abierto para revisión del usuario (seguridad).
  - Probada en los equipos: la tablet y la PC abren su base cifrada, y el aviso al salir con pendientes funciona en las dos.
  - Comprobado: ninguna base empieza con «SQLite format 3», ninguna guarda texto en claro y ninguna abre sin su llave.
- **Tarea 5:** **en curso**, en la rama `phase-1/app-login` (PR #16 en borrador, sobre el #15).
  - Hecho:
    - el servidor arranca con `SERVER_HOST` vacío (antes fallaba);
    - el menú de la PC cabe al 125 % de escala y tiene la entrada «Pruebas»;
    - registro del equipo en el primer arranque;
    - ingreso con contraseña y cambio obligatorio de la contraseña inicial;
    - PIN sin conexión: el contador sube antes de verificar y sobrevive a reiniciar la app, 5 fallos exigen contraseña, la sesión dura 7 días y no se confía en un reloj atrasado;
    - «Cambiar usuario» y «Cerrar sesión»;
    - pruebas: app 200 en verde, 20 de ellas de sesión.
  - **Decisión del usuario:** Argon2id tarda **1028 ms** en la tablet (modo profile, mismos parámetros). `cryptography_flutter` no tiene Argon2id nativo, así que el usuario aceptó ~1 s. La verificación corre en segundo plano. Falta anotarlo en el ADR-0004.
  - **Incidente:** `flutter drive --profile` desinstaló la app de la tablet y borró su base local: 32 operaciones de prueba del Spike 6, sin datos del negocio. Al registrarla de nuevo, la tablet recibirá la serie `T2`. No volver a usar `flutter drive` en un equipo con datos sin preguntar.
  - **Pendiente:**
    1. prueba de punta a punta de las pantallas (registro → ingreso → cambio de contraseña → PIN);
    2. probar la migración de la base v1 a v2 con la base real de la PC;
    3. poner en `SERVER_HOST` la IP de la PC en la red local y probar en la tablet y la PC con el usuario;
    4. anotar en el ADR-0004 la decisión de ~1 s;
    5. sacar el PR #16 de borrador para revisión (autenticación: no se fusiona sin aprobación).
- El servidor local se detuvo: el sistema lo cerró por falta de memoria. Se vuelve a arrancar con `dart_frog build` y `dart build/bin/server.dart`, cargando el `.env`.
- **Tareas 6 a 8:** sin empezar.

### 2026-11-20 (tarde) — Tarea 5: punta a punta, migración y decisiones

- **Decisión del usuario (ADR-0004):** el PIN tarda **~1028 ms** en la SM-X133. Se acepta: la verificación corre en segundo plano y **no se bajan los parámetros**, porque `cryptography_flutter` no trae Argon2id nativo. Anotado en el ADR-0004.
- **Regla nueva en CLAUDE.md §12:** nunca ejecutar en un equipo real comandos que desinstalen la app o borren sus datos (`flutter drive`, `adb uninstall`, `pm clear`, reinstalar con otra firma) sin permiso del usuario, aunque sean datos de prueba.
- **Prueba de punta a punta** (`test/features/auth/login_flow_test.dart`, prueba de widgets con base en memoria y servidor falso, sin tocar ningún equipo): registro del equipo → ingreso con contraseña → cambio obligatorio (incluye contraseñas que no coinciden) → app → «Cambiar usuario» → PIN incorrecto (quedan 4 intentos) → PIN correcto. En verde; app 201 pruebas en verde y `flutter analyze` sin observaciones.
- **Migración v1 → v2 con la base real de la PC**, sobre una **copia** (la original no se tocó): versión 1 → 2, se crea `local_sessions` y se conservan todas las filas (outbox 1, spike 1, ajustes locales 2). La base real migrará sola, con el mismo código, al abrir la app nueva en la PC.
- PR #15 fusionado en `main` (`a562273`) con la CI en verde; el PR #16 apunta ahora a `main` y sigue abierto para revisión del usuario (autenticación).
- **En espera de volver a la tienda** (decisión del usuario): la PC estaba en la Wi-Fi `upc.edu.pe` (pública), donde no se debe exponer el servidor y que bloquea `git push`. Pendiente:
  1. subir el commit `3dbe381` al PR #16;
  2. en la Wi-Fi de la tienda: verificar la IP con `ipconfig`, ponerla en `SERVER_HOST` del `.env` y arrancar el servidor;
  3. probar con el usuario en la tablet y la PC (la base real de la PC migra a v2 al abrir la app nueva);
  4. sacar el PR #16 de borrador para revisión.
