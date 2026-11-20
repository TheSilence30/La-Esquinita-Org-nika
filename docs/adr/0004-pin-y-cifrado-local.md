# ADR-0004 — PIN sin conexión y cifrado de la base local

Fecha: 2026-11-20 · Estado: **aceptada** (decisión del usuario del 2026-11-20)

## Contexto

- Sin conexión, el usuario entra con su **PIN** de 4 a 6 dígitos y abre una sesión guardada en el equipo de hasta 7 días (decisión del 2026-11-19). Para verificar el PIN sin el servidor, el equipo necesita el `pin_hash` (Argon2id).
- Con el hash en el equipo, quien robe la tablet podría probar los 10⁶ PIN posibles fuera de la app. El hash solo no basta para proteger un PIN corto.
- La tablet trabaja en el mostrador y puede perderse. La PC queda en la tienda.

## Decisión

### 1. `pin_hash` baja al equipo, con límites

- `GET /sync/pull` envía el `pin_hash` de un usuario **solo al equipo donde ese usuario ya entró con contraseña** (hay un inicio de sesión suyo en `refresh_tokens` para ese `device_id`). A los demás equipos no les llega.
- El servidor **nunca** acepta el PIN para iniciar sesión: el PIN solo abre la sesión guardada en el equipo.
- **5 PIN fallidos** seguidos en el equipo obligan a entrar con contraseña, lo que exige conexión.
- El **contador de PIN fallidos** se guarda en la base local cifrada y **sobrevive a reiniciar la app** (cerrarla no da intentos nuevos). Solo vuelve a cero al entrar con el PIN correcto o con la contraseña (decisión del usuario, 2026-11-20).
- La sesión local dura **7 días** desde el último ingreso con contraseña; vencida, pide contraseña.
- Argon2id con los parámetros del servidor (19 MiB, t=2, p=1), **sin bajarlos**. Se mide en la tablet SM-X133: si la verificación pasa de **1 s**, se usa la implementación nativa (`cryptography_flutter`) con los mismos parámetros.

### 2. La base local va cifrada (SQLCipher)

- **Tablet (Android):** SQLCipher, con una llave aleatoria de 256 bits guardada en el **almacén seguro de Android** (Keystore).
- **PC (Windows):** SQLCipher, con la llave protegida con **DPAPI** (atada a la cuenta de Windows).
- La llave se crea en el primer arranque y nunca sale del equipo. Si se pierde, la base local se descarta y se vuelve a bajar del servidor: lo que aún no se envió se pierde, así que la app avisa antes de cualquier reinstalación.
- Los paquetes concretos se eligen y prueban en la tarea 4 de la Fase 1.

### 3. Administración desde la PC

- El Administrador puede **cambiar el PIN** de un usuario. El nuevo `pin_hash` baja en el siguiente pull; el anterior deja de servir en ese momento en los equipos conectados.
- El Administrador puede **cerrar las sesiones de un equipo perdido**: el servidor revoca sus refresh tokens y desactiva el equipo, que ya no puede enviar ni bajar datos. Si el equipo vuelve a conectarse, borra su sesión guardada.

## Consecuencias

- Mientras el equipo perdido siga sin conexión, alguien con un PIN válido puede abrir la sesión guardada hasta que venza (7 días). El cifrado impide leer la base fuera de la app, y los 5 intentos impiden adivinar el PIN dentro de ella.
- Las operaciones que el equipo perdido no llegó a enviar no se recuperan.
- La app suma SQLCipher y el acceso al almacén de llaves de cada plataforma.
- La verificación del PIN en la tablet queda **pendiente de prueba en dispositivo**.
