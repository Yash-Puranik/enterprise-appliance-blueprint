const express = require('express');
const { Pool } = require('pg');

const app = express();
const port = process.env.PORT || 3000;
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgres://postgres:secret@db:5432/appdb'
});
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.status(200).json({ status: 'healthy', database: 'connected' });
  } catch (err) {
    res.status(500).json({ status: 'unhealthy', error: err.message });
  }
});
app.get('/api/status', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() as current_time, version()');
    res.json({
      app: 'Enterprise Appliance Core',
      version: 'v1.0.0',
      timestamp: result.rows[0].current_time,
      db_version: result.rows[0].version
    });
  } catch (err) {
    res.status(500).json({ error: 'Database unreachable', details: err.message });
  }
});

app.listen(port, () => {
  console.log(`Backend API listening on port ${port}`);
});
