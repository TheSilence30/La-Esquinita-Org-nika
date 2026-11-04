# CLAUDE.md — Sistema La Esquinita Orgánika

Guía permanente para Claude Code. **Léela completa al iniciar cada sesión.**

- Especificación del cliente (fuente de verdad de requisitos): `docs/ESPECIFICACION.md`
- Decisiones de arquitectura: `docs/adr/`
- Plan y fases: `docs/PLAN.md`
- Fase en curso y su checklist: `docs/FASE-ACTUAL.md`

Si una tarea contradice estos documentos, **detente y pregunta**. No cambies la arquitectura sin un ADR nuevo aprobado por el usuario.

---

## 1. Qué es

Sistema de ventas, inventario y gestión comercial (estilo FactuSmart, con identidad propia) para **La Esquinita Orgánika**, tienda de un solo local en Av. Famesa, Mz. C, Lt. 3, Paradero Famesa, Puente Piedra, Lima. Vende orgánicos, alimentos, bebidas, productos naturales y suplementos, por unidad, peso, paquete y caja, al por menor y al por mayor.

Régimen tributario: **Nuevo RUS**. La V1 **no** integra SUNAT (Fase 8). La venta siempre se registra; el comprobante físico, si se entrega, se anota como referencia.

## 2. Plataformas (por prioridad)

1. **Tablet Android — principal y de mayor uso.** Samsung Galaxy Tab A11, modelo **SM-X133** (Android 16, 4 GB de RAM, pantalla 800×1340 px). Táctil, escaneo con cámara, impresión Bluetooth en la térmica.
2. **PC Windows — administración y caja secundaria.** Teclado, mouse, lector USB tipo teclado, Epson L460 (A4) y la térmica por USB.
3. Celulares Android: soportados con el layout de tablet adaptado.

Interfaces **independientes** por plataforma (tablet ≠ escritorio), mismas reglas de negocio y mismos datos.

## 3. Stack (ADR-0001)

| Capa | Tecnología |
| --- | --- |
| App (Android + Windows) | **Flutter** (stable), Dart 3 |
| Estado | Riverpod (con generador) |
| Navegación | go_router |
| Base local | **SQLite con drift** (una por dispositivo) |
| Dominio compartido | Paquete Dart puro `packages/esquinita_core` (sin Flutter) usado por app y servidor |
| Escaneo cámara | `mobile_scanner` (ML Kit en Android) |
| Escaneo físico | Lector HID tipo teclado: `KeyboardListener` + detector de ráfaga |
| Impresión térmica | Generación ESC/POS en Dart + transporte Bluetooth (Android) / USB (Windows). Paquetes concretos se eligen en el **spike de impresión de la Fase 0** |
| Impresión A4/PDF | `pdf` + `printing` (diálogo del sistema → Epson L460) |
| Códigos de barras | paquete `barcode` (generación de etiquetas) |
| Servidor | **Dart Frog** + paquete `postgres` (v3), SQL explícito |
| Base central | **PostgreSQL 16** |
| Migraciones servidor | SQL versionado en `apps/server/migrations` (dbmate) |
| Auth | Argon2id para contraseñas, JWT de acceso corto + refresh rotativo, PIN de cajero, sesión offline cacheada |
| Infra | Docker Compose (Postgres + servidor + Caddy) en un VPS; desarrollo local con Docker Desktop |
| Pruebas | `package:test` (core, server), `flutter_test` + golden tests, `integration_test` en tablet real |

## 4. Estructura del repositorio

```
apps/
  esquinita_app/          Flutter (Android + Windows)
    lib/
      app/                arranque, tema, router, selección de shell por plataforma
      shells/tablet/      navegación y layouts de tablet (barra inferior, táctil)
      shells/desktop/     navegación y layouts de escritorio (menú lateral, atajos)
      features/<modulo>/
        application/      casos de uso y providers (compartidos por ambos shells)
        tablet/           pantallas tablet
        desktop/          pantallas escritorio
        widgets/          widgets comunes del módulo
      data/local/         drift: tablas, DAOs, proyecciones
      data/sync/          cliente de sincronización (outbox, pull, estado)
      devices/            escáner, impresoras, cámara (interfaces + implementaciones por plataforma)
  server/                 Dart Frog: rutas, servicios, repositorios SQL, migraciones
packages/
  esquinita_core/         dominio puro: entidades, value objects (Money, Quantity), reglas,
                          cálculo de totales, validaciones, comandos de sync, PrintDocument
docs/
```

