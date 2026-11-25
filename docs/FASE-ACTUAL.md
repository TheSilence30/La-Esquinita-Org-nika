# Fase actual: 1 — Fundamentos

Estado: **en curso** (desde 2026-11-19). Plan aprobado: `docs/planes/fase-1.md`. La bitácora de la Fase 0 está en `docs/informes/fase-0-bitacora.md`. Actualiza esta lista al terminar cada tarea.

## Tareas (cada una con pruebas y un PR pequeño)

- [x] 1. Migraciones (usuarios, roles, permisos, dispositivos, series, ajustes, auditoría, refresh, conflictos, log, estado de equipos) y seed: roles Administrador y Trabajo, permisos de `docs/modelo-datos.md` §4, ajustes del negocio (RUC 10409288419, "Gracias por su preferencia"). Pruebas contra PostgreSQL. Los **usuarios** se crean en la tarea 2: sus contraseñas necesitan Argon2id
- [x] 2. Autenticación en el servidor: login Argon2id, JWT de 15 min, refresh rotativo, logout, `/me`, middleware de permisos. PR #12, aprobado y fusionado
- [x] 3. Registro de dispositivos, series y `GET /sync/pull` con cursor. PR #13, aprobado y fusionado
- [x] 4. Permisos en el core (misma regla en el servidor y en el equipo); Riverpod y drift (réplicas) con **SQLCipher** (llave en Keystore en Android, DPAPI en Windows); el pull baja `pin_hash` solo a los equipos donde el usuario entró con contraseña (ADR-0004). PR #15, aprobado y fusionado
- [x] 5. PR #16, aprobado y fusionado. App: primer arranque (servidor y registro del equipo), login con contraseña, PIN sin conexión (5 fallos exigen contraseña; el contador vive en la base local cifrada, sobrevive a reiniciar la app y solo vuelve a cero al entrar bien o con contraseña; medir Argon2id en la tablet, nativo si pasa de 1 s), sesión de 7 días
- [x] 5b. PR #18, aprobado y fusionado; probado en la tablet K70_PRO. Reloj atrasado: guardar en la base cifrada la hora más alta vista por la app (`last_seen_at`) y bloquear el PIN si el reloj del equipo retrocede más de 5 minutos respecto de esa hora, para que no se pueda estirar la sesión de 7 días atrasando la hora. Con su prueba
- [x] 6. **PR #17 abierto para revisión del usuario** (sincronización). Motor de sincronización completo (push por lotes, pull, reintentos, recuperación) e indicador real
- [ ] 7. **PR abierto para revisión del usuario** (rama `phase-1/admin-screens`). Pantallas de Usuarios y Ajustes del negocio (solo Administrador), con cambio de PIN y cierre de sesiones de un equipo perdido (revoca tokens y desactiva el equipo)
- [ ] 8. Prueba de aceptación en la tablet y la PC con el usuario; informe en `docs/informes/fase-1.md`

## Pendientes heredados de la Fase 0

- [ ] Prueba en dispositivo del escáner de venta con la cámara real (prototipo)
- [ ] Spike 2 (lector USB), antes de la Fase 3
- [ ] Spike 5 (A4 para reportes), con la Fase 6
- [ ] Regenerar el token de decolecta antes de producción

## Pendientes para fases siguientes

- [x] ~~**Fase 3**: sincronización inmediata por cada operación nueva~~. **Ya existe** (usuario, 2026-11-25): el motor de la tarea 6 arranca una ronda cuando sube el contador de pendientes del outbox, sea cual sea el comando. No queda pendiente para la Fase 3. Basta con que cada operación nueva pase por el outbox, que es la regla de siempre (CLAUDE.md §7).

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
  - **Incidente:** `flutter drive --profile` desinstaló la app de la tablet y borró su base local: 32 operaciones de prueba del Spike 6, sin datos del negocio. Al registrarla de nuevo, la tablet recibirá la serie `T2` (corregido el 2026-11-22: recibió `T1`, ver abajo). No volver a usar `flutter drive` en un equipo con datos sin preguntar.
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

### 2026-11-22 — Tarea 5: de vuelta en la tienda

