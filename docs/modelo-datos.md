# Modelo de datos inicial — La Esquinita Orgánika

Estado: **aprobado por el usuario** (Fase 0, 2026-11-17). Fuente de requisitos: `docs/ESPECIFICACION.md`. Decisiones de arquitectura: ADR-0001 y ADR-0002.

Este documento define tablas, columnas, claves, índices únicos y relaciones del servidor (PostgreSQL 16) y su réplica en cada dispositivo (SQLite con drift). Las migraciones de la Fase 1 se escriben a partir de aquí; cualquier cambio posterior se registra en este archivo.

---

## 1. Convenciones

| Tema | Regla |
| --- | --- |
| Identificadores | `id uuid` (UUID v7), generado en el dispositivo para toda entidad y operación |
| Dinero | `*_cents bigint` (céntimos enteros). Costos unitarios: céntimos **por unidad base**, redondeados al céntimo |
| Cantidades | `*_milli bigint` (milésimas). En productos por peso con base kg, 1 g = 1 |
| Fechas | `timestamptz` en UTC. `occurred_at` = reloj del dispositivo; `received_at` = reloj del servidor (solo en servidor) |
| Fechas sin hora | `date` (vencimientos, fechas de pago) |
| Enumeraciones | `text` con `CHECK (col IN (...))` |
| Borrado | **Nada se borra.** Maestros: `active boolean`. Operaciones: inmutables; se revierten con otra operación |
| Maestros | Columna `version bigint` tomada de la secuencia global `sync_version_seq` (trigger en cada insert/update); permite `GET /sync/pull?since=` |
| Operaciones | Columnas comunes: `op_id uuid` (el comando de sync que la creó), `device_id uuid`, `user_id uuid`, `occurred_at` |
| Nombres | Tablas y columnas en inglés, `snake_case`, plural |
| Claves únicas con columnas opcionales | Ver §1.1 |

Abreviatura en las tablas de abajo: **PK** clave primaria, **FK** clave foránea, **UQ** única, **M** maestro (lleva `active` y `version`), **Op** operación (lleva `op_id`, `device_id`, `user_id`, `occurred_at`; en el servidor también `received_at`).

### 1.1 Claves únicas con columnas que pueden ser NULL

En SQL, dos `NULL` no se consideran iguales, así que una clave única con una columna opcional deja pasar duplicados. Se resuelve según lo que signifique el `NULL`:

| Si `NULL` significa… | Servidor (PostgreSQL 16) | Dispositivo (SQLite) | Casos |
| --- | --- | --- | --- |
| **Un valor real** (p. ej. “sin lote”) | `UNIQUE NULLS NOT DISTINCT (...)` | Índice único sobre expresión: `(product_id, IFNULL(lot_id, ''))` | `stock_balances (product_id, lot_id)`, `stock_reservations (order_note_id, product_id, lot_id)`, `lots (product_id, lot_code, expires_on)`, `inventory_count_lines (count_id, product_id, lot_id)` |
| **“No aplica”** (muchas filas pueden no tenerlo) | Índice único **parcial**: `... WHERE col IS NOT NULL` | Igual (SQLite admite índices parciales) | `customers (doc_type, doc_number)`, `sales (order_note_id)`, `suppliers (ruc)`, `product_presentations (product_id) WHERE is_base` |

---

## 2. Tablas por módulo

### 2.1 Catálogo

**`categories`** (M)

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| name | text | UQ (`lower(name)`) |
| sort_order | int | |

**`brands`** (M): `id` PK, `name` UQ (`lower(name)`).

**`units`** (M)

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| code | text UQ | `und`, `kg`, `l`, … |
| name | text | “Unidad”, “Kilogramo” |
| kind | text | `count` \| `weight` \| `volume` |

**`products`** (M)

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| internal_code | text UQ | Código interno de la tienda |
| name | text | |
| description | text | nullable |
| image_path | text | nullable |
| category_id | uuid FK → categories | |
| brand_id | uuid FK → brands | nullable |
| base_unit_id | uuid FK → units | Unidad en que se lleva el stock |
| tracks_lots | boolean | Si es `true`, recepción exige lote y la venta usa FEFO |
| min_stock_milli | bigint | Stock mínimo (unidad base) |

**`product_costs`** (servidor calcula, dispositivo réplica; versión propia)

| Columna | Tipo | Notas |
| --- | --- | --- |
| product_id | uuid PK, FK → products | |
| avg_cost_cents | bigint | **Promedio ponderado móvil** por unidad base. Lo recalcula **solo el servidor** en cada recepción (§3.4) |
| last_cost_cents | bigint | Último costo de compra por unidad base (referencia) |
| on_hand_milli | bigint | Stock total usado en el cálculo (≥ 0) |
| version | bigint | |

**`product_presentations`** (M)

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| product_id | uuid FK → products | |
| name | text | “Unidad”, “Caja x12”, “Bolsa 500 g”, “kg” |
| factor_milli | bigint | Unidades base que contiene × 1000. **Obligatorio y > 0; nunca se asume** |
| is_base | boolean | Exactamente una por producto (índice único parcial `WHERE is_base`) con `factor_milli = 1000` |
| retail_price_cents | bigint | Precio minorista de la presentación (en productos por peso: precio por kg) |
| wholesale_price_cents | bigint | nullable |
| wholesale_min_milli | bigint | nullable; cantidad mínima para precio mayorista |
| UQ | | `(product_id, lower(name))` |

**`barcodes`** (M)

| Columna | Tipo | Notas |
| --- | --- | --- |
| code | text PK | **Único global** (incluye todas las presentaciones) |
| presentation_id | uuid FK → product_presentations | |
| format | text | `ean13` \| `ean8` \| `upca` \| `upce` \| `code128` \| `code39` |
| generated | boolean | `true` si lo generó el sistema (§3.6) |

**`product_suppliers`**: `product_id` FK, `supplier_id` FK, `supplier_code` nullable, `last_cost_cents`; PK `(product_id, supplier_id)`.

