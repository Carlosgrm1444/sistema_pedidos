# Sistema de pedidos

Aplicación Flutter del Grupo 5. En esta versión usa Firebase Authentication
(Google) y Cloud Firestore en el proyecto `sistema-pedidos-grupo5-2026`, dentro
del plan Spark sin facturación. El icono y la pantalla de inicio usan
`assets/brand/mark.png`.

## Qué hace

- Google registra al usuario con rol **sin permisos**; un administrador le da
  acceso como administrador o colaborador.
- El administrador crea y asigna clientes, administra usuarios y estados, ve
  todos los pedidos y confirma la entrega con un botón y diálogo específicos.
- El colaborador ve únicamente sus clientes y sus pedidos. Puede registrar
  productos y categorías, crear pedidos y moverlos entre estados que no sean
  «Entregado». No puede registrar clientes ni confirmar entregas.
- Los productos guardan su categoría y precio. Cada línea de pedido conserva
  una copia del precio al momento de crear el pedido; cambios futuros al
  catálogo no alteran el total histórico.
- Los catálogos permiten crear, editar y activar/desactivar elementos. Los
  estados se pueden renombrar, añadir y reordenar por ponderación. «Entregado»
  siempre se establece desde el botón de confirmación.
- El resumen muestra indicadores y gráficas simples de pedidos e importes,
  filtrables por colaborador y cliente para el administrador. Todavía no se
  cargaron datos simulados; esos indicadores parten vacíos.
- La interfaz se adapta a pantallas grandes y pequeñas y permite tema claro u
  oscuro.

La cuenta `carlosgabrielrm1444@gmail.com` es el administrador inicial. Debe
entrar una vez con Google para crear su perfil; las demás cuentas quedarán
pendientes hasta que él les asigne un rol. Si el administrador inicial debe ser
otro correo, hay que cambiar **tanto** `bootstrapAdminEmail` en `lib/data.dart`
como `bootstrapAdmin()` en `firestore.rules` y volver a desplegar las reglas.

## Requisitos y ejecución

Instala Flutter y comprueba el entorno con `flutter doctor`. El proyecto se
configuró con Flutter 3.41.5. Luego:

```bash
flutter pub get
flutter run -d chrome
```

Se debe elegir `chrome` explícitamente si hay un teléfono conectado; ejecutar
`flutter run` a secas podría iniciar Android. Firebase Authentication tiene autorizado
`localhost` para la prueba web. Si el navegador bloquea ventanas emergentes,
autoriza la ventana de Google.

En un Android conectado:

```bash
flutter run -d ID_DEL_DISPOSITIVO
```

Cada integrante que compile Android con **su propio equipo o clave de firma**
debe registrar el SHA-1 de esa clave en Firebase Authentication/Configuración
del proyecto y actualizar `android/app/google-services.json`. La clave de
depuración de este equipo ya está registrada. En iOS y macOS se incluyó la
configuración OAuth, pero sus compilaciones aún deben verificarse en una Mac.
Windows usa el flujo de Firebase Auth y también requiere una prueba en Windows.
Los plugins oficiales usados no ofrecen Linux nativo; en Linux se usa la versión
web en Chrome.

Para compilar y verificar:

```bash
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

El resultado web queda en `build/web`. No subas esa carpeta al repositorio.

## Firebase

La configuración de plataformas está en `lib/firebase_options.dart`; las
reglas de acceso, en `firestore.rules`. No cambies las reglas únicamente en la
consola: el archivo del repositorio es la fuente para el equipo. Para desplegar
la configuración desde una cuenta con permisos de administrador:

```bash
npx --yes firebase-tools@15.32.1 login
npx --yes firebase-tools@15.32.1 deploy --only auth,firestore:rules
```

Los catálogos y pedidos se almacenan en Cloud Firestore. No se necesita una
base de datos local. Desactivar un cliente, producto o categoría evita usarlo
en nuevas capturas sin borrar pedidos históricos. Cuando un administrador
reasigna un cliente, la aplicación transfiere sus pedidos existentes al nuevo
colaborador. Para catálogos enormes, esa actualización puede tomar varias
operaciones y debe dejarse terminar antes de salir.

## Clonar y trabajar en equipo

```bash
git clone https://github.com/Carlosgrm1444/sistema_pedidos.git
cd sistema_pedidos
git switch --track origin/carlos
flutter pub get
```

La versión nueva se desarrolla en `carlos`. Hasta que se integre a `main`, los
compañeros que quieran probarla deben cambiar a esa rama. Cada integrante
continúa trabajando en su rama al hacer modificaciones:

```bash
# Carlos
git switch carlos

# Memo, primera vez después de clonar
git switch --track origin/memo

# Meño, primera vez después de clonar (incluye ñ)
git switch --track origin/meño
```

Para guardar y subir cambios en tu rama:

```bash
git branch --show-current
git pull --rebase origin NOMBRE_DE_TU_RAMA
git status
git add .
git commit -m "Describe brevemente el cambio"
git push origin NOMBRE_DE_TU_RAMA
```

Sustituye `NOMBRE_DE_TU_RAMA` por `carlos`, `memo` o `meño`. No subas
directamente a `main`; integra el trabajo mediante un pull request.
