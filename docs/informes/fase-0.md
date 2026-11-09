# Informe de Fase 0

Estado: **en curso**. Cada spike se marca ✅ solo con evidencia en hardware real.

## Entorno verificado (2026-11-04)

| Componente | Versión / estado |
| --- | --- |
| Flutter / Dart | 3.47.9 stable / 3.13.7 — `flutter doctor` sin problemas |
| Android SDK / NDK | 36 / 28.2.13676358 |
| Visual Studio | 2026 Community, C++ y Windows SDK 10.0.26100 |
| Tablet | Galaxy Tab A11 **SM-X133**, Android 16, 4 GB de RAM (3,8 GB visibles), 800×1340 px; densidad física 213 dpi con override de fábrica a 240 dpi → **533×893 dp** (umbral de tablet en la app: 520 dp) |
| Docker Desktop | 29.1.3 instalado (motor no iniciado en la verificación) |

## Spike 1 — Escaneo con cámara (Tab A11)

Estado: **código listo · pendiente de prueba en dispositivo**.

### Qué se construyó

- `packages/esquinita_core/lib/src/scanning/scan_filter.dart`: filtro puro y determinista. Un código se acepta solo si:
  1. aparece en 2 detecciones separadas como máximo por **300 ms** (confirmación);
  2. si ya se aceptó, desapareció de la vista al menos **500 ms** (re-armado). Un producto quieto frente a la cámara cuenta **una sola vez**;
  3. pasaron al menos **1,5 s** desde su última aceptación (enfriamiento).

  Los tres tiempos se configuran con `ScanFilterConfig`. Como diagnóstico hay un cuarto, el **límite de re-armado sospechoso** (1000 ms): una ausencia de un código ya aceptado que dura entre el re-armado (500 ms) y ese límite se cuenta como **re-armado sospechoso**, porque lo más probable es que el producto no se haya movido y el detector solo haya perdido el código un instante. Si después de esa ausencia hay una nueva aceptación, se cuenta como **lectura extra**. Este límite no cambia qué lecturas se aceptan. Todos los tiempos usan un reloj monotónico (`Stopwatch`); la hora UTC solo se registra. Cada código se filtra por separado: un producto distinto entra en cuanto se confirma.
- `apps/esquinita_app/lib/devices/scanner/camera_scan_view.dart`: `mobile_scanner` 7.5.0 con ML Kit **incluido en el APK** (sin Google Play), `DetectionSpeed.unrestricted` y solo formatos de tienda (EAN‑13/8, UPC‑A/E, Code128, Code39). El QR se activa con el interruptor **“Incluir QR”** (apagado por defecto; en ventas va siempre desactivado).
- `apps/esquinita_app/lib/spikes/scan_spike_page.dart`: pantalla del spike con:
  - lecturas, unidades, repetidas ignoradas, cuadros/s y latencia (promedio, p50, p95);
  - **hueco máximo** entre detecciones (global y por código), **re-armados sospechosos** y **lecturas extra**; en el CSV, `max_gap_ms` y `after_suspicious_rearm` por lectura;
  - campo **“× cantidad”**, que se aplica a la siguiente lectura y vuelve a 1;
  - ingreso manual o lector USB;
  - linterna, vibración y sonido;
  - ajuste en vivo de los 3 tiempos y del límite de re-armado sospechoso;
  - interruptor **“Incluir QR”**;
  - botón **Copiar resultados (CSV)**.
- Layout adaptable: lado a lado cuando la pantalla es más ancha que alta (tablet horizontal, PC) y apilado si no lo es (tablet o celular en vertical). El panel se desplaza en pantallas bajas. La pantalla muestra el factor de forma y el tamaño en dp.

### Pruebas automáticas (ejecutadas)

- `packages/esquinita_core`: 19 pruebas en verde, entre ellas: *producto quieto 10 s a ~30 cuadros/s → 1 lectura*; lo mismo con detecciones irregulares (huecos < 500 ms); re-armado; enfriamiento; códigos independientes; tiempos personalizados.
- `apps/esquinita_app`: 15 pruebas en verde: sesión (multiplicador, CSV, latencias) y diseño sin desbordes en 6 tamaños (celular vertical y horizontal, Tab A11 vertical y horizontal, PC 1366×768, ventana 800×600).
- `apps/server`: 1 prueba en verde (`GET /health`).
- `flutter analyze` y `dart analyze`: sin problemas. `flutter build apk --debug` y `flutter build windows --debug`: compilan.

