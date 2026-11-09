# Fase actual: 0 — Planificación

Estado: **en curso**. Actualiza esta lista al terminar cada tarea.

## Entorno (usuario)

- [x] Git instalado y repositorio clonado (2.55)
- [x] Flutter SDK (canal stable) — `flutter doctor` sin errores para Android y Windows (Flutter 3.47.9, Dart 3.13.7)
- [x] Android Studio + Android SDK (SDK 36; NDK 28.2.13676358 instalado el 2026-11-04 para compilar `mobile_scanner`)
- [x] Visual Studio (2026 Community) con "Desarrollo para el escritorio con C++" (para compilar Windows)
- [x] Docker Desktop (PostgreSQL local): 29.1.3, motor funcionando (2026-11-09)
- [x] Tablet Tab A11 con opciones de desarrollador y depuración USB activadas
- [x] Claude Code instalado y abierto en la carpeta del repositorio

## Tareas de Claude Code

- [x] Crear monorepo (pub workspace en la raíz; `dart_frog_cli` 1.2.14 instalado): `apps/esquinita_app` (`flutter create --platforms=android,windows`), `apps/server` (Dart Frog), `packages/esquinita_core`
- [x] Configurar análisis estático (`very_good_analysis` o `flutter_lints`), formato y CI básica (GitHub Actions: analyze + test) — **análisis y formato hechos** (`lints`/`flutter_lints`/`dart_frog_lint` + modo estricto). **CI hecha el 2026-11-09** (`.github/workflows/ci.yml`): en cada push y PR, en `ubuntu-latest` con Flutter 3.47.9, revisa el formato y corre `analyze --fatal-infos` y las pruebas de core, servidor y app. El APK debug se compila solo en push a `main` y se publica como artefacto. Sin build de Windows. Primera ejecución en verde: run 42712624172 (core 29, servidor 1, app 29). `.gitattributes`: LF por defecto, CRLF para `.bat`/`.cmd`/`.ps1`, y binarios marcados (la normalización no cambió archivos).
- [x] `docker-compose.yml` de desarrollo con PostgreSQL 16. Hecho el 2026-11-09: `postgres:16-alpine` (16.15), credenciales tomadas de `.env`, puerto solo en `127.0.0.1:5432`, volumen `pgdata` y chequeo de salud. Verificado: estado `healthy`, `select version()` y los datos persisten tras `down`/`up`. Uso: copiar `.env.example` a `.env` y ejecutar `docker compose up -d`.
- [x] **Spike 1 — Escaneo**: pantalla de prueba con `mobile_scanner`, escaneo continuo, enfriamiento 1,5 s, confirmación en 2 cuadros, contador de lecturas. Medir tiempo por lectura en la Tab A11. Hecho el 2026-11-09: resultados y conclusiones en `docs/informes/fase-0.md`. El usuario decidió que no hace falta el video.
  - [x] Filtro `ScanFilter` en core (2 cuadros ≤ 300 ms, enfriamiento 1,5 s, re-armado tras 500 ms de ausencia; configurables) con pruebas
  - [x] Pantalla del spike con métricas, “× cantidad”, ingreso manual, CSV; layout adaptable (celular, tablet, PC) probado en 6 tamaños
  - [x] APK debug y build Windows compilan
  - [ ] **Pendiente de prueba en dispositivo**: mediciones reales en la Tab A11 (ver `docs/informes/fase-0.md`)
