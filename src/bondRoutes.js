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

router.post('/bonds/interest', async (req, res) => {
  try {
    const { bond_id, amount, type, date } = req.body;
    
    // Create interest transaction
    const [result] = await pool.query(
      'INSERT INTO transactions (investor_id, bond_id, amount, type, date, status) VALUES (?, ?, ?, ?, ?, ?)',
      [bond.investor_id, bond_id, amount, type, date, 'pending']
    );
    
    res.json({ message: 'Interest added successfully', transactionId: result.insertId });
  } catch (error) {
    res.status(500).json({ message: 'Failed to add interest', error: error.message });
  }
});


router.post('/bonds/general-interest', async (req, res) => {
  try {
    const { amount, type, date } = req.body;
    
    // Get all active bonds
    const [bonds] = await pool.query('SELECT * FROM bonds WHERE status = "active"');
    
    // Create interest transactions for each bond
    for (const bond of bonds) {
      await pool.query(
        'INSERT INTO transactions (investor_id, bond_id, amount, type, date, status) VALUES (?, ?, ?, ?, ?, ?)',
        [bond.investor_id, bond.id, amount, type, date, 'pending']
      );
    }
    
    res.json({ message: 'General interest added to all bonds successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to add general interest', error: error.message });
  }
});
// Add global interest to all bonds
router.post('/interest/global', async (req, res) => {
  const { interest_amount, date } = req.body;
  try {
    // Get total bonds
    const [[{ totalAllBonds }]] = await pool.query('SELECT SUM(total_bonds) as totalAllBonds FROM investors');
    if (!totalAllBonds || totalAllBonds <= 0) return res.status(400).json({ message: 'No bonds found.' });
    // Get all investors with bonds
    const [investors] = await pool.query('SELECT id, total_bonds FROM investors WHERE total_bonds > 0');
    // For each investor, calculate interest and insert transaction
    for (const inv of investors) {
      const percentage = inv.total_bonds / totalAllBonds;
      const interest = interest_amount * percentage;
      await pool.query('INSERT INTO transactions (investor_id, amount, date, type, status) VALUES (?, ?, ?, ?, ?)', [inv.id, interest, date, 'interest', 'approved']);
      // Update total_bonds
      const [[{ total }]] = await pool.query('SELECT SUM(amount) as total FROM transactions WHERE investor_id = ? AND status = ?', [inv.id, 'approved']);
      await pool.query('UPDATE investors SET total_bonds = ? WHERE id = ?', [total || 0, inv.id]);
    }
    res.status(201).json({ message: 'Global interest added and distributed.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

export default router;
