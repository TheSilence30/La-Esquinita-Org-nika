# Cómo llenar `catalogo_inicial.csv`

Ábrelo en Excel y reemplaza la fila de EJEMPLO (bórrala al final).

**Para qué sirve:** sobre todo para los productos **sin código de barras** (granel, artesanales, frescos). Los que traen código en el empaque se registran más rápido **escaneándolos** con la cámara o el lector.

**Antes de escribir códigos:** selecciona la columna `codigo_barras` (y `codigo_barras_presentacion`) y dale formato **Texto**. Si no, Excel los convierte en `7.75E+12` o les quita los ceros, y esas filas se rechazan.

| Columna | Qué poner |
| --- | --- |
| nombre | Nombre como aparecerá en el ticket |
| codigo_barras | **Vacío si no tiene**: el sistema genera uno interno (empieza con 29) y luego puedes imprimir su etiqueta. Si tiene, el del empaque |
| categoria | Orgánicos, Alimentos, Bebidas, Productos naturales, Suplementos, Otros o una nueva |
| marca | Opcional |
| unidad_base | unidad, kg, g, L, ml |
| se_vende_por_peso | si / no |
| precio_compra / precio_venta / precio_mayorista | En soles, con punto decimal (12.50) |
| stock_inicial / stock_minimo | En la unidad base |
| controla_lote | si / no |
| lote, fecha_vencimiento | Si controla lote; fecha AAAA-MM-DD |
| presentacion_extra | Paquete, Caja, etc. (opcional) |
| factor_presentacion | Cuántas unidades base contiene (ej. 12) |
| codigo_barras_presentacion | Código de la caja o paquete, si tiene |
| precio_venta_presentacion | Precio de la presentación |
| proveedor | Nombre del proveedor habitual |

Con 20 productos basta para empezar las pruebas.
