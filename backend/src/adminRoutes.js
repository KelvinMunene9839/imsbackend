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

// Add, edit, and manage assets, interest rates, penalties, and investors would be implemented similarly.

export default router;
