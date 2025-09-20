import bcrypt from 'bcrypt';
import express from 'express';
import pool from './db.js';

const router = express.Router();

// Add a new investor
router.post('/investor', async (req, res) => {
  const { name, email, password } = req.body;
  try {
    const [existing] = await pool.query('SELECT id FROM investors WHERE email = ?', [email]);
    if (existing.length > 0) return res.status(400).json({ message: 'Email already registered.' });
    const hash = await bcrypt.hash(password, 10);
    await pool.query('INSERT INTO investors (name, email, password_hash) VALUES (?, ?, ?)', [name, email, hash]);
    res.status(201).json({ message: 'Investor added.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Update investor details
router.put('/investor/:id', async (req, res) => {
  try {
    const { name, email } = req.body;
    const { id } = req.params;
    if (!name || !email) {
      return res.status(400).json({ message: "Name, email are required." });
    }
    await pool.query('UPDATE investors SET name = ?, email = ?  WHERE id = ?', [name, email, id]);
    res.json({ message: 'Investor updated.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.', err });
  }
});

// Deactivate or suspend investor
router.patch('/investor/:id/status', async (req, res) => {
  const { status } = req.body; // 'active', 'suspended', 'deactivated'
  const { id } = req.params;
  if (!status) {
    return res.status(400).json({ message: 'Status is required.' });
  }
  if (!['active', 'suspended', 'deactivated'].includes(status)) {
    return res.status(400).json({ message: 'Invalid status.' });
  }
  try {
    const [result] = await pool.query('UPDATE investors SET status = ? WHERE id = ?', [status, id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Investor not found.' });
    }
    res.json({ message: `Investor status updated to ${status}.` });
  } catch (err) {
    res.status(500).json({ message: 'Server error.', error: err.message });
  }
});

// Get all investors
router.get('/investor', async (req, res) => {
  try {
    const [investors] = await pool.query('SELECT id, name, email, status FROM investors');
    res.status(200).json({message:"Investors found successfully" ,investors,number:investors.length});
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get pending transactions
router.get('/transactions/pending', async (req, res) => {
  try {
    const [transactions] = await pool.query('SELECT t.*, i.name as investor_name FROM transactions t JOIN investors i ON t.investor_id = i.id WHERE t.status = ? ORDER BY t.created_at DESC', ['pending']);
    res.json(transactions);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Approve or reject transaction
router.patch('/transaction/:id', async (req, res) => {
  const { id } = req.params;
  const { status } = req.body; // 'approved' or 'rejected'
  if (!['approved', 'rejected'].includes(status)) return res.status(400).json({ message: 'Invalid status.' });
  try {
    await pool.query('UPDATE transactions SET status = ? WHERE id = ?', [status, id]);
    if (status === 'approved') {
      // Update total_bonds
      const [trans] = await pool.query('SELECT investor_id, amount FROM transactions WHERE id = ?', [id]);
      if (trans.length > 0) {
        const { investor_id, amount } = trans[0];
        const [[{ total }]] = await pool.query('SELECT SUM(amount) as total FROM transactions WHERE investor_id = ? AND status = ?', [investor_id, 'approved']);
        await pool.query('UPDATE investors SET total_bonds = ? WHERE id = ?', [total || 0, investor_id]);
      }
    }
    res.json({ message: `Transaction ${status}.` });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get transactions for a specific investor
router.get('/investor/:id/transactions', async (req, res) => {
  const { id } = req.params;
  try {
    const [transactions] = await pool.query('SELECT id, amount, date, type, status FROM transactions WHERE investor_id = ? ORDER BY date DESC', [id]);
    res.json(transactions);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

export default router;
