import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constantes.dart';

class TelaAdmin extends StatefulWidget {
  const TelaAdmin({super.key});
  @override
  State<TelaAdmin> createState() => _TelaAdminState();
}

class _TelaAdminState extends State<TelaAdmin>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> stats = {};
  bool carregando = true;
  final _bannerMsgCtrl = TextEditingController();
  String _bannerCor = "0xFF1D4F90";
  bool _bannerAtivo = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    carregarTudo();
  }

  Future<void> carregarTudo() async {
    await carregarStats();
    await carregarConfig();
  }

  Future<void> carregarStats() async {
    try {
      final res = await http.get(
        Uri.parse('$urlBase/admin/stats'),
        headers: defaultHeaders,
      );
      if (res.statusCode == 200) {
        setState(() {
          stats = jsonDecode(res.body);
          carregando = false;
        });
      }
    } catch (e) {
      setState(() => carregando = false);
    }
  }

  Future<void> carregarConfig() async {
    try {
      final res = await http.get(
        Uri.parse('$urlBase/config'),
        headers: defaultHeaders,
      );
      if (res.statusCode == 200) {
        final cfg = jsonDecode(res.body);
        setState(() {
          _bannerMsgCtrl.text = cfg['banner_msg'] ?? "";
          _bannerCor = cfg['banner_cor'] ?? "0xFF1D4F90";
          _bannerAtivo = cfg['banner_ativo'] == 'true';
        });
      }
    } catch (e) {}
  }

  Future<void> salvarConfig() async {
    try {
      await http.post(
        Uri.parse('$urlBase/admin/config'),
        headers: defaultHeaders,
        body: jsonEncode({
          "banner_msg": _bannerMsgCtrl.text,
          "banner_cor": _bannerCor,
          "banner_ativo": _bannerAtivo.toString(),
        }),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Marketing atualizado com sucesso!")),
      );
    } catch (e) {}
  }

  Widget _buildGraficoBarras(
    String titulo,
    List<dynamic> dados,
    Color corBase,
  ) {
    if (dados.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text("$titulo: Sem dados coletados ainda."),
        ),
      );
    }
    int maxVal = 0;
    for (var item in dados) {
      int val = int.tryParse(item['qtd'].toString()) ?? 0;
      if (val > maxVal) maxVal = val;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...dados.map((item) {
              int val = int.tryParse(item['qtd'].toString()) ?? 0;
              double pct = maxVal == 0 ? 0 : val / maxVal;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['nome_local'] ?? item['nome'] ?? 'Item',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "$val",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: corBase,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: corBase,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: corBase.withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Admin"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kPrimaryColor,
          indicatorColor: kPrimaryColor,
          tabs: const [
            Tab(text: "Métricas", icon: Icon(Icons.analytics_outlined)),
            Tab(text: "Marketing", icon: Icon(Icons.campaign_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          carregando
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kPrimaryColor, Color(0xFF143D75)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Usuários Ativos",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Total Cadastrado",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "${stats['total_usuarios'] ?? 0}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildGraficoBarras(
                      "🔥 Locais Mais Clicados",
                      stats['top_cliques'] ?? [],
                      Colors.orange,
                    ),
                    _buildGraficoBarras(
                      "📍 Categorias Mais Visitadas",
                      stats['top_categorias_visitadas'] ?? [],
                      kSecondaryColor,
                    ),
                    _buildGraficoBarras(
                      "❤️ Locais Mais Curtidos",
                      stats['top_curtidas'] ?? [],
                      Colors.pinkAccent,
                    ),
                  ],
                ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Banner Promocional",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Gerencie o banner da tela inicial.",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _bannerMsgCtrl,
                        decoration: const InputDecoration(
                          labelText: "Mensagem do Banner",
                          prefixIcon: Icon(Icons.message),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SwitchListTile(
                        title: const Text("Banner Ativo"),
                        subtitle: const Text("Ligar/Desligar visualização"),
                        activeColor: kSecondaryColor,
                        contentPadding: EdgeInsets.zero,
                        value: _bannerAtivo,
                        onChanged: (v) => setState(() => _bannerAtivo = v),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Cor do Fundo",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: [
                          _corBtn("0xFF1D4F90", Colors.blue[900]!),
                          _corBtn("0xFF31B152", Colors.green),
                          _corBtn("0xFFFF9800", Colors.orange),
                          _corBtn("0xFFE91E63", Colors.pink),
                          _corBtn("0xFF9C27B0", Colors.purple),
                          _corBtn("0xFF000000", Colors.black),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: salvarConfig,
                          icon: const Icon(Icons.save),
                          label: const Text("PUBLICAR ALTERAÇÕES"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _corBtn(String code, Color color) {
    bool isSelected = _bannerCor == code;
    return GestureDetector(
      onTap: () => setState(() => _bannerCor = code),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 24)
            : null,
      ),
    );
  }
}