- PC en la Wi-Fi `LA/ESQUINITA-2.4G` (perfil privado). `ipconfig`: **192.168.18.12**. Puesta en `SERVER_HOST` del `.env` (no va a git).
- PostgreSQL arrancado; migraciones al día (última `20261120000002`). Servidor compilado y escuchando en `http://192.168.18.12:8080`; el firewall solo lo abre en redes privadas (regla «Esquinita dev server (8080)»).
- Respaldo de la base real de la PC y su llave antes de la migración v1 → v2: `%LOCALAPPDATA%\LaEsquinita\backup-2026-11-22`.
- Compilados: app Windows (release) y APK de depuración.
- **Pendiente de prueba en dispositivo, con el usuario**: abrir la app nueva en la PC (migra a v2), registro → ingreso → cambio de contraseña → PIN en la PC y en la tablet (que recibirá la serie `T2`). Luego, sacar el PR #16 de borrador.
- **PC probada por el usuario**: la base migró a v2; registro, ingreso, cambio de contraseña y PIN bien; con un PIN incorrecto aparece el contador de intentos.
- **Pedido del usuario:** escribir el usuario era incómodo. Ahora la pantalla de ingreso lista a **todos los usuarios activos** del equipo (de la réplica bajada al registrarlo): con sesión guardada se entra con PIN; sin ella, solo se escribe la contraseña. Los desactivados no aparecen. Queda un enlace «Otro usuario» para quien se cree después del último pull. Pruebas: app 201 en verde, `flutter analyze` sin observaciones.
- Instalado en la tablet con `adb install -r` (conserva los datos). **Pendiente de prueba en dispositivo**: el selector en la tablet y en la PC.
- **Tarea 5 probada en la tablet y la PC por el usuario** («todo perfecto»): registro, selector de usuarios, contraseña, cambio obligatorio y PIN con contador. PR #16 fuera de borrador, para revisión del usuario (autenticación: no se fusiona sin su aprobación).

### 2026-11-22 — PR #16 fusionado; decisiones para la tarea 6

- El usuario aprobó el PR #16 (inicio de sesión). Se fusionó en `main` (`f576e4f`) con la CI en verde. La tarea 6 sigue en la rama `phase-1/sync-engine`.
- **Decisiones del usuario (tarea 6):**
  - **Reconexión sin paquetes nuevos**: mientras haya pendientes, reintentos con espera creciente de **60 s como máximo** (antes, 5 min). Además se sincroniza **justo después de registrar cada operación**, si hay conexión, y **al volver la app al primer plano** (`AppLifecycleState.resumed`). Esto reemplaza el pendiente de la Fase 0 «detectar al instante cuando vuelve la conexión».
  - **Refresh perdido** (la app se cerró justo al rotarlo y el servidor revocó la sesión): se pide la contraseña para volver a sincronizar. El PIN sigue funcionando sin conexión, los pendientes esperan sin perderse y el indicador dice «Entra con tu contraseña para sincronizar». No se relaja la regla del refresh rotativo.
- **Pendiente nuevo de la Fase 1** (tarea 5b): `last_seen_at` contra el reloj atrasado, con su prueba.

### 2026-11-22 — Tarea 6: motor de sincronización (PR en borrador)

- **Servidor**: `POST /sync/push` recibe `status.pending_ops` (lo que el equipo aún tiene por enviar después de ese envío) y lo guarda en `device_sync_status` (`last_push_at`, `pending_ops`, `reported_at`). Un valor inválido es un 400 y no toca la base.
- **App**:
  - `ServerSync`: envío y bajada con la sesión guardada del usuario en pantalla. El token de acceso (15 min) sale del refresh rotativo; el refresh nuevo se guarda en la base cifrada antes de usarlo. Ante un 401, renueva una vez y reintenta.
  - **Refresh revocado** (decisión del usuario): el refresh muerto se borra y nunca se reenvía. El indicador pide la contraseña, los pendientes esperan y no se programan reintentos hasta entrar con contraseña. El PIN sigue funcionando.
  - **Motor**: cada ronda envía por lotes y luego baja los maestros. Corre al iniciar sesión, al registrar una operación, al volver la app al primer plano, con el botón y cada 30 s **solo si hay pendientes**. Ante errores reintenta a los 5, 10, 20 y 40 s, y luego cada 60 s como máximo. Si se le pide una ronda durante otra, corre una más al terminar.
  - **Indicador real** en los dos shells: «Sincronizado», «Pendientes N», «Error · pendientes N», «Contraseña · pendientes N» o «Sincronizando…». Al tocarlo sincroniza y dice cómo fue. Se quitó el estado simulado del prototipo.
  - La página *Pruebas › Sincronización* usa el motor real, con el usuario de la sesión y el servidor registrado. Conserva «Envío lento» y «Reenviar todo».
