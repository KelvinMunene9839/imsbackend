import express from 'express';
import pool from './db.js';

const router = express.Router();

// Set or update interest rate
router.post('/interest-rate', async (req, res) => {
  const { rate, start_date, end_date } = req.body;
  try {
    await pool.query('INSERT INTO interest_rates (rate, start_date, end_date) VALUES (?, ?, ?)', [rate, start_date, end_date]);
    res.status(201).json({ message: 'Interest rate set.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get all interest rates
router.get('/interest-rates', async (req, res) => {
  try {
    const [rates] = await pool.query('SELECT * FROM interest_rates ORDER BY start_date DESC');
    res.json(rates);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Set or update penalty
router.post('/penalty', async (req, res) => {
  const { amount, reason, investor_id, date } = req.body;
  try {
    await pool.query('INSERT INTO penalties (amount, reason, investor_id, date) VALUES (?, ?, ?, ?)', [amount, reason, investor_id, date]);
    res.status(201).json({ message: 'Penalty applied.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error. ' });
  }
});

// Get all penalties
router.get('/penalties', async (req, res) => {
  try {
    const [penalties] = await pool.query('SELECT p.*, i.name as investor_name FROM penalties p JOIN investors i ON p.investor_id = i.id ORDER BY date DESC');
    res.json(penalties);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

export default router;
