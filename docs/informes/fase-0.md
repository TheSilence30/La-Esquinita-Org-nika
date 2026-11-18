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

### Resultados en dispositivo (2026-11-17, usuario con la Tab A11 y la Éterma)

Fotos en la tablet (`Download/Quick Share/20261117_142137.jpg`, `20261117_142102.jpg`, `20261117_152031 (2).jpg`) y CSV de la pantalla, pegado en la conversación (copiado abajo).

**Página de códigos** (foto de la hoja de prueba):

| Página | ÁÉÍÓÚ | ñÑ üÜ ¿¡ ° S/ |
| --- | --- | --- |
| PC437 (`ESC t 0`) | ❌ salen sin tilde (`AEIOU`), como se esperaba | ✅ |
| **PC850 (`ESC t 2`)** | ✅ | ✅ |
| PC858 (`ESC t 19`) | ✅ | ✅ |
| WPC1252 (`ESC t 16`) | ✅ | ✅ |

Decisión: **PC850** (ya era el valor por defecto).

**Envío por bloques** (`send_ms` mide el tiempo de escritura en el socket, no el de impresión):

| Trabajo | Bytes | 256 B / 20 ms | 1024 / 20 | 4096 / 20 | **4096 / 10** | 4096 / 50 |
| --- | --- | --- | --- | --- | --- | --- |
| Ticket como texto | 9010 | 716 ms | 166 ms | 41 ms | **22 ms** (2 veces) | — |
| Ticket como imagen | 55 552 | 4487 ms | — | 264 ms | **136 ms** | 655 ms |

- Con **4096 B / 10 ms** el usuario confirmó que el texto y la imagen salen completos y limpios. Desde ahora es el valor por defecto (`PrintSettings`).
- Ticket como texto (foto de las 15:19): salen bien el logo, la leyenda, las tildes, la ñ y la ü en minúscula y mayúscula, y los importes `S/` alineados; llega hasta "Línea 40 de 40 – fin".
- Ticket como imagen (foto de las 14:20, con 256/20): salen bien el logo y el texto. "Línea 37" y "Cliente: …" salieron con un pequeño recorte horizontal; el usuario lo dio por aceptable. **No se investigó la causa**; vigilarlo si se usa el ticket como imagen en producción.
- Conexión: 2,0 s la primera vez y 744–807 ms al reconectar.

**Reconexión**: dos veces (`reconnected=1`) la impresora se había apagado y vuelto a encender después del último ticket; la app reconectó sola y el ticket salió una vez, sin duplicarse. **Sin probar en el dispositivo:** pulsar con la impresora todavía apagada (el mensaje de error). En el CSV no hay ninguna fila con error; solo lo cubren las pruebas automáticas.

**Mejora para después (fuera del spike):** al partir las líneas largas, la unidad queda separada del número ("Villa Rica 250" / "g", "Oxapampa 1" / "kg"). Usar un espacio que no se parta entre la cantidad y la unidad.

CSV:

```csv
at_utc,job,bytes,connect_ms,send_ms,chunk,delay_ms,code_page,reconnected,error
2026-11-17T19:20:30.968741Z,image,55552,2028,4487,256,20,,0,
2026-11-17T19:21:02.738532Z,codePages,657,,41,256,20,,0,
2026-11-17T19:21:28.186981Z,text,9010,,716,256,20,pc850,0,
2026-11-17T20:17:11.269235Z,text,9010,744,717,256,20,pc850,1,
2026-11-17T20:17:53.256127Z,text,9010,,716,256,20,pc850,0,
2026-11-17T20:19:24.827406Z,text,9010,,41,4096,20,pc850,0,
2026-11-17T20:19:41.408211Z,text,9010,,42,4096,20,pc850,0,
2026-11-17T20:19:55.436648Z,text,9010,,166,1024,20,pc850,0,
2026-11-17T20:20:46.870163Z,image,55552,,264,4096,20,,0,
2026-11-17T20:21:00.517623Z,image,55552,,136,4096,10,,0,
2026-11-17T20:21:25.018337Z,image,55552,,655,4096,50,,0,
2026-11-17T20:22:38.987842Z,text,9010,,22,4096,10,pc850,0,
2026-11-17T20:23:10.357702Z,text,9010,807,22,4096,10,pc850,1,
```