- [ ] **Spike 2 — Lector HID**: en Windows, detectar ráfagas del lector USB vs tecleo humano
- [ ] **Spike 3 — Térmica Bluetooth (Android)** (en curso, rama `phase-0/spike-printing`; falta la prueba con papel): listar dispositivos, conectar a la Éterma, imprimir ticket de prueba con tildes, ñ, S/, logo raster y 40 líneas
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
- [x] Foto de la etiqueta/manual de la Éterma (modelo exacto): en su lugar se usó la **página de autoprueba** (2026-11-09). Firmware `1.005PH5I` (2025/10/15); USB y Bluetooth `V2.1+V4.0` (clásico SPP y BLE); `Printer001-C9E2` / `C0:2B:F3:AB:C9:E2`; 70 mm/s; densidad 4 de 8; **página de códigos por defecto PC437** (no tiene Á Í Ó Ú; probar `ESC t 2` = PC850); guarda imágenes en memoria (NV); sin cortador; apagado automático a los 60 min.
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

- ~~Spike 1: prueba en dispositivo.~~ Hecho el 2026-11-09 (ver las corridas de abajo). El sonido usa el clic del sistema, que no suena si los sonidos de toque de Android están apagados; si no sirve, agregar un pitido propio.
- ~~CI con GitHub Actions y `docker-compose.yml` con PostgreSQL 16.~~ Hecho el 2026-11-09 (rama `phase-0/ci-docker`).
- Spikes 2 a 6, prototipo navegable y modelo de datos.
- ~~Revisión del usuario y fusión de la rama a `main`.~~ Hecho el 2026-11-09.

**Corrida 1 en tablet (2026-11-09, parcial, no válida para cerrar el spike)**

- 21 lecturas de 12 códigos. Latencia: p50 62 ms, p95 381 ms. Hueco máximo: 486 ms.
- `7750543400036` dio 9 lecturas en 16 s, 4 de ellas marcadas como extra (filas 13–15, separadas entre sí ~1,5 s = el enfriamiento). Sin `absence_ms` no se puede saber si fueron cortes del detector o re-presentaciones, porque el paso 3.3 pedía retirar ~1 s, dentro del rango sospechoso.
- "Cuadros/s" = 1,1 estaba mal calculado (incluía el tiempo sin códigos a la vista).
- QR: no lo leyó, con `qr=off` en el CSV. Falta confirmar si el interruptor estaba encendido.
- Faltaron: la línea "Pantalla:", la orientación, los 20 productos distintos y el paso 3.4.
- Arreglos (2026-11-09): `977db78` agrega la columna `absence_ms`, `42af6c2` corrige los cuadros/s solo con el código a la vista, `dfd6734` agrega el selector **Paso de prueba** y la columna `step`, y el paso 3.3 del protocolo pasa a ~2 s.

**Corrida 2 en tablet (2026-11-09)**: los pasos 3.3, 3.4 y QR salieron como se esperaba. 0 lecturas extra; latencia p50 66 ms / p95 191 ms. El detalle está en `docs/informes/fase-0.md`. Repetición del 3.2: ✅ 1 lectura en ~22 s detectado (`191069706931`, `qr=off`). Falta: registrar las condiciones del 3.5, probar `7750543400036` quieto 10 s, la línea “Pantalla:” y las dos orientaciones.

**Siguiente paso exacto**

