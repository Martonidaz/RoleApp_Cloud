// config/db.js
require('dotenv').config();
const { Pool } = require('pg');

// Configuração da conexão
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
        rejectUnauthorized: false // Obrigatório para Neon/Render
    },
    // Configurações de estabilidade
    max: 10, // Máximo de conexões simultâneas
    idleTimeoutMillis: 30000, // Fecha conexão inativa após 30s
    connectionTimeoutMillis: 5000, // Espera até 5s para conectar
});

// ⚠️ O PULO DO GATO: Escutar erros inesperados
// Isso impede que o servidor caia se a conexão com o Neon piscar
pool.on('error', (err, client) => {
    console.error('⚠️ Erro inesperado no cliente do banco (Idle):', err.message);
    // Não encerra o processo, apenas avisa. O Pool vai tentar reconectar.
});

// Teste de conexão inicial
(async () => {
    try {
        const client = await pool.connect();
        console.log("✅ Banco de Dados Conectado com Sucesso (Neon)");
        client.release(); // Libera a conexão de teste para não prender recursos
    } catch (err) {
        console.error("❌ Falha crítica ao conectar no banco:", err.message);
    }
})();

module.exports = pool;