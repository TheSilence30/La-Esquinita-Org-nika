# PROYECTO INTEGRAL: LA ESQUINITA ORGÁNIKA
## Sistema profesional de ventas, inventario y gestión comercial para Windows PC y Android

---

# 1. INSTRUCCIÓN GENERAL

Actúa como un equipo senior de desarrollo de software compuesto por:

- Arquitecto de software.
- Analista de sistemas.
- Desarrollador multiplataforma.
- Especialista en POS y gestión comercial.
- Especialista en inventarios y compras.
- Especialista en bases de datos.
- Especialista en sincronización offline.
- Diseñador UX/UI.
- Especialista en impresión, escáneres y códigos de barras.
- Especialista en seguridad, pruebas y despliegue.

Tu misión es diseñar y desarrollar un sistema integral, personalizado y profesional para **La Esquinita Orgánika**, una tienda peruana que comercializa productos orgánicos, alimentos, bebidas, productos naturales, suplementos y otros productos configurables.

El objetivo es construir un sistema similar en funcionalidad y experiencia de uso a FactuSmart, tomando como referencia el video proporcionado por el usuario, pero desarrollando una identidad visual propia, moderna, sofisticada y mejor adaptada al negocio.

No debes limitarte a entregar recomendaciones, ejemplos o código aislado. El objetivo final es construir una aplicación funcional, completa, probada, documentada e instalable.

Sin embargo, el desarrollo debe realizarse por fases controladas. No intentes construir todo el sistema de manera desordenada o en una sola operación.

Debes conservar los requisitos de este documento durante todo el proyecto y consultar esta especificación antes de tomar decisiones que afecten a la arquitectura o a los módulos existentes.

---

# 2. INFORMACIÓN DEL NEGOCIO

Nombre comercial: La Esquinita Orgánika.

Ubicación:
Av. Famesa, Mz. C, Lt. 3, Paradero Famesa, Puente Piedra, Lima, Perú.

Actividad comercial:

- Venta de productos orgánicos.
- Alimentos.
- Bebidas.
- Productos naturales.
- Suplementos.
- Productos por unidad.
- Productos por peso.
- Productos por paquetes.
- Productos por cajas.
- Presentaciones comerciales.
- Compra y venta mayorista.

Situación inicial:

- Un solo local.
- Inicio de digitalización desde cero.
- Actualmente se utilizan registros manuales.
- Se desea comenzar con un sistema propio y escalable.

El sistema debe poder adaptarse a futuras necesidades sin tener que reconstruir toda su arquitectura.

---

# 3. OBJETIVO DEL SISTEMA

Desarrollar un sistema de gestión comercial que integre:

- Punto de venta.
- Productos.
- Inventario.
- Compras.
- Proveedores.
- Clientes.
- Ventas.
- Caja.
- Gastos.
- Cuentas por cobrar.
- Cuentas por pagar.
- Notas de pedido.
- Impresión.
- Etiquetas.
- Usuarios.
- Reportes.
- Sincronización.
- Funcionamiento offline.

La aplicación debe priorizar:

1. Rapidez en ventas.
2. Facilidad de uso.
3. Seguridad de los datos.
4. Exactitud del inventario.
5. Confiabilidad.
6. Diseño visual profesional.
7. Compatibilidad entre dispositivos.
8. Capacidad de crecimiento.

---

# 4. PLATAFORMAS

El sistema deberá funcionar en:

## 4.1 Windows PC

Sistema operativo principal: Windows.

Interfaz adaptada para:

- Pantalla amplia.
- Mouse.
- Teclado.
- Escáner físico.
- Cámara.
- Impresoras.
- Uso intensivo de POS e inventario.

## 4.2 Android

Compatibilidad con:

- Celulares Android.
- Tablets Android.

Dispositivo principal inicial:
Tablet Samsung A11, cuya versión y características exactas deberán confirmarse antes de validar el rendimiento.

Interfaz adaptada para:

- Pantallas táctiles.
- Escaneo con cámara.
- Uso portátil.
- Ventas.
- Inventario.
- Compras.
- Operaciones comerciales.

## 4.3 Independencia de interfaces

PC y Android deben tener interfaces independientes y adaptadas a sus características.

No se debe obligar a que ambas plataformas tengan exactamente la misma distribución visual.

La PC debe sentirse como un sistema de escritorio profesional.

Android debe sentirse como una aplicación móvil o tablet moderna.

Ambos deben compartir datos y reglas de negocio.

---

# 5. ARQUITECTURA TÉCNICA

