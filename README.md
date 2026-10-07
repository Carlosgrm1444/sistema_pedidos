# Sistema de pedidos — guía para el equipo

Aplicación de Flutter del Grupo 5 para organizar clientes, productos y pedidos.
Esta guía explica la versión actual de manera sencilla, para que cualquiera del
equipo pueda presentarla, ubicar sus partes y responder preguntas en clase.

La versión actual se trabaja en la rama `carlos`. El proyecto de Flutter se llama
`sistema_pedido`, aunque la carpeta descargada de GitHub se llama `sistema_pedidos`.

[Abrir la aplicación web](https://sistema-pedidos-grupo5-2026.web.app/)

## Por dónde empezar a estudiar

1. [Qué hace la aplicación](#qué-hace-la-aplicación).
2. [Cómo están divididos los archivos](#cómo-están-divididos-los-archivos).
3. [Qué sucede al abrir la app](#qué-sucede-al-abrir-la-app).
4. [Cómo funciona cada sección](#cómo-funciona-cada-sección).
5. [Las piezas de Flutter que utilizamos](#las-piezas-de-flutter-que-utilizamos).
6. [Preguntas que podrían hacernos en clase](#preguntas-que-podrían-hacernos-en-clase).
7. [Guion para demostrar la app](#guion-para-demostrar-la-app).
8. [Ejecutar el proyecto](#ejecutar-el-proyecto).
9. [Clonar y trabajar en equipo](#clonar-y-trabajar-en-equipo).
10. [Firebase y publicación web](#firebase-y-publicación-web).

## Qué hace la aplicación

Podemos explicarla así:

> Nuestra aplicación permite registrar productos con categoría y precio,
> asignar clientes a colaboradores y formar pedidos con cantidades y total.
> Cada pedido tiene un estado y solamente un administrador puede confirmar
> su entrega. El resumen muestra indicadores y gráficas calculados con esos
> pedidos. Entramos con Google y la información se guarda en Firebase.

Piensen en una tienda: el catálogo dice qué vendemos, los clientes dicen a quién
atendemos y el pedido es la lista de lo que solicita cada cliente.

### Quién puede hacer qué

| Acción | Sin permisos | Colaborador | Administrador |
| --- | --- | --- | --- |
| Entrar con Google y cerrar sesión | Sí | Sí | Sí |
| Usar el espacio de trabajo | No; aparece «Acceso pendiente» | Sí | Sí |
| Consultar clientes y pedidos | No | Sus clientes al crear pedidos; sus pedidos en la lista | Todos |
| Crear pedidos y cambiar estados no finales | No | Para sus clientes | Para cualquier cliente disponible |
| Registrar y editar productos y categorías | No | Sí | Sí |
| Crear, editar y asignar clientes | No | No | Sí |
| Administrar estados y sus colores | No | No | Sí |
| Asignar permisos a otros usuarios | No | No | Sí |
| Confirmar la entrega de un pedido | No | No | Sí, después de confirmar |
| Consultar el resumen | No | Sus pedidos | Todos, con filtros por colaborador y cliente |

Los productos y las categorías son catálogos compartidos. Lo que se separa por
colaborador son los clientes y sus pedidos.

La cuenta `carlosgabrielrm1444@gmail.com` es el administrador inicial. Las demás
cuentas aparecen en Usuarios después de entrar por primera vez con Google y
quedan sin permisos hasta que un administrador les asigne un rol.

## Cómo están divididos los archivos

El código principal está en la carpeta `lib/`. Dividirlo ayuda a encontrar cada
cosa sin colocar toda la aplicación en un solo archivo.

| Archivo | Explicación sencilla | Qué buscar ahí |
| --- | --- | --- |
| [lib/main.dart](lib/main.dart) | La puerta de entrada de la app. | Inicio, conexión a Firebase, login, acceso pendiente y cambio de tema. |
| [lib/workspace.dart](lib/workspace.dart) | El organizador del espacio de trabajo. | Menú, sección seleccionada, carga de listas y opciones según el rol. |
| [lib/panels.dart](lib/panels.dart) | Las pantallas donde trabajamos. | Resumen, pedidos, productos, categorías, clientes, estados, usuarios y formularios. |
| [lib/data.dart](lib/data.dart) | El encargado de leer y guardar información. | Conexión a los datos, precios, líneas del pedido y operaciones de Firebase. |
| [lib/design.dart](lib/design.dart) | Las reglas para que todo tenga el mismo aspecto. | Colores, temas, tarjetas, fondos, animaciones y mensajes de listas vacías. |
| [lib/feedback.dart](lib/feedback.dart) | Las pequeñas señales de la app. | Sonidos de selección, éxito y error, vibración y opción de silenciar. |
| [lib/firebase_options.dart](lib/firebase_options.dart) | La dirección del proyecto de Firebase. | Configuración para conectar cada plataforma con el mismo proyecto. |
| [firestore.rules](firestore.rules) | El control de acceso a la información. | Quién puede leer, guardar o confirmar una entrega. |
| [pubspec.yaml](pubspec.yaml) | La lista de herramientas y recursos. | Paquetes utilizados, logo, iconos y splash. |
| [firebase.json](firebase.json) | La configuración de publicación. | Carpeta web que se publica y configuración de Hosting. |

Otras carpetas importantes:

- `assets/brand/`: contiene el logo PNG `mark.png`.
- `web/`: página que carga Flutter, iconos del navegador y splash web.
- `android/`, `ios/`, `macos/`, `windows/` y `linux/`: archivos para ejecutar
  el proyecto en cada plataforma; tener la carpeta no significa que todas
  estén verificadas o que todos los paquetes funcionen en ella.
- `test/`: comprobaciones automáticas y capturas de referencia del login.
- `build/`: resultados generados al compilar. No es donde escribimos el código
  ni se debe subir al repositorio.

La relación principal entre los archivos es:

```text
main.dart → workspace.dart → panels.dart
  Acceso       Menú           Pantallas y formularios
                 ↓                    ↓
                         data.dart ↔ Firebase

design.dart da el estilo; feedback.dart da sonidos y señales.
```

## Qué sucede al abrir la app

1. `main()` prepara Flutter y abre `BootstrapApp`.
2. `BootstrapApp` conecta Firebase. Mientras espera muestra el logo y un
   indicador de carga; si falla, permite reintentar.
3. `OrderApp` prepara el tema claro u oscuro y carga las preferencias locales.
4. `AuthGate` comprueba si tenemos una sesión abierta. Es como el encargado
   de decidir qué puerta podemos cruzar.
5. Si no hemos entrado, muestra `LoginView`. El botón llama a
   `signInWithGoogle()` y Google identifica nuestra cuenta.
6. `ensureProfile()` crea el perfil si todavía no existe. Guarda nombre,
   correo y rol; no vuelve a crearlo en cada inicio.
7. Si el rol es `pending`, aparece `PendingView`, la pantalla de acceso
   pendiente. Si es `admin` o `collaborator`, abre `Workspace`.

Iniciar sesión y tener permisos son cosas distintas: Google confirma quién
eres; el rol de Firebase decide qué puedes hacer. La aplicación no tiene un
formulario propio de contraseña o registro con correo y contraseña.

`Workspace` escucha los cambios de las listas en Firebase. Cuando llegan datos
nuevos, actualiza la pantalla. El acceso también escucha el perfil: cuando el
administrador cambia un permiso, la app adapta el acceso y el menú.

En web, [web/index.html](web/index.html) muestra el splash y prepara la carga.
[web/flutter_bootstrap.js](web/flutter_bootstrap.js) carga el programa de Flutter
y limpia la caché web heredada para evitar ejecutar versiones anteriores.

## Cómo funciona cada sección

### Usuarios: dar acceso al equipo

`UsersPanel` muestra nombre, correo y permiso de las cuentas registradas.
Primero coloca a quienes no tienen permisos; después muestra administradores
y colaboradores, ordenados por nombre dentro de su grupo.

El administrador cambia el rol desde una lista desplegable. Esa acción llama a
`Store.setRole()` y guarda el cambio. La interfaz no permite cambiar el rol de
la propia cuenta desde esa lista, para evitar quitarse el acceso por accidente.

### Categorías: organizar productos

`CategoriesPanel` permite crear una categoría, cambiar su nombre y marcarla
como activa o inactiva. Por ejemplo: «Bebidas», «Papelería» o «Limpieza».
`Store.saveCategory()` realiza el guardado.

Una categoría se asigna al producto. Al preparar un pedido no necesitamos
volver a escribirla.

### Productos: definir qué vendemos y cuánto cuesta

`ProductsPanel` permite registrar y editar nombre, categoría, precio y estado
activo/inactivo. El formulario necesita nombre, categoría y precio válido.
No acepta precios negativos o texto como «hola»; sí permite un precio de cero.

`parsePrice()` convierte el precio escrito a centavos. Por ejemplo, `25.50`
se guarda como `2550`. `money()` hace lo contrario para mostrarlo como
`$25.50`. Usamos el punto para escribir decimales.

Guardar dinero en centavos facilita las sumas y multiplicaciones. No son
cantidades en otra moneda: es una forma interna de representar el mismo precio.

### Clientes: asignar a quién atiende cada colaborador

`ClientsPanel` permite al administrador crear y editar clientes, asignarles
un colaborador y activarlos o desactivarlos. También pueden quedar sin asignar;
para que un colaborador los vea, deben asignársele.

`assignedUid` identifica al usuario encargado del cliente. Un UID es el
identificador único de una cuenta, como su número de identificación dentro de
la app. Firebase usa ese dato para entregar a cada colaborador sus clientes y
pedidos.

Si el administrador reasigna un cliente, `Store.saveClient()` también actualiza
la asignación de sus pedidos existentes. Si cambia el nombre del cliente,
actualiza ese nombre en sus pedidos.

### Estados: identificar en qué parte está un pedido

`StatusesPanel` permite añadir estados, cambiar sus nombres, elegir un color y
subirlos o bajarlos en la lista. Los iniciales son En espera, En preparación,
Enviado y Entregado.

La ponderación (`rank`) funciona como un número de posición: un estado con
10 aparece antes que uno con 20. Las flechas intercambian esos números mediante
`swapStatusRank()`. Esto organiza las opciones; no obliga a pasar por cada
estado antes de elegir el siguiente.

El color se ve en el borde y los indicadores del pedido. El estado final tiene
el identificador interno `delivered`: aunque cambiemos su nombre, sigue siendo
la entrega y requiere el botón especial. No basta con crear otro estado que
también se llame «Entregado».

`seedStatuses()` crea los cuatro estados iniciales sólo si el catálogo está
vacío. No vuelve a agregarlos en cada inicio.

### Pedidos: juntar productos para un cliente

`OrdersPanel` muestra los pedidos. `OrderEditor` es el formulario que aparece
al pulsar «Nuevo pedido».

1. Elegimos un cliente activo.
2. Elegimos un producto activo cuya categoría también esté activa.
3. Escribimos una cantidad entera mayor que cero.
4. Pulsamos «Agregar producto». Se crea una línea en la lista del formulario.
5. Podemos agregar más líneas o quitar alguna antes de guardar.
6. La app muestra el total. Al pulsar «Guardar pedido», `Store.createOrder()`
   lo guarda en Firestore junto con el cliente, usuario y fechas.

Mientras estamos preparando el formulario, las líneas están en una lista
temporal. Firebase recibe el pedido cuando pulsamos «Guardar pedido».

La clase `OrderLine` representa un renglón del pedido. Por ejemplo:

```text
Producto: termo     Precio: $25.00     Cantidad: 3
Subtotal: $25.00 × 3 = $75.00

Otra línea: libreta a $10.00 × 2 = $20.00
Total del pedido: $75.00 + $20.00 = $95.00
```

En el código de `OrderLine`, la operación principal es:

```dart
int get subtotalCents => unitPriceCents * quantity;
```

`unitPriceCents` es el precio unitario en centavos y `quantity` es la cantidad.
El total suma los subtotales de todas las líneas.

Cada línea conserva una copia del nombre, categoría y precio usado al agregarla.
Si mañana cambiamos el precio del catálogo, el pedido anterior conserva su
importe. Es parecido a guardar un ticket de compra.

El pedido nuevo comienza en el estado `pending` (inicialmente llamado En espera)
si existe; si no, usa el primer estado disponible que no sea el final. El
colaborador responsable se toma de la asignación del cliente, aunque un
administrador sea quien capture el pedido.

En la lista podemos desplegar el detalle. El administrador filtra por
colaborador, cliente y estado; el colaborador filtra por estado dentro de sus
propios pedidos. El texto «N productos» cuenta renglones del pedido, no la suma
de unidades.

### Confirmar una entrega

La entrega se realiza con «Confirmar entrega», visible para administradores.
Primero aparece un diálogo; si cancelamos, no se registra la entrega.

Si confirmamos, `Store.deliverOrder()` guarda el estado final, la fecha y el
usuario que confirmó. Comprueba que no estuviera entregado ya, para evitar
confirmarlo dos veces. Después, la interfaz deja de ofrecer cambios de estado
para ese pedido.

### Resumen: entender los indicadores y gráficas

`OverviewPanel` calcula el resumen usando los pedidos que podemos ver y los
filtros seleccionados. Los valores se calculan; no están escritos a mano en las
tarjetas.

| Indicador | Qué significa |
| --- | --- |
| Pedidos | Cuántos pedidos hay en la selección. |
| Entregados | Cuántos tienen el estado final. |
| Pendientes | Todos los que aún no están entregados, incluso los enviados o en preparación. |
| Importe total | Suma del importe de esos pedidos, entregados o no. No es una medición de cobros o ganancias. |
| Promedio por pedido | Importe total dividido entre cantidad de pedidos. |
| Tasa de entrega | Entregados dividido entre pedidos y expresado en porcentaje. |
| Clientes activos | Clientes diferentes que aparecen en los pedidos seleccionados; aquí no se refiere al interruptor del catálogo. |
| Unidades solicitadas | Suma de las cantidades de todos los renglones. |

Ejemplo: si tenemos 10 pedidos y entregamos 4, la tasa de entrega es 40 % y
quedan 6 pendientes. Un pedido puede tener 2 renglones y 8 unidades en total:
son dos conteos diferentes.

Las gráficas muestran lo siguiente:

- **Actividad de los últimos 7 días:** pedidos creados cada día, incluyendo
  hoy. `_TrendPainter` dibuja los puntos, la línea y el área sombreada.
- **Salud del flujo:** representa la misma tasa de entrega con un anillo.
- **Pedidos por estado:** cuenta cuántos hay en cada estado.
- **Productos más solicitados:** muestra hasta seis nombres de productos con
  más unidades pedidas.
- **Actividad reciente:** muestra los cuatro pedidos más nuevos.

Los KPIs toman todos los pedidos seleccionados; solamente los puntos de la
gráfica de actividad se limitan a siete días. El texto bajo esa gráfica
actualmente muestra la cantidad total seleccionada, no sólo la de esos siete
días.

Se cargaron catálogos y pedidos de ejemplo para la presentación. Son datos
guardados en Firebase, no números falsos incrustados en las gráficas. Clonar
el proyecto no vuelve a generarlos. Sus fechas permanecen guardadas: conforme
pasen los días, los pedidos antiguos saldrán de la gráfica semanal.

### Diseño, temas y sonidos

`appTheme()` en `design.dart` define el aspecto azul y gris y sus variantes
clara y oscura. Así no necesitamos decidir el color de cada botón por separado.
El logo está en `assets/brand/mark.png` y se usa en el login, carga e iconos.

La interfaz mide el espacio con `MediaQuery` y `LayoutBuilder`. En móvil usa un
menú desplegable y apila las secciones; en escritorio muestra un menú lateral
y acomoda tarjetas en columnas. Los KPIs se distribuyen en dos columnas en
móvil y cuatro en pantallas amplias.

`MotionReveal` anima la aparición de elementos; `PolishedCard` cambia bordes y
sombras al pasar el puntero. `AnimatedSwitcher` suaviza el cambio de sección
y los indicadores tienen animaciones de progreso.

`AppFeedback` produce tonos cortos de selección, éxito y error. Los genera
localmente; no descarga música. En Android/iOS nativos compatibles también
intenta una pequeña vibración. El botón de sonido silencia los tonos; la vibración es
independiente. La disponibilidad de audio depende del navegador o dispositivo.

`SharedPreferences` recuerda el tema y la opción de sonido en ese dispositivo
o navegador. Los permisos y pedidos, en cambio, están en Firebase y se comparten
entre dispositivos.

### Qué guarda Firebase y cómo protege los datos

Usamos tres servicios con tareas diferentes:

- **Firebase Authentication:** reconoce la cuenta de Google.
- **Cloud Firestore:** guarda y entrega la información de la app.
- **Firebase Hosting:** publica la aplicación web para abrirla con un enlace.

Firestore agrupa la información en colecciones. Piensen en carpetas con fichas:

| Colección | Qué contiene |
| --- | --- |
| `users` | Nombre, correo y rol de cada usuario. |
| `categories` | Categorías y su estado activo/inactivo. |
| `products` | Productos, su categoría, precio y estado activo/inactivo. |
| `clients` | Clientes y el usuario al que se asignan. |
| `statuses` | Nombre, color y posición de los estados. |
| `orders` | Cliente, líneas, totales, responsables, estado y fechas del pedido. |

`Item` es la clase sencilla que usamos para representar una ficha recibida de
Firebase. Su `id` identifica el registro y `data` contiene sus datos. Métodos
como `text()`, `number()` y `date()` ayudan a leerlos.

Los métodos `watch...()` de `Store` escuchan los cambios. Los métodos
`save...()`, `createOrder()` y `deliverOrder()` guardan información.

Ocultar una opción del menú no es suficiente para protegerla. Por eso
`firestore.rules` también revisa el rol y la asignación antes de autorizar
operaciones. La app adapta lo que vemos y Firebase aplica las restricciones.

### Hasta dónde llega esta versión

Categorías, productos y clientes permiten crear, consultar, editar y
activar/desactivar. Los estados permiten crear, editar y ordenar. No hay botones
para borrar definitivamente registros. Desactivar conserva el historial y
evita seleccionar esos elementos en nuevos pedidos.

Antes de guardar un pedido podemos quitar líneas. Después de guardarlo, la
interfaz permite consultar sus detalles y gestionar su estado; todavía no tiene
un formulario para cambiar sus productos, cantidades o cliente, ni para borrar
el pedido. Tampoco incluye inventario de existencias, cobros o facturación.

## Las piezas de Flutter que utilizamos

Un **widget** es una pieza de la pantalla. Una pantalla se construye colocando
piezas dentro de otras: textos dentro de una tarjeta, tarjetas dentro de una
lista y esa lista dentro del espacio de trabajo.

| Pieza | Para qué sirve en esta app |
| --- | --- |
| `MaterialApp` | Configura la aplicación, los temas y la pantalla inicial. |
| `Scaffold` y `AppBar` | Dan la estructura de pantalla y su barra superior. |
| `Text`, `Icon` e `Image.asset` | Muestran textos, símbolos y el logo. |
| `Column`, `Row` y `Wrap` | Acomodan elementos verticalmente, horizontalmente o en varias filas. |
| `Padding`, `SizedBox` y `Expanded` | Controlan márgenes, separaciones y el espacio disponible. |
| `ListView` y `SingleChildScrollView` | Permiten desplazarnos cuando el contenido no cabe. |
| `TextField` y `TextEditingController` | Capturan y leen nombres, precios o cantidades. |
| `DropdownButtonFormField` | Permite elegir roles, clientes, productos o filtros. |
| `SwitchListTile` | Activa o desactiva un elemento de catálogo. |
| `FilledButton`, `OutlinedButton` e `IconButton` | Ejecutan acciones como guardar, agregar o editar. |
| `Dialog` y `AlertDialog` | Abren formularios y piden confirmación de entrega. |
| `ListTile` y `ExpansionTile` | Organizan registros y permiten abrir el detalle de un pedido. |
| `SnackBar` | Muestra mensajes breves de éxito o error. |
| `Drawer` | Muestra el menú lateral desplegable en móvil. |
| `CustomPaint` e indicadores de progreso | Dibujan la tendencia y las barras o el anillo del resumen. |

`TextEditingController` es un ayudante para leer el campo, no un widget visual.

### Algunas palabras del código, explicadas fácil

- **`build()`** describe cómo se debe ver un widget con los datos actuales.
- **`StatelessWidget`** recibe datos y dibuja; no guarda un estado propio
  cambiante. Ejemplo: `PendingView`.
- **`StatefulWidget`** tiene un estado que puede cambiar, como el formulario
  de pedido o la sección seleccionada del menú.
- **`setState()`** avisa a Flutter: «algo cambió; vuelve a dibujar esta parte».
  Lo usamos al agregar una línea, elegir un filtro o cambiar de sección.
- **`onPressed`, `onChanged` y `onTap`** son instrucciones que se ejecutan al
  pulsar un botón, cambiar una opción o tocar un elemento.
- **`Future`, `async` y `await`** permiten esperar una tarea, como guardar en
  Firebase. `FutureBuilder` muestra carga, resultado o error de esa tarea.
- **`Stream` y `StreamBuilder`** reciben novedades continuamente, como un
  cambio de sesión o de permiso.
- **`where()`** filtra una lista; **`sort()`** la ordena; **`fold()`** acumula
  valores, por ejemplo para sumar el total de los pedidos.
- **`dispose()`** libera recursos cuando dejan de usarse, como los
  controladores de texto y las conexiones que escuchan listas.

## Preguntas que podrían hacernos en clase

**¿Por dónde empieza el programa?** En `main()` de `lib/main.dart`. Después
inicia Firebase y decide qué pantalla mostrar según la sesión y el rol.

**¿Dónde está el formulario del pedido?** En `OrderEditor`, dentro de
`lib/panels.dart`. `_addLine()` agrega productos y `_save()` guarda el pedido.

**¿Dónde se calcula el total?** `OrderLine.subtotalCents` multiplica precio
por cantidad; el formulario y `Store.createOrder()` suman esos subtotales.

**¿Por qué cambiar el precio no altera pedidos anteriores?** Porque cada
línea guarda una copia del precio que usó al capturarse.

**¿Cómo sabe la app qué pedidos pertenecen a cada colaborador?** Compara
`assignedUid` con el identificador de la cuenta. `watchOrders()` hace esa
selección y las reglas de Firebase protegen el acceso.

**¿Por qué no se entrega desde la lista de estados?** Porque la entrega
requiere confirmar una acción especial y guardar quién la realizó y cuándo.

**¿Qué pasa si cerramos y volvemos a abrir?** Los datos guardados siguen en
Firestore. Un pedido que sólo estaba en el formulario, sin guardarse, no está
registrado. El tema y sonido se recuerdan localmente.

**¿Cómo cambiaríamos el color principal?** Revisando `brandBlue` y
`appTheme()` en `lib/design.dart`, donde se comparte el estilo de la app.

**¿Cómo se actualiza una lista sin volver a cargar todo?** `Store` escucha
Firebase y `Workspace` recibe esas novedades y actualiza las pantallas.

**¿Qué investigamos para construirla?** Podemos explicar `StreamBuilder`
para escuchar cambios, `LayoutBuilder` para acomodar pantallas, `CustomPaint`
para dibujar la gráfica y los servicios de Firebase. Cada integrante debe
elegir un ejemplo que realmente pueda ubicar y explicar en el código.

## Guion para demostrar la app

1. Abrir la web y explicar el login con Google y los roles.
2. Mostrar Usuarios: pendientes arriba, después administradores y colaboradores.
3. Mostrar una categoría, un producto con precio y un cliente asignado.
4. Crear un pedido de prueba: elegir cliente, agregar productos y explicar
   cantidad × precio. Usar un cliente de demo para la práctica.
5. Mostrar su detalle, el color del estado y los filtros. Cambiar un estado
   no final y después confirmar la entrega con una cuenta administradora.
6. Abrir Resumen y explicar una tarjeta, la tendencia semanal y el anillo
   de entregas. Probar un filtro de cliente o colaborador.
7. Cambiar tema y silenciar sonido. Reducir la ventana para mostrar la
   adaptación móvil.
8. En el editor, ubicar `main.dart`, `workspace.dart`, `panels.dart`,
   `data.dart` y `design.dart`, y decir en una frase qué hace cada uno.

Pueden repartir la explicación entre acceso/permisos, catálogos/pedidos y
resumen/diseño. Aun así, los tres deben entender el recorrido completo y
practicar al menos una modificación sencilla, como cambiar un texto visible.

## Ejecutar el proyecto

El proyecto se configuró con Flutter 3.41.5 y Dart 3.11.3. Instala Flutter y
revisa el entorno con `flutter doctor`. Desde la carpeta del proyecto:

```bash
flutter pub get
flutter run -d chrome
```

`flutter pub get` descarga los paquetes indicados en `pubspec.yaml`.
`flutter run -d chrome` abre la app en Chrome. Elegir el dispositivo evita que
`flutter run` a secas intente iniciar Android si hay un teléfono conectado.
Firebase permite `localhost` para pruebas web. Si Google no abre, revisa si el
navegador bloqueó su ventana emergente.

Para consultar dispositivos y ejecutar en un Android conectado:

```bash
flutter devices
flutter run -d ID_DEL_DISPOSITIVO
```

Sustituye `ID_DEL_DISPOSITIVO` por el identificador mostrado. En Android, cada
equipo o clave de firma necesita tener su SHA-1 registrado en Firebase y su
archivo `android/app/google-services.json` actualizado.

La configuración de iOS y macOS está incluida, pero sus compilaciones necesitan
verificarse en una Mac. Windows también requiere una prueba en Windows. Los
plugins de Firebase utilizados no ofrecen Linux nativo; en Linux ejecutamos
la versión web en Chrome.

### Cómo comprobamos el proyecto

```bash
flutter analyze
flutter test
flutter build web --release
flutter build apk --debug
```

`flutter analyze` revisa problemas del código. `flutter test` ejecuta pruebas
de precios y subtotales, de algunas pantallas y de capturas de referencia del
login. Estas comprobaciones ayudan, pero no prueban por sí solas el inicio de
sesión real con Google ni todos los permisos de Firebase.

`flutter build web --release` genera la web en `build/web`; el último comando
genera un APK de depuración si el entorno Android está preparado.

## Clonar y trabajar en equipo

Para descargar y estudiar la versión actual:

```bash
git clone https://github.com/Carlosgrm1444/sistema_pedidos.git
cd sistema_pedidos
git switch --track origin/carlos
flutter pub get
flutter run -d chrome
```

Las cuatro ramas son `main`, `carlos`, `memo` y `meño`. `main` se reserva para
trabajo integrado; la versión que explica esta guía está en `carlos` hasta que
se integre. Abrir una rama antigua puede mostrar otra versión de la app.

Para hacer cambios, cada integrante trabaja en su rama:

```bash
# Carlos; ya creada al seguir los pasos anteriores
git switch carlos

# Memo; primera vez después de clonar
git switch --track origin/memo

# Meño; primera vez después de clonar, incluye ñ
git switch --track origin/meño
```

Ejecuta sólo la opción que corresponde a tu cuenta. En las siguientes ocasiones
usa `git switch memo` o `git switch meño`, sin `--track`.

Si tu rama todavía no incluye la versión de `carlos`, guarda primero tus cambios
y después, estando en tu propia rama, integra esa versión:

```bash
git fetch origin
git merge origin/carlos
```

Si aparecen conflictos, resuélvanlos revisando el código con el equipo antes
de continuar. Cambiar de rama no trae automáticamente las mejoras de otra.

Para guardar y subir tu trabajo:

```bash
git branch --show-current
git status
git add .
git commit -m "Describe brevemente el cambio"
git pull --no-rebase origin NOMBRE_DE_TU_RAMA
git push origin NOMBRE_DE_TU_RAMA
```

Sustituye `NOMBRE_DE_TU_RAMA` por `carlos`, `memo` o `meño`. Revisa `git status`
antes de agregar archivos. `commit` guarda una versión local, `pull` trae e
integra cambios de la rama y `push` envía tu trabajo a GitHub. No subas
directamente a `main`; integra el trabajo mediante un pull
request, para que el equipo revise lo que se va a unir.

## Firebase y publicación web

El proyecto configurado es `sistema-pedidos-grupo5-2026`. No necesitamos montar
un servidor propio ni una base de datos local para usar la app.

La configuración de plataformas está en `lib/firebase_options.dart` y las
reglas de acceso están en `firestore.rules`. Las reglas del repositorio son la
referencia del equipo; si se cambian, deben publicarse en Firebase.

Para desplegar la configuración desde una cuenta autorizada:

```bash
npx --yes firebase-tools@15.32.1 login
npx --yes firebase-tools@15.32.1 deploy --only auth,firestore:rules --project sistema-pedidos-grupo5-2026
```

Si se cambia el administrador inicial, hay que modificar tanto
`bootstrapAdminEmail` en `lib/data.dart` como `bootstrapAdmin()` en
`firestore.rules`, y publicar las reglas. Los perfiles que ya existen conservan
su rol hasta que se cambie.

### Publicar una nueva versión web

Desde la rama con los cambios y con una cuenta autorizada para Firebase:

```bash
flutter pub get
flutter build web --release
npx --yes firebase-tools@15.32.1 login
npx --yes firebase-tools@15.32.1 deploy --only hosting --project sistema-pedidos-grupo5-2026
```

Cada cambio de código necesita una nueva compilación antes de publicar.
Hosting sirve los archivos de `build/web`; Google Authentication necesita
que el dominio esté autorizado. El dominio de este Hosting ya está configurado.

Guardar datos en Firestore, subir código a GitHub y publicar en Hosting son
tres acciones distintas: respectivamente cambian la información, el código
compartido y la versión web que abre el equipo.
