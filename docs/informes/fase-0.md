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

_Pendiente: la tabla por orientación se completa cuando se confirme la orientación y se tenga la línea “Pantalla:”._

#### Corrida 2 — 2026-11-09, Tab A11 (SM-X133), orientación sin confirmar

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

| Métrica | Horizontal | Vertical |
| --- | --- | --- |
| Lecturas esperadas / obtenidas | | |
| Latencia p50 / p95 | | |
| Cuadros/s | | |
| Lecturas dobles accidentales | | |
| Tamaño en dp y densidad | | |