Regla: **la UI no toca drift ni HTTP directamente**; pasa por `application/`. El dominio (`esquinita_core`) no importa Flutter ni drift.

Módulos: `auth`, `settings`, `catalog` (productos, categorías, marcas, unidades, presentaciones, códigos), `inventory` (stock, lotes, movimientos, conteos, ajustes, alertas), `purchases` (proveedores, compras, recepciones, cuentas por pagar), `sales` (POS, devoluciones, anulaciones), `order_notes`, `customers` (crédito, cuentas por cobrar), `cash` (sesiones, movimientos, gastos, arqueo), `labels`, `printing`, `reports`, `dashboard`, `sync`, `audit`, `tax` (vacío hasta Fase 8).

## 5. Convenciones de datos (no negociables)

- **Dinero en céntimos enteros** (`int`), tipo `Money` en core. Nunca `double` para dinero.
- **Cantidades en milésimas enteras** (`Quantity`, 3 decimales) para soportar peso (kg).
- **IDs UUID v7** generados en el dispositivo para toda entidad y operación.
- Fechas en UTC en la base; se muestran en `America/Lima`.
- Moneda PEN, formato `S/ 1,234.50`.
- Interfaz y documentación en **español (Perú)**; código, tablas y commits en **inglés**.

## 6. Reglas de negocio que NO se rompen

1. **Stock solo por movimientos** (`stock_movements`). Cada movimiento registra producto, lote, cantidad ±, tipo, motivo, usuario, dispositivo, fecha y referencia a la operación de origen. El saldo es una proyección.
2. **Operaciones atómicas**: venta + ítems + pagos + movimientos + deuda en una sola transacción (local y servidor).
3. **Nada se borra**: se desactiva o se revierte con una operación inversa. Cierres de caja no se modifican sin permiso y auditoría.
4. **Saldos por movimientos**: deudas de clientes y proveedores se calculan desde cargos y abonos; nunca se edita un saldo.
5. **Diferenciar** venta, pago recibido, ingreso de caja, deuda, gasto y utilidad. Un pago Yape/Plin/transferencia **no** entra al efectivo de caja (`payment_methods.affects_cash_drawer`).
6. Medios de pago iniciales: Efectivo, Yape, Plin, Billetera digital, Transferencia. **Sin tarjetas**. Configurables. Pagos mixtos detrás de un ajuste.
7. **Presentaciones** con factor de conversión explícito a la unidad base (ej. Caja = 12 unidades). Nunca asumir factores. Cada presentación puede tener su código de barras, precio minorista y mayorista.
8. **Lotes y vencimientos**: si el producto controla lote, la venta descuenta por FEFO (primero en vencer) y la recepción exige lote/vencimiento.
9. **Compras**: una compra pendiente **no** mueve stock; solo las **recepciones** (parciales o totales) generan entradas.
10. **Nota de pedido** = documento interno no tributario, con leyenda clara; no descuenta stock (reserva opcional configurable); genera como máximo una venta.
11. **Escaneo por contexto**: venta, inventario, compras, registro, conteo y ajuste tienen comportamientos propios.
12. **Unicidad**: código de barras (global, incluyendo presentaciones), código interno, `op_id` de sincronización, correlativos por serie.
13. Precio o descuento fuera de lo permitido requiere permiso y queda auditado.
14. Cada ítem de venta guarda precio y **costo del momento**.

## 7. Offline-first y sincronización (ADR-0002)

- Cada dispositivo trabaja contra su **SQLite local**; el servidor es la fuente de verdad global.
- **Bajada (pull)**: datos maestros y saldos con cursor de versión (`GET /sync/pull?since=`), incluyendo registros desactivados.
- **Subida (push)**: tabla local `outbox` de **comandos inmutables** (`CreateSale`, `ReceivePurchase`, `AdjustStock`, `RegisterPayment`, `OpenCash`, `CloseCash`, `CreateOrderNote`, `CreateProduct`…) con `op_id`, `device_id`, `user_id`, `created_at`, `payload`, `status`.
- El servidor aplica cada comando en transacción y de forma **idempotente** (`sync_inbox` con `op_id` único). Respuesta por comando: `applied | duplicate | rejected | conflict`.
- **Nunca sobrescribir**: se suben operaciones, no filas.
- **Correlativos offline**: cada dispositivo tiene su propia serie por tipo de documento (ej. tablet `T1`, PC `P1`).
- **Conflictos**: una venta ya realizada nunca se rechaza por stock; si el stock global queda negativo se crea un registro en `sync_conflicts` y una alerta para revisión. Producto duplicado por código de barras creado offline en dos equipos → conflicto para fusionar. Ediciones de maestros (precios, productos) requieren conexión en la V1.
- Sincronización automática (al reconectar y cada 30 s), manual (botón), reintentos con espera creciente, registro de errores, recuperación tras reinicio, **indicador de estado visible** (sincronizado / pendientes N / error).
- No afirmar en la UI que el stock global es exacto cuando hay operaciones pendientes: mostrar "stock local".