- Pruebas: servidor 63 y app 213, en verde. `flutter analyze` sin observaciones. Nuevas:
  - token rotado guardado; token vencido; refresh perdido y reutilizado (pide contraseña y no lo reenvía); sin sesión;
  - pendientes informados por lote; dos equipos sin conexión; reintentos hasta 60 s; sin temporizador cuando no queda nada; ronda extra para una operación registrada a mitad; la bajada después del envío;
  - en el servidor: `device_sync_status` contra PostgreSQL y validación de `status`.
  - Ya existían: duplicado al reenviar, corte a mitad del envío, reinicio de la app y reloj adelantado o atrasado.
- shortcut: el indicador no cuenta las operaciones **rechazadas** (hoy solo hay de prueba). Se agrega con las ventas (Fase 3).
- Servidor reconstruido y corriendo en `192.168.18.12:8080`. APK instalado en la tablet (`adb install -r`) y app Windows compilada.
- **Pendiente de prueba en dispositivo, con el usuario**: operaciones de prueba sin conexión en la tablet y la PC; al reconectar se envían solas, sin duplicados, también cerrando la app a mitad del envío.
- **Probado en la tablet y la PC con el usuario (2026-11-22):**
  - **Los dos sin conexión** (servidor apagado): la tablet creó 30 operaciones y la PC 3. Los dos indicadores mostraron «Error · pendientes N». Al encender el servidor a las 14:32:32, la tablet envió las 30 al instante y la PC las 3 once segundos después (14:32:43), **sin tocar nada**. En el servidor: 30 y 4 (con 1 anterior), todas distintas, y `pending_ops` = 0 en los dos. Los indicadores pasaron a «Sincronizado».
  - **Cierre a mitad del envío** (tablet, «Envío lento», «Crear 30»): llegaron 7 y luego hubo una pausa de 16,6 s (app cerrada y abierta de nuevo, entrada con PIN). Las 23 restantes llegaron solas: **30 de 30, ninguna repetida**. La tablet suma 60 en el servidor, 60 distintas.
- Corrección: la tablet recibió la serie `T1`, no `T2`. El registro de equipos se estrenó en la tarea 5, después del incidente, y su primer registro en el servidor es el de hoy. Las 67 operaciones viejas del Spike 6 son de equipos de prueba de la Fase 0, sin registrar.
- PR #17 fuera de borrador, para revisión del usuario (sincronización: no se fusiona sin su aprobación).

### 2026-11-22 (cierre) — Estado y siguiente paso

- El usuario revisó y aprobó el PR #17 (sincronización). Se fusiona en `main` solo con la CI en verde; si falla, queda abierto y se anota aquí.
- Servidor de desarrollo **apagado**. PostgreSQL (Docker) sigue encendido. Para volver a arrancar el servidor: `dart pub global run dart_frog_cli:dart_frog build` en `apps/server`, y luego `dart build/bin/server.dart` con el `.env` cargado. `SERVER_HOST=192.168.18.12` (Wi-Fi de la tienda); revisarlo con `ipconfig` si cambia la red.
- Pendiente anotado para la Fase 3: sincronización inmediata por cada operación nueva. **Corregido el 2026-11-25:** ya existe (disparador por aumento de pendientes), no queda pendiente.
- **Siguiente paso exacto**, en este orden y cada uno en su propia rama desde `main`:
  1. **Tarea 5b**, rama `phase-1/clock-guard`: guardar en la base cifrada la hora más alta vista por la app (`last_seen_at`). Se actualiza al abrir la app, al entrar y en cada ronda de sincronización, y nunca baja. El PIN se bloquea (pide contraseña) si el reloj del equipo está más de 5 min por detrás de esa hora. Pruebas: reloj atrasado 6 min (bloquea), 4 min (no bloquea), y la hora vista que sobrevive a reiniciar la app. Es de autenticación: PR para revisión del usuario.
  2. **Tarea 7**, rama `phase-1/admin-screens`: pantallas de Usuarios (crear, rol, contraseña, PIN, desactivar) y Ajustes del negocio, solo Administrador, en el servidor y en la app. Más el cierre de sesiones de un equipo perdido (revoca tokens y desactiva el equipo). Antes de programar, presentar el plan al usuario.
  3. **Tarea 8**: prueba de aceptación en la tablet y la PC con el usuario e informe en `docs/informes/fase-1.md`.

