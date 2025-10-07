import express from 'express';
import pool from './db.js';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const router = express.Router();

// UPDATED: Multer configuration for profiles folder
const storage = multer.diskStorage({
  destination: './uploads/profiles', // UPDATED: Save to profiles folder
  filename: (_, file, cb) => {
    const originalName = file.originalname.replace(/\s+/g, '-'); // Replace spaces with hyphens
    cb(null, Date.now() + '-' + Math.round(Math.random() * 1e9) + '-' + originalName);
  },
});

const allowed = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg'];
const upload = multer({
  storage,
  fileFilter: (_, file, cb) => {
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only PDF, JPG, PNG, JPEG allowed'));
    }
  },
  limits: { fileSize: 10 * 1024 * 1024 },
});

// Get investor dashboard (self)
router.get('/me', async (req, res) => {
  const investorId = req.query.id;
  if (!investorId) {
    return res.status(400).json({ message: 'Investor id required.' });
  }

  try {
    const [investorRows] = await pool.query(
      'SELECT id, name, email, total_bonds, status, image FROM investors WHERE id = ?',
      [investorId]
    );

    if (investorRows.length === 0) {
      return res.status(404).json({ message: 'Investor not found.' });
    }

    const investor = investorRows[0];
    
    console.log('=== PROFILE IMAGE DEBUG ===');
    console.log('Raw image from database:', investor.image);
    console.log('Request protocol:', req.protocol);
    console.log('Request host:', req.get('host'));
    
    // ✅ FIX: Properly construct image URL with profiles folder
    if (investor.image) {
      // Remove any leading slashes or uploads/ prefix to avoid double pathing
      const cleanImagePath = investor.image.replace(/^\/?uploads\//, '');
      investor.image = `${req.protocol}://${req.get('host')}/uploads/profiles/${cleanImagePath}`;
      console.log('Final image URL:', investor.image);
    } else {
      console.log('No image found in database');
    }

    // Get transactions
    const [transactions] = await pool.query(
      'SELECT * FROM transactions WHERE investor_id = ?',
      [investorId]
    );

    // Calculate percentage share
    const [[{ totalAll }]] = await pool.query(
      'SELECT SUM(total_bonds) AS totalAll FROM investors'
    );

    const percentage_share =
      totalAll && totalAll > 0
        ? Number((((investor.total_bonds || 0) / totalAll) * 100).toFixed(2))
        : 0;

    res.json({ ...investor, percentage_share, transactions, image:investor.image });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error.',err });
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

router.get('/transactions', async (req, res) => {
  const { investorId, q } = req.query;
  if (!investorId) return res.status(400).json({ message: 'Investor ID required' });

  try {
    const query = `
      SELECT * FROM transactions 
      WHERE investor_id = ? AND 
      (CAST(amount AS CHAR) LIKE ? OR date LIKE ? OR status LIKE ?)
      ORDER BY date DESC
    `;
    const [rows] = await pool.execute(query, [investorId, `%${q}%`, `%${q}%`, `%${q}%`]);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update investor profile (including image)
router.put('/me/:id', upload.single('image'), async (req, res) => {
  const investorId = req.params.id;
  if (!investorId) {
    return res.status(400).json({ message: 'Investor id required.' });
  }

  const { name, status } = req.body;
  
  try {
    // Check if investor exists
    const [currentRows] = await pool.query(
      'SELECT image FROM investors WHERE id = ?',
      [investorId]
    );
    if (currentRows.length === 0) {
      return res.status(404).json({ message: 'Investor not found.' });
    }

    const currentImage = currentRows[0].image;
    let imagePath = currentImage;

    // Handle new image upload
    if (req.file) {
      imagePath = req.file.filename;
      
      // Delete old image if it exists and is different from new one
      if (currentImage && currentImage !== imagePath) {
        // UPDATED: Look in profiles folder
        const oldImagePath = path.join(process.cwd(), 'uploads/profiles', currentImage);
        if (fs.existsSync(oldImagePath)) {
          fs.unlinkSync(oldImagePath);
          console.log(`Deleted old profile image: ${oldImagePath}`);
        }
      }
    }

    // Build update query
    const fields = [];
    const values = [];
    
    if (name) { 
      fields.push('name = ?'); 
      values.push(name); 
    }
    if (status) { 
      fields.push('status = ?'); 
      values.push(status); 
    }
    if (req.file) { 
      fields.push('image = ?'); 
      values.push(imagePath); 
    }

    if (fields.length === 0) {
      return res.status(400).json({ message: 'No fields to update.' });
    }

    values.push(investorId);
    const sql = `UPDATE investors SET ${fields.join(', ')} WHERE id = ?`;
    const [result] = await pool.query(sql, values);
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Investor not found.' });
    }

    // Return updated investor data with proper image URL
    const [rows] = await pool.query(
      'SELECT id, name, email, total_bonds, status, image FROM investors WHERE id = ?', 
      [investorId]
    );
    
    const updatedInvestor = rows[0];
    
    // ✅ FIX: Construct proper image URL for response with profiles folder
    if (updatedInvestor.image) {
        const cleanImagePath = updatedInvestor.image.replace(/^\/?uploads\//, '');
        updatedInvestor.image = `${req.protocol}://${req.get('host')}/uploads/profiles/${cleanImagePath}`;
        console.log('Updated profile image URL:', updatedInvestor.image);
    }

    res.json(updatedInvestor);
  } catch (err) {
    console.error('Profile update error:', err);
    res.status(500).json({ message: 'Server error.' });
  }
});

// REMOVED: All document-related routes since they're now in document.js
// Only keeping investor-specific routes

router.get("/anounce/latest", async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT id, title, content, created_at FROM anouncements ORDER BY created_at DESC"
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: "No announcements found." });
    }

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error." });
  }
});

router.get("/search", async (req, res) => {
  const { q } = req.query;

  if (!q || !q.trim()) return res.json([]);

  const searchQuery = `%${q}%`;

  try {
    // Search investors safely
    let investors = [];
    try {
      [investors] = await pool.query(
        "SELECT id, name, 'Investor' AS type FROM investors WHERE name LIKE ? LIMIT 5",
        [searchQuery]
      );
    } catch (err) {
      console.warn("Investors search failed:", err.message);
    }

    // Search assets safely
    let assets = [];
    try {
      [assets] = await pool.query(
        "SELECT id, name, 'Asset' AS type FROM assets WHERE name LIKE ? LIMIT 5",
        [searchQuery]
      );
    } catch (err) {
      console.warn("Assets search failed:", err.message);
    }

    // Search transactions safely
    let transactions = [];
    try {
      [transactions] = await pool.query(
        "SELECT id, CONCAT('Transaction #', id) AS name, 'Transaction' AS type FROM transactions WHERE status LIKE ? LIMIT 5",
        [searchQuery]
      );
    } catch (err) {
      console.warn("Transactions search failed:", err.message);
    }

    res.json([...investors, ...assets, ...transactions]);
  } catch (err) {
    console.error("Search backend error:", err);
    res.status(500).json({ message: "Search failed" });
  }
});

export default router;