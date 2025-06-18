import express from 'express';
import pool from './db.js';

const router = express.Router();

// Add a new asset
router.post('/asset', async (req, res) => {
  const { name, value, ownerships } = req.body; // ownerships: [{ investor_id, percentage }]
  try {
    const [result] = await pool.query('INSERT INTO assets (name, value) VALUES (?, ?)', [name, value]);
    const assetId = result.insertId;
    for (const owner of ownerships) {
      await pool.query('INSERT INTO asset_ownership (asset_id, investor_id, percentage) VALUES (?, ?, ?)', [assetId, owner.investor_id, owner.percentage]);
    }
    res.status(201).json({ message: 'Asset added.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get all assets with ownership breakdown
router.get('/assets', async (req, res) => {
  try {
    const [assets] = await pool.query('SELECT * FROM assets');
    for (const asset of assets) {
      const [owners] = await pool.query('SELECT ao.investor_id, i.name, ao.percentage FROM asset_ownership ao JOIN investors i ON ao.investor_id = i.id WHERE ao.asset_id = ?', [asset.id]);
      asset.ownerships = owners;
    }
    res.json(assets);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Edit asset (name, value, ownership)
router.put('/asset/:id', async (req, res) => {
  const { name, value, ownerships } = req.body;
  const { id } = req.params;
  try {
    await pool.query('UPDATE assets SET name = ?, value = ? WHERE id = ?', [name, value, id]);
    await pool.query('DELETE FROM asset_ownership WHERE asset_id = ?', [id]);
    for (const owner of ownerships) {
      await pool.query('INSERT INTO asset_ownership (asset_id, investor_id, percentage) VALUES (?, ?, ?)', [id, owner.investor_id, owner.percentage]);
    }
    res.json({ message: 'Asset updated.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

export default router;