**Estado: Spike 3 pendiente de aprobación del usuario.**

## Spike 4 — Impresión térmica USB (Éterma, PC Windows)

Rama `phase-0/spike-usb-printing`.

### Cómo la ve Windows (2026-11-17)

La Éterma conectada por cable aparece como **impresora USB estándar**: `Printer POS-58-P504A`, `USB\VID_0483&PID_5743`, con el controlador `usbprint.sys` de Windows (puerto virtual `USB009`). **No tiene cola de impresión** y no hace falta instalar un controlador: se le escriben los bytes ESC/POS directamente a través de la interfaz de dispositivo `GUID_DEVINTERFACE_USBPRINT`.

### Qué se construyó

- `lib/devices/printer/usb_printer_transport.dart`: `UsbPrinterTransport`, otra implementación de `PrinterTransport`.
  - Busca la impresora **por su identificador de hardware** (`VID_0483&PID_5743`) en cada conexión, nunca por el puerto `USB009` ni por la ruta del dispositivo, que cambian al reconectar el cable.
  - Envía por bloques con pausa (4096 B / 10 ms por defecto, igual que por Bluetooth).
  - Si la escritura falla, informa cuántos bytes llegaron; los mensajes son los mismos que por Bluetooth.
- `lib/devices/printer/win_usbprint.dart`: la implementación real con `win32` y `ffi` (SetupAPI, `CreateFile`, `WriteFile`). Cada llamada corre en un isolate aparte para no congelar la pantalla. **Es el único archivo que importa `win32`**, y solo se usa cuando la app corre en Windows. El APK y la CI en Linux compilan y pasan sin cambios.
- La pantalla de impresión (**Spikes 3 y 4 — Impresión térmica**) usa USB en Windows y Bluetooth en Android, y preselecciona la Éterma por su identificador de hardware. `EscPosEncoder`, el ticket de prueba y `PrintJobRunner` no cambiaron.

### Pruebas automáticas (ejecutadas)

- App: 70 en verde (10 nuevas). Con un simulador de USB cubren: el identificador sacado de la ruta real del dispositivo, la lista sin repetidos, la conexión por identificador (sin distinguir mayúsculas), el envío en bloques de 4096 B, la impresora ausente o tomada por otro programa, la escritura sin conexión, el corte a mitad de ticket (con los bytes que llegaron) y **desconectar y reconectar el cable en otro puerto**: el ticket sale una sola vez por la ruta nueva, y si el cable sigue desconectado aparece un mensaje claro y la impresión funciona al volver a conectarlo.
- Formato y `analyze --fatal-infos` sin problemas. El APK debug y el build de Windows compilan.
- En la PC (Claude): la lista real encuentra `Printer POS-58-P504A | VID_0483&PID_5743`, y abrir y cerrar el dispositivo toma 12 ms. Todavía no se imprimió nada.

### Protocolo de prueba (usuario, en la PC)

Abrir **La Esquinita › Spikes 3 y 4 — Impresión térmica** (la barra superior debe decir **Impresión · USB**), con la Éterma conectada por cable y encendida.

1. **Página de códigos** y **Ticket como texto** (PC850, 4096 B / 10 ms): revisar las tildes, la ñ, `S/` y que llegue hasta “Línea 40 de 40 – fin”.
2. **Ticket como imagen** con 4096 / 10.
3. **Cable**: desconectar el USB y pulsar **Ticket como texto** (debe salir un mensaje claro sin congelarse); conectarlo en **otro puerto USB** y pulsar de nuevo (debe imprimir una sola vez).
4. **Apagar y encender** la impresora con el cable puesto y volver a imprimir.
5. **Copiar resultados (CSV)** y pegarlo en la conversación, junto con las fotos.

### Resultados en dispositivo (2026-11-17, usuario en la PC)

Foto del ticket como texto en `Pictures/Spike4.jpg` de la PC (16:14 en Lima) y CSV de la pantalla:

| Hora (UTC) | Prueba | Resultado |
| --- | --- | --- |
| 21:12:42 | Ticket como texto | ✅ 9010 B; conexión 23 ms; envío 162 ms |
| 21:12:58 | Ticket como texto con el cable desconectado | ✅ mensaje `notPaired` (“revisa el cable”), 0 bytes, la app no se congeló |
| 21:13:40 | Ticket como imagen, tras reconectar el cable | ✅ 55 552 B; la impresora se encontró sola (conexión 5 ms); envío 2,2 s |
| 21:14:14 | Ticket como texto, tras apagar y encender la impresora | ✅ 9010 B; envío 177 ms; foto correcta |

- **Papel** (foto de las 16:14): logo, leyenda, tildes, ñ y ü en minúscula y mayúscula, importes `S/` alineados y “Línea 40 de 40 – fin”. Igual que por Bluetooth.
- **Cable**: el usuario lo desconectó y lo volvió a conectar. Salió el mensaje claro y luego imprimió sin reiniciar la app.
- **Apagar y encender**: el ticket salió bien. En el CSV ese ticket aparece sin reconexión: Windows mantuvo válido el dispositivo abierto. No se sabe si es porque la Éterma sigue alimentada por el USB cuando está “apagada”. Sin efecto práctico: si el dispositivo se pierde, la reconexión por identificador ya está probada con el simulador y con el cable.
- **Velocidad**: por USB, `send_ms` incluye la espera a que la impresora acepte cada bloque, por eso la imagen tarda 2,2 s (por Bluetooth, 136 ms solo de envío). 4096 B / 10 ms sirve igual en los dos transportes.
- **Sin foto** del ticket como imagen por USB; el usuario no informó problemas. La página de códigos no se imprimió por USB (el ticket como texto ya cubre todas las letras).
- Detalle cosmético: en el CSV, el error sin detalle técnico aparece como `null`.

CSV:

```csv
at_utc,job,bytes,connect_ms,send_ms,chunk,delay_ms,code_page,reconnected,error
2026-11-17T21:12:42.871343Z,text,9010,23,162,4096,10,pc850,0,
2026-11-17T21:12:58.363220Z,text,0,,,4096,10,pc850,0,"notPaired: null"
2026-11-17T21:13:40.653306Z,image,55552,5,2180,4096,10,,0,
2026-11-17T21:14:14.052704Z,text,9010,,177,4096,10,pc850,0,
```

**Estado: Spike 4 pendiente de aprobación del usuario (PR).**

## Spike 6 — drift + outbox contra el servidor local

Rama `phase-0/spike-drift-outbox`. Objetivo: crear operaciones sin conexión, cerrar la app, volver a abrirla y sincronizar con el servidor local **sin duplicados**. Solo subida (`/sync/push`); la bajada (`/sync/pull`), el login y el motor completo van en la Fase 1.

### Qué se construyó

- **Core:** `uuidV7()`; `SyncCommand` (`op_id`, `device_id`, `user_id`, `created_at`, `type`, `payload`) con lectura estricta del JSON; `PushStatus` (`applied | duplicate | rejected | conflict`); `PushResult`, que en un duplicado trae el veredicto original; y `SpikeOperation` (nota + importe en céntimos), la operación de prueba.
- **Servidor** (Dart Frog + PostgreSQL 16):
  - migración `20261117000001_sync_inbox.sql` (tablas `sync_inbox` y `spike_operations`), aplicada con **dbmate como servicio de Docker Compose**: `docker compose run --rm dbmate up`;
  - `POST /sync/push` (hasta 100 comandos): cada comando, en **una sola transacción**, se reserva en `sync_inbox` con `INSERT … ON CONFLICT (op_id) DO NOTHING` y se aplica. Si el `op_id` ya existía, responde `duplicate` con el estado y el mensaje que se guardaron la primera vez. Los rechazos también se guardan, así un reenvío recibe la misma respuesta;
  - `received_at` con la hora del servidor, además del `created_at` del dispositivo;
  - escucha en `SERVER_HOST` (la IP privada de la PC) o, si no se define, solo en `127.0.0.1`; nunca en todas las interfaces.