**`product_import_batches`** (solo servidor): `id` PK, `user_id`, `device_id`, `file_name`, `rows_total`, `rows_created`, `rows_failed`, `errors` jsonb (fila → motivo), `created_at`. Traza de cada carga masiva por CSV (ESPECIFICACION §29.2); los productos se crean con los mismos pasos que `CreateProduct`, en una transacción por producto.

**`price_changes`** (Op, solo servidor): `id` PK, `presentation_id` FK, `old_retail_cents`, `new_retail_cents`, `old_wholesale_cents`, `new_wholesale_cents`, `reason`.

### 2.2 Inventario

**`lots`** (M)

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| product_id | uuid FK → products | |
| lot_code | text | Código impreso por el fabricante, o generado si no tiene |
| expires_on | date | nullable (lotes sin vencimiento) |
| UQ | | `(product_id, lot_code, expires_on)` **NULLS NOT DISTINCT** |

**`stock_movements`** (Op) — **la única fuente del stock**

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| product_id | uuid FK → products | |
| lot_id | uuid FK → lots | nullable (producto sin lotes) |
| qty_milli | bigint | ± en **unidad base** |
| type | text | `initial` \| `purchase_receipt` \| `sale` \| `sale_void` \| `sale_return` \| `adjustment` \| `count` \| `loss` |
| reason | text | nullable; obligatorio en `adjustment` y `loss` |
| unit_cost_cents | bigint | Costo por unidad base aplicado al movimiento |
| source_type | text | `sale_item_lot` \| `receipt_line` \| `adjustment_line` \| `count_line` \| `return_item` \| `void` |
| source_id | uuid | Fila de origen |
| op_id, device_id, user_id, occurred_at | | |

Índice: `(product_id, lot_id, occurred_at)`.

**`stock_balances`** (proyección; servidor oficial, dispositivo réplica)

| Columna | Tipo | Notas |
| --- | --- | --- |
| product_id | uuid FK → products | |
| lot_id | uuid FK → lots | nullable |
| qty_milli | bigint | Suma de `stock_movements`; puede quedar negativo (conflicto) |
| version | bigint | |
| UQ | | `(product_id, lot_id)` **NULLS NOT DISTINCT**; en SQLite `(product_id, IFNULL(lot_id, ''))` |

Se actualiza solo dentro de la transacción que inserta el movimiento. Nunca se edita a mano.

**`stock_adjustments`** (Op): `id` PK, `reason` text, `notes` nullable. **`stock_adjustment_lines`**: `id` PK, `adjustment_id` FK, `product_id` FK, `lot_id` FK nullable, `qty_milli` ±, `is_loss` boolean. Cada línea → un `stock_movement` (`adjustment`, o `loss` si `is_loss`).

**`inventory_counts`** (Op): `id` PK, `status` `open` \| `closed`, `scope` text (todo / categoría / lista), `closed_at` nullable. **`inventory_count_lines`**: `id` PK, `count_id` FK, `product_id` FK, `lot_id` FK nullable, `expected_milli` (foto del stock local al contar), `counted_milli`; UQ `(count_id, product_id, lot_id)` NULLS NOT DISTINCT. Al cerrar, cada diferencia ≠ 0 → `stock_movement` tipo `count`.

**`stock_losses`** (Op) — **mermas**, para reportes y reclamo al proveedor

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| product_id | uuid FK → products | |
| lot_id | uuid FK → lots | nullable |
| qty_milli | bigint | > 0 (unidad base) |
| unit_cost_cents | bigint | Costo del momento |
| reason | text | `defective_return` \| `damaged` \| `expired` \| `other` |
| source_type, source_id | | `return_item` o `adjustment_line` |
| supplier_id | uuid FK → suppliers | nullable (proveedor a reclamar, si se conoce) |
| claim_status | text | `none` \| `pending` \| `claimed` \| `credited` |

### 2.3 Compras y proveedores

**`suppliers`** (M): `id` PK, `name`, `ruc` nullable (UQ parcial `WHERE ruc IS NOT NULL`), `phone`, `contact_name`, `notes`.

**`purchases`** (Op)

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| supplier_id | uuid FK → suppliers | |
| supplier_doc_ref | text | nullable; n.º de factura/guía del proveedor |
| status | text | `pending` \| `partial` \| `received` \| `cancelled` |
| due_on | date | nullable; vencimiento del pago |
| notes | text | nullable |

**`purchase_items`**: `id` PK, `purchase_id` FK, `presentation_id` FK, `qty_milli` (en la presentación), `factor_milli` (**foto** del factor), `unit_cost_cents` (por presentación).

**`purchase_receipts`** (Op): `id` PK, `purchase_id` FK.
**`receipt_lines`**: `id` PK, `receipt_id` FK, `purchase_item_id` FK, `lot_id` FK nullable (obligatorio si el producto controla lotes), `qty_base_milli` (recibido, unidad base), `unit_cost_cents` (por unidad base). Cada línea → `stock_movement` tipo `purchase_receipt`.

**`supplier_ledger`** (Op) — deuda con proveedores por movimientos

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| supplier_id | uuid FK → suppliers | |
| kind | text | `charge` (al **recibir**) \| `payment` \| `credit_note` \| `adjustment` |
| amount_cents | bigint | `charge` +, `payment`/`credit_note` −, `adjustment` ± (con permiso y auditoría) |
| purchase_id | uuid FK | nullable |
| receipt_id | uuid FK | nullable (el cargo nace de la recepción) |
| supplier_payment_id | uuid FK | nullable |
| due_on | date | nullable |

**`supplier_payments`** (Op): `id` PK, `supplier_id` FK, `amount_cents`, `payment_method_id` FK, `reference` nullable, `cash_session_id` FK nullable (si salió del cajón). **`supplier_payment_allocations`**: `payment_id` FK, `purchase_id` FK, `amount_cents`; PK `(payment_id, purchase_id)`.

### 2.4 Ventas