Evalúa y selecciona la mejor arquitectura para el proyecto.

Considera inicialmente:

- Flutter para Windows y Android.
- SQLite para almacenamiento local.
- PostgreSQL para almacenamiento central.
- Backend independiente.
- API para comunicación.
- Sistema de sincronización offline-first.

No adoptes estas tecnologías sin evaluar sus limitaciones reales.

Antes de iniciar el desarrollo, compara alternativas y explica por qué la arquitectura seleccionada es la más apropiada.

La arquitectura deberá permitir:

- Desarrollo multiplataforma.
- Interfaces adaptadas.
- Funcionamiento offline.
- Sincronización.
- Seguridad.
- Mantenimiento.
- Actualizaciones.
- Escalabilidad.
- Integración futura con otros servicios.

No mezcles indiscriminadamente la interfaz, lógica comercial y almacenamiento.

Organiza el sistema en módulos independientes, reutilizables y mantenibles.

---

# 6. FUNCIONAMIENTO OFFLINE

Este requisito es obligatorio.

La aplicación debe poder continuar trabajando sin internet.

Cada dispositivo deberá disponer de almacenamiento local y permitir operaciones autorizadas sin conexión.

Implementar:

- Base de datos local.
- Cola de sincronización.
- Registro de operaciones pendientes.
- Sincronización automática.
- Sincronización manual.
- Identificadores únicos.
- Prevención de duplicados.
- Reintentos.
- Registro de errores.
- Recuperación después de cerrar o reiniciar la aplicación.
- Detección de conflictos.
- Estado visible de sincronización.

## Reglas de sincronización

No sobrescribir datos indiscriminadamente.

Las ventas, compras, pagos y movimientos de inventario deben conservar su historial.

Cada operación debe identificar:

- Dispositivo de origen.
- Usuario.
- Fecha y hora.
- Identificador de operación.
- Estado de sincronización.

Cuando varios dispositivos registren operaciones offline simultáneamente, el sistema debe detectar inconsistencias.

No afirmar que el stock global está garantizado cuando existen ventas simultáneas desconectadas.

Implementar mecanismos de prevención, detección y resolución de conflictos.

---

# 7. DISEÑO VISUAL Y EXPERIENCIA DE USUARIO

El diseño debe ser:

- Moderno.
- Sofisticado.
- Elegante.
- Limpio.
- Profesional.
- Intuitivo.
- Rápido.
- Fácil de aprender.

Utiliza el logo proporcionado por el usuario.

Incorpora una identidad visual propia para La Esquinita Orgánika.

La estética debe transmitir:

- Naturalidad.
- Calidad.
- Confianza.
- Profesionalismo.
- Elegancia.

Utiliza una paleta coherente con la marca, tipografía legible, jerarquía visual y espacios bien distribuidos.

Evita:

- Interfaces saturadas.
- Exceso de colores.
- Botones innecesarios.
- Menús complicados.
- Formularios extensos sin necesidad.
- Animaciones que dificulten el trabajo.
- Diseños poco prácticos para caja.

## Referencia FactuSmart

Utiliza el video proporcionado como referencia funcional y visual.

Antes de diseñar las pantallas definitivas:

1. Inspecciona el video.
2. Identifica sus módulos.
3. Identifica sus flujos de trabajo.
4. Identifica las características que el usuario quiere replicar.
5. Identifica posibles mejoras.
6. Documenta las observaciones.

No inventes características del video si no pueden verificarse.

No copies código, marca o recursos protegidos.

El sistema debe tener identidad propia.

---

# 8. DASHBOARD

Crear un panel principal moderno.

Mostrar información útil:

- Ventas del día.
- Ingresos.
- Productos más vendidos.
- Stock bajo.
- Productos próximos a vencer.
- Cuentas por cobrar.
- Compras recientes.
- Gastos.
- Estado de caja.
- Estado de sincronización.

El dashboard debe ser configurable y adaptado a PC y Android.

No mostrar información innecesaria en pantallas pequeñas.

---

# 9. PRODUCTOS

Crear un módulo completo de gestión de productos.

Cada producto debe admitir:

- Nombre.
- Código interno.
- Código de barras.
- Categoría.
- Marca.
- Descripción.
- Imagen.
- Precio de compra.
- Precio de venta.
- Precio mayorista.
- Unidad de medida.
- Presentaciones.
- Stock.
- Stock mínimo.
- Proveedores.
- Lotes.
- Vencimientos.
- Estado activo/inactivo.

## Categorías

