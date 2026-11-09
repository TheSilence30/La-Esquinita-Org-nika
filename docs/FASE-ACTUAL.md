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

## Bitácora

### 2026-11-04 — Monorepo + Spike 1 (rama `phase-0/monorepo-scan-spike`, sin fusionar)

**Se hizo**

- Entorno verificado: `flutter doctor` sin problemas. Se instalaron el NDK 28.2.13676358 (lo requiere `mobile_scanner`) y `dart_frog_cli` 1.2.14. Este último **no está en el PATH**: falta agregar `C:\Users\Leandro\AppData\Local\Pub\Cache\bin`.
- Tablet: SM-X133, Android 16, 4 GB de RAM, 800×1340 px; densidad de fábrica 240 dpi, que da **533×893 dp**. Decisión abierta n.º 1 cerrada.
- Monorepo con pub workspace: `apps/esquinita_app`, `apps/server` (`GET /health`) y `packages/esquinita_core`. Análisis estático en modo estricto.
- Core: `Money`, `Quantity` y `ScanFilter` (confirmación 300 ms, enfriamiento 1,5 s, re-armado tras 500 ms de ausencia; los tres configurables).
- App: pantalla del Spike 1 con métricas, campo “× cantidad”, ingreso manual, CSV y diseño adaptable (celular, tablet, PC). Umbral de tablet: 520 dp.
- Pruebas: core 19, app 16 y servidor 1, todas en verde. `analyze` sin problemas. APK debug y build de Windows compilan.
- APK instalado en la tablet: abre sin errores en el log.

**Pendientes ANTES de la prueba en tablet** (revisión del usuario, 2026-11-04)

1. Correcciones de revisión:
   - [x] (a) Registrar, en el CSV y en pantalla, el **hueco máximo entre detecciones** de cada código aceptado y los **re-armados falsos**. Hecho, con los ajustes del usuario: **re-armado sospechoso** = ausencia de un código ya aceptado entre `rearmAbsence` y `suspiciousRearmLimit` (1000 ms, inclusive y configurable), termine o no en otra aceptación; **lecturas extra** = las aceptaciones que vienen después de un re-armado sospechoso. Ambas cifras aparecen en pantalla y en el CSV, junto con `max_gap_ms` por lectura.
   - [x] (b) Interruptor **“Incluir QR”**, apagado por defecto. Agregar a CLAUDE.md que en ventas el QR va desactivado. Hecho: `scanFormats(includeQr:)`, la cámara se reinicia al cambiar el interruptor, el CSV anota `qr=on/off` y CLAUDE.md §6.11 lo registra.
   - [x] (c) **Reloj monotónico** para los tiempos del filtro (`ScanFilter`). `DateTime` UTC solo para registrar la hora de cada lectura. Hecho: `ScanFilter.offer` recibe `Duration` de un `Stopwatch` compartido; la sesión recibe ambos tiempos y los cuadros/s usan el monotónico. Prueba nueva: salto de 1 h del reloj UTC sin efecto.
2. Umbral de tablet: clasificar por el lado más corto (`shortestSide`) con umbral de **520 dp** y agregar una prueba con **533×893 dp** (la Tab A11 en vertical queda por debajo de 550 dp).
   - [x] Ya aplicado en el commit `f74a095`: `FormFactor.resolve` usa `size.shortestSide >= 520`, y hay pruebas con 533×893 (clasificación y diseño en vertical y horizontal). Revisar al aplicar el punto 1.

**Falta**

- Spike 1: **prueba en dispositivo**. Hay que escanear productos reales siguiendo el protocolo de `docs/informes/fase-0.md`, y obtener el CSV, el video y la línea “Pantalla:”. El sonido usa el clic del sistema, que no suena si los sonidos de toque de Android están apagados; si no sirve, agregar un pitido propio.
- CI con GitHub Actions (analyze + test) y `docker-compose.yml` con PostgreSQL 16. Antes hay que iniciar Docker Desktop.
- Spikes 2 a 6, prototipo navegable y modelo de datos.
- Revisión del usuario y fusión de la rama a `main` (la hace el usuario).

**Corrida 1 en tablet (2026-11-09, parcial, no válida para cerrar el spike)**

- 21 lecturas de 12 códigos. Latencia: p50 62 ms, p95 381 ms. Hueco máximo: 486 ms.
- `7750543400036` dio 9 lecturas en 16 s, 4 de ellas marcadas como extra (filas 13–15, separadas entre sí ~1,5 s = el enfriamiento). Sin `absence_ms` no se puede saber si fueron cortes del detector o re-presentaciones, porque el paso 3.3 pedía retirar ~1 s, dentro del rango sospechoso.
- "Cuadros/s" = 1,1 estaba mal calculado (incluía el tiempo sin códigos a la vista).
- QR: no lo leyó, con `qr=off` en el CSV. Falta confirmar si el interruptor estaba encendido.
- Faltaron: la línea "Pantalla:", la orientación, los 20 productos distintos y el paso 3.4.
- Arreglos (2026-11-09): `977db78` agrega la columna `absence_ms`, `42af6c2` corrige los cuadros/s solo con el código a la vista, `dfd6734` agrega el selector **Paso de prueba** y la columna `step`, y el paso 3.3 del protocolo pasa a ~2 s.

**Siguiente paso exacto**

1. ~~Aplicar los pendientes 1 (a, b, c) y 2 de arriba, con sus pruebas automáticas.~~ Hecho el 2026-11-09 (`33e46d5`, `94f79c6`, `b548cf9`). Pruebas: core 29, app 25 y servidor 1, todas en verde; `analyze` sin problemas.
2. ~~Recompilar y reinstalar el APK en la tablet.~~ Hecho el 2026-11-09: APK debug instalado en la SM-X133 (R8YL60HT6CX); abre sin errores en el log. `adb` no está en el PATH: usar `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`.
3. Recién entonces, el usuario abre **La Esquinita › Spike 1** y sigue los pasos 2 a 7 del protocolo de `docs/informes/fase-0.md`, en horizontal y en vertical.
4. El usuario pega en la conversación el CSV de **Copiar resultados (CSV)** (ahora incluye `max_gap_ms`, `suspicious_rearms` y `extra_reads`) y la línea “Pantalla:”. Claude completa la tabla “Resultados en dispositivo” del informe, ajusta los tiempos del filtro si hubo lecturas dobles o perdidas, y marca el Spike 1 como hecho.
5. Después: CI y `docker-compose.yml`, y luego el Spike 3 (térmica Bluetooth).
