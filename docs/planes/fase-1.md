# Plan de la Fase 1 — Fundamentos

Estado: **aprobado por el usuario el 2026-11-19**. Semanas 3–6 de `docs/PLAN.md`.

## Objetivo

Que la tablet y la PC **inicien sesión con usuarios reales** y trabajen con su **base local**. Además, que las operaciones hechas **sin conexión** lleguen al servidor **una sola vez**, aunque la app se cierre o el equipo se reinicie. Todavía no se vende ni se maneja stock real: la Fase 1 construye la base sobre la que se apoyan las Fases 2 a 6.

## Criterios de aceptación (de `docs/PLAN.md`)

1. Un usuario inicia sesión en la **tablet** y en la **PC**: con contraseña cuando hay conexión y con **PIN** cuando no la hay (sesión guardada en el equipo y con vencimiento).
2. Una **operación de prueba** creada **sin conexión en los dos equipos** se sincroniza **sin duplicados** al reconectar, también si se cierra la app a mitad del envío.
3. El **indicador de sincronización** es real (sincronizado / pendientes N / error) y está siempre visible.
4. Las pruebas automáticas de sincronización, autenticación y permisos están en verde, en la CI y ejecutadas en local.

## Qué entra

### A. Servidor (Dart Frog + PostgreSQL)

- **Migraciones** (dbmate, `apps/server/migrations`) de las tablas de `docs/modelo-datos.md` §2.8–§2.9:
  - `users`, `roles`, `permissions`, `role_permissions`, `user_roles`;
  - `devices`, `document_series`, `settings`;
  - `audit_log`, `refresh_tokens`;
  - `sync_conflicts`, `sync_log`, `device_sync_status`. `sync_inbox` ya existe.
- **Seed**:
  - roles **Administrador** y **Trabajo** con los permisos de §4;
  - el usuario Administrador inicial, con su contraseña tomada de `.env` en el primer arranque;
  - `settings` con `TODO(config)` para los datos del negocio.
- **Autenticación**:
  - `POST /auth/login` (usuario y contraseña, **Argon2id**);
  - `POST /auth/refresh` (refresh **rotativo**, el anterior queda revocado);
  - `POST /auth/logout`;
  - `GET /me` (usuario, roles, permisos).
  - El access token **JWT dura 15 minutos**.
- **Middleware**: verifica el JWT y el permiso `modulo.accion` en cada ruta.
- **Dispositivos**: `POST /devices/register` con nombre, plataforma y su serie (`T1`, `P1`…) y dígito de código de barras únicos.
- **Sincronización**:
  - `POST /sync/push` (ya existe) pasa a exigir sesión y recibe el `status` del equipo (pendientes);
  - nuevo `GET /sync/pull?since=` con cursor de versión para usuarios, roles, permisos, dispositivos y ajustes;
  - `audit_log` se escribe en la misma transacción que aplica cada comando.
- **Usuarios y ajustes** (API directa, solo Administrador): crear usuario, asignar rol, cambiar contraseña o PIN, desactivar (nunca borrar); leer y editar los datos del negocio.

### B. Dominio compartido (`packages/esquinita_core`)

- Catálogo de **permisos** (códigos `modulo.accion`) y la regla "¿este usuario puede?", **la misma** en el servidor y en el equipo sin conexión.
- `Quantity` (milésimas) junto a `Money`, si aún falta.
- Comando de prueba de sincronización: no toca ventas ni stock.

### C. App Flutter (tablet primero; la PC se tiene en cuenta)

- **Riverpod** (con generador): reemplaza el `DemoStore` en lo que se construye en esta fase.
- **drift**:
  - réplica local de usuarios (**sin** contraseña, solo el `pin_hash` de quien usa ese equipo), roles, permisos, dispositivos y ajustes;
  - `sync_state` y `local_settings`;
  - el `outbox` (ya existe).
- **Primer arranque**: dirección del servidor y registro del equipo (nombre, por ejemplo "Tablet caja"). Desde ese momento el equipo conoce su `device_id` y su serie.
- **Inicio de sesión**:
  - usuario y contraseña con conexión;
  - **PIN** para el ingreso rápido y sin conexión, con la sesión guardada y vencimiento;
  - cierre de sesión;
  - pantalla inicial según el rol (Dashboard o Vender).
