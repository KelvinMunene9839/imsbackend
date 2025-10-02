import express from 'express';
import pool from './db.js';
import bcrypt from 'bcrypt';
const router = express.Router();

// Get all transactions
router.get('/transactions', async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT t.id, t.investor_id, i.name AS investor_name, t.amount, t.date, t.status, t.created_at, t.type, a.name AS asset_name FROM transactions AS t JOIN investors AS i ON t.investor_id = i.id LEFT JOIN assets AS a ON t.asset_id = a.id ORDER BY t.created_at DESC");
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

//Approve transaction
// Update transaction status (approve/reject)
router.patch('/transactions/:id', async (req, res) => {
  try {
    const transactionId = req.params.id;
    const { status } = req.body;

    console.log(`🔄 Updating transaction ${transactionId} to status: ${status}`);

    // Validate status
    if (!status || !['pending', 'approved', 'rejected'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status. Must be: pending, approved, or rejected.' });
    }

    // Update only the status field
    const [result] = await pool.query(
      'UPDATE transactions SET status = ? WHERE id = ?',
      [status, transactionId]
    );

    console.log('✅ Update result:', result);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Transaction not found.' });
    }

    res.json({ 
      message: `Transaction ${status} successfully.`,
      affectedRows: result.affectedRows 
    });

  } catch (err) {
    console.error('❌ Update error:', err);
    res.status(500).json({ 
      message: 'Failed to update transaction',
      error: err.message,
      code: err.code 
    });
  }
});
// Update investor
router.patch('/investor/:id', async (req, res) => {
  try {
    const investorId = req.params.id;
    const { name, email, password, status, date_of_joining, national_id_number } = req.body;
    
    console.log('🔄 Updating investor ID:', investorId);
    console.log('📦 Received data:', { ...req.body, password: password ? '[HIDDEN]' : undefined });

    // Validation
    if (!name || !email) {
      return res.status(400).json({ message: 'Name and email are required.' });
    }

    // Convert date format from ISO to YYYY-MM-DD
    let formattedDate = null;
    if (date_of_joining) {
      const date = new Date(date_of_joining);
      if (!isNaN(date.getTime())) {
        formattedDate = date.toISOString().split('T')[0]; // Get YYYY-MM-DD part
        console.log('📅 Formatted date:', formattedDate);
      }
    }

    // Build update query dynamically
    let updateFields = [];
    let queryParams = [];

    updateFields.push('name = ?', 'email = ?', 'status = ?');
    queryParams.push(name, email, status || 'active');

    if (formattedDate) {
      updateFields.push('date_of_joining = ?');
      queryParams.push(formattedDate);
    } else if (date_of_joining === null || date_of_joining === '') {
      updateFields.push('date_of_joining = NULL');
    }

    if (national_id_number) {
      updateFields.push('national_id_number = ?');
      queryParams.push(national_id_number);
    }

    // Update password if provided
    if (password) {
      console.log('🔑 Hashing and updating password');
      const hash = await bcrypt.hash(password, 10);
      updateFields.push('password_hash = ?');
      queryParams.push(hash);
    }

    queryParams.push(investorId);

    const updateQuery = `UPDATE investors SET ${updateFields.join(', ')} WHERE id = ?`;
    
    console.log('📝 Executing query:', updateQuery);
    console.log('🔢 Query parameters:', queryParams.map(param => 
      param === queryParams[queryParams.length - (password ? 2 : 1)] ? '[HASHED_PASSWORD]' : param
    ));

    // Execute single update query
    const [result] = await pool.query(updateQuery, queryParams);
    
    console.log('✅ Update result:', result);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Investor not found.' });
    }

    res.json({ 
      message: 'Investor updated successfully.',
      affectedRows: result.affectedRows 
    });

  } catch (err) {
    console.error('❌ Update error:', err);
    res.status(500).json({ 
      message: 'Failed to update investor',
      error: err.message,
      code: err.code 
    });
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
    const [rows] = await pool.query('SELECT MONTH(created_at) as month, YEAR(created_at) as year, SUM(amount) as total , SUM(amount)/count(id) as average FROM transactions WHERE status = ? GROUP BY YEAR(created_at), MONTH(created_at)', ['approved']);
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
    // Get assets first
    const [assets] = await pool.query('SELECT id, name, value FROM assets ORDER BY name');
    
    // Get ownership data separately
    const [ownershipData] = await pool.query(`
      SELECT 
        a.id as asset_id,
        i.id as investor_id,
        i.name,
        SUM(t.amount) as amount,
        (SUM(t.amount) / a.value) * 100 as percentage
      FROM assets a
      JOIN transactions t ON t.asset_id = a.id AND t.status = 'approved'
      JOIN investors i ON t.investor_id = i.id
      WHERE a.value > 0
      GROUP BY a.id, i.id, i.name, a.value
    `);

    // Combine the data
    const assetsWithOwnership = assets.map(asset => {
      const ownerships = ownershipData
        .filter(o => o.asset_id === asset.id)
        .map(({ asset_id, ...rest }) => rest);
      
      return {
        ...asset,
        ownerships
      };
    });

    res.json(assetsWithOwnership);
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


// routes/adminRoutes.js

router.get('/search', async (req, res) => {
  try {
    const { q } = req.query;
    if (!q || q.trim() === '') {
      return res.json({ assets: [], investors: [], transactions: [] });
    }

    const query = `%${q}%`;

    const [assets] = await pool.query(
      `SELECT id, name, value FROM assets WHERE name LIKE ? OR id LIKE ?`,
      [query, query]
    );

    const [investors] = await pool.query(
      `SELECT id, name, email FROM investors WHERE name LIKE ? OR email LIKE ?`,
      [query, query]
    );

    const [transactions] = await pool.query(
      `SELECT 
         t.id,
         t.amount,
         t.status,
         t.type,
         t.date,
         i.name AS investor_name,
         a.name AS asset_name
       FROM transactions t
       JOIN investors i ON t.investor_id = i.id
       LEFT JOIN assets a ON t.asset_id = a.id
       WHERE i.name LIKE ? OR a.name LIKE ? OR t.type LIKE ?`,
      [query, query, query]
    );

    res.json({ assets, investors, transactions });
  } catch (err) {
    console.error('Error running search:', err);
    res.status(500).json({ message: 'Server error.' });
  }
});

export default router;