### Protocolo de prueba en la Tab A11 (usuario)

1. `cd apps/esquinita_app` → `flutter run -d R8YL60HT6CX` (o instalar `build/app/outputs/flutter-apk/app-debug.apk`).
2. Abrir **Spike 1**, aceptar el permiso de cámara y anotar la línea **Pantalla:** (dp y densidad).
3. Con luz normal de la tienda, en **horizontal** y luego en **vertical**. Antes de cada paso, elegirlo en **Paso de prueba** (queda en la columna `step` del CSV):
   1. Escanear 20 productos distintos, uno tras otro. Esperado: 20 lecturas.
   2. Dejar un producto **quieto 10 s** frente a la cámara. Esperado: +1 lectura.
   3. Mostrar el mismo producto, **retirarlo ~2 s** (fuera del encuadre) y volver a mostrarlo, 5 veces. Esperado: +5 lecturas. Con ~1 s, la ausencia cae en el rango sospechoso (500–1000 ms) y no se distingue de un corte del detector.
   4. Poner **× 6**, escanear un producto. Esperado: +6 unidades y el campo vuelve a 1.
   5. Probar un código pequeño o arrugado y uno con poca luz (con y sin linterna).
4. Pulsar **Copiar resultados (CSV)**, pegarlo aquí y grabar un video corto del escaneo continuo.

### Resultados en dispositivo

#### Corrida 2 — 2026-11-09, Tab A11 (SM-X133), horizontal (vertical igual, según el usuario)

Configuración: `confirm 300 / cooldown 1500 / rearm 500 / sospechoso 1000 ms`, `qr=on` en todos los pasos.

| Paso | Esperado | Obtenido | Observaciones |
| --- | --- | --- | --- |
| 3.1 · 20 productos distintos | 20 | 19 códigos de tienda + 2 QR | Los 2 QR (`https://jugoskero.pe`) salieron de envases que también tenían código de barras (filas 16–17 y 20–21): con QR encendido, un mismo producto genera 2 lecturas. Las filas 7–8 (`793969324781` y `…750`) se leyeron con 60 ms de diferencia: dos códigos en el mismo encuadre. Latencia p50 66 ms / p95 191 ms; 16,5 cuadros/s. |
| 3.2 · Producto quieto 10 s | +1 | +1 | Solo 15 cuadros con código (~0,6 s detectado a 24,8 cuadros/s). **No demuestra los 10 s**: el producto estuvo poco tiempo a la vista o el detector dejó de verlo. Repetir. |
| 3.3 · Retirar ~2 s ×5 | +5 | +5 | Ausencias de 3800, 6521, 1596 y 3426 ms. Ningún re-armado sospechoso. |
| 3.4 · × 6 | +6 unidades | +6 | La lectura siguiente (3.5) volvió a 1 unidad. |
| 3.5 · Pequeño / poca luz | — | 1 lectura (`191069706931`, 46 ms) | No se registró qué condición se probó (pequeño, arrugado, poca luz, con o sin linterna). |
| Libre · QR | lee | lee (`https://www.naturalmaxx.com.pe`, 44 ms) | El QR funciona con el interruptor encendido. En la corrida 1 no leía porque estaba en `qr=off`. |

En toda la corrida: 0 re-armados sospechosos, 0 lecturas extra y hueco máximo de 387 ms (margen de 113 ms hasta los 500 ms del re-armado). El producto que en la corrida 1 dio 4 lecturas extra (`7750543400036`) **no se probó** en esta.

**Repetición del 3.2** (2026-11-09 22:05 UTC, `qr=off`): `191069706931` quieto frente a la cámara. Hubo 640 cuadros con código a 29,3 cuadros/s, unos **22 s detectado sin cortes** (hueco máximo de 156 ms). Resultado: **1 lectura** y 638 repeticiones ignoradas; latencia de 23 ms. ✅ Un producto quieto cuenta una sola vez.

**Repetición del 3.2 con `7750543400036`** (el producto que dio 4 lecturas extra en la corrida 1; `qr=off`): quieto unos 11 s (310 cuadros a 27,6 cuadros/s). Resultado: **1 lectura** y 307 repeticiones ignoradas; latencia de 47 ms; hueco máximo de 195 ms (en la corrida 1 había sido de 486 ms). ✅

