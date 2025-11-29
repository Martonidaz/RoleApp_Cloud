import 'package:flutter/material.dart';
import '../utils/constantes.dart';

class TelaTermos extends StatelessWidget {
  const TelaTermos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Termos e Privacidade"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 48,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Transparência em primeiro lugar",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "O Rolê foi criado para conectar você aos melhores lugares e eventos da sua cidade. Para que essa mágica aconteça, precisamos de algumas permissões e dados. Aqui explicamos tudo detalhadamente.",
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- SEÇÃO 1: LOCALIZAÇÃO ---
                  const _ItemTermo(
                    icone: Icons.location_on_outlined,
                    titulo: "Sua Localização (GPS)",
                    descricao:
                        "Utilizamos sua localização precisa apenas quando o app está em uso para:\n\n"
                        "• Mostrar rolês num raio de até 20km de você.\n"
                        "• Calcular a distância exata até os locais.\n"
                        "• Ordenar recomendações baseadas na proximidade.\n\n"
                        "Não rastreamos sua posição em segundo plano quando o app está fechado.",
                  ),

                  // --- SEÇÃO 2: DADOS DO USUÁRIO ---
                  const _ItemTermo(
                    icone: Icons.person_outline,
                    titulo: "Seus Dados",
                    descricao:
                        "Coletamos seu nome, email e idade para criar sua conta única. Sua foto de perfil é usada para que amigos possam reconhecê-lo em eventos e curtidas. Nunca vendemos seus dados pessoais para terceiros.",
                  ),

                  // --- SEÇÃO 3: CÂMERA E GALERIA ---
                  const _ItemTermo(
                    icone: Icons.camera_alt_outlined,
                    titulo: "Câmera e Fotos",
                    descricao:
                        "Solicitamos acesso à sua galeria apenas se você decidir:\n\n"
                        "• Alterar sua foto de perfil.\n"
                        "• Adicionar uma capa ao criar um novo evento.\n\n"
                        "Nenhuma foto é acessada sem o seu consentimento explícito.",
                  ),

                  // --- SEÇÃO 4: CONTEÚDO E COMUNIDADE ---
                  const _ItemTermo(
                    icone: Icons.diversity_3_outlined,
                    titulo: "Regras da Comunidade",
                    descricao:
                        "Ao criar eventos ou interagir no Rolê, você concorda em manter o respeito. Conteúdos ofensivos, discriminatórios ou ilegais resultarão no banimento imediato da conta.",
                  ),

                  // --- SEÇÃO 5: RESPONSABILIDADE ---
                  const _ItemTermo(
                    icone: Icons.info_outline,
                    titulo: "Dados dos Locais",
                    descricao:
                        "As informações dos locais são fornecidas pela API do Google Maps e colaboração dos usuários. Recomendamos verificar horários de funcionamento diretamente com o estabelecimento antes de sair de casa.",
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // --- BOTÃO DE ACEITE ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, true); // Retorna 'true' se aceitou
                },
                child: const Text(
                  "ENTENDI E CONCORDO",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTermo extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String descricao;

  const _ItemTermo({
    required this.icone,
    required this.titulo,
    required this.descricao,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: kPrimaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  descricao,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
