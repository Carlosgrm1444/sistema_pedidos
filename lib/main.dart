import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// Base de datos simulada en memoria para probar el registro y el login.
// En un proyecto real, esto se conectaría a Firebase o una API.
final Map<String, Map<String, String>> mockDatabase = {
  'admin@sqlbros.com': {
    'nombre': 'Memo',
    'apellidos': 'Admin',
    'password': '123',
  },
};

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portal de Oficina',
      theme: ThemeData(
        // Tema estilo oficina: Colores neutros, azules y grises
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // Azul corporativo
          background: Colors.grey[200], // Fondo gris claro para resaltar la tarjeta
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// ==========================================
// PANTALLA DE INICIO DE SESIÓN (LOGIN)
// ==========================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _errorMessage;

  void _login() {
    setState(() {
      _errorMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      final email = _emailCtrl.text;
      final password = _passwordCtrl.text;

      // Validación contra nuestra base de datos simulada
      if (mockDatabase.containsKey(email)) {
        if (mockDatabase[email]!['password'] == password) {
          // Login exitoso
          final nombre = mockDatabase[email]!['nombre']!;
          final apellidos = mockDatabase[email]!['apellidos']!;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(nombre: nombre, apellidos: apellidos),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Contraseña incorrecta.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Usuario no encontrado. Por favor, regístrese.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            // Restringe el ancho máximo para dar el efecto de formulario centrado
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.business,
                        size: 80,
                        color: Color(0xFF1E3A8A),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'SQL_BROS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Campo de Correo
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese su correo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo de Contraseña
                      TextFormField(
                        controller: _passwordCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese su contraseña';
                          }
                          return null;
                        },
                      ),

                      // Mensaje de Error
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Botón de Iniciar Sesión
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Iniciar Sesión'),
                      ),
                      const SizedBox(height: 16),

                      // Enlace a Registro
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text(
                          '¿No tienes cuenta? Solicita acceso aquí',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA DE REGISTRO
// ==========================================
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  void _register() {
    if (_formKey.currentState!.validate()) {
      // Guardar en la base de datos simulada
      mockDatabase[_emailCtrl.text] = {
        'nombre': _nombreCtrl.text,
        'apellidos': _apellidosCtrl.text,
        'password': _passwordCtrl.text,
      };

      // ==========================================
      // NOTIFICACIÓN ESTILO REDES SOCIALES
      // ==========================================
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating, // Hace que la notificación flote
          backgroundColor: Colors.white, // Fondo de la tarjeta
          elevation: 8, // Sombra para dar profundidad
          margin: const EdgeInsets.all(16), // Separación de los bordes
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Bordes redondeados
          ),
          duration: const Duration(seconds: 4), // Tiempo en pantalla
          content: Row(
            children: [
              // Icono circular
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Textos de la notificación
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Registro completado!',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ya puedes iniciar sesión con tu cuenta.',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      // Regresar al Login
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Personal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Nuevo Registro',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nombre y Apellidos
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nombreCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _apellidosCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Apellidos',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Campo de Correo
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requerido';
                          if (mockDatabase.containsKey(value)) {
                            return 'Este correo ya está registrado';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo de Contraseña
                      TextFormField(
                        controller: _passwordCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) =>
                            value!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Campo de Confirmar Contraseña
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Confirmar Contraseña',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_reset),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requerido';
                          if (value != _passwordCtrl.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Botón de Registrarse
                      ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Registrarse'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA PRINCIPAL (HOME) - SISTEMA DE PEDIDOS
// ==========================================
class HomePage extends StatefulWidget {
  final String nombre;
  final String apellidos;

  const HomePage({super.key, required this.nombre, required this.apellidos});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Controladores para capturar la información
  final TextEditingController _productoCtrl = TextEditingController();
  final TextEditingController _precioCtrl = TextEditingController();
  final TextEditingController _cantidadCtrl = TextEditingController();

  // Memoria temporal para registrar los productos del pedido
  final List<Map<String, dynamic>> _pedido = [];
  
  // Variable para saber si estamos editando un producto existente
  int? _indiceEdicion;

  void _guardarProducto() {
    if (_productoCtrl.text.isNotEmpty && _precioCtrl.text.isNotEmpty) {
      setState(() {
        final nuevoItem = {
          'nombre': _productoCtrl.text,
          'precio': double.tryParse(_precioCtrl.text) ?? 0.0,
          'cantidad': int.tryParse(_cantidadCtrl.text) ?? 1,
        };

        if (_indiceEdicion != null) {
          // Actualizar producto existente
          _pedido[_indiceEdicion!] = nuevoItem;
          _indiceEdicion = null; // Salimos del modo edición
        } else {
          // Agregar producto nuevo
          _pedido.add(nuevoItem);
        }
      });

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto guardado correctamente'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      // Limpiar campos tras registrar/actualizar
      _productoCtrl.clear();
      _precioCtrl.clear();
      _cantidadCtrl.clear();
    }
  }

  void _cargarParaEdicion(int index) {
    setState(() {
      _indiceEdicion = index;
      final item = _pedido[index];
      _productoCtrl.text = item['nombre'];
      _precioCtrl.text = item['precio'].toString();
      _cantidadCtrl.text = item['cantidad'].toString();
    });
  }

  void _eliminarProducto(int index) {
    setState(() {
      _pedido.removeAt(index);
      // Si eliminamos el producto que estábamos editando, limpiamos el formulario
      if (_indiceEdicion == index) {
        _indiceEdicion = null;
        _productoCtrl.clear();
        _precioCtrl.clear();
        _cantidadCtrl.clear();
      }
    });
  }

  // Método para confirmar antes de eliminar
  void _confirmarEliminacion(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar este producto?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo sin hacer nada
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
                _eliminarProducto(index); // Ejecuta el borrado real
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  double get _totalPedido {
    double total = 0;
    for (var item in _pedido) {
      total += (item['precio'] * item['cantidad']);
    }
    return total;
  }

  @override
  void dispose() {
    _productoCtrl.dispose();
    _precioCtrl.dispose();
    _cantidadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Sistema de Pedidos - ${widget.nombre}'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Ancho máximo
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // FORMULARIO DE CAPTURA
                // ==========================================
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          _indiceEdicion == null ? 'Registrar Producto' : 'Editar Producto',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _productoCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del producto',
                            prefixIcon: Icon(Icons.shopping_bag_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _precioCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Precio (\$)',
                                  prefixIcon: Icon(Icons.attach_money),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _cantidadCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Cantidad',
                                  prefixIcon: Icon(Icons.numbers),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _guardarProducto,
                          icon: Icon(_indiceEdicion == null ? Icons.add_shopping_cart : Icons.save),
                          label: Text(_indiceEdicion == null ? 'Agregar al Pedido' : 'Actualizar Producto'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 45),
                            backgroundColor: _indiceEdicion == null 
                                ? const Color(0xFF1E3A8A) 
                                : Colors.orange[800], 
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ==========================================
                // LISTA DEL PEDIDO ACTUAL
                // ==========================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Detalle del Pedido',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total: \$${_totalPedido.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: _pedido.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay productos en el pedido.\nAgrega uno arriba.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _pedido.length,
                          itemBuilder: (context, index) {
                            final item = _pedido[index];
                            final double subtotal = item['precio'] * item['cantidad'];
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                                  child: Text(
                                    '${item['cantidad']}x',
                                    style: const TextStyle(
                                      color: Color(0xFF1E3A8A),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  item['nombre'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('Precio unitario: \$${item['precio']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '\$${subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      tooltip: 'Editar',
                                      onPressed: () => _cargarParaEdicion(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Eliminar',
                                      onPressed: () => _confirmarEliminacion(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      // BOTÓN FLOTANTE PARA FINALIZAR TODO EL PEDIDO
      floatingActionButton: _pedido.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pedido procesado por \$${_totalPedido.toStringAsFixed(2)}'),
                    backgroundColor: Colors.green,
                  ),
                );
                // setState(() { _pedido.clear(); }); // Descomenta esto para vaciar el carrito al procesar
              },
              backgroundColor: Colors.green,
              icon: const Icon(Icons.check, color: Colors.white,),
              label: const Text('Finalizar Pedido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}