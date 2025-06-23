import bcrypt from 'bcrypt';
import pool from './db.js';

export async function registerInvestor(req, res) {
  const { name, email, password } = req.body;
  try {
    const [existing] = await pool.query('SELECT id FROM investors WHERE email = ?', [email]);
    if (existing.length > 0) return res.status(400).json({ message: 'Email already registered.' });
    const hash = await bcrypt.hash(password, 10);
    await pool.query('INSERT INTO investors (name, email, password_hash) VALUES (?, ?, ?)', [name, email, hash]);
    res.status(201).json({ message: 'Investor registered.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
}

export async function loginInvestor(req, res) {
  const { email, password } = req.body;
  try {
    const [rows] = await pool.query('SELECT * FROM investors WHERE email = ?', [email]);
    if (rows.length === 0) return res.status(400).json({ message: 'Invalid credentials.' });
    const investor = rows[0];
    const match = await bcrypt.compare(password, investor.password_hash);
    if (!match) return res.status(400).json({ message: 'Invalid credentials.' });
    // Return id, name, email for frontend
    res.json({ id: investor.id, name: investor.name, email: investor.email, message: 'Login successful.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
}

export async function loginAdmin(req, res) {
  const { email, password } = req.body;
  try {
    const [rows] = await pool.query('SELECT * FROM admins WHERE email = ?', [email]);
    if (rows.length === 0) return res.status(400).json({ message: 'Invalid credentials.' });
    const admin = rows[0];
    if (!admin.password_hash) {
      console.error('Admin user has no password hash:', admin);
      return res.status(500).json({ message: 'Server error: password hash missing.' });
    }
    const match = await bcrypt.compare(password, admin.password_hash);
    if (!match) return res.status(400).json({ message: 'Invalid credentials.' });
    // TODO: Add 2FA check here
    res.json({ message: 'Login successful.' });
  } catch (err) {
    console.error('Error in loginAdmin:', err);
    res.status(500).json({ message: 'Server error.' });
  }
}
