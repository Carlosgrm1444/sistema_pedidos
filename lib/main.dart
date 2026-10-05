import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- IMPORTANTE PARA RESTRINGIR SOLO NÚMEROS

void main() {
  runApp(const MyApp());
}

// Base de datos simulada en memoria para probar el registro y el login.
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          background: Colors.grey[200],
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

      if (mockDatabase.containsKey(email)) {
        if (mockDatabase[email]!['password'] == password) {
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
                      const Icon(Icons.business, size: 80, color: Color(0xFF1E3A8A)),
                      const SizedBox(height: 16),
                      const Text(
                        'SQL_BROS',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(height: 24),
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
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                        },
                        child: const Text('¿No tienes cuenta? Solicita acceso aquí'),
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
      mockDatabase[_emailCtrl.text] = {
        'nombre': _nombreCtrl.text,
        'apellidos': _apellidosCtrl.text,
        'password': _passwordCtrl.text,
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
          elevation: 8,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¡Registro completado!', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Ya puedes iniciar sesión con tu cuenta.', style: TextStyle(color: Colors.black54, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Nuevo Registro', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nombreCtrl,
                              decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                              validator: (value) => value!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _apellidosCtrl,
                              decoration: const InputDecoration(labelText: 'Apellidos', border: OutlineInputBorder()),
                              validator: (value) => value!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requerido';
                          if (mockDatabase.containsKey(value)) return 'Este correo ya está registrado';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                        obscureText: true,
                        validator: (value) => value!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Confirmar Contraseña', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_reset)),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requerido';
                          if (value != _passwordCtrl.text) return 'Las contraseñas no coinciden';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
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
  // NUEVA LLAVE PARA VALIDAR EL FORMULARIO DE PRODUCTOS
  final _formKeyPedido = GlobalKey<FormState>();

  final TextEditingController _productoCtrl = TextEditingController();
  final TextEditingController _empresaCtrl = TextEditingController();
  final TextEditingController _precioCtrl = TextEditingController();
  final TextEditingController _cantidadCtrl = TextEditingController();

  final List<String> _categorias = ['Consumibles', 'Industriales', 'Negocios'];
  String _categoriaSeleccionada = 'Consumibles';

  final List<Map<String, dynamic>> _pedido = [];
  final List<Map<String, dynamic>> _historialPedidos = [];
  
  int? _indiceEdicion;

  String _formatearMoneda(double monto) {
    String s = monto.toStringAsFixed(2);
    List<String> partes = s.split('.');
    RegExp re = RegExp(r'\B(?=(\d{3})+(?!\d))');
    partes[0] = partes[0].replaceAll(re, ',');
    return partes.join('.');
  }

  IconData _obtenerIconoCategoria(String categoria) {
    switch (categoria) {
      case 'Consumibles': return Icons.shopping_cart; 
      case 'Industriales': return Icons.settings; 
      case 'Negocios': return Icons.storefront; 
      default: return Icons.category;
    }
  }

  void _guardarProducto() {
    // AHORA VALIDAMOS EL FORMULARIO ANTES DE GUARDAR
    if (_formKeyPedido.currentState!.validate()) {
      setState(() {
        final nuevoItem = {
          'nombre': _productoCtrl.text,
          'empresa': _empresaCtrl.text,
          'precio': double.parse(_precioCtrl.text),
          'cantidad': int.parse(_cantidadCtrl.text),
          'categoria': _categoriaSeleccionada,
        };

        if (_indiceEdicion != null) {
          _pedido[_indiceEdicion!] = nuevoItem;
          _indiceEdicion = null; 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Se actualizó correctamente'), backgroundColor: Colors.blue),
          );
        } else {
          _pedido.add(nuevoItem);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto agregado correctamente'), backgroundColor: Colors.green),
          );
        }
      });

      _productoCtrl.clear();
      _empresaCtrl.clear();
      _precioCtrl.clear();
      _cantidadCtrl.clear();
      setState(() => _categoriaSeleccionada = 'Consumibles');
    }
  }

  void _cargarParaEdicion(int index) {
    setState(() {
      _indiceEdicion = index;
      final item = _pedido[index];
      _productoCtrl.text = item['nombre'];
      _empresaCtrl.text = item['empresa'];
      _precioCtrl.text = item['precio'].toString();
      _cantidadCtrl.text = item['cantidad'].toString();
      _categoriaSeleccionada = item['categoria'] ?? 'Consumibles';
    });
  }

  void _eliminarProducto(int index) {
    setState(() {
      _pedido.removeAt(index);
      if (_indiceEdicion == index) {
        _indiceEdicion = null;
        _productoCtrl.clear();
        _empresaCtrl.clear();
        _precioCtrl.clear();
        _cantidadCtrl.clear();
        _categoriaSeleccionada = 'Consumibles';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Se eliminó correctamente'), backgroundColor: Colors.red),
    );
  }

  void _confirmarEliminacion(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar este producto?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); 
                _eliminarProducto(index); 
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  void _finalizarPedido() {
    final double totalActual = _totalPedido;
    final String totalFinal = _formatearMoneda(totalActual);
    final fechaActual = DateTime.now();
    final String fechaFormateada = "${fechaActual.day.toString().padLeft(2, '0')}/${fechaActual.month.toString().padLeft(2, '0')}/${fechaActual.year}";

    setState(() {
      _historialPedidos.insert(0, {
        'fecha': fechaFormateada,
        'total': totalActual,
        'estado': 'En espera',
        'productos': List<Map<String, dynamic>>.from(_pedido), // Corrección del error de lista dinámica
      });

      _pedido.clear(); 
      _indiceEdicion = null; 
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pedido procesado exitosamente por \$$totalFinal'), backgroundColor: Colors.green[800]),
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
    _empresaCtrl.dispose();
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
            icon: const Icon(Icons.history_edu),
            tooltip: 'Ver pedidos procesados',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistorialPedidosPage(
                    historial: _historialPedidos,
                    formatearMoneda: _formatearMoneda,
                  ),
                ),
              ).then((_) => setState(() {})); 
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), 
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // FORMULARIO DE CAPTURA DE PRODUCTOS
                // ==========================================
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form( // ENVOLVEMOS LOS CAMPOS EN UN FORM
                      key: _formKeyPedido,
                      child: Column(
                        children: [
                          Text(
                            _indiceEdicion == null ? 'Registrar Producto' : 'Editar Producto',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _productoCtrl,
                                  decoration: const InputDecoration(labelText: 'Producto', prefixIcon: Icon(Icons.shopping_bag_outlined), border: OutlineInputBorder()),
                                  validator: (value) => value == null || value.trim().isEmpty ? 'Requerido' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _empresaCtrl,
                                  decoration: const InputDecoration(labelText: 'Empresa', prefixIcon: Icon(Icons.business), border: OutlineInputBorder()),
                                  validator: (value) => value == null || value.trim().isEmpty ? 'Requerido' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _categoriaSeleccionada,
                            decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category), border: OutlineInputBorder()),
                            items: _categorias.map((String categoria) => DropdownMenuItem<String>(value: categoria, child: Text(categoria))).toList(),
                            onChanged: (String? nuevaCategoria) {
                              if (nuevaCategoria != null) setState(() => _categoriaSeleccionada = nuevaCategoria);
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _precioCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  // BLOQUEA CARACTERES QUE NO SEAN NÚMEROS O PUNTOS
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                  decoration: const InputDecoration(labelText: 'Precio (\$)', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder()),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Requerido';
                                    if (double.tryParse(value) == null) return 'Inválido';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _cantidadCtrl,
                                  keyboardType: TextInputType.number,
                                  // BLOQUEA PUNTOS Y LETRAS, SOLO ENTEROS
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(labelText: 'Cantidad', prefixIcon: Icon(Icons.numbers), border: OutlineInputBorder()),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Requerido';
                                    if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Mínimo 1';
                                    return null;
                                  },
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
                              backgroundColor: _indiceEdicion == null ? const Color(0xFF1E3A8A) : Colors.orange[800], 
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
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
                    const Text('Detalle del Pedido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Total: \$${_formatearMoneda(_totalPedido)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: _pedido.isEmpty
                      ? const Center(child: Text('No hay productos en el pedido.\nAgrega uno arriba.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)))
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
                                  child: Icon(_obtenerIconoCategoria(item['categoria'] ?? ''), color: const Color(0xFF1E3A8A)),
                                ),
                                title: Text('${item['cantidad']}x ${item['nombre']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Empresa: ${item['empresa']}\nCategoría: ${item['categoria']} | Precio: \$${_formatearMoneda(item['precio'])}'),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('\$${_formatearMoneda(subtotal)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(width: 8),
                                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), tooltip: 'Editar', onPressed: () => _cargarParaEdicion(index)),
                                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), tooltip: 'Eliminar', onPressed: () => _confirmarEliminacion(index)),
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
      floatingActionButton: _pedido.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _finalizarPedido, 
              backgroundColor: Colors.green,
              icon: const Icon(Icons.check, color: Colors.white,),
              label: const Text('Finalizar Pedido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}

// ==========================================
// NUEVA PANTALLA: HISTORIAL Y ESTADO DE PEDIDOS
// ==========================================
class HistorialPedidosPage extends StatefulWidget {
  final List<Map<String, dynamic>> historial;
  final Function(double) formatearMoneda;

  const HistorialPedidosPage({
    super.key, 
    required this.historial,
    required this.formatearMoneda,
  });

  @override
  State<HistorialPedidosPage> createState() => _HistorialPedidosPageState();
}

class _HistorialPedidosPageState extends State<HistorialPedidosPage> {
  Color _getColorEstado(String estado) {
    if (estado == 'En espera') return Colors.red;
    if (estado == 'Enviado') return Colors.blue;
    if (estado == 'Pagado') return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Pedidos Procesados'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: widget.historial.isEmpty
              ? const Center(
                  child: Text(
                    'No hay pedidos procesados.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: widget.historial.length,
                  itemBuilder: (context, index) {
                    final pedido = widget.historial[index];
                    // Conversión segura requerida para evitar errores
                    final productos = List<Map<String, dynamic>>.from(pedido['productos']);
                    final colorEstado = _getColorEstado(pedido['estado']);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colorEstado, width: 2), 
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: colorEstado.withOpacity(0.2),
                          child: Icon(Icons.receipt_long, color: colorEstado),
                        ),
                        title: Text(
                          'Pedido del ${pedido['fecha']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: DropdownButton<String>(
                            value: pedido['estado'],
                            isDense: true,
                            dropdownColor: Colors.white,
                            style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold),
                            items: <String>['En espera', 'Enviado', 'Pagado'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? nuevoEstado) {
                              if (nuevoEstado != null) {
                                setState(() {
                                  pedido['estado'] = nuevoEstado;
                                });
                              }
                            },
                          ),
                        ),
                        trailing: Text(
                          '\$${widget.formatearMoneda(pedido['total'])}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        children: productos.map((prod) {
                          final subtotal = prod['precio'] * prod['cantidad'];
                          return ListTile(
                            title: Text('${prod['cantidad']}x ${prod['nombre']}'),
                            subtitle: Text('Empresa: ${prod['empresa']} | Cat: ${prod['categoria']}'),
                            trailing: Text('\$${widget.formatearMoneda(subtotal)}', style: const TextStyle(color: Colors.grey)),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}