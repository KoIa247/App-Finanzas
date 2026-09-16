# Finanzas · app de finanzas personales para Peru

Lee los correos que tu banco te manda cada vez que gastas, los convierte en
movimientos clasificados y arma tu presupuesto solo. Todo pasa en el telefono:
no hay servidor, no hay cuenta que crear y tus datos no salen del dispositivo.

Es un port a Flutter del sistema que ya venia corriendo sobre Google Apps
Script y Sheets (`message (6).txt` y `code.html` en la carpeta de arriba). Los
parsers, el motor de reglas y la deteccion de suscripciones son portes fieles
de ese codigo, que lleva meses probado contra correos reales del BCP.

---

## Que hace

| | |
|---|---|
| **Lee tus correos** | Solo de los bancos que autorices. Permiso de lectura, nada mas. |
| **Clasifica solo** | 70 reglas de fabrica con comercios peruanos reales. Lo que corriges se vuelve regla. |
| **Detecta suscripciones** | Cargos que se repiten cada mes con el mismo monto y cerca del mismo dia. |
| **Presupuesto por categoria** | Con aviso cuando te acercas al limite. |
| **Ingresos del regimen peruano** | Quincena, fin de mes, gratificacion, CTS, utilidades. |
| **Patrimonio neto** | Liquidez, deuda e inversiones, en soles y dolares. |

### Lo que es especificamente de aca

- **Plantillas del BCP.** Las nueve que manda el Servicio de Notificaciones:
  consumo con tarjeta, pago de tarjeta, transferencia entre cuentas propias,
  transferencia a terceros, Yape, retiro en cajero, transferencia desde cajero,
  devolucion y pago de servicios.
- **Yape y Plin.** Un Plin viaja por el canal de la tarjeta de debito, pero no
  es una compra: es plata que le mandas a una persona. Se registra aparte para
  que no infle el consumo de tu tarjeta.
- **Soles y dolares.** Todo se consolida en soles con el tipo de cambio del
  dia, que la app busca sola.
- **"Este dinero no es mio".** Para la cuenta del negocio de un familiar que tu
  operas: el banco te manda el correo porque tu haces la operacion, pero esa
  plata nunca fue tuya. Esos correos no se registran.
- **Solo tarjeta de credito, de fabrica.** Los consumos de debito se ignoran
  salvo que los actives. Es lo que evita contar dos veces la misma compra.
- **Zona horaria de Lima fija (UTC-5).** Peru no usa horario de verano.

---

## Como correrlo

Hace falta **Flutter 3.27 o mas nuevo**. Verificado contra Flutter 3.47.3 y
Dart 3.13.3: `flutter analyze` sin observaciones, **61 pruebas en verde** y APK
de release compilado (55.5 MB, arm64-v8a + armeabi-v7a + x86_64).

Las carpetas `android/` e `ios/` estan en `.gitignore` porque las genera la
herramienta. Si clonas el repo desde cero:

```bash
cd mateito

# Genera android/, ios/, etc. Respeta lib/, test/ y pubspec.yaml.
flutter create . --project-name mateito --org com.mateito --platforms android,ios

flutter pub get
flutter analyze
flutter test          # la suite del parser y el clasificador
flutter run
```

La app arranca y funciona sin conectar Gmail: puedes registrar todo a mano.
Para que los gastos entren solos hay que hacer el paso de abajo.

### Si el proyecto vive dentro de OneDrive

OneDrive sincroniza y bloquea archivos mientras Gradle los esta escribiendo, y
eso rompe la compilacion de Android con errores tipo *"Could not close
incremental caches"* o *"Could not add entry to executionHistory.bin"*.

En esta maquina ya quedo resuelto asi:

- `android/gradle.properties` trae `kotlin.incremental=false`.
- `build/` y `android/.gradle/` son **uniones** (junctions) que apuntan a
  `D:\mateito-build` y `D:\mateito-gradle-state`. OneDrive no sigue los puntos
  de reparacion, asi que deja de sincronizar y de bloquear los temporales.

