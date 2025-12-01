const pool = require('../config/db');

exports.criarEvento = async (req, res) => {
    const { usuario_id, titulo, descricao, data_evento, local_nome, imagem_url, lat, lon } = req.body;
    try {
        const result = await pool.query(`INSERT INTO eventos (usuario_id, titulo, descricao, data_evento, local_nome, imagem_url, lat, lon, categoria) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id`, 
            [usuario_id, titulo, descricao, data_evento, local_nome, imagem_url, lat, lon, 'Usuario']);
        res.json({ok: true, id: result.rows[0].id});
    } catch (e) { res.status(500).json({erro: "Erro"}); }
};

exports.listarEventos = async (req, res) => { 
    try {
        const result = await pool.query("SELECT * FROM eventos ORDER BY id DESC");
        res.json(result.rows);
    } catch (e) { res.json([]); }
};

exports.deletarEvento = async (req, res) => {
    const usuario_id = parseInt(req.body.usuario_id); 
    const evento_id = parseInt(req.params.id);
    try {
        const userRes = await pool.query("SELECT is_admin FROM usuarios WHERE id = $1", [usuario_id]);
        const isAdmin = userRes.rows.length > 0 ? userRes.rows[0].is_admin : false;

        let result;
        if (isAdmin) {
            result = await pool.query("DELETE FROM eventos WHERE id = $1", [evento_id]);
        } else {
            result = await pool.query("DELETE FROM eventos WHERE id = $1 AND usuario_id = $2", [evento_id, usuario_id]);
        }

        if (result.rowCount > 0) res.json({ok: true});
        else res.status(403).json({erro: "Não permitido"});
    } catch (e) { res.status(500).json({erro: "Erro ao deletar"}); }
};

exports.editarEvento = async (req, res) => {
    const { titulo, descricao, data_evento, local_nome } = req.body;
    const usuario_id = parseInt(req.body.usuario_id);
    const evento_id = parseInt(req.params.id);
    try {
        const userRes = await pool.query("SELECT is_admin FROM usuarios WHERE id = $1", [usuario_id]);
        const isAdmin = userRes.rows.length > 0 ? userRes.rows[0].is_admin : false;

        let result;
        if (isAdmin) {
            result = await pool.query("UPDATE eventos SET titulo=$1, descricao=$2, data_evento=$3, local_nome=$4 WHERE id=$5", [titulo, descricao, data_evento, local_nome, evento_id]);
        } else {
            result = await pool.query("UPDATE eventos SET titulo=$1, descricao=$2, data_evento=$3, local_nome=$4 WHERE id=$5 AND usuario_id=$6", [titulo, descricao, data_evento, local_nome, evento_id, usuario_id]);
        }

        if (result.rowCount > 0) res.json({ok: true});
        else res.status(403).json({erro: "Não permitido"});
    } catch (e) { res.status(500).json({erro: "Erro ao atualizar"}); }
};