- **Permisos en la app**: el menú y las rutas se arman con los permisos reales, en lugar del selector de rol del prototipo.
- **Motor de sincronización**:
  - envío del outbox por lotes;
  - bajada con cursor;
  - automática al reconectar y cada 30 s **solo si hay pendientes** (con espera creciente ante errores), y un botón manual;
  - registro de errores;
  - recuperación tras reiniciar la app.
- **Indicador real** de sincronización en los dos shells.
- **Pantallas de Administrador**: Usuarios (crear, rol, PIN, desactivar) y Ajustes del negocio (datos para el ticket con `TODO(config)`).
- **Prototipo**: sigue disponible en *Más › Prototipo* como referencia y se retira módulo por módulo a medida que las Fases 2 y 3 lo reemplacen.

### D. Infraestructura

- Docker Compose de desarrollo con **servidor + PostgreSQL** (hoy solo PostgreSQL).
- La tablet se conecta por **Wi-Fi a la PC** (`SERVER_HOST` con la IP de la red local). El VPS con Caddy queda para la Fase 7.
- CI: agrega las pruebas del servidor contra PostgreSQL. La CI ya corre core, servidor y app.

## Qué no entra (y en qué fase va)

- Productos, stock, lotes reales: Fase 2.
- Ventas, cobro, tickets reales y consulta de DNI/RUC (ADR-0003): Fase 3.
- Caja y latido de `device_sync_status`: Fase 4.
- Clientes: Fase 5.
- Reportes y A4: Fase 6.
- VPS, respaldos automáticos e instaladores: Fase 7.
- Spike 2 (lector USB): pendiente; se hace cuando haya un lector, antes de la Fase 3.

## Orden de trabajo (cada paso con sus pruebas y un PR pequeño)

1. Migraciones, seed y pruebas del servidor contra PostgreSQL.
2. Autenticación en el servidor: login, refresh rotativo, logout, `/me`, middleware y permisos.
3. Registro de dispositivos, series y `GET /sync/pull`.
4. Permisos en el core y en la app; Riverpod y drift (réplicas).
5. App: primer arranque, login con contraseña y PIN, sesión sin conexión.
6. Motor de sincronización completo e indicador real.
7. Pantallas de Usuarios y Ajustes.
8. **Prueba de aceptación en la tablet y la PC**, con el usuario. Informe en `docs/informes/fase-1.md`.

## Pruebas obligatorias

- **Sincronización**:
  - el mismo comando enviado dos veces → `duplicate`;
  - corte a mitad del envío y reinicio de la app → nada se pierde ni se duplica;
  - dos equipos sin conexión → los dos se sincronizan;
  - reloj del equipo adelantado o atrasado.
- **Autenticación**:
  - contraseña incorrecta;
  - refresh reutilizado → se revoca la sesión;
  - token vencido;
  - usuario desactivado;
  - PIN sin conexión con la sesión vencida → pide conexión.
- **Permisos**: Trabajo no entra a Usuarios ni a Ajustes, ni en el servidor ni en la app.
- **Seguridad**:
  - los secretos solo viven en `.env`;
  - ni contraseñas ni tokens aparecen en logs ni en respuestas;
  - `password_hash` nunca baja al equipo.

## Decisiones del usuario (2026-11-19)

1. **Sesión sin conexión: 7 días.** Después de eso, el equipo pide conectarse una vez.
2. **PIN de 4 a 6 dígitos**, uno por usuario.
3. **Dos usuarios iniciales**:
   - `Administrador` (rol Administrador);
   - un usuario con rol **Trabajo**. Su nombre de usuario provisional es `Trabajo` y se puede cambiar en Usuarios.
   - Las contraseñas y los PIN iniciales se toman de `.env` (nunca de git) y se cambian en el primer ingreso.
4. **Datos del ticket**:
   - **RUC 10409288419** (dígito verificador correcto);
   - mensaje final **"Gracias por su preferencia"**;
   - **sin** teléfono ni WhatsApp (decisión del usuario: "nada más").

## Riesgos

- **Wi-Fi de la tienda**: si la tablet no ve la PC, solo funciona sin conexión hasta que se reconecte, que es el diseño offline-first. Para la prueba de aceptación hace falta que estén en la misma red.
- **Argon2id en Dart**: se elige el paquete en el paso 2 y se mide que el login tarde menos de 1 s en el servidor.