**`sales`** (Op)

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| series | text | Serie del dispositivo (`T1`, `P1`) |
| number | bigint | Correlativo de la serie |
| customer_id | uuid FK → customers | nullable (público en general) |
| cash_session_id | uuid FK → cash_sessions | nullable (§3.5) |
| kind | text | `cash` \| `credit`. `CHECK (kind <> 'credit' OR customer_id IS NOT NULL)`: **a crédito solo a clientes registrados** |
| status | text | `completed` \| `voided` |
| subtotal_cents, discount_cents, total_cents | bigint | |
| order_note_id | uuid FK → order_notes | nullable; **UQ parcial** `WHERE order_note_id IS NOT NULL` (una nota → máximo una venta) |
| physical_receipt_ref | text | nullable; comprobante físico entregado (Nuevo RUS) |
| stock_warning | boolean | Se vendió sin stock local suficiente (se registró con aviso) |
| UQ | | `(series, number)` |

**`sale_items`**

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| sale_id | uuid FK → sales | |
| presentation_id | uuid FK → product_presentations | |
| product_id | uuid FK → products | (desnormalizado para reportes) |
| qty_milli | bigint | En la presentación |
| factor_milli | bigint | **Foto** del factor |
| price_list | text | `retail` \| `wholesale` |
| unit_price_cents | bigint | Precio aplicado por presentación |
| discount_cents | bigint | |
| line_total_cents | bigint | |
| unit_cost_cents | bigint | **Promedio ponderado que el dispositivo conocía** al vender, por unidad base |
| authorized_by | uuid FK → users | nullable; precio o descuento fuera de lo permitido |

**`sale_item_lots`**: `id` PK, `sale_item_id` FK, `lot_id` FK nullable, `qty_base_milli`. El reparto FEFO decidido por el dispositivo (§3.2). Cada fila → `stock_movement` tipo `sale`.

**`sale_payments`**: `id` PK, `sale_id` FK, `payment_method_id` FK, `amount_cents`, `tendered_cents` nullable (efectivo entregado; el vuelto se calcula), `reference` nullable (n.º de operación Yape/Plin/transferencia).

**`sale_voids`** (Op): `id` PK, `sale_id` FK **UQ**, `reason`, `authorized_by` FK → users. Genera movimientos `sale_void` inversos, revierte el cargo en `customer_ledger` y los `cash_movements` de la venta.

**`sale_returns`** (Op)

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| sale_id | uuid FK → sales | |
| reason | text | |
| refund_cents | bigint | Total devuelto |
| refund_mode | text | `money` (contado) \| `credit` (venta a crédito: abono en `customer_ledger`) |
| refund_method_id | uuid FK → payment_methods | nullable; obligatorio si `refund_mode = money` |
| cash_session_id | uuid FK | nullable; sesión donde salió el dinero |

**`sale_return_items`**: `id` PK, `return_id` FK, `sale_item_id` FK, `lot_id` FK nullable (lote original, de `sale_item_lots`), `qty_base_milli`, `refund_cents`, **`disposition`** `restock` \| `defective`:

- `restock` → `stock_movement` tipo `sale_return` (+) al lote original, al `unit_cost_cents` de la venta.
- `defective` → **no** vuelve al stock vendible: fila en `stock_losses` (`reason = defective_return`, costo del ítem vendido, `supplier_id` si se conoce).

El reembolso: si `refund_mode = money`, un `cash_movement` (−) con `refund_method_id`; si `credit`, un movimiento `return_credit` (−) en `customer_ledger` por lo que quedaba pendiente, y el excedente, si lo hay, como dinero.

### 2.5 Caja

**`payment_methods`** (M)

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| code | text UQ | `cash`, `yape`, `plin`, `wallet`, `transfer` |
| name | text | “Efectivo”, “Yape”, “Plin”, “Billetera digital”, “Transferencia” |
| affects_cash_drawer | boolean | Solo `cash` = `true`. **Sin tarjetas** |
| requires_reference | boolean | |
| sort_order | int | |

**`cash_sessions`** (Op) — una sola caja para la tienda (§3.5)

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| status | text | `open` \| `closed` |
| opened_by, opened_at | | |
| opened_device_id | uuid FK → devices | Equipo desde el que se abrió |
| opened_offline | boolean | `true` si la abrió sin conexión el equipo de caja de respaldo |
| opening_float_cents | bigint | Fondo inicial |
| closed_by, closed_at | | nullable |
| closed_device_id | uuid FK → devices | nullable |
| closed_offline | boolean | |
| expected_cash_cents | bigint | nullable; **calculado por el servidor** con los movimientos de todos los equipos |
| device_expected_cash_cents | bigint | nullable; el esperado que mostró el equipo al cerrar sin conexión |
| counted_cash_cents | bigint | nullable; arqueo |
| difference_cents | bigint | nullable; contado − esperado del servidor |
| pending_at_close | jsonb | nullable; foto por equipo de última sincronización y pendientes al cerrar |
| close_override_reason | text | nullable; motivo si se cerró con ventas sin enviar |
| closing_notes | text | nullable |
| UQ | | Índice único parcial `ON cash_sessions ((true)) WHERE status = 'open'`: **una sola sesión abierta** |

**`cash_session_events`** (Op): `id` PK, `session_id` FK, `kind` `reopen` \| `late_movement` \| `merged_offline_session`, `reason`, `authorized_by`. Un cierre nunca se edita: se reabre con permiso o se registra el movimiento tardío.

**`cash_movements`** (Op)

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| session_id | uuid FK → cash_sessions | nullable mientras el dispositivo no conozca la sesión (§3.5) |
| kind | text | `opening_float` \| `sale` \| `customer_payment` \| `refund` \| `supplier_payment` \| `expense` \| `cash_in` \| `cash_out` |
| amount_cents | bigint | ± |
| payment_method_id | uuid FK → payment_methods | |
| concept | text | |
| source_type, source_id | | Venta, pago, gasto, devolución… |

**`expense_categories`** (M): `id`, `name` UQ. **`expenses`** (Op): `id` PK, `category_id` FK, `amount_cents`, `payment_method_id` FK, `concept`, `cash_session_id` FK nullable, `supplier_id` FK nullable. Si sale del cajón → `cash_movement` tipo `expense`.

### 2.6 Clientes y crédito

