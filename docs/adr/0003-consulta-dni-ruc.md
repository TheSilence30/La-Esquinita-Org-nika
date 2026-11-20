# ADR-0003 — Datos del cliente en la venta y consulta de DNI/RUC (decolecta)

Fecha: 2026-11-19 · Estado: **aceptada** (aprobada por el usuario el 2026-11-19)

## Contexto

- No todas las ventas son a crédito ni a clientes registrados, pero a veces el cliente pide que su nombre, DNI o RUC figure en el ticket. Lo pidió el usuario el 2026-11-19.
- El ticket sigue siendo un documento interno: "Constancia de venta – no es comprobante de pago" (CLAUDE.md §8). No es boleta ni factura; eso es la Fase 8.
- El usuario tiene una cuenta en **decolecta.com**, que consulta RENIEC (DNI) y SUNAT (RUC). Se probó el 2026-11-19 con un RUC público (SUNAT, `20131312955`):
  - `GET https://api.decolecta.com/v1/sunat/ruc?numero=…` con `Authorization: Bearer <token>` devolvió HTTP 200;
  - campos: `razon_social`, `numero_documento`, `estado`, `condicion`, `direccion`, `distrito`, `provincia`, `departamento`.
  - El DNI (`/v1/reniec/dni?numero=…`) se probará con un DNI real del usuario en la Fase 3.
- La consulta tiene costo por uso y el token es un secreto (CLAUDE.md §11).

## Opciones

| Opción | Evaluación |
| --- | --- |
| **La app consulta a nuestro servidor; el servidor consulta a decolecta** | El token no sale del servidor. Guarda las respuestas y no paga dos veces el mismo documento. Requiere conexión con el servidor |
| La app consulta a decolecta directamente | Más simple, pero el token iría dentro del APK: cualquiera puede extraerlo y gastar el saldo |
| Sin consulta: todo a mano | Sin costo, pero más lento y con errores de tipeo |

## Decisión

1. **Al cobrar: "¿Con datos del cliente?"**, con **No** por defecto (ticket normal).
   - Con **Sí** se escribe un DNI (8 dígitos) o un RUC (11 dígitos, con dígito verificador validado en core) y se toca **Buscar**.
   - DNI: devuelve el nombre.
   - RUC: devuelve razón social, dirección, estado y condición, con aviso si no está ACTIVO o HABIDO.
   - **Todos los campos son opcionales y editables.** Sin conexión, sin resultado o sin saldo, se escriben a mano o se dejan vacíos. La venta **nunca** se bloquea por la consulta.
2. **Proxy en el servidor**: `GET /lookup/dni/{n}` y `GET /lookup/ruc/{n}`, con sesión iniciada.
   - El servidor llama a decolecta con `DECOLECTA_API_TOKEN` (variable de entorno, solo en `.env`).
   - Guarda la respuesta en `doc_lookups` (documento, tipo, datos, fecha) y la reutiliza; el RUC se refresca a los 30 días.
   - Límite por usuario para que un error no agote el saldo.
3. **Qué se guarda**:
   - Los datos del cliente quedan **en esa venta** (`sales.customer_doc_type`, `customer_doc_number`, `customer_name`, `customer_address`) para reimprimir el ticket.
   - Una casilla **"Registrar como cliente"** lo agrega a `customers`. Es obligatoria para vender a crédito (Fase 5).
   - No se registra a nadie sin esa casilla: se guarda el mínimo de datos personales (Ley 29733).
4. **Ticket**: imprime "Cliente: … · DNI/RUC …" debajo de la leyenda obligatoria, que no cambia.
5. Va en la **Fase 3 (POS)**. Los clientes registrados con crédito siguen en la Fase 5.

## Consecuencias

- Pruebas en core: validación de DNI y RUC (dígito verificador).
- Pruebas en servidor: consulta guardada que no vuelve a llamar a decolecta, error o falta de saldo de decolecta (la venta sigue), y el token que nunca aparece en respuestas ni en logs.
- La búsqueda necesita internet y el servidor. Sin conexión, el campo se llena a mano (offline-first, ADR-0002).
- `docs/modelo-datos.md` agregará las columnas de `sales` y la tabla `doc_lookups` al diseñar la Fase 3.
- El token del usuario se compartió en una conversación con Claude. Conviene **regenerarlo** en decolecta antes de producción y poner el nuevo solo en el `.env` del servidor.
