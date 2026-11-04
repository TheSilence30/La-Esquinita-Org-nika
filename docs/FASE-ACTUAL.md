# Fase actual: 0 — Planificación

Estado: **en curso**. Actualiza esta lista al terminar cada tarea.

## Entorno (usuario)

- [x] Git instalado y repositorio clonado (2.55)
- [x] Flutter SDK (canal stable) — `flutter doctor` sin errores para Android y Windows (Flutter 3.47.9, Dart 3.13.7)
- [x] Android Studio + Android SDK (SDK 36; NDK 28.2.13676358 instalado el 2026-11-04 para compilar `mobile_scanner`)
- [x] Visual Studio (2026 Community) con "Desarrollo para el escritorio con C++" (para compilar Windows)
- [ ] Docker Desktop (PostgreSQL local) — instalado (29.1.3) pero el motor no estaba iniciado; abrirlo antes del `docker-compose`
- [x] Tablet Tab A11 con opciones de desarrollador y depuración USB activadas
- [x] Claude Code instalado y abierto en la carpeta del repositorio

## Tareas de Claude Code

- [x] Crear monorepo (pub workspace en la raíz; `dart_frog_cli` 1.2.14 instalado): `apps/esquinita_app` (`flutter create --platforms=android,windows`), `apps/server` (Dart Frog), `packages/esquinita_core`
- [ ] Configurar análisis estático (`very_good_analysis` o `flutter_lints`), formato y CI básica (GitHub Actions: analyze + test) — **análisis y formato hechos** (`lints`/`flutter_lints`/`dart_frog_lint` + modo estricto); **falta la CI**
- [ ] `docker-compose.yml` de desarrollo con PostgreSQL 16
- [ ] **Spike 1 — Escaneo**: pantalla de prueba con `mobile_scanner`, escaneo continuo, enfriamiento 1,5 s, confirmación en 2 cuadros, contador de lecturas. Medir tiempo por lectura en la Tab A11
  - [x] Filtro `ScanFilter` en core (2 cuadros ≤ 300 ms, enfriamiento 1,5 s, re-armado tras 500 ms de ausencia; configurables) con pruebas
  - [x] Pantalla del spike con métricas, “× cantidad”, ingreso manual, CSV; layout adaptable (celular, tablet, PC) probado en 6 tamaños
  - [x] APK debug y build Windows compilan
  - [ ] **Pendiente de prueba en dispositivo**: mediciones reales en la Tab A11 (ver `docs/informes/fase-0.md`)
- [ ] **Spike 2 — Lector HID**: en Windows, detectar ráfagas del lector USB vs tecleo humano
- [ ] **Spike 3 — Térmica Bluetooth (Android)**: listar dispositivos, conectar a la Éterma, imprimir ticket de prueba con tildes, ñ, S/, logo raster y 40 líneas
- [ ] **Spike 4 — Térmica USB (Windows)**: imprimir el mismo ticket por USB
- [ ] **Spike 5 — A4**: PDF de nota de pedido impreso en la Epson L460
- [ ] **Spike 6 — drift + outbox**: crear operación offline, cerrar la app, reabrir, sincronizar contra servidor local sin duplicar
- [ ] Prototipo navegable (pantallas sin lógica real): POS tablet, POS escritorio, alta por escaneo, dashboard tablet
- [ ] Modelo de datos inicial en `docs/modelo-datos.md` (tablas, claves, índices únicos)
- [ ] Informe de Fase 0 en `docs/informes/fase-0.md` con evidencia de cada spike

## Datos del negocio (usuario)

- [ ] Logo en alta resolución (PNG ≥ 1000 px o vectorial)
- [ ] Datos para tickets: RUC (si se mostrará), teléfono, WhatsApp, redes, mensaje final
- [ ] Catálogo inicial en `docs/plantillas/catalogo_inicial.csv` (aunque sean 20 productos para empezar)
- [ ] Usuarios iniciales y su rol
- [ ] Foto de la etiqueta/manual de la Éterma (modelo exacto)
- [x] RAM de la Tab A11 — 4 GB (SM-X133, Android 16, 800×1340 px)

## Criterio de salida

Spikes 1, 3 y 6 exitosos en hardware real con evidencia, prototipo y modelo de datos aprobados por el usuario.
