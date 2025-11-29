import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../utils/constantes.dart';
import 'tela_login.dart';

class TelaFavoritos extends StatefulWidget {
  final int usuarioId;
  const TelaFavoritos({super.key, required this.usuarioId});
  @override
  State<TelaFavoritos> createState() => _TelaFavoritosState();
}

class _TelaFavoritosState extends State<TelaFavoritos> {
  List<dynamic> favoritos = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarFavoritos();
  }

  Future<void> carregarFavoritos() async {
    if (widget.usuarioId == 0) {
      if (mounted) setState(() => carregando = false);
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('$urlBase/meus_favoritos/${widget.usuarioId}'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            favoritos = jsonDecode(response.body);
            carregando = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => carregando = false);
    }
  }

  void _abrirGoogleMaps(String endereco, String modo) async {
    final url =
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(endereco)}&travelmode=$modo";
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Erro ao abrir mapa.")));
      }
    }
  }

  void _exibirOpcoesTransporte(String endereco) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Como você vai?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.directions_car,
                  color: Colors.blue,
                  size: 30,
                ),
                title: const Text("De Carro"),
                onTap: () {
                  Navigator.pop(ctx);
                  _abrirGoogleMaps(endereco, 'driving');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.directions_walk,
                  color: Colors.green,
                  size: 30,
                ),
                title: const Text("A Pé"),
                onTap: () {
                  Navigator.pop(ctx);
                  _abrirGoogleMaps(endereco, 'walking');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.directions_bus,
                  color: Colors.orange,
                  size: 30,
                ),
                title: const Text("Busão (Transporte Público)"),
                onTap: () {
                  Navigator.pop(ctx);
                  _abrirGoogleMaps(endereco, 'transit');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _irParaLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (c) => const TelaLogin()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.usuarioId == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text("Meus Salvos")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 100,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 24),
                const Text(
                  "Guarde seus Rolês!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Faça login para salvar seus lugares favoritos e acessá-los rapidamente quando quiser.",
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
                    onPressed: _irParaLogin,
                    icon: const Icon(Icons.login),
                    label: const Text("FAZER LOGIN"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Salvos")),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : favoritos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Você ainda não salvou nada.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoritos.length,
              itemBuilder: (c, i) {
                final item = favoritos[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['nome_local'] ?? "Local",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const Icon(Icons.favorite, color: Colors.red),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['endereco'] ?? "",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _exibirOpcoesTransporte(item['endereco'] ?? ""),
                            icon: const Icon(Icons.map_outlined),
                            label: const Text("COMO CHEGAR"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimaryColor,
                              side: const BorderSide(color: kPrimaryColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
