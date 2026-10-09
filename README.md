# Salud ULV App

Aplicación Flutter para seguimiento de salud y actividad física.

## Configuración segura

La aplicación carga la URL pública del backend desde el archivo `.env`.
Crea el archivo a partir de `.env.example` y ajusta `API_URL`:

```powershell
Copy-Item .env.example .env
flutter run
```

En Windows o web local se puede usar `http://localhost:3030`. En el emulador
Android debe usarse `http://10.0.2.2:3030`. Para generar una versión de
producción, cambia primero `API_URL` por la URL HTTPS desplegada y ejecuta:

```powershell
flutter build appbundle --release
```

`API_URL` debe usar HTTPS en builds release. Las rutas del proxy OTP tienen los
valores predeterminados `/auth/otp/send` y `/auth/otp/verify`. Sólo si el backend
publica rutas distintas deben configurarse con `OTP_SEND_PATH` y
`OTP_VERIFY_PATH`; estas rutas no son secretos.

Nunca agregues contraseñas, tokens, claves privadas o credenciales OTP al
archivo `.env`: se empaqueta dentro de la aplicación y sus valores se pueden
extraer. Las credenciales OTP pertenecen exclusivamente al backend.

## Requisitos

- Flutter estable compatible con Dart 3.12 o posterior. El lockfile actual
  requiere Flutter 3.44 o posterior.
- Backend Salud ULV configurado y accesible mediante HTTPS.

## Autenticación de API y sincronización

Las operaciones de grupos, antropometría y ejercicios leen el JWT guardado en
`flutter_secure_storage` y envían `Authorization: Bearer <token>`. Si no existe
una sesión, la petición falla antes de contactar al servidor.

Las categorías compartidas con el backend son:

- `1`: caminata
- `2`: carrera
- `3`: ciclismo

La base SQLite usa la versión 3. Al abrir una instalación anterior migra el
catálogo local y actualiza las actividades existentes sin borrarlas. Al entrar
al inicio con conexión, la app intenta sincronizar las actividades pendientes;
sólo marca un registro como sincronizado después de una respuesta HTTP `2xx`.

## Firma Android de producción

1. Copia `android/key.properties.example` como `android/key.properties`.
2. Crea o usa un keystore de carga y completa sus cuatro valores reales.
3. Conserva ambos archivos fuera del control de versiones y en un respaldo
   seguro.

Los builds `release` fallan de forma explícita si falta esta configuración; la
aplicación nunca usa una firma de depuración como sustituto silencioso.

## Verificación

```powershell
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
dart tool/validate_motion_tracking.dart
```

El flujo `.github/workflows/flutter-ci.yml` crea un `.env` de prueba a partir de
`.env.example`, ejecuta estas comprobaciones y compila un APK de depuración sin
credenciales.

## Lista de salida a producción

- Ejecutar las verificaciones anteriores con un SDK compatible.
- Probar una caminata real, una sesión estacionaria moviendo únicamente el
  teléfono y un recorrido con señal GPS intermitente.
- Confirmar en Android e iOS los estados concedido, denegado y recuperación
  desde Ajustes. Los diálogos del sistema sólo se solicitan una vez; después se
  muestra la ruta de recuperación.
- Revisar modos Sistema, Claro y Oscuro, incluido el reinicio de la app.
- Configurar en `.env` el `API_URL` HTTPS de producción y construir Android con
  el keystore de carga.
- Verificar `/status`, registro, OTP, inicio de sesión, cambio de contraseña,
  antropometría y eliminación de cuenta contra el backend desplegado.