**`customers`** (M)

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| doc_type | text | `dni` \| `ruc` \| `ce` \| `none` |
| doc_number | text | nullable; **UQ parcial** `(doc_type, doc_number) WHERE doc_number IS NOT NULL` |
| name | text | |
| phone, address, email | text | nullable |
| credit_limit_cents | bigint | 0 = sin crédito |
| credit_days | int | Plazo por defecto |

**`customer_ledger`** (Op) — cuentas por cobrar por movimientos

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| customer_id | uuid FK → customers | |
| kind | text | `charge` (venta a crédito) \| `payment` \| `return_credit` \| `void_reversal` \| `adjustment` |
| amount_cents | bigint | `charge` +; los demás − (salvo `adjustment` ±, con permiso y auditoría) |
| sale_id | uuid FK | nullable |
| customer_payment_id | uuid FK | nullable |
| return_id | uuid FK | nullable |
| due_on | date | nullable (en `charge`) |

**`customer_payments`** (Op): `id` PK, `customer_id` FK, `amount_cents`, `payment_method_id` FK, `reference` nullable, `cash_session_id` FK nullable. **`customer_payment_allocations`**: `payment_id` FK, `sale_id` FK, `amount_cents`; PK `(payment_id, sale_id)`. Por defecto se aplica primero a lo que vence antes.

### 2.7 Notas de pedido

**`order_notes`** (Op)

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| series, number | | UQ `(series, number)` |
| customer_id | uuid FK | nullable |
| status | text | `issued` \| `converted` \| `cancelled` |
| notes | text | nullable |
| reserve_stock | boolean | Según ajuste `order_notes.reserve_stock` |
| total_cents | bigint | |

Siempre se imprime con la leyenda “Documento interno – no válido como comprobante de pago”.

**`order_note_items`**: `id` PK, `order_note_id` FK, `presentation_id` FK, `qty_milli`, `factor_milli`, `unit_price_cents`, `line_total_cents`.

**`stock_reservations`**: `order_note_id` FK, `product_id` FK, `lot_id` FK nullable, `qty_milli`; UQ NULLS NOT DISTINCT. **No son movimientos**: disponible = saldo − reservado. Se liberan al convertir o anular la nota.

### 2.8 Usuarios, dispositivos, configuración y auditoría

**`users`** (M)

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| username | text | UQ (`lower(username)`) |
| full_name | text | |
| password_hash | text | Argon2id. **Solo servidor** |
| pin_hash | text | nullable; Argon2id del PIN, para el ingreso rápido y sin conexión |
| must_change_password | boolean | Pide cambiar la contraseña en el próximo ingreso (usuarios creados desde `.env`) |

**`roles`** (M): `id` PK, `code` UQ, `name`, `home_view` (pantalla inicial del rol). **`permissions`**: `code` PK (`modulo.accion`), `description`. **`role_permissions`**: PK `(role_id, permission_code)`. **`user_roles`**: PK `(user_id, role_id)`. Roles propuestos en §4.

**`devices`** (M)

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | El `device_id` que el equipo genera al instalarse |
| name | text | “Tablet caja”, “PC oficina” |
| platform | text | `android` \| `windows` |
| series_prefix | text UQ | `T1`, `P1`, … |
| barcode_digit | int UQ | 0–9; dígito del equipo en los códigos generados (§3.6) |

**`device_sync_status`** (solo servidor; la consulta la pantalla de cierre de caja)

| Columna | Tipo | Notas |
| --- | --- | --- |
| device_id | uuid PK, FK → devices | |
| last_push_at | timestamptz | Último envío recibido |
| last_pull_at | timestamptz | Última bajada |
| last_heartbeat_at | timestamptz | Último latido |
| pending_ops | int | Comandos pendientes que informó el equipo |
| pending_sales | int | De ellos, ventas (y cobros) |
| reported_at | timestamptz | Hora del servidor del último informe |

Cada equipo informa sus pendientes en cada `POST /sync/push` (campo `status` junto a `commands`) y, **solo mientras hay una caja abierta**, en un **latido** `POST /sync/heartbeat` cada 60 s. Con la caja cerrada no hay latido: basta con las sincronizaciones normales.

**`document_series`**: `device_id` FK, `doc_type` `sale` \| `order_note` \| `barcode`, `next_number` bigint; PK `(device_id, doc_type)`. Cada dispositivo numera solo sus series, también sin conexión.

**`settings`** (M): `key` text PK, `value` jsonb. Datos del negocio (`TODO(config)`), `sales.mixed_payments`, `order_notes.reserve_stock`, `inventory.expiry_warning_days`, `cash.backup_device_id` (equipo de caja de respaldo; por defecto la tablet).

**`audit_log`** (solo servidor): `id` PK, `at`, `user_id`, `device_id`, `action` (`sales.void`, `sales.discount`, `catalog.change_price`, `inventory.adjust`, `cash.close`, …), `entity_type`, `entity_id`, `before` jsonb, `after` jsonb, `reason`, `authorized_by`, `op_id`. Lo escribe el servidor al aplicar cada comando, en la misma transacción.

**`refresh_tokens`** (solo servidor): `id` PK, `family_id` (la cadena de rotaciones de un inicio de sesión), `user_id`, `device_id` (sin FK: el equipo inicia sesión antes de registrarse), `token_hash` UQ (SHA-256; nunca el token), `created_at`, `expires_at`, `revoked_at`. Reusar un token ya rotado revoca toda su familia.

### 2.9 Sincronización

**`sync_inbox`** (solo servidor; ya existe desde el Spike 6): `op_id` PK, `device_id`, `user_id`, `type`, `payload` jsonb, `device_created_at`, `received_at`, `status`, `message`.

**`sync_conflicts`** (solo servidor)

| Columna | Tipo | Notas |
| --- | --- | --- |
| id | uuid PK | |
| type | text | `negative_stock` \| `duplicate_barcode` \| `duplicate_customer_doc` \| `stale_price` \| `closed_cash_session` \| `unassigned_cash_movement` \| `duplicate_cash_session` |
| op_id | uuid FK → sync_inbox | Comando que lo generó |
| entity_type, entity_id | | |
| details | jsonb | |
| status | text | `open` \| `resolved` |
| resolved_by, resolved_at, resolution | | nullable |

