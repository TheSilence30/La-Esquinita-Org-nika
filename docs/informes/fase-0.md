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

  Los tres tiempos se configuran con `ScanFilterConfig`. Cada código se filtra por separado: un producto distinto entra en cuanto se confirma.
- `apps/esquinita_app/lib/devices/scanner/camera_scan_view.dart`: `mobile_scanner` 7.5.0 con ML Kit **incluido en el APK** (sin Google Play), `DetectionSpeed.unrestricted` y solo formatos de tienda (EAN‑13/8, UPC‑A/E, Code128, Code39, QR).
- `apps/esquinita_app/lib/spikes/scan_spike_page.dart`: pantalla del spike con:
  - lecturas, unidades, repetidas ignoradas, cuadros/s y latencia (promedio, p50, p95);
  - campo **“× cantidad”**, que se aplica a la siguiente lectura y vuelve a 1;
  - ingreso manual o lector USB;
  - linterna, vibración y sonido;
  - ajuste de los 3 tiempos en vivo;
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
3. Con luz normal de la tienda, en **horizontal** y luego en **vertical**:
   1. Escanear 20 productos distintos, uno tras otro. Esperado: 20 lecturas.
   2. Dejar un producto **quieto 10 s** frente a la cámara. Esperado: +1 lectura.
   3. Mostrar el mismo producto, retirarlo ~1 s y volver a mostrarlo, 5 veces. Esperado: +5 lecturas.
   4. Poner **× 6**, escanear un producto. Esperado: +6 unidades y el campo vuelve a 1.
   5. Probar un código pequeño o arrugado y uno con poca luz (con y sin linterna).
4. Pulsar **Copiar resultados (CSV)**, pegarlo aquí y grabar un video corto del escaneo continuo.

### Resultados en dispositivo

_Pendiente._

| Métrica | Horizontal | Vertical |
| --- | --- | --- |
| Lecturas esperadas / obtenidas | | |
| Latencia p50 / p95 | | |
| Cuadros/s | | |
| Lecturas dobles accidentales | | |
| Tamaño en dp y densidad | | |
