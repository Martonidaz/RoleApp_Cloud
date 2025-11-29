const pool = require('../config/db');
const bcrypt = require('bcrypt');

exports.cadastro = async (req, res) => {
    const { nome, email, senha, idade } = req.body;
    try {
        const senhaHash = await bcrypt.hash(senha, 10);
        const isAdmin = email.includes('admin');
        const result = await pool.query(
            `INSERT INTO usuarios (nome, email, senha, idade, apelido, is_admin) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`, 
            [nome, email, senhaHash, idade, nome, isAdmin]
        );
        res.json({ok: true, id: result.rows[0].id, nome: nome, is_admin: isAdmin});
    } catch (e) { res.status(500).json({erro: "Email já cadastrado ou erro interno"}); }
};

exports.login = async (req, res) => {
    const { email, senha } = req.body;
    try {
        const result = await pool.query(`SELECT * FROM usuarios WHERE email = $1 OR apelido = $2`, [email, email]);
        const u = result.rows[0];
        
        if (!u) return res.status(401).json({erro: "Usuário não encontrado"});
        
        const match = await bcrypt.compare(senha, u.senha);
        if (match) {
            res.json({ok: true, id: u.id, nome: u.apelido || u.nome, foto: u.foto, is_admin: u.is_admin});
        } else {
            res.status(401).json({erro: "Senha incorreta"});
        }
    } catch (e) { res.status(500).json({erro: "Erro interno"}); }
};

exports.getUsuario = async (req, res) => {
    try {
        const result = await pool.query("SELECT id, nome, apelido, bio, email, idade, foto, is_admin FROM usuarios WHERE id = $1", [req.params.id]);
        if (result.rows.length === 0) return res.status(404).json({ erro: "Não encontrado" });
        res.json(result.rows[0]);
    } catch (e) { res.status(500).json({ erro: "Erro" }); }
};

exports.atualizarPerfil = async (req, res) => {
    const { id, apelido, bio, foto, senha } = req.body;
    try {
        if (senha && senha.length > 0) {
            const hash = await bcrypt.hash(senha, 10);
            await pool.query(`UPDATE usuarios SET apelido = $1, bio = $2, foto = $3, senha = $4 WHERE id = $5`, [apelido, bio, foto, hash, id]);
        } else {
            await pool.query(`UPDATE usuarios SET apelido = $1, bio = $2, foto = $3 WHERE id = $4`, [apelido, bio, foto, id]);
        }
        res.json({ok: true});
    } catch (e) { res.status(500).json({erro: "Erro interno"}); }
};