- **App** (drift):
  - tablas `local_settings` (con `device_id` fijo), `outbox` y `spike_operations`;
  - la operación local y su comando se guardan en **una sola transacción**;
  - `SyncClient` envía en lotes, guarda cada veredicto y, si no hay respuesta, deja los comandos pendientes y cuenta el intento;
  - `SyncScheduler` sincroniza al abrir, cada 30 s y con el botón; si falla, reintenta a los 5 s, 10 s, 20 s… hasta 5 min;
  - pantalla **Spike 6 — Sincronización**: dirección del servidor, indicador *Sincronizado / Pendientes N / Error*, *Crear operación*, *Crear 30*, *Sincronizar*, *Reenviar todo* y **Envío lento** (1 operación por solicitud y 300 ms de pausa, para poder cortar la conexión a la mitad).
- Solo para depuración en Android: se permite HTTP sin cifrar, porque el servidor de desarrollo no tiene TLS. El build de producción mantiene el bloqueo.

### Pruebas automáticas (ejecutadas)

- Core: 54 en verde.
- Servidor: 10 en verde. Seis corren **contra PostgreSQL real** (base `esquinita_test` en local y servicio Postgres en la CI):
  - aplicar una vez y reenvío = `duplicate`;
  - rechazo guardado y devuelto igual;
  - lote con un `op_id` repetido;
  - **8 envíos simultáneos del mismo `op_id`: una sola fila, 7 `duplicate`, ningún error**;
  - **reloj del dispositivo desfasado** (2020 y 2035): se guarda tal cual y `received_at` usa la hora del servidor.

  Las otras cuatro son de la ruta: solo POST, entradas inválidas → 400 sin tocar la base, y una respuesta por comando.
- App: 81 en verde. Cubren:
  - la transacción atómica (si falla el comando, la operación local también se deshace);
  - 3 operaciones sin conexión → cerrar y reabrir la base → siguen pendientes, con el mismo `device_id` → se sincronizan una vez;
  - **respuesta perdida** → reenvío → `duplicate`, una sola aplicación;
  - **30 operaciones con la conexión cortada a la mitad** → 15 aplicadas y 15 pendientes → la siguiente sincronización completa exactamente 30;
  - *Reenviar todo*, respuesta del servidor que no corresponde a lo enviado, espera creciente entre reintentos, y la pantalla sin desbordes y con el indicador correcto.
- Servidor real probado con `curl`: el primer envío da `applied` y el segundo `duplicate` con `original_status: applied`.
- El APK debug compila. El build de Windows necesita activar el **Modo de desarrollador** (el plugin de SQLite requiere enlaces simbólicos).

### Protocolo de prueba (usuario)

Preparación (Claude): el servidor corre en la PC (`http://192.168.18.12:8080`), la Wi‑Fi de la tienda está marcada como red privada y el firewall deja pasar el puerto 8080 solo desde la red local.

En la tablet, abrir **La Esquinita › Spike 6 — Sincronización**, escribir `http://192.168.18.12:8080` y pulsar **Guardar**.

1. **Sin servidor** (Claude lo detiene): pulsar **Crear operación** 3 veces. El indicador debe decir *Error · pendientes 3*.
2. **Cerrar la app** desde Recientes (deslizar hacia arriba) y volver a abrirla en *Spike 6*: debe seguir mostrando 3 pendientes.
3. **Servidor encendido** (Claude lo levanta): pulsar **Sincronizar**. Debe decir *Sincronizado* y las 3 operaciones, *aplicada*.
4. **Reenviar todo**: cada operación debe decir *respuesta: duplicado* y seguir *aplicada*.
5. **Corte a la mitad:** activar **Envío lento**, pulsar **Crear 30** y **Sincronizar**, y a los 3–5 s activar el **modo avión**. Debe salir el error, con parte de las operaciones *aplicada* y el resto *pendiente*. Quitar el modo avión, esperar el Wi‑Fi y pulsar **Sincronizar**: debe decir *Sincronizado*.
6. **En la PC**: repetir los pasos 1 a 4 con `http://192.168.18.12:8080` (el servidor solo escucha en esa dirección, no en `127.0.0.1`).
7. Claude verifica en PostgreSQL que por cada equipo haya **exactamente** tantas filas como operaciones se crearon (33 de la tablet), sin duplicados.

