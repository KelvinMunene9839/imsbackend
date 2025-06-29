import express from 'express';
import pool from './db.js';
import multer from 'multer';

const router = express.Router();
const upload = multer({ dest: 'uploads/' });

// Get investor dashboard (self)
router.get('/me', async (req, res) => {
  const investorId = req.query.id;
  if (!investorId) return res.status(400).json({ message: 'Investor id required.' });
  try {
    const [investorRows] = await pool.query('SELECT id, name, email, total_contributions, status FROM investors WHERE id = ?', [investorId]);
    if (investorRows.length === 0) return res.status(404).json({ message: 'Investor not found.' });
    // Get transactions
    const [transactions] = await pool.query('SELECT * FROM transactions WHERE investor_id = ?', [investorId]);
    // Calculate percentage share
    const [[{ totalAll }]] = await pool.query('SELECT SUM(total_contributions) as totalAll FROM investors');
    let percentage_share = 0;
    if (totalAll && totalAll > 0) {
      percentage_share = Number((((investorRows[0].total_contributions || 0) / totalAll) * 100).toFixed(2));
    }
    res.json({ ...investorRows[0], percentage_share, transactions });
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
    // Update total_contributions for the investor (sum of all approved and pending transactions)
    const [[{ total }]] = await pool.query('SELECT SUM(amount) as total FROM transactions WHERE investor_id = ?', [investorId]);
    await pool.query('UPDATE investors SET total_contributions = ? WHERE id = ?', [total || 0, investorId]);
    res.status(201).json({ message: 'Transaction submitted for approval.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Update investor profile (name, email, and image)
router.patch('/me', upload.single('image'), async (req, res) => {
  const investorId = req.query.id;
  if (!investorId) return res.status(400).json({ message: 'Investor id required.' });
  const { name, email } = req.body;
  let imageUrl;
  if (req.file) {
    imageUrl = `/uploads/${req.file.filename}`;
  }
  try {
    // Update name, email, and image if provided
    const fields = [];
    const values = [];
    if (name) {
      fields.push('name = ?');
      values.push(name);
    }
    if (email) {
      fields.push('email = ?');
      values.push(email);
    }
    if (imageUrl) {
      fields.push('imageUrl = ?');
      values.push(imageUrl);
    }
    if (fields.length === 0) return res.status(400).json({ message: 'No fields to update.' });
    values.push(investorId);
    await pool.query(`UPDATE investors SET ${fields.join(', ')} WHERE id = ?`, values);
    res.json({ message: 'Profile updated.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

export default router;