### 2026-11-25 — Tarea 5b: reloj atrasado (PR para revisión)

- `last_seen_at` en `local_settings` (base cifrada; sin migración): milisegundos UTC de la hora más alta vista. Se guarda al mostrar la pantalla de ingreso (abrir la app), al entrar con PIN y después de cada ronda de sincronización con éxito. Nunca baja por esas vías.
- El PIN pide contraseña si el reloj está **más de 5 min por detrás** de esa hora: «La hora del equipo está atrasada. Corrígela o entra con tu contraseña.». No cuenta como intento fallido.
- **Excepción (aprobada por el usuario el 2026-11-25):** el ingreso con **contraseña** (aceptado por el servidor) vuelve a fijar `last_seen_at` a la hora del equipo, aunque sea menor. Sin eso, un reloj adelantado una vez por error (por ejemplo, al año 2030) dejaría el PIN bloqueado hasta esa fecha en todos los usuarios del equipo.
- Pruebas nuevas (`test/features/auth/local_auth_test.dart`): atrasado 4 min (entra), 6 min (bloquea, también en la lista de usuarios), la hora vista que sobrevive a una instancia nueva y no baja; la contraseña desbloquea tras un reloj adelantado. App 215 en verde; `flutter analyze` sin observaciones.
- **Pendiente de prueba en dispositivo**: en la tablet, atrasar la hora más de 5 min y comprobar que el PIN pide contraseña.
- **Aprobado por el usuario (2026-11-25), con una mejora en el mismo PR:**
  - Al entrar con contraseña se usa la **hora del servidor** (cabecera `Date` de la respuesta del login) para `passwordLoginAt` y `last_seen_at`. Si el servidor no la envía, se usa el reloj del equipo.
  - Si el reloj del equipo difiere **más de 5 min** de esa hora, la app muestra al abrirse un aviso ámbar fijo: «La hora de este equipo no coincide con la del servidor. Corrígela en Ajustes.». Si el equipo está atrasado, además el PIN queda bloqueado hasta corregir la hora o entrar con contraseña.
  - Pruebas: hora del servidor guardada sin aviso con 4 min de diferencia; aviso con 6 min adelantado y 3 h atrasado; PIN bloqueado con el equipo 6 min atrasado; cabecera `Date` válida, ausente o mal formada; aviso visible en la app (prueba de punta a punta). App 219 en verde; `flutter analyze` sin observaciones.
- PR #18 fusionado en `main` (`554f8b1`) con la CI en verde.
- **Probado en dispositivo por el usuario (2026-11-25)** en una **tablet nueva K70_PRO_US_A** (Android 16, 800×1280, IP `192.168.18.19`), instalada con `adb install -r` sin datos previos: registro, ingreso, PIN con la hora correcta; con el reloj atrasado, el PIN pide contraseña y aparece el aviso de hora. «Todo funcionó acorde a lo establecido».

### 2026-11-25 — Tarea 7: plan y decisiones del usuario

Rama `phase-1/admin-screens`. Plan presentado y aceptado, con estas decisiones:
- **Pantallas** de Usuarios, Ajustes del negocio y Equipos (solo Administrador) en **PC, tablet y celular**; el celular usa la vista de tablet adaptada.
- **Equipos**: ninguno se desactiva solo por no conectarse; la lista muestra su última conexión, como dato. Solo **«Dar de baja»** (acción explícita del Administrador, auditada) lo bloquea: se revocan sus tokens y el servidor rechaza su login, refresh, push y pull. La app **no borra nada**: solo deja de sincronizar y lo dice. Hay «Reactivar», porque nada se borra.
- **Ajustes**: en esta tarea, solo los datos del ticket (nombre, dirección, RUC, teléfono, WhatsApp, pie). Los demás se editan en su fase.
- Usuarios: crear, editar nombre y rol, contraseña temporal (obliga a cambiarla y cierra sus sesiones), PIN y desactivar o reactivar. No se puede desactivar ni quitar el rol al último Administrador activo, ni a uno mismo.
- Todo con conexión (API directa, no outbox) y con `audit_log`. Es de autenticación: PR para revisión del usuario.