**`sync_log`** (solo servidor): errores al aplicar comandos (`at`, `op_id`, `device_id`, `error`, `details`).

`sync_conflicts` también guarda `created_at`; un conflicto `resolved` exige `resolved_at`.

**En el dispositivo:** `outbox` (Spike 6), `sync_state` (`stream` PK, `cursor` bigint, `last_pull_at`) y `local_settings` (`device_id`, URL del servidor, sesión cacheada).

---

## 3. Reglas del modelo

### 3.1 Presentaciones y factor de conversión

- El stock de todo producto se lleva en su **unidad base** (`products.base_unit_id`).
- Cada presentación declara `factor_milli` = unidades base × 1000: *Unidad* = 1 000; *Caja x12* = 12 000; con base kg, *kg* = 1 000 y *Bolsa 500 g* = 500.
- Movimiento en unidad base = `qty_milli × factor_milli / 1000`.
- Cada línea de venta, compra y nota guarda **la foto** de `factor_milli`. Cambiar el factor después no altera el historial.
- **Productos por peso** (sin balanza): la presentación base es *kg* y su `retail_price_cents` es el precio por kg. La app ofrece una calculadora en dos sentidos, peso → precio y monto → peso. El monto a peso se redondea a gramos enteros, y el precio de la línea se recalcula a partir de ese peso. No hay códigos de balanza.

### 3.2 Lotes, vencimientos y FEFO

- Solo productos con `tracks_lots`. La recepción exige lote y vencimiento (`expires_on` puede ser NULL solo si el lote no vence).
- **Al vender, el dispositivo reparte** cada ítem entre lotes:
  1. Considera solo lotes **no vencidos** (`expires_on IS NULL OR expires_on >= hoy` en hora de Lima). **Los vencidos están bloqueados, sin excepción ni permiso.**
  2. Ordena por `expires_on` ascendente (NULL al final).
  3. Toma de cada lote hasta su saldo local positivo.
  4. Si no alcanza, el resto va al lote no vencido de **vencimiento más lejano**, que queda negativo. La venta se registra con `stock_warning = true` y un aviso al usuario.
  - **Límite en el carrito** (decisión del usuario, 2026-11-19): cuando agregar (escaneo, lector, toque o **+**) supera el stock local vendible, la app pregunta "Sin stock · ¿Agregar de todas formas?". **Sí**: se agrega con aviso ámbar y no vuelve a preguntar por ese producto en la venta. **No**: no se agrega, y cada nuevo escaneo de ese código muestra el error rojo. Las respuestas se olvidan al terminar o vaciar la venta.
- El reparto se guarda en `sale_item_lots`; el servidor **lo aplica tal cual**, sin recalcular. Si un saldo global queda negativo → `sync_conflicts` `negative_stock`.
- Si el producto **no tiene ningún lote** todavía, se vende **«sin lote»** (`lot_id` NULL, saldo negativo) con `stock_warning = true`, como una venta sin stock local (decisión del usuario, 2026-11-25). Si **tiene lotes y todos están vencidos**, **no se puede vender** hasta registrar un ingreso o ajuste.

### 3.3 Pagos, caja y lo que se diferencia

- Cada cobro de venta es una fila en `sale_payments` y un `cash_movement` en la sesión, con su medio. La caja registra **todo** el dinero del turno.
- En el arqueo, el **efectivo esperado** = fondo inicial + Σ `cash_movements` cuyo medio tiene `affects_cash_drawer = true`. Yape, Plin, billetera y transferencia se muestran aparte, para cotejar con los estados de cuenta, y **no entran al cajón**.
- Cómo se distingue cada concepto:

| Concepto | Dónde vive |
| --- | --- |
| Venta | `sales` + `sale_items` |
| Pago recibido | `sale_payments`, `customer_payments` |
| Ingreso de caja | `cash_movements` |
| Deuda | `customer_ledger`, `supplier_ledger` |
| Gasto | `expenses` |
| Utilidad | Σ (`line_total_cents` − cantidad base × `unit_cost_cents`) de las ventas no anuladas, menos devoluciones |

- Pagos mixtos (varias filas en `sale_payments`) solo si `sales.mixed_payments` está activado.

### 3.4 Costo: promedio ponderado móvil

- **Solo el servidor** recalcula `product_costs.avg_cost_cents` al aplicar cada `ReceivePurchase`:
  `nuevo_promedio = (max(on_hand, 0) × promedio + recibido × costo_recibido) / (max(on_hand, 0) + recibido)`, redondeado al céntimo. También actualiza `last_cost_cents`.
- `on_hand_milli` acompaña cada movimiento de stock. Si queda en 0 o negativo, la siguiente recepción fija el promedio en su propio costo.
- El dispositivo recibe `product_costs` en la bajada y guarda en cada `sale_items.unit_cost_cents` **el promedio que conoce en ese momento**. Si estaba desactualizado, la utilidad de esa venta usa ese valor; no se reescribe.
- Devoluciones `restock` vuelven al costo de la venta y **no** alteran el promedio. Mermas usan el costo del ítem vendido o el promedio vigente.

### 3.5 Una sola caja compartida, con PC y tablet a la vez

La tienda tiene un solo cajón físico y **una sola sesión de caja abierta** a la vez. PC y tablet trabajan al mismo tiempo sobre ella.

| Acción | Con conexión al servidor | Sin conexión |
| --- | --- | --- |
| Abrir caja (`OpenCash`) | **Cualquier equipo**, con permiso `cash.open` | Solo el **equipo de caja de respaldo** (`settings.cash.backup_device_id`; por defecto la tablet, configurable) |
| Arqueo y cierre (`CloseCash`) | **Cualquier equipo**, con permiso `cash.close` | Solo el equipo de caja de respaldo |
| Reabrir caja (`ReopenCash`) | Cualquier equipo, con permiso `cash.reopen` | No |
| Ingresos, egresos, retiros (`RecordCashMovement`), gastos del cajón (`RecordExpense`) | Cualquier equipo, en la sesión abierta | Cualquier equipo que conozca la sesión abierta |
| Vender y cobrar | Cualquier equipo | Cualquier equipo |
| Cambiar el equipo de respaldo | Administrador, con la caja cerrada | No |

