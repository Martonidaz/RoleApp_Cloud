require('dotenv').config();
const express = require('express');
const cors = require('cors');
const pool = require('./config/db'); // Importa a conexão
const routes = require('./routes/routes'); // Importa as rotas

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json({ limit: '50mb' }));
app.use(cors());

// Usa as rotas modulares
app.use('/', routes);

// Inicialização das tabelas (mantida aqui para garantir que rodem no boot)
// (Você pode mover isso para um arquivo separado depois se quiser, mas aqui é seguro)
const initDb = async () => {
    const client = await pool.connect();
    try {
        await client.query(`CREATE TABLE IF NOT EXISTS usuarios (id SERIAL PRIMARY KEY, email TEXT UNIQUE, senha TEXT, nome TEXT, apelido TEXT, bio TEXT, idade INTEGER, foto TEXT, is_admin BOOLEAN DEFAULT FALSE)`);
        await client.query(`CREATE TABLE IF NOT EXISTS visitas (id SERIAL PRIMARY KEY, usuario_id INTEGER, tipo_local TEXT, data TEXT)`);
        await client.query(`CREATE TABLE IF NOT EXISTS curtidas (id SERIAL PRIMARY KEY, usuario_id INTEGER, nome_usuario TEXT, place_id TEXT, nome_local TEXT, endereco TEXT, foto TEXT, visibilidade TEXT, data TEXT)`);
        await client.query(`CREATE TABLE IF NOT EXISTS eventos (id SERIAL PRIMARY KEY, usuario_id INTEGER, titulo TEXT, descricao TEXT, data_evento TEXT, local_nome TEXT, imagem_url TEXT, lat REAL, lon REAL, categoria TEXT)`);
        await client.query(`CREATE TABLE IF NOT EXISTS cliques (id SERIAL PRIMARY KEY, usuario_id INTEGER, place_id TEXT, nome_local TEXT, data TEXT)`);
        await client.query(`CREATE TABLE IF NOT EXISTS config_app (chave TEXT PRIMARY KEY, valor TEXT)`);
        
        // Seed inicial (opcional)
        await client.query("INSERT INTO config_app (chave, valor) VALUES ('banner_ativo', 'true') ON CONFLICT DO NOTHING");
    } catch (err) {
        console.error("Erro init DB:", err);
    } finally {
        client.release();
    }
};
initDb();

app.listen(PORT, () => console.log(`🔥 API Modular rodando na porta ${PORT}`));