### Resultados en dispositivo (2026-11-17, usuario con la Tab A11 y la PC)

Servidor en `http://192.168.18.12:8080`, en la PC. Red marcada como privada y regla del firewall solo para la subred local. Capturas en la tablet (`DCIM/Screenshots/Screenshot_20261117_1800*`–`1806*`) y en el escritorio de la PC (`Spike6-PT1` a `PT4`). Los conteos salen de consultas de Claude a PostgreSQL y al SQLite de cada equipo (en la tablet, copiado con `run-as`).

**Tablet** (equipo `01a1ebb8-…`):

| Paso | Resultado |
| --- | --- |
| 1. Sin servidor: 3 operaciones | ✅ *Error · pendientes 3*. La espera entre reintentos creció hasta 40 s |
| 2. Cerrar y reabrir la app | ✅ siguen 3 pendientes, con los intentos fallidos guardados (6) |
| 3. Servidor encendido | ✅ *Sincronizado*: las 3 llegaron a las 17:59:22 |
| 4. Reenviar todo | ✅ las 3 respondieron *duplicado* y no se creó ninguna fila |
| 5. Envío lento + modo avión | ✅ 1.ª tanda de 30, creada en modo avión: no salió nada; al quitarlo se sincronizaron solas (18:04:29–41). 2.ª tanda de 30: llegaron 21 (18:05:41–48), una operación falló 2 veces, y 8 s después llegaron las 9 restantes. El usuario confirmó que esa pausa fue el modo avión, activado a mitad del envío: es el corte a la mitad que pedía el protocolo |

**PC** (equipo `01a1ebca-…`, app de Windows):

| Paso | Resultado |
| --- | --- |
| 1–2. Sin servidor, cerrar y reabrir | ✅ *Error · pendientes 3*, y siguen pendientes al reabrir |
| 3. Servidor encendido | ✅ *Sincronizado*, las 3 *aplicada* (18:18:12) |
| 4. Reenviar todo | ✅ *respuesta: duplicado* en las 3 |

**PostgreSQL** (verificado por Claude):

| Equipo | Operaciones locales | Filas en `sync_inbox` | Filas en `spike_operations` | `op_id` distintos |
| --- | --- | --- | --- | --- |
| Tablet | 63 (3 + 30 + 30) | 63 | 63 | 63 |
| PC | 3 | 3 | 3 | 3 |

- Los 63 `op_id` de la tablet son **exactamente los mismos** en su SQLite y en el servidor: cero duplicados, cero perdidos. El protocolo esperaba 33 porque contaba una sola tanda de 30; el usuario pulsó *Crear 30* dos veces.
- El servidor guardó su propia `received_at` y conservó el `created_at` de cada dispositivo.
- Hay una fila más, de otro equipo: es la prueba hecha por Claude con `curl`.

**Observaciones para la Fase 1**

- En Windows, la base local queda en `Documents\esquinita.sqlite` (la carpeta por defecto de `drift_flutter`). Es una carpeta visible para el usuario y que OneDrive puede sincronizar: moverla a la carpeta de datos de la app.
- Con el servidor apagado, el firewall descarta la conexión sin rechazarla, así que la app muestra "no respondió a tiempo" tras 10 s en lugar de "sin conexión".

**Estado: Spike 6 pendiente de aprobación del usuario (PR).**

## Prototipo navegable

Rama `phase-0/prototype`. Pantallas **sin lógica real**: los datos viven en memoria (`lib/prototype/`) y se reinician al cerrar la app. Sirve para aprobar la navegación y el diseño antes de la Fase 1.

### Qué incluye

