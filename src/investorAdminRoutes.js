import bcrypt from 'bcrypt';
import express from 'express';
import pool from './db.js';

const router = express.Router();

// Add a new investor
router.post('/investor', async (req, res) => {
  const { name, email, password, date_of_joining, national_id_number } = req.body;
  try {
    const [existing] = await pool.query('SELECT id FROM investors WHERE email = ?', [email]);
    if (existing.length > 0) return res.status(400).json({ message: 'Email already registered.' });

    // Check if national_id_number already exists
    if (national_id_number) {
      const [existingNationalId] = await pool.query('SELECT id FROM investors WHERE national_id_number = ?', [national_id_number]);
      if (existingNationalId.length > 0) return res.status(400).json({ message: 'National ID number already registered.' });
    }

    const hash = await bcrypt.hash(password, 10);
    await pool.query(
      'INSERT INTO investors (name, email, password_hash, date_of_joining, national_id_number) VALUES (?, ?, ?, ?, ?)',
      [name, email, hash, date_of_joining || null, national_id_number || null]
    );
    res.status(201).json({ message: 'Investor added successfully.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.', error: err.message });
  }
});

// Update investor details
router.put('/investor/:id', async (req, res) => {
  try {
    const { name, email, date_of_joining, national_id_number } = req.body;
    const { id } = req.params;
    if (!name || !email) {
      return res.status(400).json({ message: "Name and email are required." });
    }

    // Check if national_id_number already exists for another investor
    if (national_id_number) {
      const [existingNationalId] = await pool.query('SELECT id FROM investors WHERE national_id_number = ? AND id != ?', [national_id_number, id]);
      if (existingNationalId.length > 0) return res.status(400).json({ message: 'National ID number already registered to another investor.' });
    }

    await pool.query(
      'UPDATE investors SET name = ?, email = ?, date_of_joining = ?, national_id_number = ? WHERE id = ?',
      [name, email, date_of_joining || null, national_id_number || null, id]
    );
    res.json({ message: 'Investor updated successfully.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.', error: err.message });
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
    const [investors] = await pool.query('SELECT id, name, email, status, date_of_joining, national_id_number, created_at FROM investors ORDER BY created_at DESC');
    res.status(200).json({message:"Investors found successfully" ,investors,number:investors.length});
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Delete investor
router.delete('/investor/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const [result] = await pool.query('DELETE FROM investors WHERE id = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Investor not found.' });
    }
    res.json({ message: 'Investor deleted successfully.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.', error: err.message });
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