```powershell
mklink /J "...\mateito\build"            D:\mateito-build
mklink /J "...\mateito\android\.gradle"  D:\mateito-gradle-state
```

**Cuidado con `flutter clean`:** se lleva por delante la union de `build/`. Hay
que volver a crearla antes de compilar, o el APK sale sin `libapp.so`.

> **La trampa que cuesta encontrar.** Si borras `build/` a mano sin correr
> `flutter clean`, la cache de `.dart_tool/flutter_build/` sigue creyendo que el
> paso de AOT ya se hizo. Gradle arma el APK igual, sin `libapp.so`, y el build
> dice que todo salio bien: la app instala y se cierra al abrir. Para
> comprobarlo:
>
> ```bash
> unzip -l build/app/outputs/flutter-apk/app-release.apk | grep libapp.so
> ```
>
> Tienen que salir tres, uno por arquitectura. Si no salen, `flutter clean` y a
> compilar de nuevo.

Lo mas simple a largo plazo es mover el proyecto fuera de OneDrive.

---

## Conectar Gmail

El permiso que pide la app es `gmail.readonly`. No puede escribir, enviar ni
borrar nada, y solo mira los correos de los remitentes que tengas activos en
Ajustes.

**Tus usuarios no configuran nada de esto.** Tu creas un proyecto de Google
Cloud, y ellos solo tocan "Continuar con Google".

### 1. Proyecto y pantalla de consentimiento

1. Crea un proyecto en <https://console.cloud.google.com>.
2. Habilita la **Gmail API**.
3. En **OAuth consent screen**, tipo *External*. Agrega el scope
   `.../auth/gmail.readonly`.
4. Mientras este en *Testing*, agrega los correos de prueba en **Test users**.

### 2. Credenciales

**Android** — crea un OAuth client de tipo *Android* con tu package name
(`com.example.mateito` si no lo cambias) y el SHA-1 de tu keystore:

```bash
# Debug
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android
```

En Android no hace falta pegar el client id en el codigo: se resuelve por
package name + SHA-1. Recuerda agregar tambien el SHA-1 de tu keystore de
release antes de publicar.

**iOS** — crea un OAuth client de tipo *iOS*, descarga el plist y agrega a
`ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.TU-CLIENT-ID</string>
    </array>
  </dict>
</array>
```

Y pasa el client id en [`lib/providers.dart`](lib/providers.dart):

```dart
final autenticacionProvider = Provider<AutenticacionGmail>(
  (_) => AutenticacionGmail(clientIdIos: 'TU-CLIENT-ID.apps.googleusercontent.com'),
);
```

### 3. Antes de publicar: leelo

`gmail.readonly` es un **scope restringido**. Eso significa:

| Etapa | Que necesitas | Cuantos usuarios |
|---|---|---|
| Desarrollo y beta | Nada. Solo agregar testers en la consola | **100** |
| Publico | Verificacion de OAuth **+ evaluacion de seguridad CASA anual** (pagada) | Sin limite |

Los 100 usuarios de prueba alcanzan de sobra para validar el producto. El
salto a publico es el que hay que presupuestar: la evaluacion CASA la hace un
tercero acreditado, cuesta dinero y se renueva cada anio.

Dos cosas que ayudan a que esa revision salga bien, y que ya estan asi en el
codigo:

- La superficie de Gmail esta aislada en
  [`lib/data/gmail/`](lib/data/gmail/) y son dos endpoints. Es facil de
  auditar.
- **No se guarda ningun correo.** Se leen, se extrae el movimiento y se
  descartan. En la base solo queda el id del mensaje, que sirve para no
  registrar dos veces lo mismo.

Si mas adelante quieres etiquetar en Gmail los correos ya procesados (como
hacia la version de Apps Script), eso pide `gmail.modify`, que sube el nivel de
la evaluacion. Vale la pena pensarlo dos veces.

