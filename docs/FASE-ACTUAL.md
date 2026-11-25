# Fase actual: 2 — Productos e inventario

Estado: **en curso** (desde 2026-11-25). Plan aprobado: `docs/planes/fase-2.md`. La bitácora de la Fase 1 está en `docs/informes/fase-1-bitacora.md` y su informe en `docs/informes/fase-1.md`. Actualiza esta lista al terminar cada tarea.

## Tareas (cada una con pruebas y un PR pequeño)

- [x] 1. PR #25, aprobado y fusionado. Migraciones y seed del catálogo e inventario (`modelo-datos.md` §2.1–2.2; unidades `und`, `kg`, `l` y las 6 categorías de ejemplo), con pruebas contra PostgreSQL
- [x] 2. PR #26, aprobado y fusionado. Core: presentaciones y conversión, validación de códigos (dígito verificador, formatos, daño de Excel), saldo por movimientos y FEFO. **Pedido del usuario:** `product_costs.on_hand_milli` se actualiza en la misma transacción que cada movimiento, con una prueba de que siempre coincide con la suma de `stock_balances` del producto
- [x] 3. **PR abierto para revisión del usuario** (rama `phase-2/create-product`, sincronización). `CreateProduct` en el servidor y en la app (outbox, `duplicate_barcode`), bajada del catálogo y réplicas en drift
- [ ] 4. Pantallas de Productos y Registrar por escaneo (tablet y PC), con stock inicial
- [ ] 5. Editar producto, presentaciones, códigos y precios en línea (Administrador, `price_changes`)
- [ ] 6. Stock local, kardex, `AdjustStock` (ajustes y mermas) y PIN de Administrador para autorizar
- [ ] 7. Conteo físico por escaneo y `CloseInventoryCount`
- [ ] 8. Alertas en Inventario (bajo, agotado, por vencer, vencido; anticipación configurable)
- [ ] 9. Carga masiva CSV en la PC (vista previa, errores, confirmación) y etiquetas en la Éterma 58 mm
- [ ] 10. Prueba de aceptación con el usuario: 50 productos reales (mitad por escaneo, mitad por CSV), conteo de 20 por escaneo, kardex; informe en `docs/informes/fase-2.md`

## Pendientes heredados

- [ ] Prueba en dispositivo del escáner de venta con la cámara real (prototipo, Fase 0)
- [ ] Spike 2 (lector USB), antes de la Fase 3
- [ ] Spike 5 (A4 para reportes), con la Fase 6
- [ ] Regenerar el token de decolecta antes de producción
- [ ] Imágenes de producto (decisión del usuario: después de la Fase 2)

## Bitácora

### 2026-11-25 — Inicio

- Fase 1 aprobada (informe `docs/informes/fase-1.md`).
- Plan de la Fase 2 presentado y aprobado, con estas decisiones del usuario: etiquetas en rollo en la Éterma 58 mm; imágenes después; Trabajo también pone el stock inicial al registrar; los 50 productos de la prueba, mitad con código y mitad sin código.

### 2026-11-25 — Tarea 1: esquema del catálogo e inventario

- Migración `20261125000001_catalog_inventory.sql` con todas las tablas de `modelo-datos.md` §2.1–2.2: categorías, marcas, unidades, productos, costos, presentaciones, códigos, historial de precios, cargas CSV, lotes, movimientos, saldos, ajustes, conteos y mermas.
- Reglas en la base:
  - factor de presentación > 0 y una sola base por producto, con factor 1000;
  - nombres únicos sin importar mayúsculas (categorías, marcas, presentaciones de un mismo producto);
  - código de barras único en todo el sistema;
  - lote único por producto, código y vencimiento (incluido «sin vencimiento»);
  - un movimiento nunca es 0, y un ajuste o merma exige motivo;
  - un saldo por producto y lote;
  - una línea de merma siempre resta.
- Las tablas que bajan a los equipos llevan `version` con el mismo disparador serializado de la Fase 1. `stock_losses.supplier_id` recibe su FK cuando exista la tabla de proveedores (Fase 4).
- Seed: unidades `und`, `kg`, `l` y las 6 categorías de ejemplo.
- Pruebas: servidor 91 en verde (8 nuevas contra PostgreSQL). `dart analyze` sin observaciones.

### 2026-11-25 — PR #25 fusionado; reglas nuevas del usuario

- El usuario revisó y aprobó el PR #25. Se fusionó en `main` (`d2f2cad`) con las dos ejecuciones de la CI en verde.
- **Regla nueva: cada fusión la autoriza el usuario**, aunque la CI esté en verde y aunque sea solo de documentos o de esquema. No se crea ninguna regla de permiso para `gh pr merge`. Reemplaza la regla de la Fase 1 de `docs/planes/fase-1.md` («Claude fusiona los PR cuando la CI pasa, salvo…»).
- **Pedido para la tarea 2:** `product_costs.on_hand_milli` en la misma transacción que cada movimiento de stock, con una prueba de que coincide con la suma de `stock_balances`.

### 2026-11-25 — Tarea 2: reglas del core y proyecciones de stock

