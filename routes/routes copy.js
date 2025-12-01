const express = require('express');
const router = express.Router();

const auth = require('../controllers/authController');
const eventos = require('../controllers/eventosController');
const core = require('../controllers/coreController');

router.get('/', (req, res) => res.send('API Modular Ativa 🚀'));

// Auth
router.post('/cadastro', auth.cadastro);
router.post('/login', auth.login);
router.get('/usuario/:id', auth.getUsuario);
router.post('/atualizar_perfil', auth.atualizarPerfil);

// Eventos
router.post('/criar_evento', eventos.criarEvento);
router.get('/eventos', eventos.listarEventos);
router.delete('/evento/:id', eventos.deletarEvento);
router.put('/evento/:id', eventos.editarEvento);

// Core & Social
router.get('/recomendacoes', core.getRecomendacoes);
router.post('/registrar_clique', core.registrarClique);
router.post('/registrar_visita', core.registrarVisita);
router.post('/curtir', core.curtir);
router.get('/ver_curtidas/:place_id', core.verCurtidas);
router.get('/meus_favoritos/:usuario_id', core.meusFavoritos);

// Admin
router.get('/admin/stats', core.getStats);
router.get('/config', core.getConfig);
router.post('/admin/config', core.saveConfig);

module.exports = router;