# Plan de desarrollo — La Esquinita Orgánika

Fases según `docs/ESPECIFICACION.md` §25. Cada fase termina con **aprobación del usuario**. Estimación con 1 desarrollador asistido por Claude Code; semanas de calendario.

| Fase | Semanas | Alcance | Criterios de aceptación |
| --- | --- | --- | --- |
| **0. Planificación** | 1–2 | Revisión de requisitos y video, ADRs, modelo de datos, prototipo de pantallas clave (POS tablet, POS escritorio, alta por escaneo), **spikes en hardware real**: escaneo en Tab A11, impresión Éterma por Bluetooth (Android) y USB (Windows), Epson L460 vía PDF | Spikes con evidencia (fotos de tickets con tildes/ñ y logo, video de escaneo continuo); prototipo aprobado; modelo de datos aprobado |
| **1. Fundamentos** | 3–6 | Monorepo, `esquinita_core`, app Flutter con shells tablet/escritorio, tema, drift, servidor Dart Frog + Postgres + migraciones, login/roles/permisos/auditoría, configuración del negocio, **motor de sincronización** (outbox, pull, idempotencia, estado visible) | Usuario inicia sesión en tablet y PC; una operación de prueba creada offline en ambos equipos sincroniza sin duplicados tras reconectar y reiniciar la app; pruebas automáticas de sync en verde |
| **2. Productos e inventario** | 7–10 | Catálogo, categorías, marcas, unidades, presentaciones con conversión, códigos múltiples, precios minorista/mayorista, imágenes, lotes, vencimientos, movimientos, ajustes, conteo físico por escaneo, alertas, importación desde plantilla | 50 productos reales cargados; conteo físico de 20 productos por escaneo con diferencias correctas; kardex cuadra |
| **3. POS** | 11–14 | Carrito, escaneo continuo antiduplicados, búsqueda, cantidades/peso, descuentos con permiso, cliente, medios de pago, contado/crédito, notas de pedido, impresión 58 mm y A4, historial, devoluciones, anulaciones | Venta de 5 productos escaneados + cobro + ticket en < 30 s en la tablet; venta offline sincroniza una sola vez; ticket legible |
| **4. Compras y caja** | 15–17 | Proveedores, compras, recepción parcial/total con lotes, cuentas por pagar y pagos, apertura/cierre/arqueo por usuario o turno, ingresos, egresos, gastos | Compra con dos recepciones parciales deja stock y deuda correctos; arqueo distingue efectivo de pagos digitales |
| **— Piloto en tienda** | 17–18 | Uso real en paralelo al registro manual | 2 semanas sin diferencias atribuibles al sistema |
| **5. Clientes y crédito** | 18–19 | Clientes, crédito, abonos parciales, vencimientos, cuentas por cobrar, cobro múltiple | Saldos por movimientos cuadran con casos de prueba |
| **6. Reportes** | 20–21 | Dashboard configurable (tablet y PC), los 12 reportes, alertas, auditoría, etiquetas | Reportes cuadran con datos de prueba; ventas ≠ ingresos ≠ utilidad |
| **7. Pruebas y despliegue** | 22–24 | Pruebas PC, Android, offline, sync, impresión, escaneo, respaldos y restauración; servidor de producción; instaladores (APK firmado, instalador Windows); capacitación | Una semana en producción sin incidentes críticos; restauración de respaldo probada |
| **8. Evolución** | Después | Módulo tributario (tras validar normativa y PSE), multi-local, integraciones | Según cada propuesta |

Decisiones abiertas (cerrar en Fase 0):

1. RAM exacta de la Tab A11.
2. Transporte Bluetooth de la Éterma (clásico o BLE) y página de códigos.
3. Formato de etiquetas: rollo térmico en la Éterma o hojas adhesivas A4 en la Epson L460.
4. ¿La PC también vende offline en simultáneo con la tablet? (si sí, conflictos de stock posibles: se detectan y marcan).
5. Proveedor del VPS de producción.