**Con conexión: el servidor decide**

- `OpenCash`, `CloseCash` y `ReopenCash` se envían **en línea** (no esperan en el `outbox`). El servidor los aplica uno a la vez (bloqueo de fila sobre la sesión abierta, dentro de la transacción) y el índice único parcial garantiza una sola sesión abierta. Si dos equipos intentan abrir a la vez, uno la abre y el otro recibe “La caja ya fue abierta por …” y pasa a usarla.
- El **esperado** lo calcula el servidor con los `cash_movements` de **todos los equipos**: fondo inicial + Σ movimientos con medio `affects_cash_drawer = true`. Los demás medios se muestran aparte.

**Estado de los equipos al cerrar**

- Cada equipo informa sus pendientes en cada sincronización y, **solo mientras hay una caja abierta**, en un latido cada 60 s. Con la caja cerrada no hay latido: bastan las sincronizaciones normales.
- La pantalla de cierre consulta `device_sync_status` y muestra, por equipo, **la última sincronización y sus operaciones pendientes**.
- Si algún equipo informa **ventas o cobros sin enviar** (o no informa desde hace más de 2 min), avisa y **ofrece esperar**: la pantalla se actualiza sola hasta que los pendientes lleguen a 0.
- Cerrar de todos modos exige escribir un motivo (`close_override_reason`), queda en `audit_log` y guarda la foto en `pending_at_close`.

**Sin conexión: el equipo de caja de respaldo**

- Solo ese equipo puede abrir o cerrar sin conexión; los comandos van a su `outbox`. En el cierre muestra un esperado **local** (sus movimientos + los de otros equipos que ya había bajado) y avisa que es provisional; se guarda en `device_expected_cash_cents`. Al llegar el comando, el servidor recalcula `expected_cash_cents` y la diferencia oficial.
- Si al llegar su `OpenCash` ya hay otra sesión abierta (abierta en línea desde otro equipo), el servidor **no crea una segunda**: sus movimientos se asignan a la sesión abierta (es el mismo cajón), se registra `cash_session_events` (`merged_offline_session`) y un conflicto `duplicate_cash_session` para que el Administrador revise el fondo inicial.
- Los demás equipos siguen vendiendo y cobrando sin conexión.

**Efectivo cobrado sin conocer una caja abierta**

- Si un equipo cobra en efectivo y no conoce ninguna sesión abierta, **avisa en pantalla** (“No hay una caja abierta conocida; el cobro se asignará al sincronizar”) y envía el `cash_movement` con `session_id = NULL`. El servidor lo asigna a la sesión abierta en ese momento; si no hay ninguna → conflicto `unassigned_cash_movement`.

**Movimiento que llega después del cierre**

- El cierre no se modifica. Se registra `cash_session_events` (`late_movement`) y un conflicto `closed_cash_session`. El Administrador lo revisa y lo asigna a la siguiente sesión, que lo muestra como “ajuste por sincronización tardía”.

### 3.6 Códigos de barras generados

- Formato EAN-13 interno: `29` + dígito del equipo (`devices.barcode_digit`) + 9 dígitos de secuencia (`document_series` tipo `barcode`) + dígito de control.
- El prefijo `29` (zona de uso interno) deja libre el resto del rango `2x` por si más adelante se usa una balanza.
- Con el dígito del equipo, dos equipos sin conexión nunca generan el mismo código. La unicidad global de `barcodes.code` lo confirma en el servidor; si un código del fabricante se registra en dos equipos a la vez → conflicto `duplicate_barcode` para fusionar.

### 3.7 Saldos por movimientos

- Clientes y proveedores: saldo = Σ `amount_cents` de su libro (`customer_ledger`, `supplier_ledger`). **Nunca se guarda ni se edita un saldo**; el servidor puede mantener una vista o proyección para consultas rápidas.
- Venta a crédito → `charge` (+) con `due_on = fecha + credit_days`. Abono → `payment` (−) + asignaciones a ventas. Corregir una deuda → `adjustment` con permiso y auditoría.
- Compra: el cargo al proveedor nace **al recibir** (`ReceivePurchase`), por lo recibido.

---

## 4. Roles y vistas

Al inicio hay **un solo usuario** (Administrador). Los roles se definen **por vistas**: cada rol ve solo los módulos de su trabajo. Son datos (`roles`, `role_permissions`): se ajustan sin migraciones. Aprobado por el usuario el 2026-11-17; reemplaza los cuatro roles iniciales de CLAUDE.md §9.

| Rol | Vistas | Puede | No puede | Pantalla inicial |
| --- | --- | --- | --- | --- |
| **Administrador** | Todas | Todo: dashboard, reportes, costos y utilidad, catálogo y precios, compras, anulaciones, ajustes de stock, reabrir caja, usuarios, ajustes, resolver conflictos | — | Dashboard |
| **Trabajo** | Vender, Escanear, Inventario (stock), Pedidos, Clientes, Caja del turno | Vender y cobrar, **descuentos con el % que se requiera**, ventas a crédito **solo a clientes registrados**, devoluciones, notas de pedido, consultar stock, conteos, **recibir compras sin ver costos**, alta de productos y clientes por escaneo, abrir y cerrar caja, gastos del cajón | Ver costos, utilidad o reportes; editar productos o precios; anular ventas; ajustes de stock; reabrir caja; usuarios y ajustes | Vender |

- Una acción fuera del rol (anular, precio especial, descuento mayor) puede hacerse en el mismo equipo si un Administrador **autoriza con su PIN**; queda en `authorized_by` y en `audit_log`.
- **Recibir compras sin ver costos:** la pantalla de recepción del rol Trabajo muestra productos, cantidades, lotes y vencimientos, pero no costos ni totales; los costos vienen de la compra creada por el Administrador.
- Las vistas se derivan de permisos `*.view`; el resto, de permisos `modulo.accion`.

Permisos iniciales:

