import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../utils/constantes.dart';

class TelaDetalhes extends StatefulWidget {
  final dynamic local;
  final int usuarioId;
  final String nomeUsuario;
  final bool isAdmin;

  const TelaDetalhes({
    super.key,
    required this.local,
    required this.usuarioId,
    required this.nomeUsuario,
    this.isAdmin = false,
  });

  @override
  State<TelaDetalhes> createState() => _TelaDetalhesState();
}

class _TelaDetalhesState extends State<TelaDetalhes> {
  List<String> quemCurtiu = [];
  bool jaCurtiu = false;

  @override
  void initState() {
    super.initState();
    carregarCurtidas();
  }

  bool get _possoGerenciar {
    if (widget.local['usuario_id'] == null) return false;
    return widget.local['usuario_id'] == widget.usuarioId || widget.isAdmin;
  }

  Future<void> _excluirEvento() async {
    try {
      final res = await http.delete(
        Uri.parse('$urlBase/evento/${widget.local['id']}'),
        headers: defaultHeaders,
        body: jsonEncode({"usuario_id": widget.usuarioId}),
      );
      if (res.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Evento excluído com sucesso!")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Erro ao excluir.")));
      }
    } catch (e) {}
  }

  void _editarEvento() {
    final tituloCtrl = TextEditingController(text: widget.local['nome']);
    final descCtrl = TextEditingController(text: widget.local['descricao']);
    final String dataOriginal = widget.local['data_evento'] ?? "Data a definir";
    final String localOriginal = widget.local['endereco'] ?? "Local a definir";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar Evento"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloCtrl,
                decoration: const InputDecoration(labelText: "Título"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Descrição"),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final response = await http.put(
                  Uri.parse('$urlBase/evento/${widget.local['id']}'),
                  headers: defaultHeaders,
                  body: jsonEncode({
                    "usuario_id": widget.usuarioId,
                    "titulo": tituloCtrl.text,
                    "descricao": descCtrl.text,
                    "data_evento": dataOriginal,
                    "local_nome": localOriginal,
                  }),
                );
                if (response.statusCode == 200) {
                  Navigator.pop(context); // Fecha detalhes para recarregar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Evento atualizado!")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Erro ao atualizar.")),
                  );
                }
              } catch (e) {}
            },
            child: const Text("SALVAR"),
          ),
        ],
      ),
    );
  }

  Future<void> carregarCurtidas() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$urlBase/ver_curtidas/${widget.local['id']}?usuario_id=${widget.usuarioId}',
        ),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            quemCurtiu = List<String>.from(dados['nomes']);
            jaCurtiu = dados['ja_curtiu'];
          });
        }
      }
    } catch (e) {}
  }

  void _abrirMenuCurtida() {
    if (widget.usuarioId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Entre na sua conta para curtir!"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (jaCurtiu) {
      enviarCurtida(null);
    } else {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Salvar local como:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: kPrimaryColor,
                  child: Icon(Icons.public, color: Colors.white),
                ),
                title: const Text(
                  "Público",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Visível para a comunidade"),
                onTap: () {
                  Navigator.pop(ctx);
                  enviarCurtida('publico');
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[700],
                  child: const Icon(Icons.lock, color: Colors.white),
                ),
                title: const Text(
                  "Privado",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Apenas você pode ver"),
                onTap: () {
                  Navigator.pop(ctx);
                  enviarCurtida('privado');
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> enviarCurtida(String? visibilidade) async {
    setState(() => jaCurtiu = !jaCurtiu);
    await http.post(
      Uri.parse('$urlBase/curtir'),
      headers: defaultHeaders,
      body: jsonEncode({
        "usuario_id": widget.usuarioId,
        "nome_usuario": widget.nomeUsuario,
        "place_id": widget.local['id'],
        "nome_local": widget.local['nome'],
        "endereco": widget.local['endereco'],
        "foto": widget.local['foto'],
        "visibilidade": visibilidade,
      }),
    );
    carregarCurtidas();
  }

  void _abrirGoogleMaps(String modo) async {
    final endereco = widget.local['endereco'];
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

  void _exibirOpcoesTransporte() {
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
                  _abrirGoogleMaps('driving');
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
                  _abrirGoogleMaps('walking');
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
                  _abrirGoogleMaps('transit');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _gerarTextoLikes() {
    if (quemCurtiu.isEmpty) return "";
    int total = quemCurtiu.length;
    if (jaCurtiu) {
      if (total == 1) return "Você curtiu isso";
      return "Você e mais ${total - 1} curtiram";
    } else {
      if (total == 1) return "1 pessoa curtiu";
      return "$total pessoas curtiram";
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? fotoString = widget.local['foto'];

    Widget imagemWidget;
    if (fotoString != null && fotoString.startsWith('http')) {
      imagemWidget = Image.network(
        fotoString,
        fit: BoxFit.cover,
        color: Colors.black26,
        colorBlendMode: BlendMode.darken,
        errorBuilder: (c, o, s) => Container(color: kPrimaryColor),
      );
    } else if (fotoString != null && fotoString.isNotEmpty) {
      try {
        imagemWidget = Image.memory(
          base64Decode(fotoString),
          fit: BoxFit.cover,
          color: Colors.black26,
          colorBlendMode: BlendMode.darken,
          errorBuilder: (c, o, s) => Container(color: kPrimaryColor),
        );
      } catch (e) {
        imagemWidget = Container(color: kPrimaryColor);
      }
    } else {
      imagemWidget = Container(color: kPrimaryColor);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.local['nome'],
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 10)],
                ),
              ),
              background: imagemWidget,
            ),
            actions: [
              if (_possoGerenciar) ...[
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: _editarEvento,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text("Excluir Evento?"),
                        content: const Text("Essa ação não pode ser desfeita."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: const Text("CANCELAR"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(c);
                              _excluirEvento();
                            },
                            child: const Text(
                              "EXCLUIR",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              IconButton(
                onPressed: _abrirMenuCurtida,
                icon: CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(
                    jaCurtiu ? Icons.favorite : Icons.favorite_border,
                    color: jaCurtiu ? Colors.red : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (quemCurtiu.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _gerarTextoLikes(),
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Text(
                    "Sobre",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.local['descricao'] ?? "Sem descrição.",
                    style: TextStyle(height: 1.5, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Onde fica?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: kPrimaryColor,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.local['endereco'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: _exibirOpcoesTransporte,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text("COMO CHEGAR"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimaryColor,
                        side: const BorderSide(color: kPrimaryColor, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
