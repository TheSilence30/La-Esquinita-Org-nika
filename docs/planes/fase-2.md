# Plan de la Fase 2 — Productos e inventario

Estado: **propuesta, en espera de la aprobación del usuario** (2026-11-25).

## Objetivo

Que la tienda tenga su **catálogo real** en el sistema y un **stock confiable**: productos con presentaciones, códigos y precios; stock que solo cambia por movimientos, con lotes y vencimientos; conteo físico por escaneo; alertas. Todavía no se vende (Fase 3) ni se compra (Fase 4): esta fase deja listo lo que esas dos usan.

## Criterios de aceptación (de `docs/PLAN.md`)

1. **50 productos reales cargados** (por escaneo y por CSV), con sus presentaciones, códigos y precios.
2. **Conteo físico de 20 productos por escaneo**, con las diferencias correctas.
3. **El kardex cuadra**: para cada producto, la suma de sus movimientos es igual a su stock, en el equipo y en el servidor.
4. Pruebas automáticas de catálogo, stock, lotes, conteos y CSV en verde, en la CI y en local.

## Qué entra

### A. Servidor

- **Migraciones** de `docs/modelo-datos.md` §2.1–2.2: `categories`, `brands`, `units`, `products` (con `active`), `product_presentations`, `barcodes`, `product_costs`, `lots`, `stock_movements`, `stock_balances`, `stock_adjustments` (+líneas), `inventory_counts` (+líneas), `stock_losses`, `product_import_batches`, `price_changes`.
- **Seed**: unidades (`und`, `kg`, `l`) y las categorías de ejemplo (Orgánicos, Alimentos, Bebidas, Productos naturales, Suplementos, Otros). Se pueden cambiar.
- **Comandos de sincronización** (idempotentes, con `audit_log`):
  - `CreateProduct` (sin conexión): producto, presentaciones, códigos y stock inicial como movimiento `initial`. Si dos equipos registran el mismo código → conflicto `duplicate_barcode` para fusionar.
  - `AdjustStock` (sin conexión, permiso `inventory.adjust` o PIN de Administrador): ajustes y mermas.
  - `CloseInventoryCount` (sin conexión): cada diferencia → movimiento `count`.
  - Stock global negativo → `sync_conflicts` `negative_stock`, nunca se rechaza.
- **API en línea** (solo Administrador, auditada): editar producto, presentaciones, códigos y precios (`price_changes`); categorías y marcas (se desactivan, no se borran).
- **Carga masiva CSV**: `POST /catalog/import` con vista previa y confirmación (§29.2).
- **Bajada**: catálogo, costos, lotes y saldos de stock, con el mismo cursor de la Fase 1.

### B. Dominio compartido (`esquinita_core`)

- Reglas de presentaciones y conversión a unidad base (factor explícito, nunca asumido).
- Validación de códigos: dígito verificador EAN-13/EAN-8/UPC-A/UPC-E, formatos Code128/Code39, y códigos dañados por Excel (`7.75E+12`, ceros perdidos).
- Código interno `29…` (ya existe) con la serie del equipo.
- Lector y validador del CSV (`,` o `;`, decimal `.` o `,`, UTF-8 con o sin BOM), con el motivo de cada error por fila.
- Saldo por movimientos y reparto FEFO (lo usará la venta en la Fase 3).

### C. App (tablet primero; la PC con sus pantallas)

- **drift**: réplicas del catálogo y saldos, y los movimientos propios aún no confirmados. Se muestra **«stock local»** mientras haya pendientes (CLAUDE.md §7).
- **Productos**: lista con búsqueda (nombre, código, escaneo), ficha (presentaciones, códigos, precios, stock por lote, kardex) y activar o desactivar. Los costos se ven solo con `catalog.view_cost`.
- **Registrar producto por escaneo** (reemplaza la pantalla del prototipo): escaneo de contexto *registro*. Si el código ya existe, abre la ficha. Si no tiene código, genera uno `29…`. Incluye presentaciones, precios y stock inicial.
- **Editar producto y precios** (Administrador, con conexión).
- **Inventario**: stock actual con alertas (bajo, agotado, por vencer, vencido; anticipación configurable), ajustes y mermas con motivo, y conteo físico por escaneo (contexto *conteo*): Trabajo cuenta y el Administrador aplica las diferencias, o se aplican con su PIN.
- **PIN de Administrador para autorizar** una acción fuera del rol en el mismo equipo (`authorized_by` y auditoría). Lo estrena el ajuste de stock y lo reutilizará la Fase 3.
- **Carga CSV en la PC**: elegir archivo, vista previa (nuevos, errores, códigos que se generarán), descargar errores y confirmar.
- **Etiquetas** de los códigos generados (formato a decidir, ver abajo).
- El prototipo de Inventario y de Registrar se retira cuando estas pantallas lo reemplacen.

## Qué no entra (y en qué fase va)

- Vender y el reparto FEFO en una venta: Fase 3.
- Proveedores, compras, recepciones y el costo promedio por recepción: Fase 4. En esta fase el costo inicial lo da el alta o el CSV.
- Actualizar precios en bloque por CSV: después de la V1 (§29.2).
- Reportes y descargas: Fase 6.

## Orden de trabajo (cada paso con sus pruebas y un PR pequeño)

1. Migraciones y seed del catálogo e inventario, con pruebas contra PostgreSQL.
2. Core: presentaciones, validación de códigos, saldo por movimientos y FEFO.
3. `CreateProduct` en el servidor y en la app (outbox), bajada del catálogo y réplicas en drift.
4. Pantallas de Productos y Registrar por escaneo (tablet y PC).
5. Editar producto y precios en línea (Administrador).
6. Movimientos: stock local, kardex, `AdjustStock` y PIN de Administrador para autorizar.
7. Conteo físico por escaneo y `CloseInventoryCount`.
8. Alertas en Inventario.
9. Carga masiva CSV (PC) y etiquetas.
10. Prueba de aceptación con el usuario: 50 productos reales, conteo de 20, kardex. Informe en `docs/informes/fase-2.md`.

## Decisiones que necesito del usuario

1. **Formato de etiquetas** (abierta desde la Fase 0): rollo en la **Éterma 58 mm** (sale una por una, en la tablet o la PC) u **hojas adhesivas A4** en la **Epson L4160** (muchas a la vez, desde la PC).
2. **Imágenes de producto**: en esta fase o después. Si entran, se toman con la cámara de la tablet o se eligen en la PC, y se guardan en el servidor.
3. **Stock inicial al registrar por escaneo**: si Trabajo también puede ponerlo al dar de alta un producto, o solo el Administrador.
4. **Los 50 productos reales** de la prueba: cuántos tienen código de fabricante (se escanean) y cuántos no (van por CSV).

## Riesgos

- Los datos reales (nombres, precios, factores de cajas) los da la tienda. Sin ellos no se cumple el criterio 1; el CSV de ejemplo sirve para las pruebas.
- Las etiquetas necesitan una prueba en la impresora real antes de cerrar la fase.
- El límite de 10 equipos (un dígito por equipo en el código `29…`) se mantiene.
