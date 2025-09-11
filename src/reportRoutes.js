import express from 'express';
import pool from './db.js';

const router = express.Router();

// Monthly contribution report (admin)
router.get('/report/contributions/monthly', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT i.id as investor_id, i.name, MONTH(t.date) as month, YEAR(t.date) as year, SUM(t.amount) as total
      FROM transactions t
      JOIN investors i ON t.investor_id = i.id
      WHERE t.status = 'approved'
      GROUP BY i.id, year, month
      ORDER BY year DESC, month DESC
    `);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Yearly contribution report (admin)
router.get('/report/contributions/yearly', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT i.id as investor_id, i.name, YEAR(t.date) as year, SUM(t.amount) as total
      FROM transactions t
      JOIN investors i ON t.investor_id = i.id
      WHERE t.status = 'approved'
      GROUP BY i.id, year
      ORDER BY year DESC
    `);
    res.status(200).json({message:"contributions found successfully",rows});
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Asset ownership breakdown (admin)
router.get('/report/assets', async (req, res) => {
  try {
    const [assets] = await pool.query('SELECT * FROM assets');
    for (const asset of assets) {
      const [owners] = await pool.query('SELECT ao.investor_id, i.name, ao.percentage FROM asset_ownership ao JOIN investors i ON ao.investor_id = i.id WHERE ao.asset_id = ?', [asset.id]);
      asset.ownerships = owners;
    }
    // Fix: Ensure proper JSON formatting by serializing assets explicitly
    res.setHeader('Content-Type', 'application/json');
    res.status(200).json({message:"Assets returned successfully",data:assets,count:assets.length})
    // res.send(JSON.stringify(assets));

  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Penalty records (admin)
router.get('/report/penalties', async (req, res) => {
  try {
    const [penalties] = await pool.query('SELECT p.*, i.name as investor_name FROM penalties p JOIN investors i ON p.investor_id = i.id ORDER BY date DESC');
    res.json(penalties);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Interest accrual statements (admin)
router.get('/report/interests', async (req, res) => {
  try {
    const [rates] = await pool.query('SELECT * FROM interest_rates ORDER BY start_date DESC');
    res.json(rates);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

export default router;
