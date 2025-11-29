const axios = require('axios');
const pool = require('../config/db');
const { getDistanciaEmMetros } = require('../utils/geo');
const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY || '';

// --- ADMIN & CONFIG ---
exports.getStats = async (req, res) => {
    try {
        const totalUsers = await pool.query("SELECT count(*) as c FROM usuarios");
        const topCliques = await pool.query("SELECT nome_local, count(*) as qtd FROM cliques GROUP BY place_id, nome_local ORDER BY qtd DESC LIMIT 5");
        const topVisitas = await pool.query("SELECT tipo_local as nome, count(*) as qtd FROM visitas GROUP BY tipo_local ORDER BY qtd DESC LIMIT 5");
        const topCurtidas = await pool.query("SELECT nome_local, count(*) as qtd FROM curtidas GROUP BY place_id, nome_local ORDER BY qtd DESC LIMIT 5");

        res.json({
            total_usuarios: parseInt(totalUsers.rows[0].c),
            top_cliques: topCliques.rows,
            top_categorias_visitadas: topVisitas.rows,
            top_curtidas: topCurtidas.rows
        });
    } catch (e) { res.status(500).json({erro: "Erro stats"}); }
};

exports.getConfig = async (req, res) => {
    try {
        const result = await pool.query("SELECT * FROM config_app");
        const config = {};
        result.rows.forEach(r => config[r.chave] = r.valor);
        res.json(config);
    } catch (e) { res.json({}); }
};

exports.saveConfig = async (req, res) => {
    const { banner_msg, banner_cor, banner_ativo } = req.body;
    try {
        const query = `INSERT INTO config_app (chave, valor) VALUES ($1, $2) ON CONFLICT (chave) DO UPDATE SET valor = $2`;
        await pool.query(query, ['banner_msg', banner_msg]);
        await pool.query(query, ['banner_cor', banner_cor]);
        await pool.query(query, ['banner_ativo', banner_ativo]);
        res.json({ok: true});
    } catch (e) { res.status(500).json({erro: "Erro"}); }
};

// --- INTERAÇÕES ---
exports.registrarClique = async (req, res) => {
    const { usuario_id, place_id, nome_local } = req.body;
    try {
        await pool.query(`INSERT INTO cliques (usuario_id, place_id, nome_local, data) VALUES ($1, $2, $3, $4)`, 
            [usuario_id, place_id, nome_local, new Date().toISOString()]);
        res.json({ok: true});
    } catch (e) { res.status(500).json({ok: false}); }
};

exports.registrarVisita = async (req, res) => {
    try {
        await pool.query(`INSERT INTO visitas (usuario_id, tipo_local, data) VALUES ($1, $2, $3)`, 
            [req.body.usuario_id, req.body.tipo_local, new Date().toISOString()]);
        res.json({ok: true});
    } catch (e) { res.status(500).json({ erro: "Erro" }); }
};

exports.curtir = async (req, res) => {
    const { usuario_id, nome_usuario, place_id, nome_local, endereco, foto, visibilidade } = req.body;
    try {
        const check = await pool.query(`SELECT * FROM curtidas WHERE usuario_id = $1 AND place_id = $2`, [usuario_id, place_id]);
        if (check.rows.length > 0) {
            await pool.query(`DELETE FROM curtidas WHERE id = $1`, [check.rows[0].id]);
            res.json({ status: 'removido' });
        } else {
            const vis = visibilidade || 'publico';
            await pool.query(`INSERT INTO curtidas (usuario_id, nome_usuario, place_id, nome_local, endereco, foto, visibilidade, data) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`, 
                [usuario_id, nome_usuario, place_id, nome_local, endereco, foto, vis, new Date().toISOString()]);
            res.json({ status: 'adicionado' });
        }
    } catch (e) { res.status(500).json({ erro: "Erro" }); }
};

exports.verCurtidas = async (req, res) => {
    const { place_id } = req.params;
    const { usuario_id } = req.query;
    try {
        const result = await pool.query(`SELECT nome_usuario FROM curtidas WHERE place_id = $1 AND (visibilidade = 'publico' OR visibilidade = 'comunidade' OR usuario_id = $2)`, 
            [place_id, usuario_id || 0]);
        const nomes = result.rows.map(x => x.nome_usuario);
        
        let ja_curtiu = false;
        if(usuario_id && usuario_id != 0) {
            const check = await pool.query(`SELECT id FROM curtidas WHERE place_id = $1 AND usuario_id = $2`, [place_id, usuario_id]);
            ja_curtiu = check.rows.length > 0;
        }
        res.json({ nomes, ja_curtiu });
    } catch (e) { res.json({ nomes: [], ja_curtiu: false }); }
};