1. ~~Aplicar los pendientes 1 (a, b, c) y 2 de arriba, con sus pruebas automáticas.~~ Hecho el 2026-11-09 (`33e46d5`, `94f79c6`, `b548cf9`). Pruebas: core 29, app 25 y servidor 1, todas en verde; `analyze` sin problemas.
2. ~~Recompilar y reinstalar el APK en la tablet.~~ Hecho el 2026-11-09: APK debug instalado en la SM-X133 (R8YL60HT6CX); abre sin errores en el log. `adb` no está en el PATH: usar `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`.
3. ~~Prueba del usuario en la tablet.~~ Hecho el 2026-11-09: corridas 1 y 2 y repeticiones del 3.2 (`191069706931` y `7750543400036`, 1 lectura cada uno).
4. ~~Completar la tabla del informe y decidir los tiempos.~~ Hecho: se mantienen 300 / 1500 / 500 / 1000 ms. **Spike 1 marcado como hecho** (el video no hace falta, según el usuario).
5. ~~Revisión del usuario y fusión a `main`.~~ Aprobado por el usuario el 2026-11-09; Claude hizo la fusión con `--no-ff`, a pedido del usuario.
6. ~~CI y `docker-compose.yml`.~~ Hecho el 2026-11-09 en la rama `phase-0/ci-docker`, con PR abierto a `main` para revisión del usuario (no lo fusiona Claude). El job del APK correrá por primera vez después de la fusión.
7. ~~Fusión del PR #2~~ (2026-11-09). El primer build del APK en `main` salió en verde (run 42714969073).
8. Spike 3 (rama `phase-0/spike-printing`): plan aprobado y código hecho el 2026-11-09 (`eb25b1d` núcleo ESC/POS, `0dffd69` transporte SPP, `5ece331` pantalla y ticket). Se confirmó Bluetooth clásico (SPP). Logo definitivo en blanco y negro en `docs/marca/logo-bn.png`. Primera impresión en la tablet: conexión en 552 ms, sin errores.
9. **Siguiente:** ver la entrada del 2026-11-09 (Spike 3) más abajo.

### 2026-11-09 — CI + Docker, y Spike 3 (rama `phase-0/spike-printing`, sin fusionar)

