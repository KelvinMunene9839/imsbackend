import express from 'express';
import pool from './db.js';

const router = express.Router();

// Get all transactions
router.get('/transactions', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT t.id,t.investor_id,i.name,t.amount,t.date,t.status,t.created_at,t.type FROM transactions AS t JOIN investors AS i ON t.investor_id = i.id ORDER BY t.created_at DESC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get all pending transactions
router.get('/transactions/pending', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT t.*, i.name as investor_name FROM transactions t JOIN investors i ON t.investor_id = i.id WHERE t.status = ?', ['pending']);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});


// Approve or reject a transaction
router.patch('/transaction/:id', async (req, res) => {
  const { status } = req.body; // 'approved' or 'rejected'
  const { id } = req.params;
  if (!['approved', 'rejected'].includes(status)) return res.status(400).json({ message: 'Invalid status.' });

  try {
    // First check if transaction exists
    const [existingTransaction] = await pool.query('SELECT * FROM transactions WHERE id = ?', [id]);
    if (existingTransaction.length === 0) {
      return res.status(404).json({ message: 'Transaction not found.' });
    }

    // Update transaction status
    await pool.query('UPDATE transactions SET status = ? WHERE id = ?', [status, id]);

    // After status update, recalculate total_bonds for the investor
    const [[{ investor_id }]] = await pool.query('SELECT investor_id FROM transactions WHERE id = ?', [id]);
    if (investor_id) {
      const [[{ total }]] = await pool.query('SELECT SUM(amount) as total FROM transactions WHERE investor_id = ? AND status = ?', [investor_id, 'approved']);
      await pool.query('UPDATE investors SET total_bonds = ? WHERE id = ?', [total || 0, investor_id]);
    }

    res.json({ message: `Transaction ${status} successfully.` });
  } catch (err) {
    console.error('Error updating transaction:', err);
    res.status(500).json({ message: 'Server error.', error: err.message });
  }
});
// Update investor
router.patch('/investor/:id', async (req, res) => {
  const { id } = req.params;
  const { name, email, password, status } = req.body;
  try {
    // Update name/email/status
    await pool.query('UPDATE investors SET name = ?, email = ?, status = ? WHERE id = ?', [name, email, status || 'active', id]);
    // Optionally update password if provided
    if (password) {
      await pool.query('UPDATE investors SET password = ? WHERE id = ?', [password, id]);
    }
    res.json({ message: 'Investor updated.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Delete investor
router.delete('/investor/:id', async (req, res) => {
  const { id } = req.params;
  try {
    await pool.query('DELETE FROM investors WHERE id = ?', [id]);
    res.json({ message: 'Investor deleted.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get all investors
router.get('/investors', async (req, res) => {
  try {
    const [investors] = await pool.query('SELECT id, name, email, status FROM investors');
    res.json(investors);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get pending approvals (transactions)
router.get('/pending-approvals', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT t.*, i.name as investor_name FROM transactions t JOIN investors i ON t.investor_id = i.id WHERE t.status = ?', ['pending']);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get assets report
router.get('/report/assets', async (req, res) => {
  try {
    const [assets] = await pool.query('SELECT * FROM assets');
    res.json({message:"Assets shown successfully",count:assets.length,assets});
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get yearly contributions report
router.get('/report/contributions/yearly', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT YEAR(created_at) as year, SUM(amount) as total FROM transactions WHERE status = ? GROUP BY YEAR(created_at)', ['approved']);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get total asset value
router.get('/total-asset-value', async (req, res) => {
  try {
    const [[{ total }]] = await pool.query('SELECT SUM(value) as total FROM assets');
    res.json({ total: total || 0 });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get interests report
router.get('/report/interests', async (req, res) => {
  try {
    const [interests] = await pool.query('SELECT * FROM interest_rates');
    res.json(interests);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get monthly contributions report
router.get('/report/contributions/monthly', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT MONTH(created_at) as month, YEAR(created_at) as year, SUM(amount) as total FROM transactions WHERE status = ? GROUP BY YEAR(created_at), MONTH(created_at)', ['approved']);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});


// Add, edit, and manage assets, interest rates, penalties, and investors would be implemented similarly.

// Get transactions for a specific investor
router.get('/investor/:id/transactions', async (req, res) => {
  const { id } = req.params;
  try {
    const [transactions] = await pool.query('SELECT * FROM transactions WHERE investor_id = ? ORDER BY created_at DESC', [id]);
    res.json(transactions);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get total contributions for all investors
router.get('/investor/total_contributions', async (req, res) => {
  try {
    const [investors] = await pool.query('SELECT id, name, total_bonds as totalContributions FROM investors');
    res.json(investors);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get ownership summary for all assets
router.get('/ownership-summary', async (req, res) => {
  try {
    // Get all assets with their ownership information
    const [assets] = await pool.query(`
      SELECT a.id, a.name, a.value,
             JSON_ARRAYAGG(
               JSON_OBJECT(
                 'investor_id', i.id,
                 'name', i.name,
                 'amount', COALESCE(SUM(t.amount), 0),
                 'percentage', CASE
                   WHEN a.value > 0 THEN (COALESCE(SUM(t.amount), 0) / a.value) * 100
                   ELSE 0
                 END
               )
             ) as ownerships
      FROM assets a
      LEFT JOIN transactions t ON t.asset_id = a.id AND t.status = 'approved'
      LEFT JOIN investors i ON t.investor_id = i.id
      GROUP BY a.id, a.name, a.value
      ORDER BY a.name
    `);

    // Clean up the ownership data
    const cleanedAssets = assets.map(asset => ({
      ...asset,
      ownerships: asset.ownerships ? asset.ownerships.filter(o => o.name !== null) : []
    }));

    res.json(cleanedAssets);
  } catch (err) {
    console.error('Error fetching ownership summary:', err);
    res.status(500).json({ message: 'Server error.' });
  }
});

router.post('/anounce', async (req, res) => {
    const { title, content } = req.body || {};
    if (!title || !content || title.trim() === "" || content.trim() === "") {
        return res.status(400).json({ message: "Title and content are required." });
    }
    try {
        await pool.query('INSERT INTO anouncements (title,content) VALUES (?,?)', [title, content]);
        res.status(201).json({ message: "Anouncement created successfully.", title, content });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "Server error." });
    }
});
export default router;
