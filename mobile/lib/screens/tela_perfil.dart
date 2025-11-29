import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../utils/constantes.dart';
import 'tela_login.dart';
import 'tela_admin.dart';

class TelaPerfil extends StatefulWidget {
  final int usuarioId;
  final bool isAdmin;

  const TelaPerfil({super.key, required this.usuarioId, this.isAdmin = false});
  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  final _apelidoCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  Uint8List? _imagemBytes;
  String? _fotoBase64Antiga;
  bool carregando = false;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    if (widget.usuarioId == 0) return;
    try {
      final response = await http.get(
        Uri.parse('$urlBase/usuario/${widget.usuarioId}'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _apelidoCtrl.text =
                dados['apelido'] ?? dados['nickname'] ?? dados['nome'] ?? "";
            _bioCtrl.text = dados['bio'] ?? "";
            _fotoBase64Antiga = dados['foto'];
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _escolherFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imagemBytes = bytes;
      });
    }
  }

  Future<void> salvar() async {
    setState(() => carregando = true);
    String? fotoFinal = _fotoBase64Antiga;
    if (_imagemBytes != null) {
      fotoFinal = base64Encode(_imagemBytes!);
    }
    try {
      final body = {
        "id": widget.usuarioId,
        "apelido": _apelidoCtrl.text,
        "bio": _bioCtrl.text,
        "foto": fotoFinal,
        "senha": _senhaCtrl.text,
      };
      final response = await http.post(
        Uri.parse('$urlBase/atualizar_perfil'),
        headers: defaultHeaders,
        body: jsonEncode(body),
      );
      if (!mounted) return;
      if (response.statusCode == 200)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Perfil atualizado!")));
    } catch (e) {}
    if (mounted) setState(() => carregando = false);
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (c) => const TelaLogin()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.usuarioId == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text("Perfil")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 120,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 24),
                const Text(
                  "Perfil de Visitante",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Crie uma conta para personalizar seu perfil, salvar seus rolês favoritos e interagir com a galera!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.login),
                    label: const Text("CRIAR CONTA OU ENTRAR"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    ImageProvider? imagemProvider;
    if (_imagemBytes != null) {
      imagemProvider = MemoryImage(_imagemBytes!);
    } else if (_fotoBase64Antiga != null && _fotoBase64Antiga!.isNotEmpty) {
      try {
        imagemProvider = MemoryImage(base64Decode(_fotoBase64Antiga!));
      } catch (e) {
        imagemProvider = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: imagemProvider,
                    child: imagemProvider == null
                        ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _escolherFoto,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: kSecondaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isAdmin)
              Container(
                margin: const EdgeInsets.only(top: 24, bottom: 8),
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: const Icon(Icons.bar_chart),
                  label: const Text("ABRIR DASHBOARD ADMIN"),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const TelaAdmin()),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _apelidoCtrl,
              decoration: const InputDecoration(labelText: "Apelido"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _bioCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Sua Bio"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _senhaCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Trocar Segredo (Senha)",
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: carregando ? null : salvar,
                child: carregando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("ATUALIZAR PERFIL"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
