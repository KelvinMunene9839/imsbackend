import express from 'express';
import pool from './db.js';

const router = express.Router();

// Get all pending transactions
router.get('/transactions/pending', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT t.*, i.name as investor_name FROM transactions t JOIN investors i ON t.investor_id = i.id WHERE t.status = ?', ['pending']);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});


// Approve or reject a transaction
router.patch('/transaction/:id', async (req, res) => {
  const { status } = req.body; // 'approved' or 'rejected'
  const { id } = req.params;
  if (!['approved', 'rejected'].includes(status)) return res.status(400).json({ message: 'Invalid status.' });
  try {
    await pool.query('UPDATE transactions SET status = ? WHERE id = ?', [status, id]);
    // After status update, recalculate total_contributions and total_bonds for the investor
    const [[{ investor_id }]] = await pool.query('SELECT investor_id FROM transactions WHERE id = ?', [id]);
    const [[{ total }]] = await pool.query('SELECT SUM(amount) as total FROM transactions WHERE investor_id = ?', [investor_id]);
    await pool.query('UPDATE investors SET total_contributions = ?, total_bonds = ? WHERE id = ?', [total || 0, total || 0, investor_id]);
    res.json({ message: `Transaction ${status}.` });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});
// Update investor
router.patch('/investor/:id', async (req, res) => {
  const { id } = req.params;
  const { name, email, password, status } = req.body;
  try {
    // Update name/email/status
    await pool.query('UPDATE investors SET name = ?, email = ?, status = ? WHERE id = ?', [name, email, status || 'active', id]);
    // Optionally update password if provided
    if (password) {
      await pool.query('UPDATE investors SET password = ? WHERE id = ?', [password, id]);
    }
    res.json({ message: 'Investor updated.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Delete investor
router.delete('/investor/:id', async (req, res) => {
  const { id } = req.params;
  try {
    await pool.query('DELETE FROM investors WHERE id = ?', [id]);
    res.json({ message: 'Investor deleted.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get all investors
router.get('/investors', async (req, res) => {
  try {
    const [investors] = await pool.query('SELECT id, name, email, status FROM investors');
    res.json(investors);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get pending approvals (transactions)
router.get('/pending-approvals', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT t.*, i.name as investor_name FROM transactions t JOIN investors i ON t.investor_id = i.id WHERE t.status = ?', ['pending']);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get assets report
router.get('/report/assets', async (req, res) => {
  try {
    const [assets] = await pool.query('SELECT * FROM assets');
    res.json(assets);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get yearly contributions report
router.get('/report/contributions/yearly', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT YEAR(created_at) as year, SUM(amount) as total FROM transactions WHERE status = ? GROUP BY YEAR(created_at)', ['approved']);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get total asset value
router.get('/total-asset-value', async (req, res) => {
  try {
    const [[{ total }]] = await pool.query('SELECT SUM(value) as total FROM assets');
    res.json({ total: total || 0 });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get interests report
router.get('/report/interests', async (req, res) => {
  try {
    const [interests] = await pool.query('SELECT * FROM interest_rates');
    res.json(interests);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get monthly contributions report
router.get('/report/contributions/monthly', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT MONTH(created_at) as month, YEAR(created_at) as year, SUM(amount) as total FROM transactions WHERE status = ? GROUP BY YEAR(created_at), MONTH(created_at)', ['approved']);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});


// Add, edit, and manage assets, interest rates, penalties, and investors would be implemented similarly.

// Get transactions for a specific investor
router.get('/investor/:id/transactions', async (req, res) => {
  const { id } = req.params;
  try {
    const [transactions] = await pool.query('SELECT * FROM transactions WHERE investor_id = ? ORDER BY created_at DESC', [id]);
    res.json(transactions);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

export default router;