Permitir crear, modificar y eliminar categorías de forma controlada.

Ejemplos iniciales:

- Orgánicos.
- Alimentos.
- Bebidas.
- Productos naturales.
- Suplementos.
- Otros.

No limitar permanentemente las categorías a estos ejemplos.

## Presentaciones

Soportar:

- Unidad.
- Peso.
- Paquete.
- Caja.
- Presentaciones personalizadas.

Permitir conversiones de unidades.

Ejemplo:

Una caja puede contener determinada cantidad de unidades.

La conversión debe ser configurable y explícita.

No asumir cantidades fijas.

---

# 10. CÓDIGOS DE BARRAS Y ESCANEO

El escaneo es una función fundamental.

## 10.1 PC

Permitir:

- Escáner USB.
- Escáner Bluetooth.
- Escáner que funcione como teclado.
- Cámara.
- Ingreso manual.
- Búsqueda de producto.

Priorizar compatibilidad con lectores convencionales.

## 10.2 Android

Permitir escaneo mediante cámara.

Implementar:

- Escaneo continuo.
- Lectura rápida.
- Indicador visual.
- Confirmación sonora opcional.
- Control de lecturas duplicadas.
- Búsqueda de producto.
- Registro de productos sin código.

## 10.3 POS

Cuando se escanea un producto:

- Si no está en la venta, añadirlo.
- Si ya está en la venta, incrementar cantidad.
- Actualizar el total.
- Mostrar el producto identificado.
- Permitir corregir cantidades.

Evitar que una sola lectura accidental incremente varias veces la cantidad.

## 10.4 Contextos de escaneo

Separar los siguientes usos:

1. Escaneo de venta.
2. Escaneo de inventario.
3. Escaneo de compras.
4. Escaneo para registrar productos.
5. Escaneo para conteo físico.
6. Escaneo para ajustes.

Cada módulo debe tener su propio comportamiento.

---

# 11. INVENTARIO

Crear un sistema de inventario confiable.

Funciones:

- Stock actual.
- Entradas.
- Salidas.
- Ajustes.
- Devoluciones.
- Compras.
- Ventas.
- Inventario físico.
- Conteos.
- Diferencias.
- Historial.
- Lotes.
- Vencimientos.
- Stock mínimo.
- Alertas.

## Trazabilidad

Cada movimiento debe registrar:

- Producto.
- Cantidad.
- Tipo de movimiento.
- Fecha.
- Usuario.
- Dispositivo.
- Motivo.
- Referencia a la operación que lo originó.

No modificar el stock sin registrar el movimiento correspondiente.

## Alertas

Mostrar:

- Stock bajo.
- Productos agotados.
- Productos próximos a vencer.
- Productos vencidos.
- Diferencias de inventario.

Permitir configurar anticipación para alertas de vencimiento.

---

# 12. COMPRAS

Crear un módulo de compras y recepción.

Funciones:

- Registrar proveedores.
- Crear compras.
- Añadir productos.
- Escanear productos.
- Registrar cantidades.
- Registrar costos.
- Registrar lotes.
- Registrar vencimientos.
- Recepción parcial.
- Recepción completa.
- Compras pendientes.
- Cuentas por pagar.
- Pagos.
- Historial.

Una compra pendiente no debe incrementar automáticamente el stock.

Solo las cantidades recibidas deben ingresar al inventario.

La recepción debe generar movimientos de inventario trazables.

---

# 13. PUNTO DE VENTA

Crear un POS profesional, rápido y fácil de usar.

Debe incluir:

- Escaneo.
- Búsqueda.
- Carrito.
- Cantidades.
- Precios.
- Descuentos autorizados.
- Cliente.
- Medios de pago.
- Venta al contado.
- Venta al crédito.
- Pagos mixtos cuando se habiliten.
- Notas de pedido.
- Impresión.
- Historial.
- Devoluciones.
- Anulaciones.

## Experiencia de venta

El usuario debe poder:

1. Abrir una venta.
2. Escanear productos.
3. Añadir varios productos.
4. Modificar cantidades.
5. Seleccionar cliente.
6. Seleccionar medio de pago.
7. Confirmar.
8. Imprimir el documento correspondiente.

Reducir al mínimo los pasos innecesarios.

---

# 14. MEDIOS DE PAGO

Medios iniciales:

- Efectivo.
- Yape.
- Plin.
- Billeteras digitales.
- Transferencias.

No implementar tarjetas como medio inicial.

Permitir agregar medios de pago posteriormente.

Diferenciar:

- Venta.
- Pago recibido.
- Ingreso de caja.
- Deuda pendiente.

Permitir pagos mixtos si se habilitan.

No registrar automáticamente como efectivo una venta pagada mediante transferencia o billetera digital.

---

# 15. CLIENTES Y CRÉDITO

Implementar:

- Registro de clientes.
- Contacto.
- Historial.
- Ventas.
- Crédito.
- Pagos.
- Abonos.
- Saldos.
- Vencimientos.
- Cuentas por cobrar.

El sistema debe permitir pagos parciales.

Los saldos deben calcularse mediante movimientos.

No permitir alterar deudas directamente sin registrar una operación.

---

# 16. PROVEEDORES Y CUENTAS POR PAGAR

Implementar:

- Registro de proveedores.
- Datos de contacto.
- Compras.
- Historial.
- Deudas.
- Pagos.
- Abonos.
- Saldos pendientes.

Los pagos deben quedar vinculados a sus documentos y operaciones.

---

# 17. CAJA

Implementar:

- Apertura.
- Fondo inicial.
- Ingresos.
- Egresos.
- Gastos.
- Arqueo.
- Cierre.
- Diferencias.
- Historial.

Cada movimiento debe registrar:

- Usuario.
- Fecha.
- Concepto.
- Monto.
- Medio de pago.
- Caja o turno correspondiente.

Permitir cierres por usuario o turno.

No permitir modificar cierres sin autorización y trazabilidad.

---

# 18. NOTAS DE PEDIDO

Crear notas de pedido internas, no tributarias.

El diseño debe ser moderno y sofisticado.

Incluir:

- Logo.
- Nombre del negocio.
- Número correlativo.
- Fecha.
- Cliente.
- Productos.
- Cantidades.
- Precios.
- Total.
- Observaciones.
- Usuario responsable.
- Estado.

Permitir imprimir en:

- A4.
- Ticket de 58 mm.

Diferenciar claramente las notas internas de documentos tributarios.

No presentar una nota de pedido como boleta o factura.

---

# 19. IMPRESIÓN

Impresoras existentes:

- Epson L460 A4.
- Éterma térmica de 58 mm.
- Conexión por cable y Bluetooth.

Implementar plantillas específicas.

## A4

Para:

- Reportes.
- Notas.
- Documentos internos.
- Documentos comerciales autorizados.

## 58 mm

Para:

- Tickets.
- Notas compactas.
- Resúmenes de venta.

## Etiquetas

Para:

- Productos.
- Códigos de barras.
- Precios opcionales.

Validar compatibilidad real en Windows y Android.

No asumir que los mecanismos de impresión son iguales en ambos sistemas.

Probar:

- Bluetooth.
- USB.
- Drivers.
- Tamaño de papel.
- Márgenes.
- Cortes.
- Caracteres especiales.
- Logo.
- Tickets largos.

---

# 20. ETIQUETAS

Crear un módulo de etiquetas.

Funciones:

- Generar código de barras.
- Registrar código.
- Imprimir.
- Reimprimir.
- Elegir formato.
- Incluir nombre.
- Incluir precio opcional.
- Incluir código.
- Generar etiquetas para productos sin código.

No generar códigos duplicados.

---

# 21. USUARIOS Y PERMISOS

Implementar:

- Inicio de sesión.
- Usuarios individuales.
- Roles.
- Permisos.
- Administrador.
- Cajero.
- Inventario.
- Supervisor.

Registrar auditoría de:

- Ventas.
- Anulaciones.
- Descuentos.
- Ajustes.
- Compras.
- Cambios de precio.
- Pagos.
- Cierres.

Proteger operaciones sensibles.

No almacenar contraseñas en texto plano.

No incluir credenciales SUNAT en código, documentación o repositorios.

---

# 22. REPORTES

Crear reportes de:

- Ventas.
- Compras.
- Inventario.
- Productos más vendidos.
- Stock mínimo.
- Vencimientos.
- Gastos.
- Caja.
- Cuentas por cobrar.
- Cuentas por pagar.
- Actividad por usuario.
- Movimientos de inventario.

Diferenciar correctamente:

- Venta.
- Ingreso de dinero.
- Utilidad.
- Pago.
- Deuda.
- Gasto.

No confundir ingresos con ganancias.

---

# 23. SUNAT Y FUTURA FACTURACIÓN

El negocio indica estar actualmente en Nuevo RUS.

No asumir automáticamente que puede emitir todos los tipos de comprobantes.

Antes de implementar el módulo tributario:

