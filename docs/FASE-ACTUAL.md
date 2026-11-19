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
- [ ] **Spike 3 — Térmica Bluetooth (Android)** (rama `phase-0/spike-printing`; probado con papel el 2026-11-17, **pendiente de aprobación del usuario**): listar dispositivos, conectar a la Éterma, imprimir ticket de prueba con tildes, ñ, S/, logo raster y 40 líneas. Resultado: PC850 y 4096 B / 10 ms (ver `docs/informes/fase-0.md`)
- [ ] **Spike 4 — Térmica USB (Windows)** (rama `phase-0/spike-usb-printing`; probado con papel el 2026-11-17, **pendiente de aprobación del usuario**): imprimir el mismo ticket por USB
- [ ] **Spike 5 — A4** (**en espera** por decisión del usuario, 2026-11-17): PDF de nota de pedido impreso en la Epson L4160
- [ ] **Spike 6 — drift + outbox** (rama `phase-0/spike-drift-outbox`; probado en tablet y PC el 2026-11-17, **pendiente de aprobación del usuario**): crear operación offline, cerrar la app, reabrir, sincronizar contra servidor local sin duplicar
- [ ] Prototipo navegable (pantallas sin lógica real): POS tablet, POS escritorio, alta por escaneo, dashboard tablet — hecho en la rama `phase-0/prototype` (también cobro, calculadora de peso, cierre de caja y layout de celular); probado en PC, celular y tablet; **pendiente de aprobación del usuario (PR)**
- [x] Modelo de datos inicial en `docs/modelo-datos.md` (tablas, claves, índices únicos) — **aprobado por el usuario el 2026-11-17** (PR #6; roles Administrador/Trabajo en CLAUDE.md §9)
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

### 2026-11-17 — Spike 3: prueba con papel (rama `phase-0/spike-printing`, sin fusionar)

**Se hizo**

- El usuario imprimió en la Éterma desde la tablet: la página de códigos, el ticket como texto y como imagen, varias combinaciones de bloque y pausa, y dos reconexiones automáticas. Mandó las fotos por Quick Share (`Download/Quick Share`, no `DCIM/Camera`) y pegó el CSV (Samsung Notes no se puede leer por `adb`).
- Página de códigos: **PC850** (también sirven PC858 y WPC1252; PC437 no tiene ÁÉÍÓÚ). Ya era el valor por defecto.
- Envío: **4096 B / 10 ms** imprime texto e imagen completos y limpios (texto en 22 ms, imagen en 136 ms, frente a 716 ms y 4,5 s con 256/20). Ahora es el valor por defecto en `PrintSettings`, y la pantalla del spike lo toma de ahí.
- Resultados completos y CSV en `docs/informes/fase-0.md` → *Resultados en dispositivo*.
- Pruebas de la app: 60 en verde; formato y `analyze --fatal-infos` sin problemas.

**Quedó sin probar o anotado**

- El mensaje de error al pulsar con la impresora **todavía apagada** no se probó en el dispositivo (solo las pruebas automáticas).
- Recorte pequeño en dos líneas del ticket como imagen (con 256/20). El usuario lo aceptó; no se investigó.
- Para después: un espacio que no se parta entre la cantidad y la unidad ("250 g").

**Siguiente paso exacto**

1. ~~El usuario revisa y aprueba el Spike 3.~~ Aprobado el 2026-11-17.
2. ~~Claude abre el PR.~~ PR #3 abierto; falta que el usuario lo fusione.
3. Spike 4: térmica por USB en Windows.

### 2026-11-17 — Spike 4: térmica por USB en Windows (rama `phase-0/spike-usb-printing`)

**Se hizo**

- El PR #3 (Spike 3) fue fusionado por el usuario. Se creó la rama desde `main` (`6da77c6`).
- La impresora A4 es la **Epson L4160**, no la L460: se corrigió en CLAUDE.md, PLAN.md y esta lista (`310cbc5`). Se usará también para los reportes de ventas mensuales. Después, con el visto bueno del usuario, también en `docs/ESPECIFICACION.md` y el ADR-0001.
- Windows ve la Éterma como impresora USB estándar (`VID_0483&PID_5743`, `usbprint.sys`, sin cola).
- Decisiones del usuario: usar `win32` + `ffi`; buscar siempre por el identificador de hardware y no por `USB009`; prueba de desconectar y reconectar con el simulador; `win32` solo en Windows.
- Commits: `78865e1` transporte USB y pruebas, `9e96c00` implementación con `win32`, `e93c6f9` pantalla USB/Bluetooth según la plataforma.
- Pruebas de la app: 70 en verde; `analyze` sin problemas; el APK y el build de Windows compilan. Lista y apertura reales verificadas en la PC.

**Siguiente paso exacto**

1. ~~Prueba con papel del usuario.~~ Hecha: texto, imagen, cable desconectado/reconectado y apagar/encender, todo correcto (ver el informe).
2. ~~Claude completa los resultados y abre el PR.~~ PR abierto; falta que el usuario lo revise y lo fusione.
3. El usuario pidió que Claude fusione el PR #4. Sigue el **Spike 6** (drift + outbox); el Spike 5 queda en espera.

### 2026-11-17 — Spike 6: drift + outbox (rama `phase-0/spike-drift-outbox`)

**Se hizo**

- El PR #4 (Spike 4) fue fusionado por Claude, a pedido del usuario (`31c3092`). El Spike 5 queda en espera.
- Decisiones del usuario:
  - dependencias aprobadas: `drift`, `drift_flutter`, `http`, `drift_dev`, `build_runner` y `postgres`;
  - operación de prueba genérica (nota + importe en céntimos);
  - `/sync/pull` en la Fase 1 y sin login en el spike;
  - el servidor escucha solo en la red local y la regla del firewall es solo para redes privadas;
  - reserva del `op_id` y aplicación en la misma transacción, con `ON CONFLICT DO NOTHING` y el resultado original guardado;
  - prueba de concurrencia, y `received_at` con la hora del servidor, con prueba de reloj desfasado;
  - prueba de 30 operaciones con modo avión a la mitad.
- Commits:
  - `866ea7d` core: UUID v7, `SyncCommand` y resultados;
  - `9994165` servidor: `/sync/push`, migraciones con dbmate y Postgres en la CI;
  - `5abcc12` app: outbox con drift, envío por lotes y reintentos;
  - `b1ea94e` pantalla del Spike 6.
- Pruebas: core 54, servidor 10 (6 contra PostgreSQL, también en la CI) y app 81, todas en verde. El APK compila. Servidor real verificado con `curl`.
- Base `esquinita_test` creada en el contenedor local para las pruebas del servidor (`TEST_DATABASE_URL` en `.env.example`).

**Bloqueos para la prueba en hardware (usuario)**

- La Wi‑Fi `LA/ESQUINITA-2.4G` está marcada como **Pública**: hay que marcarla como **Privada** y crear la regla del firewall (comandos de administrador).
- El build de Windows necesita el **Modo de desarrollador** de Windows.
- La tablet tiene que estar conectada por USB para instalar el APK.

**Tareas para la Fase 1 (pedidas por el usuario el 2026-11-17)**

- [ ] Detectar al instante cuando vuelve la conexión y sincronizar en ese momento, sin esperar los 30 s.
- [ ] Limitar el tamaño de las solicitudes en el servidor (hoy solo se limita la cantidad: 100 comandos).
- [ ] Autenticación del servidor: hoy, mientras está encendido, cualquiera en la red local podría enviarle operaciones.
- [ ] Sincronizar cada 30 s solo cuando haya operaciones pendientes, y espaciar el chequeo cuando no haya nada que enviar.
- [ ] En Windows, mover la base local de `Documents` a la carpeta de datos de la app (hoy queda en `Documents\esquinita.sqlite`, visible y sincronizable por OneDrive).

**Preparación de la prueba en hardware (2026-11-17)**

- El usuario marcó la Wi‑Fi como privada, creó la regla del firewall (TCP 8080, solo perfil privado y solo la subred local) y activó el Modo de desarrollador; el build de Windows ya compila.
- APK instalado en la tablet (`192.168.18.15`). Desde la tablet, `GET /health` al servidor en `192.168.18.12:8080` respondió `ok`.

**Siguiente paso exacto**

1. ~~El usuario ejecuta los comandos de administrador y activa el Modo de desarrollador.~~ Hecho.
2. ~~Prueba en tablet y PC.~~ Hecha: tablet 63 operaciones y PC 3, todas con exactamente una fila en PostgreSQL, sin duplicados (detalle en el informe).
3. ~~Claude completa los resultados y abre el PR.~~ PR abierto; falta que el usuario lo revise y lo fusione.

### 2026-11-17 — Modelo de datos (rama `phase-0/data-model`)

**Se hizo**

- El PR #5 (Spike 6) fue fusionado por Claude, a pedido del usuario (`a0d1ea8`). El usuario confirmó que la pausa de 8 s fue el modo avión. PostgreSQL apagado con `docker compose down`.
- `docs/modelo-datos.md`: tablas por módulo con columnas, claves e índices únicos; reglas de presentaciones, FEFO, caja, costo y saldos; qué vive en cada equipo; comandos de sync por operación; diagrama de relaciones (Mermaid).
- Decisiones del usuario:
  - costo por **promedio ponderado móvil**, calculado por el servidor en cada recepción, más `last_cost` como referencia;
  - la deuda con el proveedor nace al recibir;
  - lotes vencidos bloqueados, sin excepción;
  - sin balanza: calculadora peso ↔ monto, y códigos internos con prefijo `29`;
  - **una sola caja compartida**;
  - al inicio un solo usuario; roles por vistas, **Administrador** y **Trabajo** (corrección del usuario: reemplaza la idea de Dueño/Trabajador/Asistente);
  - la venta sin stock local se registra con aviso;
  - devoluciones con `disposition` (`restock` / `defective` → merma);
  - claves únicas con `NULL` resueltas.
- Propuestas de Claude que el usuario debe aprobar:
  - **la caja vive en un equipo designado** (por defecto la tablet), que es el único que abre y cierra;
  - **mapeo de roles** y cambio de CLAUDE.md §9.

**Siguiente paso exacto**

1. ~~El usuario revisa el PR del modelo de datos.~~ Corrigió la caja (§3.5): con conexión, abrir/cerrar/arquear/reabrir desde **cualquier equipo**, con el servidor como árbitro y el esperado calculado en el servidor; cada equipo informa sus pendientes (push + latido) y el cierre los muestra y ofrece esperar; sin conexión, solo el **equipo de caja de respaldo** (tablet por defecto) abre y cierra. Roles: **Administrador** y **Trabajo**, por vistas.
2. ~~Claude actualiza `docs/modelo-datos.md` y CLAUDE.md §9.~~ Hecho; el usuario aprobó §3.5 con un ajuste: el latido de 60 s solo mientras haya una caja abierta. Roles confirmados; Trabajo: abre y cierra caja, descuentos con el % que se requiera, crédito solo a clientes registrados, devoluciones.
3. ~~Fusión del PR #6~~ (Claude, a pedido del usuario). **Modelo de datos aprobado.**
4. **Siguiente:** prototipo navegable (último entregable de la Fase 0).

### 2026-11-17 — Prototipo navegable (rama `phase-0/prototype`)

**Se hizo**

- El PR #6 (modelo de datos) fue fusionado por Claude, a pedido del usuario (`ceecdf2`).
- Decisiones del usuario:
  - además de las 4 pantallas, incluir el cobro (efectivo con vuelto, Yape, Plin y pago mixto), el cierre de caja con el estado de cada equipo y la calculadora de peso;
  - **layout de celular diseñado aparte** (360 dp, una mano), con pruebas a 360×640 y 360×800;
  - crédito: **no** se simplifica el modelo de datos (el libro de cuentas, los abonos, el límite y los plazos llegan en la Fase 5). En el prototipo, el interruptor “Venta a crédito” exige un cliente registrado, no pide medio de pago y no suma a la caja.
- Commits:
  - `e35d302` core: calculadora de peso y EAN-13 interno;
  - `8385d05` prototipo: navegación, pantallas, fuentes y logo;
  - `031d73e` pruebas y arreglos de diseño;
  - título de la ventana de Windows: “La Esquinita Orgánika”.
- Dependencia nueva: `go_router` (ya prevista en el stack, CLAUDE.md §3).
- Pruebas: core 60 y app 108, en verde. El APK y el build de Windows compilan; la app de Windows quedó abierta en la PC para revisión.
- **Sin probar en dispositivo:** al terminar no había ninguna tablet ni celular conectados por USB.

**Siguiente paso exacto**

1. ~~El usuario conecta un celular.~~ APK instalado en un Samsung **SM-A576B** (Android 16, 1080×2340, densidad 420 ≈ 411 dp de ancho); abre sin errores y pide el permiso de cámara. Falta la tablet.
   - Pedido del usuario (2026-11-17): en la calculadora de peso, el **precio por kg** viene de la presentación pero **se puede cambiar** en el momento (ej. 300 g de kion al precio que diga). Hecho en `88e48b9`: campo *Precio por kg* editable, botón *Usar precio de lista*, y la línea del carrito queda marcada “Precio editado”. En la Fase 3 ese cambio requerirá el permiso `sales.change_price` y quedará auditado (CLAUDE.md §6.13).
   - El usuario indicó que las mejoras visuales quedan para la versión final.
   - Pedido del usuario: **sonido y vibración al escanear**, para darse cuenta sin mirar. Hecho con un canal nativo propio (`FeedbackChannel.kt`: `ToneGenerator` con el volumen multimedia + `Vibrator`, permiso `VIBRATE`), porque `SystemSound`/`HapticFeedback` no suenan si el usuario apagó los sonidos y vibraciones táctiles (ya visto en el Spike 1). Código reconocido: un pitido corto y una vibración; código no registrado o bloqueado: tono de error y doble vibración. En la PC se usa el sonido del sistema (los lectores USB suelen pitar solos). **Pendiente de prueba en dispositivo** (con el volumen multimedia del teléfono en 3/15 se oirá bajo).
2. ~~Recorrido del usuario.~~ Instalado también en la tablet SM-X133. Observaciones atendidas (precio por kg editable, sonido y vibración, interruptores) y dos ajustes de legibilidad en la tablet. Resultados en `docs/informes/fase-0.md`.
3. ~~PR del prototipo.~~ Abierto; falta la aprobación del usuario. Con eso se cumple el criterio de salida de la Fase 0 (Spikes 1, 3 y 6, prototipo y modelo de datos aprobados).

### 2026-11-17 — Carga masiva CSV y descargas (rama `docs/csv-import-reports`)

**Se hizo**

- Interruptores de **sonido** y **vibración** al escanear en el prototipo (`19bca76`, rama `phase-0/prototype`), instalado en el celular.
- Pedidos del usuario, agregados a la especificación como **§29** y al plan:
  - **carga masiva de productos por CSV** (Fase 2), pensada sobre todo para productos **sin código de barras**. Los que tienen código se registran escaneando. Genera códigos `29…`, vista previa, errores por fila y etiquetas;
  - **descargas en CSV, XLSX y PDF**, cada formato con su vista (Fase 6):
    - CSV: datos crudos;
    - XLSX: libro con hojas de resumen y detalle;
    - PDF: reporte A4 con KPIs y tablas;
  - **reporte consolidado con filtros y KPIs** (Fase 6).
- Supuestos de Claude, **confirmados por el usuario**:
  - en la V1 la carga CSV solo crea productos nuevos. Los precios del CSV son datos iniciales del producto; un cambio masivo de precios no es una operación de negocio de la V1;
  - no se arma maqueta en el prototipo, solo documentación.
- Modelo de datos: tabla `product_import_batches` y endpoint `POST /catalog/import`.
- Guía de la plantilla: formato **Texto** para los códigos en Excel.

**Pendiente**

- Elegir el paquete para XLSX en la Fase 6 (requiere aprobación de dependencia). El PDF usa `pdf` + `printing`, ya en el stack.

### 2026-11-17 (cierre del día) — Prototipo: arreglos del carrito y del catálogo (rama `phase-0/prototype`, PR #8 abierto, sin fusionar)

**Se arregló hoy** (commits `795bc9b` y `498cef8`, tras las capturas del usuario en la tablet)

- **Nombres de productos** apretados, ilegibles o cortados en la cuadrícula de la tablet:
  - las columnas se calculan según el ancho que deja el carrito (tarjetas de hasta 210 dp);
  - el nombre ocupa hasta 3 líneas con letra de 15 px y termina en “…” si no cabe;
  - el panel del carrito en horizontal ocupa el 38 % del ancho (entre 320 y 420 dp), en lugar de 400 dp fijos.
- **Eliminar una línea:** botón rojo de papelera en cada línea del carrito, también en las de productos por peso, que antes no se podían quitar.
- **Deslizar para quitar:** deslizar la línea hacia la izquierda la elimina.
- **Vaciar venta:** botón con confirmación (“¿Vaciar la venta?”) en el celular, en la tablet (vertical y horizontal) y en la PC.
- **Importe del botón Cobrar:** en el celular crecía con el total y tapaba el botón del carrito (desborde de 14 px). Ahora los dos botones comparten el ancho (2:3) y el importe se achica para caber.
- También: los indicadores de caja y sincronización ya no se repiten en el Dashboard. La cabecera del carrito se adapta si no hay espacio.
- Pruebas: app 115 en verde, incluida una nueva de eliminar, deslizar y vaciar a 360×640 y 893×533. `analyze` sin problemas.

**Falta verificar en dispositivo**

- **Tablet SM-X133:** el APK con estos arreglos quedó instalado, pero la tablet se bloqueó y Claude no pudo ver la pantalla. Falta revisar los nombres en vertical y en horizontal, y probar eliminar, deslizar y vaciar.
- **Celular SM-A576B:** sigue con una versión anterior (sin los arreglos de hoy de la tarde). Hay que reinstalar y revisar el POS, la barra de cobro con totales grandes y el carrito.
- **Sonido y vibración al escanear:** no se confirmó en ningún equipo con un escaneo real con la cámara. En el celular, el volumen multimedia estaba en 3/15.

**Observaciones del usuario pendientes**

- Ninguna sin atender. Todo lo que pidió hoy está hecho y falta que lo confirme en los equipos:
  - precio por kg editable;
  - sonido y vibración;
  - interruptores;
  - nombres legibles;
  - eliminar, deslizar y vaciar.
- Decisión del usuario: las **mejoras visuales generales** quedan para la versión final.

**Siguiente paso exacto (mañana)**

1. El usuario conecta la tablet (desbloqueada) y el celular. Claude instala el APK actual en los dos.
2. El usuario revisa en la tablet (vertical y horizontal) y en el celular:
   - nombres de productos;
   - eliminar, deslizar y vaciar;
   - botón Cobrar con un total grande;
   - pitido y vibración al escanear un producto del catálogo de ejemplo (por ejemplo la quinua `7750543400036`) y un código desconocido.
3. Claude atiende las observaciones, actualiza los *Resultados en dispositivo* del prototipo en `docs/informes/fase-0.md` y sube los cambios al PR #8.
4. Si el usuario aprueba el prototipo, se fusiona el PR #8 y se marca la **Fase 0 como terminada**. Spikes 1, 3 y 6 y el modelo de datos ya están aprobados.
5. Después: plan de la Fase 1 (fundamentos), para aprobación del usuario antes de programar.

### 2026-11-19 — Prototipo: celular en horizontal y teclado de montos (rama `phase-0/prototype`, PR #8)

**Se hizo** (commit `3546aeb`, tras las capturas del usuario en el celular SM-A576B en horizontal)

- APK instalado en la tablet SM-X133 y en el celular SM-A576B.
- **Celular en horizontal (891×411 dp):** sin la barra verde (pedido del usuario). "Sincronizado" pasa a la derecha de la barra inferior, para que siga visible (CLAUDE.md §10). Los íconos de la barra del sistema quedan oscuros sobre el crema. El cobro tampoco muestra la barra (ya tiene "Volver"). En vertical y en la tablet no cambia nada.
- **Teclado de montos:** primero los soles enteros y con la tecla "." los céntimos: "25" = S/ 25.00, "30.5" = S/ 30.50, "350" = S/ 350.00 (pedido del usuario). La tecla "00" se reemplaza por "."; en gramos sigue el "00". También acepta "." y "," del teclado físico.
- Arreglo: el teclado del cobro se desbordaba 47 px en el celular en horizontal.
- El botón del carrito vacío dice "0 ítems" (antes "Carrito v…" a 360 dp).
- Pruebas: app 123 en verde (nuevas: teclado y celular en horizontal); `analyze` sin problemas.
- **Segundo pedido del día** (commit `385fe49`):
  - **Tablet en horizontal:** tampoco muestra la barra verde. "Caja abierta" y "Sincronizado" pasan a la barra inferior.
  - **Celular en horizontal:** usa los **dos paneles de la tablet** (tarjetas y carrito a la derecha) desde 840 dp de ancho.
  - **Calculadora de peso con selector kg / g:** en kg, "1.5" = 1.500 kg y "2" = 2 kg; en g, "500" = 500 g. Atajos: 250 g, 300 g, 500 g, 1 kg y 2 kg, en una sola fila con desplazamiento (en dos filas, a 360×640 empujaban el teclado fuera de la pantalla). En el carrito, el peso se muestra como "1.500 kg" desde 1 kg.
  - Pruebas: app 128 en verde.

**Falta verificar en dispositivo**

- El cobro en el celular en horizontal y el teclado nuevo (25, 30.5, borrar).
- Lo pendiente del 2026-11-17: nombres en la tablet, eliminar/deslizar/vaciar, pitido y vibración.
- ~~Sin ver en dispositivo: la tablet en horizontal sin barra, el celular con dos paneles y la calculadora kg / g.~~ El usuario confirmó todo en los dos equipos ("todo ok").
- **Tercer pedido del día: escaneo en ventas con semáforo.** El aviso de código no registrado salía detrás de la cámara (un SnackBar queda debajo de las hojas y los diálogos).
  - **Escáner de venta a pantalla completa** (`/escanear-venta`): cámara con marco (esquinas + línea guía) en una mitad y el carrito en vivo en la otra (arriba/abajo en vertical, izquierda/derecha en horizontal). El último producto agregado sale primero. Botón Cobrar y Vaciar.
  - **Avisos flotantes tipo semáforo** (`widgets/notice.dart`), siempre encima de todo:
    - 🟢 agregado, con la cantidad acumulada (×2);
    - 🟡 agregado pero sin stock local o con stock bajo, y producto por peso (abre la calculadora sobre la cámara);
    - 🔴 código no registrado (queda fijo hasta tocarlo o hasta el siguiente escaneo, con botón **Registrar** que abre el alta con el código escrito) y lotes vencidos.
  - El lector USB de la PC usa el mismo semáforo. Los 8 SnackBar de la app pasaron a este componente.
  - El marco también está en la cámara de *Registrar producto*.
  - Tarjetas de producto más bajas cuando la pantalla tiene menos de 500 dp de alto (celular en horizontal): caben más filas.
  - Pruebas: app 136 en verde (semáforo en el store y escáner en 4 tamaños).
  - **Pendiente de prueba en dispositivo:** el escáner nuevo con la cámara real en la tablet y el celular. Instalado en la tablet; el celular no estaba conectado.
