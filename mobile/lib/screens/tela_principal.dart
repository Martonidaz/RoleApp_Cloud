import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constantes.dart';
import 'tela_lista_locais.dart';
import 'tela_lista_eventos.dart';
import 'tela_favoritos.dart';
import 'tela_perfil.dart';

class TelaPrincipal extends StatefulWidget {
  final int usuarioId;
  final String nomeUsuario;
  final String? fotoUsuario;
  final bool isAdmin;

  const TelaPrincipal({
    super.key,
    required this.usuarioId,
    required this.nomeUsuario,
    this.fotoUsuario,
    this.isAdmin = false,
  });
  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _abaAtual = 0;
  late List<Widget> _telas;
  Map<String, dynamic>? configBanner;

  @override
  void initState() {
    super.initState();
    carregarConfig();
    _telas = [
      TelaListaLocais(
        usuarioId: widget.usuarioId,
        nomeUsuario: widget.nomeUsuario,
        fotoUsuario: widget.fotoUsuario,
      ),
      TelaListaEventos(usuarioId: widget.usuarioId),
      TelaFavoritos(usuarioId: widget.usuarioId),
      TelaPerfil(usuarioId: widget.usuarioId, isAdmin: widget.isAdmin),
    ];
  }

  Future<void> carregarConfig() async {
    try {
      final res = await http.get(
        Uri.parse('$urlBase/config'),
        headers: defaultHeaders,
      );
      if (res.statusCode == 200)
        setState(() => configBanner = jsonDecode(res.body));
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (configBanner != null && configBanner!['banner_ativo'] == 'true')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 50,
                bottom: 12,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: Color(
                  int.parse(configBanner!['banner_cor'] ?? "0xFF1D4F90"),
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 5),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.campaign, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      configBanner!['banner_msg'] ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _telas[_abaAtual]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaAtual,
        onDestinationSelected: (i) => setState(() => _abaAtual = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place),
            label: 'Locais',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Eventos',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Salvos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