1. Verificar normativa peruana vigente.
2. Confirmar régimen.
3. Confirmar documentos permitidos.
4. Confirmar requisitos.
5. Confirmar mecanismos de emisión.
6. Diseñar el módulo tributario independiente.

Preparar la arquitectura para futuras necesidades.

No desarrollar una integración tributaria sin validar previamente su legalidad y funcionamiento.

No incluir contraseñas SUNAT en archivos o código.

---

# 24. SEGURIDAD Y RESPALDOS

Implementar:

- Autenticación.
- Roles.
- Permisos.
- Auditoría.
- Copias de seguridad.
- Recuperación.
- Protección de datos.
- Gestión segura de secretos.
- Control de sesiones.

El sistema debe poder recuperar información ante fallos.

---

# 25. FASES DE DESARROLLO

## Fase 0: Planificación

- Revisar requisitos.
- Inspeccionar video.
- Definir arquitectura.
- Diseñar pantallas.
- Diseñar base de datos.
- Validar impresoras.
- Preparar prototipo.

## Fase 1: Fundamentos

- Aplicación base.
- Usuarios.
- Configuración.
- Base local.
- Backend.
- API.
- Sincronización inicial.

## Fase 2: Productos e inventario

- Catálogo.
- Categorías.
- Unidades.
- Presentaciones.
- Códigos.
- Stock.
- Lotes.
- Vencimientos.

## Fase 3: POS

- Ventas.
- Escaneo.
- Carrito.
- Medios de pago.
- Notas.
- Impresión.

## Fase 4: Compras y caja

- Proveedores.
- Compras.
- Recepción.
- Caja.
- Gastos.
- Arqueos.

## Fase 5: Clientes y crédito

- Clientes.
- Deudas.
- Abonos.
- Cuentas por cobrar.

## Fase 6: Reportes

- Dashboard.
- Reportes.
- Alertas.
- Auditoría.

## Fase 7: Pruebas y despliegue

- Pruebas PC.
- Pruebas Android.
- Pruebas offline.
- Sincronización.
- Impresión.
- Escaneo.
- Copias de seguridad.
- Instalación.

## Fase 8: Evolución

- Funciones tributarias.
- Multi-local.
- Nuevas integraciones.
- Funciones avanzadas.

---

# 26. METODOLOGÍA DE DESARROLLO

Trabaja de manera profesional y ordenada.

Antes de desarrollar cada fase:

1. Revisar requisitos.
2. Definir alcance.
3. Diseñar.
4. Implementar.
5. Probar.
6. Documentar.
7. Solicitar aprobación.

No comenzar una fase nueva hasta que la anterior tenga sus criterios de aceptación cumplidos.

Mantener documentación técnica.

No entregar funcionalidades incompletas como si estuvieran terminadas.

No afirmar que algo funciona sin haberlo probado.

No inventar resultados de pruebas.

No ignorar errores.

No cambiar la arquitectura sin justificarlo y solicitar aprobación.

---

# 27. CRITERIOS GENERALES DE ACEPTACIÓN

El sistema será considerado satisfactorio cuando:

- Funcione en Windows.
- Funcione en Android.
- Tenga interfaces adaptadas.
- Permita trabajar offline.
- Sincronice correctamente.
- Evite duplicar ventas.
- Registre movimientos de stock.
- Controle lotes y vencimientos.
- Permita compras y ventas.
- Gestione caja.
- Gestione clientes y crédito.
- Imprima documentos.
- Escanee códigos.
- Proteja operaciones.
- Mantenga historial.
- Sea estable.
- Sea fácil de usar.
- Tenga documentación.
- Pueda instalarse y utilizarse en el negocio.

---

# 28. INSTRUCCIÓN FINAL

Comienza revisando toda la documentación disponible.

No empieces a desarrollar todo el sistema inmediatamente.

Primero presenta:

1. Análisis del proyecto.
2. Arquitectura recomendada.
3. Tecnologías elegidas.
4. Estructura del proyecto.
5. Modelo de datos inicial.
6. Plan de implementación.
7. Riesgos.
8. Decisiones pendientes.
9. Primer prototipo o fase inicial.

Explica cualquier decisión que pueda afectar significativamente el sistema.

Cuando la planificación esté aprobada, comienza el desarrollo por fases.

Tu objetivo final es entregar un sistema funcional, profesional, confiable y personalizado para La Esquinita Orgánika, preparado para operar en PC Windows y Android, con sincronización, POS, inventario, compras, caja, clientes, impresión y crecimiento futuro.
