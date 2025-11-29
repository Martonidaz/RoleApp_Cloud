import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constantes.dart';
import 'tela_criar_evento.dart';
import 'tela_detalhes.dart';

class TelaListaEventos extends StatefulWidget {
  final int usuarioId;
  const TelaListaEventos({super.key, required this.usuarioId});
  @override
  State<TelaListaEventos> createState() => _TelaListaEventosState();
}

class _TelaListaEventosState extends State<TelaListaEventos> {
  List<dynamic> eventos = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    try {
      final response = await http.get(
        Uri.parse('$urlBase/eventos'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            eventos = jsonDecode(response.body);
            carregando = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => carregando = false);
    }
  }

  void _irParaCriar() async {
    if (widget.usuarioId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Faça login para criar eventos!")),
      );
      return;
    }
    final recarregar = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => TelaCriarEvento(usuarioId: widget.usuarioId),
      ),
    );
    if (recarregar == true) carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Próximos Rolês")),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : eventos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    "Nenhum evento por enquanto.",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  if (widget.usuarioId != 0)
                    const Text(
                      "Seja o primeiro a criar um!",
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: eventos.length,
              itemBuilder: (ctx, i) {
                final ev = eventos[i];
                ImageProvider imagem;

                if (ev['imagem_url'] != null &&
                    ev['imagem_url'].startsWith('http')) {
                  imagem = NetworkImage(ev['imagem_url']);
                } else if (ev['imagem_url'] != null) {
                  try {
                    imagem = MemoryImage(base64Decode(ev['imagem_url']));
                  } catch (e) {
                    imagem = const NetworkImage(
                      'https://via.placeholder.com/400',
                    );
                  }
                } else {
                  imagem = const NetworkImage(
                    'https://via.placeholder.com/400',
                  );
                }

                return Card(
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () {
                      final eventoAdaptado = {
                        "id": ev['id'],
                        "nome": ev['titulo'],
                        "endereco": ev['local_nome'],
                        "foto": ev['imagem_url'],
                        "descricao": ev['descricao'],
                        "distancia": 0,
                        "tipo": ev['categoria'] ?? "Evento",
                        "usuario_id": ev['usuario_id'],
                        "lat": ev['lat'],
                        "lon": ev['lon'],
                      };

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => TelaDetalhes(
                            local: eventoAdaptado,
                            usuarioId: widget.usuarioId,
                            nomeUsuario: "Visitante",
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: imagem,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.7),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: kSecondaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  ev['categoria'] ?? 'Rolê',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ev['titulo'],
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: kSecondaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    ev['data_evento'],
                                    style: const TextStyle(
                                      color: kSecondaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.pin_drop,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    ev['local_nome'],
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (ev['descricao'] != null &&
                                  ev['descricao'].isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  ev['descricao'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _irParaCriar,
        icon: const Icon(Icons.add),
        label: const Text("Criar Rolê"),
      ),
    );
  }
}