| Permiso | Administrador | Trabajo |
| --- | :---: | :---: |
| `dashboard.view`, `reports.view`, `reports.profit` | ✔ | |
| `sales.view`, `sales.create`, `order_notes.create` | ✔ | ✔ |
| `sales.credit` (solo a clientes registrados), `sales.return` | ✔ | ✔ |
| `sales.discount` (cualquier %; queda auditado) | ✔ | ✔ |
| `sales.change_price`, `sales.void` | ✔ | con PIN de Administrador |
| `cash.view`, `cash.open`, `cash.close`, `cash.movement`, `cash.expense` | ✔ | ✔ |
| `cash.reopen` | ✔ | |
| `catalog.view`, `catalog.create` | ✔ | ✔ |
| `catalog.edit`, `catalog.view_cost` | ✔ | |
| `inventory.view`, `inventory.count` | ✔ | ✔ |
| `inventory.adjust` | ✔ | con PIN de Administrador |
| `purchases.receive` (incluye registrar lotes y vencimientos al recibir) | ✔ | ✔ (sin costos) |
| `purchases.manage` | ✔ | |
| `customers.view`, `customers.create`, `customers.payment` | ✔ | ✔ |
| `customers.edit`, `customers.credit_limit` | ✔ | |
| `users.manage`, `settings.manage`, `sync.resolve_conflicts` | ✔ | |

Decisión del usuario (2026-11-19): Trabajo **sí** registra lotes y vencimientos al recibir mercadería, sin ver costos. Las salidas por merma y los conteos que dejan una diferencia son ajustes (`inventory.adjust`) y siguen siendo del Administrador: Trabajo puede anotar un conteo (`inventory.count`), pero la diferencia la aplica el Administrador o se aplica con su PIN.

---

## 5. Dónde vive cada tabla

| Tabla | Servidor | Tablet / PC (SQLite) | Cómo llega al dispositivo |
| --- | --- | --- | --- |
| categories, brands, units, products, product_presentations, barcodes, product_suppliers | ✔ | ✔ réplica | Bajada (pull) |
| product_costs | ✔ (calcula) | ✔ réplica | Bajada |
| price_changes | ✔ | — | — |
| lots | ✔ | ✔ réplica + propios | Bajada; los creados al recibir viajan en el comando |
| stock_movements | ✔ | ✔ **solo propios** | Se crean localmente |
| stock_balances | ✔ oficial | ✔ réplica | Bajada; stock local = réplica + movimientos propios aún no confirmados |
| stock_adjustments(+lines), inventory_counts(+lines), stock_losses | ✔ | ✔ propios | Locales |
| suppliers | ✔ | ✔ réplica | Bajada |
| purchases, purchase_items | ✔ | ✔ réplica de **pendientes** | Bajada (para recibir sin conexión) |
| purchase_receipts, receipt_lines | ✔ | ✔ propios | Locales |
| supplier_ledger, supplier_payments(+allocations) | ✔ | ✔ propios + saldo por proveedor | Bajada de saldos |
| sales, sale_items, sale_item_lots, sale_payments, sale_voids, sale_returns(+items) | ✔ | ✔ propios (y recientes de otros equipos, para devoluciones) | Locales; bajada de los últimos 30 días |
| payment_methods, expense_categories | ✔ | ✔ réplica | Bajada |
| cash_sessions | ✔ | ✔ sesión abierta + propias | Bajada |
| cash_session_events | ✔ | ✔ propios | Locales |
| cash_movements, expenses | ✔ | ✔ propios + los de otros equipos en la sesión abierta (para el esperado provisional del equipo de respaldo) | Locales + bajada |
| customers | ✔ | ✔ réplica | Bajada |
| customer_ledger, customer_payments(+allocations) | ✔ | ✔ propios + saldo por cliente | Bajada de saldos |
| order_notes(+items), stock_reservations | ✔ | ✔ propias + emitidas pendientes | Locales + bajada |
| users | ✔ | ✔ sin `password_hash` (solo `pin_hash` de quienes usan ese equipo) | Bajada |
| roles, permissions, role_permissions, user_roles | ✔ | ✔ réplica | Bajada (permisos verificados también sin conexión) |
| devices | ✔ | ✔ réplica | Bajada |
| document_series | ✔ | ✔ **solo las propias** | Las numera el propio equipo |
| settings | ✔ | ✔ réplica | Bajada |
| audit_log, refresh_tokens, sync_inbox, sync_conflicts, sync_log, device_sync_status | ✔ | — | — |
| outbox, sync_state, local_settings | — | ✔ | — |

---

## 6. Comandos de sincronización por operación

Todos los comandos usan el sobre `SyncCommand` (`op_id`, `device_id`, `user_id`, `created_at`, `type`, `payload`) y se aplican de forma idempotente (`sync_inbox`). **Sin conexión = sí** significa que va al `outbox` y se envía después. **No** significa que la app lo envía en línea y, si no hay conexión, no lo permite (ediciones de maestros en la V1).

