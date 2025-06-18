import express from 'express';
import pool from './db.js';

const router = express.Router();

// Get investor dashboard (self)
router.get('/me', async (req, res) => {
  const investorId = req.query.id;
  if (!investorId) return res.status(400).json({ message: 'Investor id required.' });
  try {
    const [investorRows] = await pool.query('SELECT id, name, email, total_contributions, percentage_share, status FROM investors WHERE id = ?', [investorId]);
    if (investorRows.length === 0) return res.status(404).json({ message: 'Investor not found.' });
    // Get transactions
    const [transactions] = await pool.query('SELECT * FROM transactions WHERE investor_id = ?', [investorId]);
    res.json({ ...investorRows[0], transactions });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Record a new transaction (pending approval)
router.post('/transaction', async (req, res) => {
  const investorId = req.query.id;
  if (!investorId) return res.status(400).json({ message: 'Investor id required.' });
  const { amount, date } = req.body;
  try {
    await pool.query('INSERT INTO transactions (investor_id, amount, date, status) VALUES (?, ?, ?, ?)', [investorId, amount, date, 'pending']);
    res.status(201).json({ message: 'Transaction submitted for approval.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

export default router;
