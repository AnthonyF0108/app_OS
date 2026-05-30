import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CadastroVeiculoPage extends StatefulWidget {
const CadastroVeiculoPage({super.key});

@override
State<CadastroVeiculoPage> createState() =>
_CadastroVeiculoPageState();
}

class _CadastroVeiculoPageState
extends State<CadastroVeiculoPage> {

final marcaController = TextEditingController();

final modeloController = TextEditingController();

final anoController = TextEditingController();

final placaController = TextEditingController();

final compraController = TextEditingController();

final vendaController = TextEditingController();

final obsController = TextEditingController();

String status = 'Estoque';

@override
void dispose() {

marcaController.dispose();

modeloController.dispose();

anoController.dispose();

placaController.dispose();

compraController.dispose();

vendaController.dispose();

obsController.dispose();

super.dispose();
}

Future<void> salvar() async {

await FirebaseFirestore.instance
    .collection('veiculos')
    .add({

'marca': marcaController.text,

'modelo': modeloController.text,

'ano': anoController.text,

'placa': placaController.text,

'valor_compra':
double.tryParse(compraController.text) ?? 0,

'valor_venda':
double.tryParse(vendaController.text) ?? 0,

'observacoes': obsController.text,

'status': status,

'data': Timestamp.now(),
});

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(

const SnackBar(
content: Text('Veículo salvo com sucesso'),
),
);

Navigator.pop(context);
}

@override
Widget build(BuildContext context) {

return Scaffold(

backgroundColor: Colors.black,

appBar: AppBar(

title: const Text('Novo Veículo'),

backgroundColor: const Color(0xFF000033),

foregroundColor: Colors.white,
),

body: ListView(

padding: const EdgeInsets.all(16),

children: [

_campo(
'Marca',
marcaController,
),

_campo(
'Modelo',
modeloController,
),

_campo(
'Ano',
anoController,
tipo: TextInputType.number,
),

_campo(
'Placa',
placaController,
),

_campo(
'Valor Compra',
compraController,
tipo: TextInputType.number,
),

_campo(
'Valor Venda',
vendaController,
tipo: TextInputType.number,
),

const SizedBox(height: 15),

DropdownButtonFormField(

value: status,

dropdownColor: Colors.grey[900],

style: const TextStyle(
color: Colors.white,
),

decoration: _decoracao('Status'),

items: const [

DropdownMenuItem(
value: 'Estoque',
child: Text('Estoque'),
),

DropdownMenuItem(
value: 'Vendido',
child: Text('Vendido'),
),

DropdownMenuItem(
value: 'Reservado',
child: Text('Reservado'),
),
],

onChanged: (v) {

setState(() {

status = v!;
});
},
),

const SizedBox(height: 15),

TextField(

controller: obsController,

maxLines: 4,

style: const TextStyle(
color: Colors.white,
),

decoration: _decoracao(
'Observações',
),
),

const SizedBox(height: 25),

SizedBox(

height: 55,

child: ElevatedButton.icon(

style: ElevatedButton.styleFrom(

backgroundColor: Colors.blueAccent,

shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(14),
),
),

onPressed: salvar,

icon: const Icon(Icons.save),

label: const Text(
'SALVAR VEÍCULO',
),
),
),
],
),
);
}

Widget _campo(
String label,
TextEditingController controller, {
TextInputType tipo = TextInputType.text,
}) {

return Padding(

padding: const EdgeInsets.only(
bottom: 15,
),

child: TextField(

controller: controller,

keyboardType: tipo,

style: const TextStyle(
color: Colors.white,
),

decoration: _decoracao(label),
),
);
}

InputDecoration _decoracao(String label) {

return InputDecoration(

labelText: label,

labelStyle: const TextStyle(
color: Colors.white70,
),

filled: true,

fillColor: Colors.white10,

border: OutlineInputBorder(

borderRadius:
BorderRadius.circular(14),

borderSide: BorderSide.none,
),
);
}
}
