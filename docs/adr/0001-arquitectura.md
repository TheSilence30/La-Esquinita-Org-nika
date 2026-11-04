# ADR-0001 — Flutter + Dart en todo el stack, tablet primero

Fecha: 2026-11-04 · Estado: **aceptada**

## Contexto

- Plataforma principal: tablet Android (Galaxy Tab A11). Secundaria: PC Windows.
- Offline obligatorio en cada dispositivo, con sincronización (especificación §6).
- Interfaces independientes por plataforma con reglas de negocio compartidas (§4.3).
- Impresión térmica 58 mm por Bluetooth (Android) y USB (Windows); A4 en Epson L460.
- Un desarrollador asistido por Claude Code: el costo de mantenimiento pesa más que la popularidad.

## Opciones evaluadas

| Opción | Pros | Contras |
| --- | --- | --- |
| **Flutter (Android + Windows) + backend Dart** | Una app nativa para ambos; SQLite (drift) igual en los dos; dominio compartido con el servidor en el mismo lenguaje; Bluetooth y ML Kit nativos | Cámara en Windows débil (se usa lector USB); tablas de escritorio requieren buen widget; ecosistema backend Dart más pequeño |
| React + Capacitor + Tauri/Electron | Gran ecosistema web | Tres empaquetados; SQLite distinto por plataforma; offline-first más complejo |
| Kotlin (Android) + app Windows aparte | Máximo rendimiento Android | Dos bases de código, el doble de mantenimiento |
| PWA | Muy barata | Sin Bluetooth clásico; almacenamiento offline poco confiable para ventas |
| Flutter + backend NestJS | Backend maduro | Reglas de negocio duplicadas en Dart y TypeScript |

## Decisión

Flutter para la app (shells tablet y escritorio separados), drift/SQLite local, paquete `esquinita_core` en Dart puro compartido con un servidor **Dart Frog** sobre **PostgreSQL 16** con SQL explícito.

## Consecuencias

- Las reglas (totales, conversiones, FEFO, validaciones de comandos) se escriben una vez.
- El servidor usa SQL explícito para controlar transacciones, bloqueos (`FOR UPDATE`) e índices únicos.
- Los paquetes de impresión Bluetooth/USB se eligen tras el spike de Fase 0; se encapsulan detrás de `PrinterTransport` para poder cambiarlos.