---

## Como esta armado

```
lib/
├── core/            texto, numeros, fechas, formato de plata, tema
├── domain/          los modelos: movimiento, cuenta, categoria, regla...
├── data/
│   ├── parser/      ★ lectura de los correos (BCP + generico)
│   ├── clasificador/★ motor de reglas, aprendizaje, suscripciones
│   ├── ingesta/     ★ la tuberia: Gmail → parser → anti duplicados → base
│   ├── gmail/       autenticacion y cliente REST
│   ├── fx/          tipo de cambio USD/PEN
│   ├── db/          esquema SQLite y catalogo de fabrica
│   └── repos/       acceso a datos y vistas para la interfaz
├── features/        las 8 pantallas
└── widgets/         tarjetas, fichas, dona y barras (dibujadas a mano)
```

Las tres carpetas con ★ son el corazon. Todo lo demas se puede rehacer; eso no.

**Sin generacion de codigo.** El SQL va a mano y no hay `build_runner`: se
clona, `pub get` y corre.

### Las tres capas anti duplicados

Un movimiento contado dos veces es peor que uno que falta, porque no se nota.
Por eso hay tres barreras, de la mas fuerte a la mas debil:

1. **Id del mensaje de Gmail.** Exacta, y se revisa antes de descargar nada.
2. **Banco + numero de operacion.** Atrapa el mismo aviso llegado por otro hilo.
3. **Huella** de banco, dia, importe, moneda, comercio y tarjeta. Atrapa los
   reenvios donde el banco cambia el id.

### Por que los saldos los escribes tu

La app **no** deriva tu saldo sumando correos, y es a proposito. El banco no
notifica el abono del sueldo ni lo que pagas en efectivo, asi que un saldo
calculado solo con correos siempre estaria mal, y estaria mal en silencio.

Lo que si es exacto y automatico son tus **gastos**, sus categorias y tu
presupuesto. El patrimonio neto lo copias de la app de tu banco cuando quieras.
Cuando un mes tiene pocos correos, el Dashboard te lo dice en vez de mostrar un
numero bonito y falso.

---

## Pruebas

```bash
flutter test
```

Cubren lo que de verdad se puede romper sin que nadie se de cuenta:

- **`nucleo_test.dart`** — que `"1,465"` sea mil cuatrocientos y `"12.50"` sean
  doce cincuenta; las cinco formas en que el BCP escribe una fecha; AM/PM;
  "setiembre" y "septiembre"; anios bisiestos.
- **`parser_bcp_test.dart`** — las nueve plantillas, el Plin que no se carga a
  la tarjeta, las tres politicas de transferencias a terceros, y los avisos que
  no son movimientos.
- **`clasificador_test.dart`** — que "Google Workspace" le gane al comodin
  "GOOGLE", que YouTube Premium caiga en Streaming, y que **ir al supermercado
  todos los meses no sea una suscripcion**.
- **`cuentas_ajenas_test.dart`** — las tres direcciones del dinero ajeno, que
  la marca sobreviva a desactivar la cuenta, que un retiro en cajero no se
  confunda con un traslado, y las huellas de deduplicacion.

---

## Lo que falta

- **Sincronizacion en segundo plano.** Hoy se lee al abrir la app o al tocar
  sincronizar. Para que un cargo aparezca solo hace falta `workmanager`, o un
  backend con Gmail watch + push si algun dia quieres notificaciones al
  instante.
- **Mas bancos.** El parser generico agarra importe y comercio de cualquier
  correo y lo manda a revision. Interbank, BBVA y Scotiabank estan listados y
  apagados: para cada uno hay que escribir su plantilla, igual que la del BCP.
- **Exportar a CSV.**
- **Dividir un movimiento** ya esta en el repositorio
  (`Repositorio.dividirMovimiento`) pero todavia no tiene pantalla.