| Operación | Comando | Filas que crea/afecta en una transacción | ¿Sin conexión? |
| --- | --- | --- | --- |
| Venta | `CreateSale` | sales, sale_items, sale_item_lots, sale_payments, stock_movements, stock_balances, cash_movements, customer_ledger (si crédito), stock_reservations liberadas y order_notes → `converted` (si viene de una nota) | Sí |
| Anular venta | `VoidSale` | sale_voids, sales.status, stock_movements inversos, customer_ledger `void_reversal`, cash_movements inversos | Sí, con permiso `sales.void` |
| Devolución | `ReturnSale` | sale_returns, sale_return_items, stock_movements (`restock`), stock_losses (`defective`), cash_movements o customer_ledger | Sí, con permiso `sales.return` |
| Nota de pedido | `CreateOrderNote` / `CancelOrderNote` | order_notes, order_note_items, stock_reservations | Sí |
| Alta de producto (con código y presentaciones) | `CreateProduct` | products, product_presentations, barcodes, product_costs | Sí; código repetido → `duplicate_barcode` |
| Carga masiva CSV (productos nuevos) | API directa `POST /catalog/import` (vista previa + confirmación) | products, product_presentations, barcodes, product_costs, lots, stock_movements `initial`, product_import_batches | No (PC con conexión) |
| Editar producto, presentaciones o precios | `UpdateProduct` / `ChangePrice` | products, product_presentations, barcodes, price_changes, audit_log | No |
| Ajuste de stock / merma | `AdjustStock` | stock_adjustments(+lines), stock_movements, stock_losses | Sí, con permiso `inventory.adjust` |
| Conteo físico | `CloseInventoryCount` | inventory_counts(+lines), stock_movements `count` | Sí |
| Crear / cancelar compra | `CreatePurchase` / `CancelPurchase` | purchases, purchase_items | No |
| Recibir compra | `ReceivePurchase` | purchase_receipts, receipt_lines, lots, stock_movements, stock_balances, product_costs (servidor), supplier_ledger `charge`, purchases.status | Sí |
| Pago a proveedor | `RegisterSupplierPayment` | supplier_payments(+allocations), supplier_ledger, cash_movements (si sale del cajón) | Sí |
| Abrir caja | `OpenCash` | cash_sessions, cash_movements `opening_float` | En línea desde cualquier equipo; sin conexión solo el equipo de respaldo |
| Ingreso/egreso/retiro | `RecordCashMovement` | cash_movements | Sí, cualquier equipo que conozca la sesión abierta |
| Gasto | `RecordExpense` | expenses, cash_movements (si sale del cajón) | Sí |
| Cerrar caja | `CloseCash` | cash_sessions (cierre, arqueo, esperado del servidor, `pending_at_close`), audit_log | En línea desde cualquier equipo; sin conexión solo el equipo de respaldo |
| Reabrir caja | `ReopenCash` | cash_session_events, audit_log | No (en línea, permiso `cash.reopen`) |
| Estado del equipo | Campo `status` de cada push; `POST /sync/heartbeat` cada 60 s solo con caja abierta | device_sync_status | — (solo con conexión) |
| Cliente nuevo | `CreateCustomer` | customers | Sí; documento repetido → `duplicate_customer_doc` |
| Editar cliente / límite de crédito | `UpdateCustomer` | customers, audit_log | No |
| Cobro a cliente | `RegisterCustomerPayment` | customer_payments(+allocations), customer_ledger, cash_movements | Sí |
| Usuarios, roles, medios de pago, dispositivos, ajustes | API directa (no `outbox`) | users, roles…, payment_methods, devices, settings | No |

El servidor escribe `audit_log` dentro de la misma transacción para ventas, anulaciones, descuentos, ajustes, compras, cambios de precio, pagos y cierres.

---

## 7. Diagrama de relaciones

```mermaid
erDiagram
    categories ||--o{ products : clasifica
    brands |o--o{ products : marca
    units ||--o{ products : "unidad base"
    products ||--|{ product_presentations : tiene
    product_presentations ||--o{ barcodes : identifica
    products ||--|| product_costs : costo
    products ||--o{ lots : lotes
    products ||--o{ product_suppliers : provee
    suppliers ||--o{ product_suppliers : provee

    products ||--o{ stock_movements : mueve
    lots |o--o{ stock_movements : lote
    products ||--o{ stock_balances : saldo
    lots |o--o{ stock_balances : saldo
    stock_adjustments ||--|{ stock_adjustment_lines : lineas
    inventory_counts ||--|{ inventory_count_lines : lineas
    products ||--o{ stock_losses : merma

    suppliers ||--o{ purchases : compra
    purchases ||--|{ purchase_items : items
    purchases ||--o{ purchase_receipts : recepciones
    purchase_receipts ||--|{ receipt_lines : lineas
    purchase_items ||--o{ receipt_lines : recibe
    suppliers ||--o{ supplier_ledger : deuda
    suppliers ||--o{ supplier_payments : pagos
    supplier_payments ||--o{ supplier_payment_allocations : aplica
    purchases ||--o{ supplier_payment_allocations : aplica

    customers |o--o{ sales : compra
    cash_sessions |o--o{ sales : turno
    order_notes |o--o| sales : "se convierte"
    sales ||--|{ sale_items : items
    product_presentations ||--o{ sale_items : vende
    sale_items ||--|{ sale_item_lots : fefo
    lots |o--o{ sale_item_lots : lote
    sales ||--|{ sale_payments : pagos
    payment_methods ||--o{ sale_payments : medio
    sales ||--o| sale_voids : anulacion
    sales ||--o{ sale_returns : devoluciones
    sale_returns ||--|{ sale_return_items : items
    sale_items ||--o{ sale_return_items : devuelve

    devices ||--o{ cash_sessions : "abre / cierra"
    devices ||--|| device_sync_status : informa
    cash_sessions ||--o{ cash_movements : movimientos
    cash_sessions ||--o{ cash_session_events : eventos
    payment_methods ||--o{ cash_movements : medio
    expense_categories ||--o{ expenses : clasifica

    customers ||--o{ customer_ledger : deuda
    customers ||--o{ customer_payments : pagos
    customer_payments ||--o{ customer_payment_allocations : aplica
    sales ||--o{ customer_payment_allocations : aplica

    customers |o--o{ order_notes : pide
    order_notes ||--|{ order_note_items : items
    order_notes ||--o{ stock_reservations : reserva

    users ||--o{ user_roles : tiene
    roles ||--o{ user_roles : asigna
    roles ||--o{ role_permissions : otorga
    permissions ||--o{ role_permissions : otorga
    devices ||--o{ document_series : numera
    sync_inbox ||--o{ sync_conflicts : genera
```

Las columnas comunes (`op_id`, `device_id`, `user_id`, `occurred_at`) relacionan cada operación con `devices`, `users` y `sync_inbox`; se omiten del diagrama para que se lea.

---

## 8. Pendientes y decisiones abiertas

- Datos del negocio para `settings` y el seed (`TODO(config)`): RUC si se mostrará, teléfono, WhatsApp, mensaje del ticket.
- Ventana de ventas de otros equipos que baja cada dispositivo (propuesta: 30 días) para devoluciones.
- Formato de etiquetas (rollo térmico o hojas A4), definido en el spike de etiquetas.
- Módulo tributario (Fase 8): tablas propias, fuera de este modelo; `sales.physical_receipt_ref` queda como puente.
