import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../utils/constantes.dart';
import 'tela_detalhes.dart';

class TelaListaLocais extends StatefulWidget {
  final int usuarioId;
  final String nomeUsuario;
  final String? fotoUsuario;
  const TelaListaLocais({
    super.key,
    required this.usuarioId,
    this.nomeUsuario = "Visitante",
    this.fotoUsuario,
  });
  @override
  State<TelaListaLocais> createState() => _TelaListaLocaisState();
}

class _TelaListaLocaisState extends State<TelaListaLocais> {
  List<dynamic> locais = [];
  bool carregando = true;
  double raioKm = 3.0;
  bool priorizarAcessibilidade = false;
  final List<String> categorias = [
    "Todos",
    "Alimentação",
    "Serviços",
    "Emergência",
    "Lazer",
  ];
  String categoriaSelecionada = "Todos";

  @override
  void initState() {
    super.initState();
    buscarLocais();
  }

  Future<void> buscarLocais() async {
    if (!mounted) return;
    setState(() => carregando = true);
    try {
      Position pos;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("O GPS está desligado. Por favor, ligue-o."),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => carregando = false);
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => carregando = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => carregando = false);
        return;
      }

      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 12),
        );
      } catch (e) {
        pos =
            await Geolocator.getLastKnownPosition() ??
            Position(
              longitude: -46.6333,
              latitude: -23.5505,
              timestamp: DateTime.now(),
              accuracy: 1,
              altitude: 1,
              heading: 1,
              speed: 1,
              speedAccuracy: 1,
              altitudeAccuracy: 1,
              headingAccuracy: 1,
            );
      }

      int raioMetros = (raioKm * 1000).toInt();
      int uid = widget.usuarioId;

      String url =
          '$urlBase/recomendacoes?lat=${pos.latitude}&lon=${pos.longitude}&priorizar_acessibilidade=$priorizarAcessibilidade&usuario_id=$uid&raio=$raioMetros';
      if (categoriaSelecionada != "Todos")
        url += '&categoria=$categoriaSelecionada';

      final response = await http.get(Uri.parse(url), headers: defaultHeaders);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            locais = jsonDecode(response.body);
            carregando = false;
          });
        }
      } else {
        if (mounted) setState(() => carregando = false);
      }
    } catch (e) {
      if (mounted) setState(() => carregando = false);
    }
  }

  Future<void> registrarClique(dynamic local) async {
    if (widget.usuarioId == 0) return;
    try {
      http.post(
        Uri.parse('$urlBase/registrar_clique'),
        headers: defaultHeaders,
        body: jsonEncode({
          "usuario_id": widget.usuarioId,
          "place_id": local['id'],
          "nome_local": local['nome'],
        }),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarImg;
    if (widget.fotoUsuario != null && widget.fotoUsuario!.isNotEmpty) {
      try {
        avatarImg = MemoryImage(base64Decode(widget.fotoUsuario!));
      } catch (_) {}
    }

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.place_rounded,
                      color: kPrimaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "rolê",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        themeNotifier.value == ThemeMode.light
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                      ),
                      onPressed: () {
                        themeNotifier.value =
                            themeNotifier.value == ThemeMode.light
                            ? ThemeMode.dark
                            : ThemeMode.light;
                      },
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: kPrimaryColor.withOpacity(0.1),
                      backgroundImage: avatarImg,
                      child: avatarImg == null
                          ? const Icon(Icons.person, color: kPrimaryColor)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ... Resto do build (Sliders, ListView) igual ao anterior, só copie a lógica acima
          // Para economizar espaço aqui, você pode copiar o restante do build da lista de locais do código anterior
          // Lembre-se de importar 'utils/constantes.dart' para usar formatarDistancia e kPrimaryColor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categorias
                        .map(
                          (cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: categoriaSelecionada == cat,
                              onSelected: (val) {
                                setState(() => categoriaSelecionada = cat);
                                buscarLocais();
                              },
                              selectedColor: kSecondaryColor,
                              labelStyle: TextStyle(
                                color: categoriaSelecionada == cat
                                    ? Colors.white
                                    : null,
                                fontWeight: FontWeight.bold,
                              ),
                              showCheckmark: false,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: categoriaSelecionada == cat
                                      ? Colors.transparent
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.radar, size: 20, color: Colors.grey),
                    Expanded(
                      child: Slider(
                        value: raioKm,
                        min: 0.5,
                        max: 20.0,
                        activeColor: kPrimaryColor,
                        onChanged: (val) => setState(() => raioKm = val),
                        onChangeEnd: (val) => buscarLocais(),
                      ),
                    ),
                    Text(
                      "${raioKm.toStringAsFixed(1)} km",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Acessibilidade",
                      style: TextStyle(fontSize: 12),
                    ),
                    Switch(
                      value: priorizarAcessibilidade,
                      activeColor: kSecondaryColor,
                      onChanged: (val) {
                        setState(() => priorizarAcessibilidade = val);
                        buscarLocais();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: carregando
                ? const Center(child: CircularProgressIndicator())
                : locais.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Nenhum local encontrado aqui.",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        TextButton(
                          onPressed: buscarLocais,
                          child: const Text("Buscar de novo"),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: locais.length,
                    itemBuilder: (ctx, i) {
                      final local = locais[i];
                      final acessibilidade = List<String>.from(
                        local['acessibilidade'] ?? [],
                      );
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () {
                            registrarClique(local);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => TelaDetalhes(
                                  local: local,
                                  usuarioId: widget.usuarioId,
                                  nomeUsuario: widget.nomeUsuario,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            children: [
                              if (local['foto'] != null)
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      child: Image.network(
                                        local['foto'],
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, o, s) => Container(
                                          height: 160,
                                          color: Colors.grey[200],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          local['tipo']
                                              .toString()
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            local['nome'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${formatarDistancia(local['distancia'])}",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (acessibilidade.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 10.0,
                                        ),
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: acessibilidade
                                              .map(
                                                (a) => Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: kSecondaryColor
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    a,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: kSecondaryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                  ],
                                ),
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
    );
  }
}
