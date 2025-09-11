import express from 'express';
import pool from './db.js';

const router = express.Router();

// Add a new asset with dynamic ownership based on investor shares
router.post('/asset', async (req, res) => {
  const { name, value, contributions } = req.body;
  if (!name || !value || !Array.isArray(contributions) || contributions.length === 0) {
    return res.status(400).json({ message: 'Missing required fields.' });
  }

  // Calculate total contribution
  const total = contributions.reduce((sum, c) => sum + Number(c.amount), 0);
  if (total <= 0) {
    return res.status(400).json({ message: 'Total contribution must be greater than zero.' });
  }

  try {
    // Start transaction
    await pool.query('START TRANSACTION');

    // Insert the asset
    const [result] = await pool.query('INSERT INTO assets (name, value) VALUES (?, ?)', [name, value]);
    const assetId = result.insertId;

    // Insert ownerships based on contributions
    for (const c of contributions) {
      const percent = ((Number(c.amount) / total) * 100).toFixed(2);
      await pool.query(
        'INSERT INTO asset_ownership (asset_id, investor_id, percentage) VALUES (?, ?, ?)',
        [assetId, c.investorId, percent]
      );
    }

    // Commit transaction
    await pool.query('COMMIT');

    res.status(201).json({ message: 'Asset and ownerships recorded.' });
  } catch (err) {
    // Rollback transaction on error
    await pool.query('ROLLBACK');
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
      // Calculate amount based on percentage and asset value
      const ownersWithAmount = owners.map(owner => {
        const amount = (owner.percentage / 100) * asset.value;
        return { ...owner, amount };
      });
      asset.ownerships = ownersWithAmount;
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

router.get('/investor/assets', async (req, res) => {
  const investorId = req.query.investorId;
  console.log('GET /investor/assets called with investorId:', investorId);
  if (!investorId) {
    console.log('Missing investorId query parameter.');
    return res.status(400).json({ message: 'Missing investorId query parameter.' });
  }
  try {
    const [assets] = await pool.query('SELECT * FROM assets');
    const filteredAssets = [];
    for (const asset of assets) {
      const [owners] = await pool.query(
        'SELECT ao.investor_id, i.name, ao.percentage FROM asset_ownership ao JOIN investors i ON ao.investor_id = i.id WHERE ao.asset_id = ? AND ao.investor_id = ?',
        [asset.id, investorId]
      );
      console.log(`Asset ${asset.id} owners for investor ${investorId}:`, owners);
      if (owners.length > 0) {
        const ownersWithAmount = owners.map(owner => {
          const amount = (owner.percentage / 100) * asset.value;
          return { ...owner, amount };
        });
        asset.ownerships = ownersWithAmount;
        filteredAssets.push(asset);
      }
    }
    console.log('Filtered assets:', filteredAssets);
    res.json(filteredAssets);
  } catch (err) {
    console.error('Error in /investor/assets:', err);
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get total asset value
router.get('/total-asset-value', async (req, res) => {
  try {
    const [[{ total }]] = await pool.query('SELECT SUM(value) as total FROM assets');
    res.status(200).json({ message:"Total asset value is found", total: total || 0 });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

export default router;
