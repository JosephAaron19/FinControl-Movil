# Guía de Publicación en Google Play Store - FinControl

Esta guía detalla los pasos necesarios para configurar, firmar, compilar y publicar la aplicación **FinControl-Movil** en Google Play Store.

---

## 1. Prerrequisitos de Entorno

Asegúrate de contar con las siguientes herramientas configuradas en tu máquina de compilación:

- **Flutter SDK**: Versión `3.41.9` o superior.
- **Java Development Kit (JDK)**: Versión `17` o superior (se recomienda utilizar la máquina virtual JBR incluida en Android Studio para evitar problemas de compatibilidad).
- **Ruta del SDK sin espacios**: Asegúrate de que la ruta donde está instalado el SDK de Android no contenga espacios. De lo contrario, los comandos de NDK podrían fallar. En macOS, si usas Android Studio, puedes crear un enlace simbólico sin espacios:
  ```bash
  ln -sfn "/Applications/Android Studio.app" ~/android-studio
  ```

---

## 2. Configuración de Firma Digital (Keystore)

El proyecto utiliza un archivo keystore para firmar digitalmente la app en modo producción. Por razones de seguridad, **las llaves de firma y contraseñas no se suben al repositorio**.

### Paso 1: Generar el archivo Keystore (si no existe)
Si necesitas generar una nueva firma para producción (o actualizarla), ejecuta el siguiente comando utilizando la herramienta `keytool`:

```bash
keytool -genkey -v -keystore android/app/fincontrol-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias fincontrol
```
*Nota: Si estás en macOS con Android Studio, puedes invocar la herramienta del JBR:*
```bash
"~/android-studio/Contents/jbr/Contents/Home/bin/keytool" -genkey -v -keystore android/app/fincontrol-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias fincontrol
```

### Paso 2: Crear el archivo `key.properties`
Crea un archivo de texto plano llamado `key.properties` en la carpeta `android/` (`android/key.properties`). Define el siguiente contenido con las credenciales de tu firma:

```properties
storePassword=TU_CONTRASEÑA_DEL_KEYSTORE
keyPassword=TU_CONTRASEÑA_DE_LA_LLAVE
keyAlias=fincontrol
storeFile=app/fincontrol-release-key.jks
```

> [!WARNING]
> Ambos archivos (`android/app/fincontrol-release-key.jks` y `android/key.properties`) están incluidos en el `.gitignore` del proyecto. **Nunca los subas a repositorios de código públicos o privados**.

---

## 3. Versionamiento de la Aplicación

Antes de cada nueva subida a Google Play Console, debes incrementar los identificadores de versión en el archivo **`pubspec.yaml`** (Línea 4):

```yaml
version: 1.0.0+1
```

Estructura de la versión: `versionName+versionCode`
- `versionName` (`1.0.0`): La versión comercial visible al usuario en la tienda.
- `versionCode` (`1`): Un número entero secuencial e interno. Google Play Console no permite subir dos builds con el mismo `versionCode`.

**Ejemplo de incremento:**
- Primera subida: `version: 1.0.0+1`
- Segunda subida: `version: 1.0.1+2`
- Tercera subida: `version: 1.0.2+3`

---

## 4. Comandos de Compilación

Debido a que las últimas versiones del SDK NDK 28 poseen cambios en sus comandos de depuración (`strip`), la compilación se realiza ejecutando Gradle de manera directa en lugar de usar la CLI de Flutter. Esto previene errores en el proceso de empaquetado de símbolos nativos.

### Preparación del entorno y limpieza:
Ejecuta los siguientes comandos desde la raíz del proyecto para limpiar la caché de compilaciones previas y obtener dependencias actualizadas:
```bash
flutter clean
flutter pub get
```

### Generar el App Bundle (.aab) firmado para Google Play Store:
Navega a la carpeta `android/` y ejecuta el comando de Gradle:
```bash
cd android
JAVA_HOME="~/android-studio/Contents/jbr/Contents/Home" ./gradlew bundleRelease
```
El archivo `.aab` generado y firmado estará en:
👉 `build/app/outputs/bundle/release/app-release.aab`
*Este es el archivo que se debe subir a Google Play Console.*

### Generar el APK de prueba firmado (para instalación manual):
Para generar un APK firmado y probarlo directamente en teléfonos físicos:
```bash
cd android
JAVA_HOME="~/android-studio/Contents/jbr/Contents/Home" ./gradlew assembleRelease
```
El archivo `.apk` generado estará en:
👉 `build/app/outputs/apk/release/app-release.apk`

---

## 5. Permisos de Android Usados

La app utiliza los siguientes permisos necesarios para la marcación de asistencia, seguimiento GPS en segundo plano y subida de evidencias, configurados en `android/app/src/main/AndroidManifest.xml`:

- `INTERNET`: Comunicación con la API backend.
- `ACCESS_FINE_LOCATION` y `ACCESS_COARSE_LOCATION`: Captura de geolocalización exacta para marcación de entrada/salida y actividades.
- `ACCESS_BACKGROUND_LOCATION`: Registro de coordenadas en segundo plano (requiere justificación en Play Store).
- `FOREGROUND_SERVICE` y `FOREGROUND_SERVICE_LOCATION`: Ejecución del servicio en segundo plano para el rastreo de ubicación de jornada activa.
- `CAMERA`: Captura de fotos para incidencias y actividades en tiempo real.
- `READ_EXTERNAL_STORAGE` (API <= 32) y `READ_MEDIA_IMAGES` (API >= 33): Selección de fotos existentes de la galería para subida de evidencias.
- `POST_NOTIFICATIONS`: Notificaciones Push en Android 13+.

---

## 6. Errores Comunes y Soluciones

### Error: "Release app bundle failed to strip debug symbols from native libraries"
- **Causa**: Ocurre cuando se ejecuta `flutter build appbundle` usando versiones muy recientes del NDK (27 o 28) porque la CLI de Flutter posee un resolvedor de comandos antiguo que no mapea correctamente la ruta de `llvm-strip`.
- **Solución**: Compilar llamando a Gradle directamente desde la carpeta `android/` usando `./gradlew bundleRelease` (paso detallado en la Sección 4). Además, hemos configurado `debugSymbolLevel = "none"` en `build.gradle.kts` para evitar que Gradle intente forzar este proceso si no es necesario.

### Error: "Android sdkmanager not found" o "Android license status unknown"
- **Causa**: Faltan las herramientas de línea de comandos del SDK (`cmdline-tools`) o las licencias de Android no han sido aceptadas en la máquina.
- **Solución**:
  1. Instalar `cmdline-tools` (en el SDK de Android ya se encuentra instalado en `cmdline-tools/latest`).
  2. Ejecutar la aceptación de licencias estableciendo la variable `JAVA_HOME` correspondiente:
     ```bash
     JAVA_HOME="~/android-studio/Contents/jbr/Contents/Home" flutter doctor --android-licenses
     ```

### Error: "applicationId ya registrado por otra app"
- **Causa**: El identificador `com.finatech.fincontrol` ya está en uso en Google Play Store por otro desarrollador.
- **Solución**: Si esto ocurre, se debe definir un package name alternativo en `android/app/build.gradle.kts` (variable `applicationId` y `namespace`) y regenerar la firma.
