
import express from 'express';
import pool from './db.js';
import upload from './uploadMiddleware.js';
// import path from 'path';

const router = express.Router();

// Get investor dashboard (self)
router.get('/me', async (req, res) => {
  const investorId = req.query.id;
  if (!investorId) return res.status(400).json({ message: 'Investor id required.' });
  try {
    const [investorRows] = await pool.query('SELECT id, name, email, total_bonds, status,image FROM investors WHERE id = ?', [investorId]);
    investorRows[0].image = `${req.protocol}://${req.get('host')}/uploads/${path.basename(investorRows[0].image)}`;

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


// Update investor profile (including image)
// Make sure your frontend sends the file with the field name 'image' (e.g., formData.append('image', file))
// PUT /api/investor/me/:id
import path from 'path';

router.put('/me/:id', upload.single('image'), async (req, res) => {
  const investorId = req.params.id;
  if (!investorId) {
    return res.status(400).json({ message: 'Investor id required.' });
  }

  const { name, status } = req.body;
  let image;

  try {
    // check current image
    const [currentRows] = await pool.query(
      'SELECT image FROM investors WHERE id = ?',
      [investorId]
    );
    if (currentRows.length === 0) {
      return res.status(404).json({ message: 'Investor not found.' });
    }
    const currentImage = currentRows[0].image;

    // set image path
    if (req.file) {
      image = `/uploads/${req.file.filename}`;
    } else if (currentImage) {
      image = currentImage;
    }

    // collect fields
    const fields = [];
    const values = [];
    if (name) { fields.push('name = ?'); values.push(name); }
    if (status) { fields.push('status = ?'); values.push(status); }
    if (image) { fields.push('image = ?'); values.push(image); }

    if (fields.length === 0) {
      return res.status(400).json({ message: 'No fields to update.' });
    }

    values.push(investorId);
    const sql = `UPDATE investors SET ${fields.join(', ')} WHERE id = ?`;
    const [result] = await pool.query(sql, values);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Investor not found.' });
    }

    // return updated row with absolute image URL
    const [rows] = await pool.query('SELECT id,name,email,total_bonds,status,image FROM investors WHERE id = ?', [investorId]);
    const updated = rows[0];
    if (updated.image) {
      updated.image = `${req.protocol}://${req.get('host')}/uploads/${path.basename(updated.image)}`;
    }

    res.json(updated);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error.' });
  }
});

router.get("/anounce/latest", async (req, res) => {
  try {
    // Order by created_at if you have a timestamp column
    const [rows] = await pool.query(
      "SELECT id, title, content, created_at FROM anouncements ORDER BY created_at DESC LIMIT 1"
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: "No announcements found." });
    }

    res.json(rows); // send the latest record only
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error." });
  }
});


export default router;
