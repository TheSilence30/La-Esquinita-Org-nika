# Fase actual: 1 — Fundamentos

Estado: **en curso** (desde 2026-11-19). Plan aprobado: `docs/planes/fase-1.md`. La bitácora de la Fase 0 está en `docs/informes/fase-0-bitacora.md`. Actualiza esta lista al terminar cada tarea.

## Tareas (cada una con pruebas y un PR pequeño)

- [ ] 1. Migraciones (usuarios, roles, permisos, dispositivos, series, ajustes, auditoría, refresh, conflictos, log, estado de equipos) y seed: Administrador y Trabajo, permisos de `docs/modelo-datos.md` §4, ajustes del negocio (RUC 10409288419, "Gracias por su preferencia"). Pruebas contra PostgreSQL
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
