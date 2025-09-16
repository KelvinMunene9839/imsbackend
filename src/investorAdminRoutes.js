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
    const { name, email, status } = req.body;
    const { id } = req.params;
    if (!req.body) {
      res.status(400).json({message:"This is not required body"})
    }
    await pool.query('UPDATE investors SET name = ?, email = ?, status = ? WHERE id = ?', [name, email, status, id]);
    res.json({ message: 'Investor updated.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.',err });
  }
});

// Deactivate or suspend investor
router.patch('/investor/:id/status', async (req, res) => {
  const { status } = req.body; // 'active', 'suspended', 'deactivated'
  const { id } = req.params;
  if (!['active', 'suspended', 'deactivated'].includes(status)) return res.status(400).json({ message: 'Invalid status.' });
  try {
    await pool.query('UPDATE investors SET status = ? WHERE id = ?', [status, id]);
    res.json({ message: `Investor status updated to ${status}.` });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
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

export default router;