### 2026-11-25 — Tarea 7: implementación (PR para revisión)

- **Core**: `isValidRuc` (11 dígitos, prefijo 10/15/16/17/20 y dígito verificador módulo 11 de SUNAT), con su prueba.
- **Servidor** (`AdminService`, todo en una transacción con `audit_log`, sin hashes en la auditoría):
  - `GET/POST /users`, `PATCH /users/:id` (nombre, usuario, rol, activo), `POST /users/:id/password` (temporal: obliga a cambiarla y cierra sus sesiones), `POST /users/:id/pin`. Permiso `users.manage`.
  - `GET/PATCH /settings`: solo los datos del ticket; solo se guardan y auditan los que cambian; un teléfono vacío queda como JSON `null`. Permiso `settings.manage`.
  - `GET /devices` (con la última conexión: último envío, bajada o renovación de sesión) y `PATCH /devices/:id` (`active`). Permiso `settings.manage`.
  - **Equipo dado de baja**: `authenticate`, `refresh` y `login` lo rechazan (el login, con 403 `device_blocked`, solo después de la contraseña correcta). Un equipo aún no registrado sí entra, porque se registra después de entrar.
  - Reglas: nadie se desactiva ni se quita el rol de Administrador a sí mismo (así siempre queda un Administrador activo) ni da de baja su propio equipo (409 `self`); usuario repetido sin importar mayúsculas (409 `username_taken`).
- **App**: *Ajustes* con tres pestañas (Negocio, Usuarios, Equipos), cada una según su permiso. En la PC desde el menú lateral; en la tablet y el celular desde *Más › Ajustes*. Usa la sesión guardada (`ServerSync.authorized`) y, tras cada cambio, una ronda de sincronización para actualizar las réplicas. Mensajes en español; un equipo dado de baja ve «Este equipo fue dado de baja. Pide al Administrador que lo reactive.» al entrar con contraseña. Fechas en hora de Lima (`limaDateTime`).
- Pruebas: servidor **78** en verde (contra PostgreSQL: usuarios, ajustes, equipos, auditoría, revocación; rutas: 403 para Trabajo en todas, 400 por datos inválidos, 404/409); app **229** en verde (casos de uso, pantallas en PC y celular, mensaje de equipo dado de baja); `flutter analyze` y `dart analyze` sin observaciones. Servidor de desarrollo reconstruido y comprobado: las rutas nuevas responden 401 sin sesión.
- **Pendiente de prueba en dispositivo, con el usuario**: desde la PC y la tablet, crear un usuario, cambiar un PIN (llega al otro equipo al sincronizar), editar los datos del negocio y dar de baja y reactivar un equipo.

### 2026-11-25 — Tarea 7: probada por el usuario y corrección de «Dar de baja»

- **Probado por el usuario**: crear un usuario desde la PC (`Leandfro`) y entrar con él en la tablet, que instaló la versión nueva con `adb install -r`. «Funcionó todo».
- **Problema que encontró el usuario**: al reactivar la tablet, la sincronización pedía la contraseña (los tokens se habían revocado al dar de baja), pero la pantalla del PIN no ofrecía entrar con contraseña.
- **Decisiones del usuario:**
  - **«Dar de baja» solo bloquea, sin revocar.** El servidor responde 403 `device_blocked` (no 401) en el login, el refresh y toda ruta con sesión. El refresh no se rota, así que la app conserva su sesión, el indicador dice «Este equipo fue dado de baja…» y sigue reintentando. Al reactivarlo, vuelve a sincronizar solo con el PIN, sin contraseña.
  - **«Entrar con contraseña»** en la pantalla del PIN, sin escribir el usuario.
- El PIN sigue verificándose solo en el equipo: no se envía al servidor, que tampoco lo valida. Así no hay forma de adivinar un PIN de 4 dígitos por la red.
- Pruebas: servidor 79 y app 231, en verde. Nuevas: el bloqueo sin revocar, el mismo refresh que vuelve a funcionar al reactivar, 403 `device_blocked` en las rutas y el refresh, la sesión que la app conserva, el envío sin contraseña tras reactivar y el enlace «Entrar con contraseña».
- **Pendiente de prueba en dispositivo**: dar de baja la tablet (el indicador lo dice) y reactivarla (sincroniza sola, sin contraseña).