**Rama actual:** `phase-0/spike-printing`, salida de `main` en `145540b` (fusión del PR #2). No hay PR abierto todavía.

**Se hizo hoy**

- **Spike 1** cerrado y fusionado a `main` (merge `c41738f`, a pedido del usuario).
- **CI y Docker** (PR #2, fusionado por el usuario):
  - `.gitattributes` con LF por defecto;
  - GitHub Actions que revisa el formato y corre `analyze` y las pruebas de core, servidor y app, y compila el APK debug solo en `main` (primer build en verde: run 42714969073);
  - `docker-compose.yml` con PostgreSQL 16.
- En esta rama, `permissions: contents: read` en el workflow (`96b90be`).
- **Datos de la Éterma** por la página de autoprueba (detalle en la lista de *Datos del negocio*): **Bluetooth clásico SPP** confirmado (la tablet registra el servicio SPP; firmware `V2.1+V4.0`), página de códigos por defecto **PC437**, sin cortador.
- **Logo definitivo** en blanco y negro: `docs/marca/logo-bn.png` (1774×887) y el recurso `apps/esquinita_app/assets/branding/logo-ticket.png` (768 px).
- **Código del Spike 3:**
  - `eb25b1d` núcleo: `PrintDocument`, `EscPosEncoder` para 58 mm, páginas de códigos y `MonoBitmap`;
  - `0dffd69` transporte: `BtSppChannel.kt` y `PrinterTransport` / `BluetoothSppTransport` / `PrintJobRunner`;
  - `5ece331` pantalla **Spike 3 — Impresión térmica**, ticket de 40 líneas y hoja de páginas de códigos;
  - `6fa7fc1` informe y protocolo en `docs/informes/fase-0.md`.
- **Pruebas** (ejecutadas al cerrar el día): core 48, app 60 y servidor 1, todas en verde; formato y `analyze --fatal-infos` sin problemas; el APK debug compila. En GitHub, la CI de `0dffd69` **falló por formato** (un import quitado sin reformatear el archivo de prueba); quedó corregido en `5ece331`, y desde ahí la CI está en verde (último run 42719130627).
- **En la tablet** (Claude vía `adb`): APK instalado; el diálogo de permisos `BLUETOOTH_CONNECT` / `BLUETOOTH_SCAN` apareció y se aceptó. Se imprimió la **página de códigos**: conexión en 552 ms, 0,6 KB enviados en 40 ms (256 B / 20 ms), sin errores.

**Decisiones tomadas (con el usuario)**

1. **Canal Bluetooth propio en Kotlin** (`BtSppChannel.kt`), sin paquetes de terceros.
2. **Condición SPP vs BLE:** si la Éterma fuera solo BLE, había que detenerse y consultar. Se verificó que es **Bluetooth clásico (SPP)**, así que se siguió. Se usa RFCOMM con el UUID SPP, primero seguro y luego inseguro.
3. **Envío por bloques con pausa configurable** (bloque de 32 B a 4 KB, pausa de 0 a 100 ms; valor inicial 256 B / 20 ms). El logo va además en franjas `GS v 0` de 64 filas. **Falta medir** qué combinación funciona en la Éterma.
4. **`PrinterTransport`:** la generación del ticket (`EscPosEncoder`, en core) no conoce el transporte. Bluetooth hoy; USB (Spike 4) será otra implementación.
5. **Permisos de Android 12+:** `BLUETOOTH_CONNECT` y `BLUETOOTH_SCAN` (este último con `neverForLocation`) se piden en tiempo de ejecución; hasta Android 11 se usan los permisos clásicos.
6. **Errores:** conexión con tiempo de espera de 8 s y mensajes claros en español. Reconexión: si la impresora se apagó y **no llegó nada**, se reconecta y se reenvía una vez; si llegó parte del ticket, **no se reenvía** (evita tickets duplicados) y se avisa que puede estar incompleto.
7. **Todo el Bluetooth fuera del hilo principal** (un hilo nativo de fondo).
8. **Texto PC850** como opción inicial: PC437, la página por defecto, no tiene Á Í Ó Ú. Se compara con el ticket como imagen.
9. **Logo con umbral simple**, sin difuminado (es arte plano en blanco y negro), a 320 puntos.

**Quedó a medias**

- **No se vio el papel** de la página de códigos: no se sabe todavía qué página (PC437, PC850, PC858 o WPC1252) imprime bien las tildes.
- **Sin probar en la Éterma:** el ticket como texto, el ticket como imagen, el barrido de bloques y pausas, y la reconexión con la impresora apagada (solo hay pruebas automáticas).
- La sección **Resultados en dispositivo** del Spike 3 en el informe está pendiente.
- No hay PR abierto (se abre al terminar la prueba en dispositivo; lo fusiona el usuario).
- Más adelante, fuera del spike: grabar el logo en la memoria NV de la impresora para que cada ticket pese menos.

**Siguiente paso exacto (mañana)**

1. Claude busca en la galería de la tablet la foto de la página de códigos (o el usuario la toma) y decide la página de códigos.
2. El usuario sigue el **protocolo del Spike 3** en `docs/informes/fase-0.md`:
   - ticket como texto con esa página;
   - barrido 4096/0 → 1024/0 → 512/10 → 256/20;
   - ticket como imagen;
   - reconexión con la impresora apagada;
   - **Copiar resultados (CSV)**.
3. Claude completa **Resultados en dispositivo** y fija los valores por defecto de página de códigos, bloque y pausa, con sus pruebas.
4. Claude abre el PR de `phase-0/spike-printing` a `main` (sin fusionarlo).
5. Después: Spike 4 (térmica por USB en Windows).

**Lo que Claude necesita del usuario**

- La **Éterma encendida, cargada y con papel** suficiente (el barrido gasta unos 8 tickets de ~15 cm).
- La **tablet conectada por USB** a la PC, con la depuración USB activa.
- **Aqp Print cerrada** mientras se prueba: puede ocupar la impresora.
- **Fotos del papel** de cada impresión (tomadas con la tablet, para que Claude las lea desde la galería) y el **CSV** de la pantalla.
- La foto de la etiqueta ya no hace falta: la autoprueba dio el modelo y el firmware.
- **Docker no hace falta mañana**: el Spike 3 no usa el servidor ni la base. Hará falta en el **Spike 6** (drift + outbox contra el servidor local). El contenedor de PostgreSQL (`la-esquinita-org-nika-db-1`) quedó corriendo; se puede apagar con `docker compose down` sin perder datos (volumen `pgdata`) y volver a levantar con `docker compose up -d`.
