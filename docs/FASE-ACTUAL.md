# Fase actual: 0 — Planificación

Estado: **en curso**. Actualiza esta lista al terminar cada tarea.

## Entorno (usuario)

- [ ] Git instalado y repositorio clonado
- [ ] Flutter SDK (canal stable) — `flutter doctor` sin errores para Android y Windows
- [ ] Android Studio + Android SDK
- [ ] Visual Studio 2022 con "Desarrollo para el escritorio con C++" (para compilar Windows)
- [ ] Docker Desktop (PostgreSQL local)
- [ ] Tablet Tab A11 con opciones de desarrollador y depuración USB activadas
- [ ] Claude Code instalado y abierto en la carpeta del repositorio

## Tareas de Claude Code

- [ ] Crear monorepo: `apps/esquinita_app` (`flutter create --platforms=android,windows`), `apps/server` (Dart Frog), `packages/esquinita_core`
- [ ] Configurar análisis estático (`very_good_analysis` o `flutter_lints`), formato y CI básica (GitHub Actions: analyze + test)
- [ ] `docker-compose.yml` de desarrollo con PostgreSQL 16
- [ ] **Spike 1 — Escaneo**: pantalla de prueba con `mobile_scanner`, escaneo continuo, enfriamiento 1,5 s, confirmación en 2 cuadros, contador de lecturas. Medir tiempo por lectura en la Tab A11
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
- [ ] RAM de la Tab A11

## Criterio de salida

Spikes 1, 3 y 6 exitosos en hardware real con evidencia, prototipo y modelo de datos aprobados por el usuario.