#### Resumen

Según el usuario, los resultados en vertical fueron iguales a los de horizontal; no hay un CSV aparte para vertical.

| Métrica | Horizontal | Vertical |
| --- | --- | --- |
| Lecturas esperadas / obtenidas | 3.1: 20 productos → 19 códigos de barras + 2 QR (`qr=on`); 3.2: 1/1 (dos productos); 3.3: 5/5; 3.4: +6/+6 | Iguales (según el usuario) |
| Latencia p50 / p95 | 66 / 191 ms (3.1) | Iguales (según el usuario) |
| Cuadros/s | 16,5–29,3 | Iguales (según el usuario) |
| Lecturas dobles accidentales | 0 (con QR apagado) | 0 (según el usuario) |
| Tamaño en dp y densidad | 893×533 dp, 1,5x (240 dpi), tablet | 533×893 dp, 1,5x (240 dpi), tablet |

La app en horizontal muestra **“Pantalla: tablet · 893×533 dp · 1.50x”** (captura por `adb` del 2026-11-09, 17:13 hora de Lima). Coincide con `adb shell wm size` / `wm density`: 800×1340 px y densidad 240. En vertical, la app muestra **“Pantalla: tablet · 533×893 dp · 1.50x”** (captura por `adb`, 17:14), con el diseño apilado: la cámara arriba y el panel abajo, sin desbordes.

**Conclusiones**

- **Se mantienen los tiempos del filtro** (300 / 1500 / 500 ms, límite sospechoso 1000 ms). `7750543400036` quieto dio 1 lectura, sin cortes que se acercaran a los 500 ms. Las 4 lecturas extra de la corrida 1 coinciden con mover el producto mientras se retiraba ~1 s, no con cortes del detector con el producto quieto.
- **El QR va apagado en ventas.** Con el QR encendido, los envases que tienen QR y código de barras se leen dos veces (3.1, filas 16–17 y 20–21).
- **Varios códigos en el encuadre se aceptan todos.** `793969324781` y `…750` se leyeron con 60 ms de diferencia y eran dos productos distintos (confirmado por el usuario). En el POS hay que tenerlo en cuenta: un producto vecino que entra en el encuadre se cobra.
- **3.5:** el usuario probó un código pequeño, uno arrugado y un ambiente oscuro con linterna, y todos se leyeron. El CSV solo registra una de esas lecturas (`191069706931`, 46 ms).
- **Video del escaneo continuo** (protocolo, punto 4): el usuario decidió que no hace falta.

**Estado: Spike 1 aprobado por el usuario el 2026-11-09.**

## Spike 3 — Impresión térmica Bluetooth (Éterma, Tab A11)

Rama `phase-0/spike-printing`.

### Impresora (página de autoprueba, 2026-11-09)

Éterma 58 mm portátil, sin cortador (se corta a mano con la barra dentada). Firmware `1.005PH5I` (2025/10/15). Tiene USB y Bluetooth `V2.1+V4.0`; la tablet la tiene emparejada como `Printer001-C9E2` (`C0:2B:F3:AB:C9:E2`) y solo ofrece el servicio **SPP (Bluetooth clásico)**. Velocidad de 70 mm/s, densidad 4 de 8, **página de códigos por defecto PC437** y memoria NV para imágenes. Se apaga sola a los 60 min.

### Qué se construyó

- `packages/esquinita_core/lib/src/printing/`: `PrintDocument` neutro (texto, fila de dos columnas, separador, imagen, avance) y `EscPosEncoder` para 58 mm (384 puntos, 32 columnas). El encoder:
  - escribe `ESC @` y `ESC t n` al inicio;
  - trae tablas para PC437, PC850, PC858 y WPC1252; una letra que falta en la página elegida se imprime sin tilde (`Á` → `A`);
  - centra el logo y lo envía con `GS v 0` en franjas de 64 filas;
  - `MonoBitmap` convierte a 1 bit con umbral o con difuminado Floyd–Steinberg.
- `apps/esquinita_app/android/.../BtSppChannel.kt`: canal propio, **todo en un hilo de fondo**:
  - lista los equipos emparejados y se conecta por RFCOMM/SPP, primero seguro y luego inseguro, con tiempo de espera;
  - envía en **bloques con pausa configurable**;
  - pide los permisos `BLUETOOTH_CONNECT` y `BLUETOOTH_SCAN` (Android 12+).
