# Fase actual: 1 — Fundamentos

Estado: **en curso** (desde 2026-11-19). Plan aprobado: `docs/planes/fase-1.md`. La bitácora de la Fase 0 está en `docs/informes/fase-0-bitacora.md`. Actualiza esta lista al terminar cada tarea.

## Tareas (cada una con pruebas y un PR pequeño)

- [x] 1. Migraciones (usuarios, roles, permisos, dispositivos, series, ajustes, auditoría, refresh, conflictos, log, estado de equipos) y seed: roles Administrador y Trabajo, permisos de `docs/modelo-datos.md` §4, ajustes del negocio (RUC 10409288419, "Gracias por su preferencia"). Pruebas contra PostgreSQL. Los **usuarios** se crean en la tarea 2: sus contraseñas necesitan Argon2id
- [ ] 2. Autenticación en el servidor: login Argon2id, JWT de 15 min, refresh rotativo, logout, `/me`, middleware de permisos
- [ ] 3. Registro de dispositivos, series y `GET /sync/pull` con cursor
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
