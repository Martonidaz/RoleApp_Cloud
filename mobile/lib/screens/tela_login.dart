import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constantes.dart'; // Caminho correto para constantes
import 'tela_principal.dart'; // Está na mesma pasta 'screens'
import 'tela_termos.dart'; // Está na mesma pasta 'screens'

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});
  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool isCadastro = false;
  bool carregando = false;

  void _mostrarDialogo(String titulo, String mensagem) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          titulo,
          style: const TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(mensagem, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "ENTENDI",
              style: TextStyle(
                color: kSecondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> auth(String rota) async {
    if (isCadastro && _nomeCtrl.text.isEmpty) {
      _mostrarDialogo("Atenção", "Por favor, preencha seu nome/apelido.");
      return;
    }
    if (_emailCtrl.text.isEmpty || _senhaCtrl.text.isEmpty) {
      _mostrarDialogo("Campos Vazios", "Preencha o email e a senha.");
      return;
    }

    setState(() => carregando = true);
    try {
      final body = {
        "email": _emailCtrl.text,
        "senha": _senhaCtrl.text,
        if (isCadastro) ...{"nome": _nomeCtrl.text, "idade": 18},
      };
      final response = await http.post(
        Uri.parse('$urlBase$rota'),
        headers: defaultHeaders,
        body: jsonEncode(body),
      );

      if (!mounted) return;

      final dados = jsonDecode(response.body);

      if (response.statusCode == 200) {
        bool isAdmin = (dados['is_admin'] == 1 || dados['is_admin'] == true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (c) => TelaPrincipal(
              usuarioId: dados['id'],
              nomeUsuario: dados['nome'],
              fotoUsuario: dados['foto'],
              isAdmin: isAdmin,
            ),
          ),
        );
      } else {
        String mensagemErro = dados['erro'] ?? "Erro inesperado.";
        if (mensagemErro.contains("Senha incorreta")) {
          _mostrarDialogo("Acesso Negado", "Senha incorreta. Tente novamente.");
        } else if (mensagemErro.contains("não encontrado")) {
          _mostrarDialogo(
            "Conta não existe",
            "Email não encontrado. Crie uma conta.",
          );
        } else {
          _mostrarDialogo("Ops!", mensagemErro);
        }
      }
    } catch (e) {
      if (mounted) _mostrarDialogo("Sem Conexão", "Verifique sua internet.");
    }
    if (mounted) setState(() => carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kSecondaryColor.withOpacity(0.2),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.place_rounded,
                    size: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "rolê",
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ),
                  const Text(
                    "EXPLORE & CONECTE",
                    style: TextStyle(
                      color: kSecondaryColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 50),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 25,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCadastro ? "Junte-se ao Rolê" : "E aí, sumido(a)!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (isCadastro) ...[
                          TextField(
                            controller: _nomeCtrl,
                            decoration: const InputDecoration(
                              labelText: "Como te chamam?",
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                            labelText: "Seu Email ou Apelido",
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _senhaCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Sua Senha Secreta",
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                auth(isCadastro ? '/cadastro' : '/login'),
                            child: Text(
                              isCadastro ? "BORA LÁ!" : "ENTRAR AGORA",
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => const TelaTermos(),
                              ),
                            );
                          },
                          child: Center(
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                                children: [
                                  const TextSpan(
                                    text:
                                        "Ao continuar, você concorda com nossos ",
                                  ),
                                  TextSpan(
                                    text: "Termos de Uso",
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                isCadastro ? "Já é da casa?" : "Novo por aqui?",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => isCadastro = !isCadastro),
                                child: Text(
                                  isCadastro ? "Fazer Login" : "Criar Conta",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 30),
                        if (!isCadastro)
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (c) => const TelaPrincipal(
                                    usuarioId: 0,
                                    nomeUsuario: "Visitante",
                                  ),
                                ),
                              ),
                              icon: const Icon(
                                Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              label: const Text(
                                "Só dar uma olhadinha (Visitante)",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
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