| Pantalla | Celular (360 dp, una mano) | Tablet | PC |
| --- | --- | --- | --- |
| POS | Lista de productos con filas de 64 dp; barra inferior con carrito, escanear y **Cobrar** al alcance del pulgar | Vertical: cuadrícula + la misma barra. Horizontal (≥ 840 dp): catálogo y carrito en dos paneles | Buscador (F2, también para el lector USB + Enter), filas densas, atajos F2/F4/F9/F12/Esc |
| Presentación | Hoja inferior: Unidad / Caja x12, precio minorista y mayorista | Diálogo | Diálogo |
| Calculadora de peso | Hoja inferior a pantalla completa: *peso → precio* y *monto → peso*, teclado propio; **precio por kg editable** (por defecto el de la presentación) | Diálogo | Diálogo (también con teclado físico) |
| Lotes | El carrito muestra el lote asignado por FEFO; los vencidos no se venden | Igual | Igual |
| Cobro | Recibido, vuelto y montos rápidos **fijos sobre el teclado**; Yape/Plin con n.º de operación; pago mixto si el ajuste está activo; **venta a crédito solo con cliente registrado**, sin medio de pago y sin sumar a la caja | Pantalla completa | Diálogo; Enter confirma, Esc vuelve |
| Venta registrada | Vista previa de la “Constancia de venta – no es comprobante de pago” | Igual | Diálogo |
| Alta por escaneo | Cámara (`mobile_scanner`, sin QR), ingreso manual, “sin código → generar 29…”; formulario de nuevo producto | Dos columnas en horizontal | Lector o teclado |
| Dashboard | Ventas de hoy, efectivo (cajón), Yape/Plin y otros, a crédito; stock bajo; lotes por vencer | Cuadrícula | Cuadrícula ancha |
| Cierre de caja | Estado de cada equipo, aviso de ventas sin enviar, *Esperar*, *Cerrar de todos modos* con motivo; esperado por medio de pago; arqueo y diferencia | Igual | Dos columnas |
| Inventario | Stock local con lotes y vencimientos (solo lectura) | Igual | Igual |

- Navegación: barra inferior **Vender · Escanear · Inventario · Pedidos · Más** en tablet y celular; menú lateral en la PC. Indicadores de **caja** y **sincronización** (simulados) siempre visibles.
- Roles por vistas: con **Trabajo** se ocultan Dashboard, Reportes y Ajustes; el Administrador entra al Dashboard.
- *Más › Ajustes de demostración*: pagos mixtos, rol, estado de sincronización y ventas pendientes simuladas en la PC.
- Diseño: paleta de CLAUDE.md §10, **Inter** (cifras tabulares) y **Fraunces** incluidas en la app (licencia OFL, sin internet), logo de `docs/marca` teñible.
- Datos de ejemplo: 17 productos orgánicos con precios de Lima. Quinua 1 kg con *Unidad* y *Caja x12* y precio mayorista desde 6; kion y quinua roja **por peso**; miel de Oxapampa **con 3 lotes** (uno vencido, uno por vencer y uno lejano); huevos por unidad y paquete x15; 4 clientes registrados.
- En el core: `priceForWeight`, `weightForAmount` e `internalEan13` (prefijo 29 + dígito del equipo + secuencia), con pruebas.

### Pruebas automáticas (ejecutadas)

- Core: 60 en verde (cálculo de peso y códigos internos).
- App: 108 en verde. Pantallas a **360×640, 360×800**, tablet 533×893 y 893×533, y PC 1280×800 y 1024×700, sin desbordes. Flujos completos: monto → peso (S/ 5.00 de kion = 417 g) y cobro en efectivo con vuelto; crédito que exige cliente y no suma a la caja; alta por código y sin código; aviso de ventas sin enviar en el cierre; FEFO en el carrito; PC con lector + Enter, F12 y Enter; rol Trabajo sin Dashboard.
- Las pruebas encontraron tres problemas de diseño, ya corregidos:
  - en el celular, la fila inferior del teclado quedaba **debajo de la barra de navegación**;
  - en el cobro del celular, el vuelto quedaba fuera de la vista;
  - en la PC, la tabla del carrito se desbordaba.

### Lo que queda fuera

- Base de datos, sincronización y stock reales.
- Login y PIN.
- Impresión: solo la vista previa.
- Detección del lector por ráfaga (Spike 2).
- Cámara en la PC.
- Notas de pedido.
- Pantallas de Compras, Clientes, Reportes y Ajustes: “Próximamente”.
- Riverpod.
- Golden tests.

### Resultados en dispositivo

_Pendiente: revisión del usuario en la tablet, en la PC y, si hay, en un celular Android._
