# Fase actual: 2 — Productos e inventario

Estado: **en curso** (desde 2026-11-25). Plan aprobado: `docs/planes/fase-2.md`. La bitácora de la Fase 1 está en `docs/informes/fase-1-bitacora.md` y su informe en `docs/informes/fase-1.md`. Actualiza esta lista al terminar cada tarea.

## Tareas (cada una con pruebas y un PR pequeño)

- [x] 1. **PR abierto** (rama `phase-2/catalog-schema`). Migraciones y seed del catálogo e inventario (`modelo-datos.md` §2.1–2.2; unidades `und`, `kg`, `l` y las 6 categorías de ejemplo), con pruebas contra PostgreSQL
- [ ] 2. Core: presentaciones y conversión, validación de códigos (dígito verificador, formatos, daño de Excel), saldo por movimientos y FEFO
- [ ] 3. `CreateProduct` en el servidor y en la app (outbox, `duplicate_barcode`), bajada del catálogo y réplicas en drift
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
