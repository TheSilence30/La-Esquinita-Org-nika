# La Esquinita Orgánika — Sistema de ventas e inventario

Sistema de POS, inventario, compras, caja, clientes, notas de pedido e impresión para La Esquinita Orgánika (Puente Piedra, Lima). Tablet Android como plataforma principal y PC Windows, con funcionamiento offline y sincronización.

- Requisitos: [docs/ESPECIFICACION.md](docs/ESPECIFICACION.md)
- Plan por fases: [docs/PLAN.md](docs/PLAN.md)
- Fase en curso: [docs/FASE-ACTUAL.md](docs/FASE-ACTUAL.md)
- Decisiones: [docs/adr](docs/adr)
- Guía para Claude Code: [CLAUDE.md](CLAUDE.md)

## Stack

Flutter (Android + Windows) · drift/SQLite · Dart Frog · PostgreSQL 16 · Docker.

## Estructura

Monorepo con [pub workspaces](https://dart.dev/tools/pub/workspaces): un `dart pub get` en la raíz resuelve todo.

| Ruta | Contenido |
| --- | --- |
| `apps/esquinita_app` | App Flutter (Android + Windows) |
| `apps/server` | Servidor Dart Frog |
| `packages/esquinita_core` | Dominio en Dart puro, compartido |

## Comandos

```sh
dart pub get                                   # en la raíz
cd packages/esquinita_core && dart test
cd apps/esquinita_app && flutter test && flutter run
cd apps/server && dart test && dart_frog dev
```