exports.meusFavoritos = async (req, res) => {
    try {
        const result = await pool.query(`SELECT * FROM curtidas WHERE usuario_id = $1 ORDER BY id DESC`, [req.params.usuario_id]);
        res.json(result.rows);
    } catch (e) { res.json([]); }
};

// --- RECOMENDAÇÕES GOOGLE ---
async function getPreferenciasUsuario(usuario_id) {
    try {
        const res = await pool.query(`SELECT tipo_local, COUNT(*) as total FROM visitas WHERE usuario_id = $1 GROUP BY tipo_local`, [usuario_id]);
        const preferencias = {};
        res.rows.forEach(row => preferencias[row.tipo_local] = parseInt(row.total));
        return preferencias;
    } catch (e) { return {}; }
}

exports.getRecomendacoes = async (req, res) => {
    const { lat, lon, categoria, priorizar_acessibilidade, usuario_id, raio } = req.query;
    if (!lat || !lon) return res.status(400).json({ erro: "GPS necessário" });

    const raioBusca = raio ? parseFloat(raio) : 3000.0;
    if(!GOOGLE_API_KEY) return res.json([]);

    const CATEGORIAS = {
        'Alimentação': ['restaurant', 'bakery', 'cafe'],
        'Serviços': ['local_government_office', 'post_office', 'bank', 'library'],
        'Emergência': ['hospital', 'police', 'fire_station', 'doctor'],
        'Lazer': ['park', 'movie_theater', 'museum', 'bar', 'night_club']
    };

    let tiposGoogle = categoria && CATEGORIAS[categoria] ? CATEGORIAS[categoria] : ['restaurant', 'hospital', 'park'];

    try {
        const pesosIA = await getPreferenciasUsuario(usuario_id);
        const fields = 'places.id,places.displayName,places.types,places.location,places.formattedAddress,places.accessibilityOptions,places.photos,places.editorialSummary';

        const response = await axios.post(
            'https://places.googleapis.com/v1/places:searchNearby',
            {
                includedTypes: tiposGoogle,
                maxResultCount: 20,
                locationRestriction: { circle: { center: { latitude: parseFloat(lat), longitude: parseFloat(lon) }, radius: raioBusca } }
            },
            { headers: { 'Content-Type': 'application/json', 'X-Goog-Api-Key': GOOGLE_API_KEY, 'X-Goog-FieldMask': fields } }
        );

        let locais = (response.data.places || []).map(l => {
            let catPrincipal = 'Outros';
            for (const [cat, tipos] of Object.entries(CATEGORIAS)) { 
                if (l.types && l.types.some(t => tipos.includes(t))) catPrincipal = cat; 
            }
            const acc = l.accessibilityOptions || {};
            const itensAcessiveis = [];
            if (acc.wheelchairAccessibleEntrance) itensAcessiveis.push("Entrada Acessível");
            if (acc.wheelchairAccessibleRestroom) itensAcessiveis.push("Banheiro Adaptado");

            const distancia = getDistanciaEmMetros(lat, lon, l.location.latitude, l.location.longitude);
            const scoreAcessibilidade = itensAcessiveis.length;
            const scoreHistorico = (pesosIA[catPrincipal] || 0); 
            let pontuacaoFinal = (priorizar_acessibilidade === 'true') 
                ? (scoreAcessibilidade * 5000) - distancia 
                : (scoreHistorico * 2000) + (scoreAcessibilidade * 500) - distancia;

            let fotoUrl = null;
            if (l.photos && l.photos.length > 0) {
                fotoUrl = `https://places.googleapis.com/v1/${l.photos[0].name}/media?key=${GOOGLE_API_KEY}&maxHeightPx=400&maxWidthPx=400`;
            }
            return {
                id: l.id,
                nome: l.displayName ? l.displayName.text : "Sem Nome",
                tipo: catPrincipal,
                endereco: l.formattedAddress,
                acessibilidade: itensAcessiveis,
                distancia: distancia,
                pontuacao: pontuacaoFinal,
                foto: fotoUrl,
                descricao: l.editorialSummary ? l.editorialSummary.text : "Sem descrição",
                lat: l.location.latitude,
                lon: l.location.longitude
            };
        });
        locais.sort((a, b) => b.pontuacao - a.pontuacao);
        res.json(locais);
    } catch (error) { res.status(500).json([]); }
};