## 8. Impresión

Un `PrintDocument` neutro (en core) → renderizadores:

| Salida | Uso | Notas |
| --- | --- | --- |
| ESC/POS 58 mm | Tickets, notas compactas, resúmenes | 384 puntos, 32 columnas, logo raster ≤ 384 px, página de códigos con tildes y ñ validada en el spike |
| PDF A4 | Notas de pedido, reportes, documentos internos | Epson L460 vía diálogo del sistema |
| Etiquetas | Producto, código, precio opcional | Formato a definir en Fase 0 (rollo térmico o hojas A4 adhesivas) |

Impresora térmica: **Éterma 58 mm portátil**, Bluetooth + USB. Tratarla como ESC/POS genérica hasta validar en el spike (BT clásico vs BLE, página de códigos, imagen, avance/corte).

Leyendas obligatorias: nota de pedido "Documento interno – no válido como comprobante de pago"; ticket de venta interno "Constancia de venta – no es comprobante de pago". Nunca presentar un documento interno como boleta o factura.

## 9. Roles

Administrador, Supervisor, Cajero, Inventario. Permisos con formato `modulo.accion` (ej. `sales.void`, `sales.discount`, `sales.change_price`, `inventory.adjust`, `cash.reopen`). Se verifican en el servidor **y** en el dispositivo (offline). Auditoría de ventas, anulaciones, descuentos, ajustes, compras, cambios de precio, pagos y cierres.

## 10. Diseño

- Paleta (del logo): verde bosque `#1F4D2E` (primario), verde hoja `#7CB342` (acento/Cobrar), crema `#FAF6EC` (fondo), madera `#8B5A2B` (detalles), ámbar `#D99A1E` (alerta), rojo `#C0392B` (error).
- Tipografía: Inter (UI, cifras tabulares); Fraunces solo para marca.
- Tablet: barra inferior (Vender, Escanear, Inventario, Pedidos, Más), objetivos táctiles ≥ 48 dp, POS en dos paneles en horizontal.
- Escritorio: menú lateral, tablas densas, atajos (F2 buscar, F4 cliente, F9 nota de pedido, F12 cobrar, Esc cancelar).
- Sin animaciones que retrasen el trabajo. Indicador de sincronización siempre visible.

## 11. Seguridad

- Secretos solo en variables de entorno (`.env`, nunca en git). `.env.example` con valores ficticios.
- **Nunca** credenciales SUNAT ni contraseñas reales en código, docs o commits.
- Base local con datos sensibles mínimos; sesión offline con expiración.
- Respaldos diarios de PostgreSQL fuera del servidor y exportación local de emergencia en la tablet.

## 12. Forma de trabajar (metodología del cliente)

Por cada fase: revisar requisitos → definir alcance → diseñar → implementar → **probar** → documentar → **pedir aprobación**. No empezar la siguiente fase sin criterios de aceptación cumplidos.

- Antes de programar, resume el plan de la tarea y los archivos que tocarás.
- Toda regla de negocio lleva prueba automática (stock, ventas, caja, deudas, sync, correlativos).
- **No afirmar que algo funciona sin haberlo ejecutado. No inventar resultados de pruebas. No ignorar errores.** Lo que requiera hardware (tablet, impresora, lector) se marca "pendiente de prueba en dispositivo" hasta que el usuario lo confirme.
- Commits pequeños en inglés: `feat(sales): ...`, `fix(sync): ...`.
- Actualizar `docs/FASE-ACTUAL.md` al terminar cada tarea.
- Datos del negocio que falten: placeholders `TODO(config)` en el seed.
