# ADR-0002 — Sincronización propia por comandos (outbox + pull versionado)

Fecha: 2026-11-04 · Estado: **aceptada**

## Contexto

Pocos dispositivos (tablet + PC, quizá un celular), operaciones mayormente de solo-agregar (ventas, movimientos, pagos) y requisito explícito de no sobrescribir datos, conservar historial, detectar conflictos y mostrar el estado.

## Opciones

| Opción | Evaluación |
| --- | --- |
| **Protocolo propio: outbox de comandos + pull por versión** | Encaja con el dominio (operaciones, no filas); sin servicios extra; control total de conflictos. Requiere pruebas rigurosas |
| PowerSync | Robusto, pero suma un servicio a operar y su modelo de subida igual exige un backend propio que valide |
| Replicación fila a fila (last-writer-wins) | Viola "no sobrescribir indiscriminadamente" |

## Decisión

1. **Push**: la app guarda cada operación como comando inmutable en `outbox` dentro de la misma transacción local que la aplica a la proyección local. `POST /sync/push` envía lotes; el servidor aplica cada comando en una transacción y registra `op_id` en `sync_inbox` (único) → reenvíos devuelven `duplicate`.
2. **Pull**: cada tabla maestra/proyección en el servidor tiene `version BIGINT` de una secuencia global; `GET /sync/pull?since=N` devuelve cambios y el nuevo cursor.
3. **Stock local** = último saldo del servidor + movimientos locales no confirmados.
4. **Conflictos**: se registran en `sync_conflicts` con tipo (`negative_stock`, `duplicate_barcode`, `stale_price`, `closed_cash_session`), se notifican y se resuelven por un usuario con permiso. Las ventas consumadas nunca se rechazan por stock.
5. **Series por dispositivo** para correlativos generados offline.
6. Reintentos con espera creciente; errores en `sync_log`; estado visible en la UI.

## Consecuencias

- Batería de pruebas obligatoria: duplicados, reinicio a mitad de envío, dos dispositivos offline vendiendo el mismo producto, reloj del dispositivo desfasado.
