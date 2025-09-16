import express from 'express';
import pool from './db.js';

const router = express.Router();

// Add a new bond contribution for an investor
router.post('/bond', async (req, res) => {
  const { investor_id, bond_amount, interest_rate, maturity_months, start_date } = req.body;
  try {
    // Insert bond
    const [result] = await pool.query('INSERT INTO bond_contributions (investor_id, bond_amount, interest_rate, maturity_months, start_date) VALUES (?, ?, ?, ?, ?)', [investor_id, bond_amount, interest_rate, maturity_months, start_date]);
    const bondId = result.insertId;
    // Insert transaction
    await pool.query('INSERT INTO transactions (investor_id, amount, date, type, status) VALUES (?, ?, ?, ?, ?)', [investor_id, bond_amount, start_date, 'contribution', 'approved']);
    // Update total_bonds
    const [[{ total }]] = await pool.query('SELECT SUM(amount) as total FROM transactions WHERE investor_id = ? AND status = ?', [investor_id, 'approved']);
    await pool.query('UPDATE investors SET total_bonds = ? WHERE id = ?', [total || 0, investor_id]);
    res.status(201).json({ message: 'Bond contribution added.', bondId });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get all bond contributions
router.get('/bonds', async (req, res) => {
  try {
    const [bonds] = await pool.query('SELECT b.*, i.name as investor_name FROM bond_contributions b JOIN investors i ON b.investor_id = i.id ORDER BY b.start_date DESC');
    res.json(bonds);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Add interest to a matured bond
router.post('/interest', async (req, res) => {
  const { bond_id, interest_amount, date } = req.body;
  try {
    // Get bond
    const [bonds] = await pool.query('SELECT * FROM bond_contributions WHERE id = ?', [bond_id]);
    if (bonds.length === 0) return res.status(404).json({ message: 'Bond not found.' });
    const bond = bonds[0];
    // Insert interest transaction
    await pool.query('INSERT INTO transactions (investor_id, amount, date, type, status) VALUES (?, ?, ?, ?, ?)', [bond.investor_id, interest_amount, date, 'interest', 'approved']);
    // Update total_bonds
    const [[{ total }]] = await pool.query('SELECT SUM(amount) as total FROM transactions WHERE investor_id = ? AND status = ?', [bond.investor_id, 'approved']);
    await pool.query('UPDATE investors SET total_bonds = ? WHERE id = ?', [total || 0, bond.investor_id]);
    // Update bond status to matured
    await pool.query('UPDATE bond_contributions SET status = ? WHERE id = ?', ['matured', bond_id]);
    res.status(201).json({ message: 'Interest added.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

export default router;