- **Core** (`esquinita_core`):
  - `toBaseUnits`: pasa una cantidad de una presentación a la unidad base con su factor explícito (2 cajas x12 = 24 unidades; 3 bolsas de 500 g = 1,5 kg).
  - `checkBarcode`: dígito verificador de EAN-13, EAN-8, UPC-A y UPC-E; caracteres de Code39 y Code128; códigos dañados por Excel (notación científica, ceros perdidos), con el motivo en español.
  - `sumMovements` y `allocateFefo` (§3.2): lotes vencidos bloqueados (uno que vence hoy aún se vende), primero el que vence antes y los sin vencimiento al final; lo que falta va al lote que vence más tarde, que queda negativo; `null` si no hay lote vendible; desempate fijo, igual en todos los equipos.
- **Servidor** (migración `20261125000002_stock_projection.sql`): un disparador en `stock_movements` actualiza, en la misma transacción, `stock_balances` y **`product_costs.on_hand_milli`** (pedido del usuario). Los movimientos son inmutables: la base rechaza modificarlos o borrarlos.
- **Prueba pedida por el usuario** (contra PostgreSQL):
  - 300 movimientos al azar (entradas, salidas y stock negativo) en 4 productos, con y sin lotes; cada 25 movimientos se comprueba que `on_hand_milli` = Σ `stock_balances` = Σ `stock_movements` por producto, y que cada saldo coincide con sus movimientos;
  - 20 transacciones a la vez sobre el mismo producto y lote;
  - una transacción revertida no deja ni movimiento, ni saldo, ni `on_hand`;
  - modificar o borrar un movimiento falla.
- El prototipo del POS tenía su propio `LotTake`, que choca con el del core; se oculta el del core en ese archivo hasta que la Fase 3 lo reemplace.
- Pruebas: core 81, servidor 95 y app 236, en verde; analizadores sin observaciones.

### 2026-11-25 — PR #26 fusionado; tarea 3: alta de producto sin conexión y bajada del catálogo

- PR #26 aprobado por el usuario y fusionado (`3edc24f`).
- **Cambio pedido por el usuario en FEFO** (core y `modelo-datos.md` §3.2):
  - un producto con lotes que **todavía no tiene ninguno** se vende «sin lote» (`lot_id` nulo, saldo negativo) con el aviso de stock, como una venta sin stock local;
  - si **tiene lotes y todos están vencidos**, sigue bloqueado.
  - `allocateFefo` devuelve el reparto y `stockWarning`. Pruebas de los dos casos.
- **Core**: comando `CreateProduct` con su validación, la misma en el equipo y en el servidor:
  - una sola presentación base con factor 1000, y factores > 0;
  - nombres y códigos sin repetir, y códigos válidos;
  - precios ≥ 0;
  - stock inicial > 0, con lote si el producto lo controla y sin lote si no.
  - Mensajes en español.
- **Servidor**:
  - `CreateProduct` en el push, en una transacción: producto, costo inicial (promedio = último = costo del alta), presentaciones, códigos, lotes y stock inicial como movimientos `initial` (el disparador de la tarea 2 lleva los saldos), con `audit_log` `catalog.create`.
  - Rechaza, sin dejar nada, una categoría, unidad o marca desconocida, un producto o código interno repetido, o un autor sin `catalog.create`.
  - Un **código de barras que ya es de otro producto** (dado de alta sin conexión en dos equipos): el producto se crea igual, sin ese código; queda un conflicto `duplicate_barcode` para que el Administrador los una, y la respuesta es `conflict`.
- **Bajada**: categorías, marcas, unidades, productos, costos, presentaciones, códigos, lotes (`expires_on` como `YYYY-MM-DD`) y saldos, **por páginas** (`more`). Cada página trae las 2000 versiones más bajas después del cursor, sin partir ni saltar filas. Se cerró el `shortcut` de la Fase 1.
- **App**:
  - base local **v3** con las réplicas del catálogo y los movimientos propios;
  - `CatalogStore.recordCreateProduct` escribe el producto y su comando en **una sola transacción**;
  - códigos internos (`T2-000001`) y `29…` con la serie y el dígito del equipo, con contadores en la base cifrada que nunca se repiten;
  - un código que ya tiene otro producto en el equipo se rechaza antes de escribir;
  - la bajada recorre todas las páginas y guarda cada una antes de pedir la siguiente.
- Pruebas: core 89, servidor 101 y app 244, en verde. Nuevas:
  - comando y validaciones;
  - alta en el servidor (con y sin lotes), reenvío duplicado, `duplicate_barcode`, los tres rechazos guardados para el reenvío;
  - bajada del catálogo como JSON y por páginas (cada fila una vez, en orden);
  - alta local atómica, contadores, código repetido, la bajada que reemplaza la copia local;
  - **migración v2 → v3 conservando los datos**.
- shortcut: si el servidor **rechaza** un alta (caso raro: categoría inexistente o autor sin permiso), la copia local se queda en el equipo. La tarea 4 mostrará las operaciones rechazadas.
