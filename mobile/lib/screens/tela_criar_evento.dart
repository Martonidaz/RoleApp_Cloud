import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constantes.dart';

class TelaCriarEvento extends StatefulWidget {
  final int usuarioId;
  const TelaCriarEvento({super.key, required this.usuarioId});
  @override
  State<TelaCriarEvento> createState() => _TelaCriarEventoState();
}

class _TelaCriarEventoState extends State<TelaCriarEvento> {
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _localCtrl = TextEditingController();
  final _dataCtrl = TextEditingController();
  Uint8List? _imagemBytes;
  double? _lat, _lon;
  bool carregando = false;

  Future<void> _escolherFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imagemBytes = bytes;
      });
    }
  }

  Future<void> _usarLocalizacaoAtual() async {
    setState(() => carregando = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Permissão negada. Digite o local manualmente."),
            ),
          );
          setState(() => carregando = false);
          return;
        }
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _lat = pos.latitude;
        _lon = pos.longitude;
        _localCtrl.text = "Minha Localização Atual";
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Localização capturada!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("GPS falhou. Digite o local manualmente."),
        ),
      );
    }
    setState(() => carregando = false);
  }

  Future<void> _salvarEvento() async {
    if (_tituloCtrl.text.isEmpty || _localCtrl.text.isEmpty) return;
    setState(() => carregando = true);
    try {
      String? fotoBase64;
      if (_imagemBytes != null) fotoBase64 = base64Encode(_imagemBytes!);
      final body = {
        "usuario_id": widget.usuarioId,
        "titulo": _tituloCtrl.text,
        "descricao": _descCtrl.text,
        "local_nome": _localCtrl.text,
        "data_evento": _dataCtrl.text,
        "imagem_url": fotoBase64,
        "lat": _lat,
        "lon": _lon,
      };
      final response = await http.post(
        Uri.parse('$urlBase/criar_evento'),
        headers: defaultHeaders,
        body: jsonEncode(body),
      );

      if (!mounted) return;
      if (response.statusCode == 200) Navigator.pop(context, true);
    } catch (e) {}
    if (mounted) setState(() => carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Criar Evento")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Foto de Capa",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _escolherFoto,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  image: _imagemBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_imagemBytes!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imagemBytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 50,
                            color: kPrimaryColor,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Toque para adicionar imagem",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Detalhes do Evento",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(
                labelText: "Nome do Evento",
                prefixIcon: Icon(Icons.event_note),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dataCtrl,
              decoration: const InputDecoration(
                labelText: "Data e Hora (Ex: Sexta, 22h)",
                prefixIcon: Icon(Icons.access_time),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _localCtrl,
                    decoration: const InputDecoration(
                      labelText: "Nome do Local",
                      prefixIcon: Icon(Icons.pin_drop),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _usarLocalizacaoAtual,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.my_location, color: kPrimaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Descrição (Opcional)",
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: carregando ? null : _salvarEvento,
                child: carregando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("PUBLICAR EVENTO"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