- `lib/devices/printer/`:
  - interfaz **`PrinterTransport`** (el ticket no depende del transporte) e implementación `BluetoothSppTransport`, con mensajes de error en español;
  - `raster.dart`, que convierte con `dart:ui` el logo y el ticket completo a imagen.
- `lib/features/printing/application/print_job_runner.dart`:
  - un trabajo a la vez, y conecta cuando hace falta;
  - si la impresora se apagó desde el último ticket y **no llegó nada**, reconecta y reenvía una vez;
  - si llegó parte del ticket, **no lo reenvía** (saldría duplicado) y avisa que puede estar incompleto.
- `lib/spikes/print_spike_page.dart` (**Spike 3 — Impresión térmica**):
  - elige la impresora, el bloque (32 B a 4 KB), la pausa (0 a 100 ms) y la página de códigos;
  - tres botones: **Página de códigos**, **Ticket como texto** y **Ticket como imagen**;
  - registro de tiempos y botón **Copiar resultados (CSV)**.
- Ticket de prueba (`test_ticket.dart`): logo en blanco y negro, nombre y dirección, leyenda “Constancia de venta – no es comprobante de pago”, 10 productos con tildes y ñ e importes `S/`, total, línea “áéíóú ÁÉÍÓÚ ñÑ üÜ ¿? ¡! °”, y líneas numeradas hasta **“Línea 40 de 40 – fin”**.
- Logo: `docs/marca/logo-bn.png` (1774×887, versión definitiva en blanco y negro), reducido a `assets/branding/logo-ticket.png` (768 px) y a 320 puntos al imprimir.

### Pruebas automáticas (ejecutadas)

- Core: 48 en verde. Cubren los bytes de cada comando, las tablas de páginas de códigos, el ajuste a 32 columnas, las filas con importe a la derecha, las franjas de imagen centradas y el umbral y difuminado.
- App: 60 en verde. Cubren el canal con mensajero simulado (argumentos y mensajes de error), `PrintJobRunner` (reconexión, no reenviar un ticket parcial, un trabajo a la vez, permisos), el ticket de exactamente 40 líneas, el render a imagen de 384 puntos y la pantalla sin desbordes en la tablet (horizontal y vertical) y en celular.

### Primera prueba en la tablet (2026-11-09, Claude vía `adb`)

- El diálogo de permisos apareció y se aceptó (`BLUETOOTH_CONNECT` y `BLUETOOTH_SCAN` quedaron `granted`, `USER_SET`).
- **Página de códigos**: conexión en **552 ms**, 0,6 KB enviados en 40 ms (bloques de 256 B, pausa de 20 ms), sin errores. Falta la foto del papel para saber qué página imprime bien.

### Protocolo de prueba (usuario)

Abrir **La Esquinita › Spike 3 — Impresión térmica**, con Aqp Print cerrada (si no, puede ocupar la impresora). Después de cada impresión, sacar una foto del papel con la tablet.

1. **Página de códigos**: ver cuál de las 4 secciones imprime bien todas las letras (sobre todo **ÁÍÓÚ**).
2. Elegir esa página en **Página de códigos (texto)** y pulsar **Ticket como texto** (256 B / 20 ms). Revisar el logo, las tildes, la ñ, “S/” y que llegue hasta **“Línea 40 de 40 – fin”**.
3. **Bloques y pausa** (el objetivo es lo más rápido que no corrompa). Con **Ticket como texto**, probar:
   - 4096 B / 0 ms (todo de golpe);
   - 1024 B / 0 ms;
   - 512 B / 10 ms;
   - 256 B / 20 ms.

   Anotar la primera combinación que imprime el ticket completo y limpio, y repetirla dos veces.
4. **Ticket como imagen** con esa combinación y con la siguiente más lenta: comparar la calidad y el tiempo con el ticket como texto.
5. **Reconexión**:
   - apagar la impresora y pulsar **Ticket como texto**: debe salir un mensaje claro y la app no debe congelarse;
   - encenderla y pulsar de nuevo: debe imprimir.
6. **Copiar resultados (CSV)** y pegarlo en la conversación, junto con las fotos.

### Resultados en dispositivo

_Pendiente._
