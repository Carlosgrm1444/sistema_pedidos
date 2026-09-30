# Sistema de pedidos

Proyecto Flutter del Grupo 5 para la materia Desarrollo de Aplicaciones
Móviles.

Actualmente incluye inicio de sesión, registro temporal de usuarios y una
pantalla para agregar productos a un pedido, indicar precio y cantidad, mostrar
el detalle y calcular el total. Los datos permanecen solamente en memoria
mientras la aplicación está abierta.

Usuario predeterminado para pruebas:

- Correo: `admin@sqlbros.com`
- Contraseña: `123`

## Requisitos

- Git.
- Flutter 3.41.5 o una versión compatible.
- Un emulador o dispositivo configurado para ejecutar Flutter.

Comprueba tu instalación con:

```bash
flutter doctor
```

## Clonar el proyecto

```bash
git clone https://github.com/Carlosgrm1444/sistema_pedidos.git
cd sistema_pedidos
flutter pub get
```

## Rama de cada integrante

Cada integrante debe trabajar solamente en su rama personal. La primera vez,
después de clonar el repositorio, debe ejecutar uno de estos comandos:

```bash
# Carlos
git switch --track origin/carlos

# Memo
git switch --track origin/memo

# Meño (el nombre de la rama incluye la letra ñ)
git switch --track origin/meño
```

Para confirmar la rama activa:

```bash
git branch --show-current
```

## Guardar y subir cambios

Antes de empezar a trabajar:

```bash
git pull --rebase origin NOMBRE_DE_TU_RAMA
```

Después de hacer cambios:

```bash
git status
git add .
git commit -m "Describe brevemente el cambio"
git push origin NOMBRE_DE_TU_RAMA
```

Sustituye `NOMBRE_DE_TU_RAMA` por `carlos`, `memo` o `meño`. No suban cambios
directamente a `main`; cuando una tarea esté lista, intégrenla mediante un pull
request en GitHub.

## Ejecutar y comprobar el proyecto

```bash
flutter run
flutter analyze
flutter test
```

El código principal de la aplicación está en `lib/main.dart`.
