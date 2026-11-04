# Cómo llenar `catalogo_inicial.csv`

Ábrelo en Excel y reemplaza la fila de EJEMPLO (bórrala al final).

| Columna | Qué poner |
| --- | --- |
| nombre | Nombre como aparecerá en el ticket |
| codigo_barras | El del empaque; vacío si no tiene (el sistema generará uno interno) |
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
