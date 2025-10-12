import express from 'express';
import pool from './db.js';

const router = express.Router();

// Get investor dashboard (self)
router.get('/me', async (req, res) => {
  const investorId = req.query.id;
  if (!investorId) return res.status(400).json({ message: 'Investor id required.' });
  try {
    const [investorRows] = await pool.query('SELECT id, name, email, total_bonds, status FROM investors WHERE id = ?', [investorId]);
    if (investorRows.length === 0) return res.status(404).json({ message: 'Investor not found.' });
    // Get transactions
    const [transactions] = await pool.query('SELECT * FROM transactions WHERE investor_id = ?', [investorId]);
    // Calculate percentage share
    const [[{ totalAll }]] = await pool.query('SELECT SUM(total_bonds) as totalAll FROM investors');
    let percentage_share = 0;
    if (totalAll && totalAll > 0) {
      percentage_share = Number((((investorRows[0].total_bonds || 0) / totalAll) * 100).toFixed(2));
    }
    res.json({ ...investorRows[0], percentage_share, transactions });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Record a new transaction (pending approval) - now as bond contribution
router.post('/transaction', async (req, res) => {
  const investorId = req.query.id;
  if (!investorId) return res.status(400).json({ message: 'Investor id required.' });
  const { amount, date } = req.body;
  try {
    // Insert bond contribution with default values
    const interestRate = 5; // default 5%
    const maturityMonths = 12; // default 12 months
    const [result] = await pool.query('INSERT INTO bond_contributions (investor_id, bond_amount, interest_rate, maturity_months, start_date) VALUES (?, ?, ?, ?, ?)', [investorId, amount, interestRate, maturityMonths, date]);
    const bondId = result.insertId;
    // Insert transaction
    await pool.query('INSERT INTO transactions (investor_id, amount, date, type, status) VALUES (?, ?, ?, ?, ?)', [investorId, amount, date, 'contribution', 'pending']);
    // Update total_bonds for the investor (sum of all approved and pending transactions)
    const [[{ total }]] = await pool.query('SELECT SUM(amount) as total FROM transactions WHERE investor_id = ?', [investorId]);
    await pool.query('UPDATE investors SET total_bonds = ? WHERE id = ?', [total || 0, investorId]);
    res.status(201).json({ message: 'Bond contribution submitted for approval.', bondId });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get latest announcements
router.get('/announce/latest', async (req, res) => {
  try {
    // For now, return a static announcement. In a real app, this would fetch from a database
    const announcements = [
      {
        id: 1,
        title: "Welcome to the Investor Management System",
        content: "Thank you for joining our platform. Your investments are secure and growing.",
        created_at: new Date().toISOString()
      },
      {
        id: 2,
        title: "New Features Available",
        content: "We've added new reporting features to help you track your investments better.",
        created_at: new Date().toISOString()
      }
    ];
    res.json(announcements);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

export default router;
