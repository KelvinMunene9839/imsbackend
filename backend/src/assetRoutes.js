import express from 'express';
import pool from './db.js';

const router = express.Router();

// Add a new asset with dynamic ownership based on investor shares
router.post('/asset', async (req, res) => {
  console.log('POST /asset req.body:', req.body);
  if (!req.body || typeof req.body !== 'object') {
    return res.status(400).json({ message: 'Missing or invalid JSON body.' });
  }
  const { name, value } = req.body || {};
  if (!name || !value) {
    return res.status(400).json({ message: 'Missing required fields.' });
  }
  try {
    // Insert the asset
    const [result] = await pool.query('INSERT INTO assets (name, value) VALUES (?, ?)', [name, value]);
    const assetId = result.insertId;
    // Fetch all investors and their shares
    const [investors] = await pool.query('SELECT id, shares FROM investors');
    const totalShares = investors.reduce((sum, inv) => sum + (inv.shares || 0), 0);
    if (totalShares === 0) {
      return res.status(400).json({ message: 'No shares found for investors.' });
    }
    // Assign ownership based on shares
    for (const investor of investors) {
      const percentage = ((investor.shares || 0) / totalShares) * 100;
      await pool.query('INSERT INTO asset_ownership (asset_id, investor_id, percentage) VALUES (?, ?, ?)', [assetId, investor.id, percentage]);
    }
    res.status(201).json({ message: 'Asset added with dynamic ownership.' });
  } catch (err) {
    console.error('Error adding asset:', err);
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
  console.log('PUT /asset/:id req.body:', req.body);
  if (!req.body || typeof req.body !== 'object') {
    return res.status(400).json({ message: 'Missing or invalid JSON body.' });
  }
  const { name, value, ownerships } = req.body || {};
  const { id } = req.params;
  if (!name || !value || !Array.isArray(ownerships)) {
    return res.status(400).json({ message: 'Missing required fields.' });
  }
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
