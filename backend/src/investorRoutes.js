import express from 'express';
import pool from './db.js';
import multer from 'multer';
import fs from 'fs/promises'; // Import for file system operations (e.g., deleting old images)
import path from 'path'; // Import for path manipulation

// Determine __dirname for ES Modules
import { fileURLToPath } from 'url';
import { dirname } from 'path';
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const router = express.Router();

// Configure multer storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Make sure the 'uploads/' directory exists
    // You might want to create it if it doesn't exist on server start
    fs.mkdir(path.join(__dirname, '..', 'uploads'), { recursive: true })
      .then(() => cb(null, path.join(__dirname, '..', 'uploads')))
      .catch(err => cb(err, null));
  },
  filename: (req, file, cb) => {
    // Generate a unique filename using timestamp and original extension
    const ext = path.extname(file.originalname);
    cb(null, `${Date.now()}-${Math.round(Math.random() * 1E9)}${ext}`);
  }
});
const upload = multer({ storage: storage });

// Serve static files (important for images)
// This should ideally be in your main app.js or index.js
// but adding here for completeness if this is your only file that needs it.
// If you have a central Express app file, move this there:
// app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));
// For now, let's just make sure the `imageUrl` path is correct.
// The frontend will request: http://your_backend_url/uploads/filename.ext

// Route for adding a new investor (with image upload)
router.post('/admin/investor', upload.single('image'), async (req, res) => {
  const { name, email, password } = req.body;
  let imageUrl = null;

  if (req.file) {
    imageUrl = `/uploads/${req.file.filename}`;
  }

  if (!name || !email || !password) {
    return res.status(400).json({ message: 'Name, email, and password are required.' });
  }

  try {
    // Check if investor with this email already exists
    const [existingInvestors] = await pool.query('SELECT id FROM investors WHERE email = ?', [email]);
    if (existingInvestors.length > 0) {
      if (req.file) { // If an image was uploaded, delete it before sending error
        await fs.unlink(path.join(__dirname, '..', req.file.path));
      }
      return res.status(409).json({ message: 'Investor with this email already exists.' });
    }

    // Hash password before saving (recommended: use bcrypt)
    // For simplicity, not hashing here, but DO NOT store plain passwords in production
    const [result] = await pool.query(
      'INSERT INTO investors (name, email, password, imageUrl) VALUES (?, ?, ?, ?)',
      [name, email, password, imageUrl]
    );
    res.status(201).json({ message: 'Investor added successfully', investorId: result.insertId });
  } catch (err) {
    console.error('Error adding investor:', err);
    if (req.file) { // If an image was uploaded, delete it on error
      try {
        await fs.unlink(path.join(__dirname, '..', req.file.path));
      } catch (fileErr) {
        console.error('Error deleting uploaded file after failed DB insert:', fileErr);
      }
    }
    res.status(500).json({ message: 'Server error: Failed to add investor.' });
  }
});

// Admin get all investors
router.get('/admin/investor', async (req, res) => {
  try {
    const [investors] = await pool.query('SELECT id, name, email, total_contributions, status, imageUrl FROM investors');
    res.json(investors);
  } catch (err) {
    console.error('Error fetching investors:', err);
    res.status(500).json({ message: 'Server error: Failed to fetch investors.' });
  }
});

// Admin update investor profile (name, email, and image)
router.patch('/admin/investor/:id', upload.single('image'), async (req, res) => {
  const investorId = req.params.id; // Get investorId from URL parameters
  const { name, email, password } = req.body; // Password is now optional

  if (!investorId) {
    // This check is technically redundant if using :id in path, but good for clarity
    if (req.file) await fs.unlink(req.file.path); // Clean up if file uploaded
    return res.status(400).json({ message: 'Investor ID required.' });
  }

  try {
    const [investorRows] = await pool.query(
      'SELECT id, imageUrl FROM investors WHERE id = ?',
      [investorId]
    );

    if (investorRows.length === 0) {
      if (req.file) await fs.unlink(req.file.path); // Clean up if file uploaded
      return res.status(404).json({ message: 'Investor not found.' });
    }

    const currentImageUrl = investorRows[0].imageUrl;
    let newImageUrl = currentImageUrl; // Start with current image URL

    if (req.file) {
      // A new image was uploaded
      newImageUrl = `/uploads/${req.file.filename}`;
      // Delete old image file if a new one is uploaded and an old one existed
      if (currentImageUrl && currentImageUrl.startsWith('/uploads/')) {
        const oldImagePath = path.join(__dirname, '..', currentImageUrl);
        try {
          await fs.unlink(oldImagePath);
          console.log(`Deleted old image: ${oldImagePath}`);
        } catch (error) {
          console.error(`Error deleting old image ${oldImagePath}:`, error);
          // Don't block the request if old image deletion fails
        }
      }
    } else if (req.body.imageUrl === 'null' && currentImageUrl) {
        // If frontend explicitly sends imageUrl: null and there was a current image
        // This case handles removal of existing image without uploading new one
        if (currentImageUrl && currentImageUrl.startsWith('/uploads/')) {
            const oldImagePath = path.join(__dirname, '..', currentImageUrl);
            try {
                await fs.unlink(oldImagePath);
                console.log(`Deleted image: ${oldImagePath}`);
            } catch (error) {
                console.error(`Error deleting image ${oldImagePath}:`, error);
            }
        }
        newImageUrl = null; // Set to null in DB
    }


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
    if (password) { // Only update password if provided
      // Hash password before saving (recommended: use bcrypt)
      fields.push('password = ?');
      values.push(password);
    }
    // Always update imageUrl, even if it's null (if removed) or new
    fields.push('imageUrl = ?');
    values.push(newImageUrl);

    if (fields.length === 0) {
      return res.status(400).json({ message: 'No fields to update.' });
    }

    values.push(investorId); // Last value for WHERE clause
    await pool.query(`UPDATE investors SET ${fields.join(', ')} WHERE id = ?`, values);

    // Fetch and return the updated investor data
    const [updatedRows] = await pool.query(
      'SELECT id, name, email, total_contributions, status, imageUrl FROM investors WHERE id = ?',
      [investorId]
    );
    if (updatedRows.length === 0) {
      return res.status(404).json({ message: 'Investor not found after update.' });
    }
    // Calculate percentage share for consistency with GET /me
    const [[{ totalAll }]] = await pool.query('SELECT SUM(total_contributions) as totalAll FROM investors');
    let percentage_share = 0;
    if (totalAll && totalAll > 0) {
      percentage_share = Number((((updatedRows[0].total_contributions || 0) / totalAll) * 100).toFixed(2));
    }
    // Get transactions for this investor
    const [transactions] = await pool.query('SELECT * FROM transactions WHERE investor_id = ?', [investorId]);
    res.json({ ...updatedRows[0], percentage_share, transactions });
  } catch (err) {
    console.error('Error updating investor profile:', err);
    if (req.file) { // Clean up newly uploaded file on error
      try {
        await fs.unlink(req.file.path);
      } catch (fileErr) {
        console.error('Error deleting newly uploaded file after failed DB update:', fileErr);
      }
    }
    res.status(500).json({ message: 'Server error: Failed to update profile.', error: err.message });
  }
});

// Admin delete investor
router.delete('/admin/investor/:id', async (req, res) => {
  const investorId = req.params.id;
  try {
    // First, get the investor's image URL if it exists
    const [investorRows] = await pool.query('SELECT imageUrl FROM investors WHERE id = ?', [investorId]);

    // Delete the investor from the database
    const [result] = await pool.query('DELETE FROM investors WHERE id = ?', [investorId]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Investor not found.' });
    }

    // If an image existed, attempt to delete the file
    if (investorRows.length > 0 && investorRows[0].imageUrl && investorRows[0].imageUrl.startsWith('/uploads/')) {
      const imagePathToDelete = path.join(__dirname, '..', investorRows[0].imageUrl);
      try {
        await fs.unlink(imagePathToDelete);
        console.log(`Deleted investor image file: ${imagePathToDelete}`);
      } catch (fileErr) {
        console.error(`Error deleting investor image file ${imagePathToDelete}:`, fileErr);
        // Continue even if file deletion fails; main record is deleted
      }
    }

    res.json({ message: 'Investor deleted successfully.' });
  } catch (err) {
    console.error('Error deleting investor:', err);
    res.status(500).json({ message: 'Server error: Failed to delete investor.' });
  }
});


// Existing Investor routes (keep these if they are used by investor-facing parts)
// Get investor dashboard (self)
router.get('/me', async (req, res) => {
  const investorId = req.query.id;
  if (!investorId) return res.status(400).json({ message: 'Investor id required.' });
  try {
    const [investorRows] = await pool.query('SELECT id, name, email, total_contributions, status, imageUrl FROM investors WHERE id = ?', [investorId]);
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
    console.error('Error in /me route:', err); // Added error logging
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
    console.error('Error in /transaction route:', err); // Added error logging
    res.status(500).json({ message: 'Server error.' });
  }
});

// Update investor profile (name, email, and image) - THIS IS THE OLD /me ROUTE FOR INVESTORS
// I've kept it separate from the admin update for clarity.
// If you want a single PATCH /me for both admin/investor, you'll need authentication/authorization logic.
// This route is specifically for an investor to update their own profile.
router.patch('/me', upload.single('image'), async (req, res) => {
  const investorId = req.query.id; // Correctly get investorId from query parameters

  if (!investorId) {
    return res.status(400).json({ message: 'Investor id required.' });
  }

  try {
    // Fetch current investor data
    const [investorRows] = await pool.query(
      'SELECT id, name, email, total_contributions, status, imageUrl FROM investors WHERE id = ?',
      [investorId]
    );

    if (investorRows.length === 0) {
      if (req.file) await fs.unlink(req.file.path); // Clean up if file uploaded
      return res.status(404).json({ message: 'Investor not found.' });
    }

    const { name, email } = req.body;
    let newImageUrl = investorRows[0].imageUrl; // Initialize with existing image URL

    if (req.file) {
      // A new image was uploaded
      newImageUrl = `/uploads/${req.file.filename}`;
      // Optional: Delete old image from 'uploads/' directory if it exists
      if (investorRows[0].imageUrl && investorRows[0].imageUrl.startsWith('/uploads/')) {
        const oldImagePath = path.join(__dirname, '..', investorRows[0].imageUrl);
        try {
          await fs.unlink(oldImagePath);
          console.log(`Deleted old image: ${oldImagePath}`);
        } catch (error) {
          console.error(`Error deleting old image ${oldImagePath}:`, error);
          // Don't block the request if old image deletion fails
        }
      }
    } else if (req.body.imageUrl === 'null' && investorRows[0].imageUrl) {
        // If frontend explicitly sends imageUrl: null and there was a current image
        if (investorRows[0].imageUrl.startsWith('/uploads/')) {
            const oldImagePath = path.join(__dirname, '..', investorRows[0].imageUrl);
            try {
                await fs.unlink(oldImagePath);
                console.log(`Deleted image: ${oldImagePath}`);
            } catch (error) {
                console.error(`Error deleting image ${oldImagePath}:`, error);
            }
        }
        newImageUrl = null;
    }


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
    // Always update imageUrl, even if it's null (if removed) or new
    fields.push('imageUrl = ?');
    values.push(newImageUrl);


    if (fields.length === 0) {
      if (req.file) await fs.unlink(req.file.path); // Clean up if file uploaded
      return res.status(400).json({ message: 'No fields to update.' });
    }

    values.push(investorId); // Last value for WHERE clause
    await pool.query(`UPDATE investors SET ${fields.join(', ')} WHERE id = ?`, values);

    // Fetch and return the updated investor data
    const [updatedRows] = await pool.query(
      'SELECT id, name, email, total_contributions, status, imageUrl FROM investors WHERE id = ?',
      [investorId]
    );
    if (updatedRows.length === 0) {
      return res.status(404).json({ message: 'Investor not found after update.' });
    }
    // Calculate percentage share for consistency with GET /me
    const [[{ totalAll }]] = await pool.query('SELECT SUM(total_contributions) as totalAll FROM investors');
    let percentage_share = 0;
    if (totalAll && totalAll > 0) {
      percentage_share = Number((((updatedRows[0].total_contributions || 0) / totalAll) * 100).toFixed(2));
    }
    // Get transactions for this investor
    const [transactions] = await pool.query('SELECT * FROM transactions WHERE investor_id = ?', [investorId]);
    res.json({ ...updatedRows[0], percentage_share, transactions });
  } catch (err) {
    console.error('Error updating investor profile (investor /me route):', err); // Added error logging
    if (req.file) { // Clean up newly uploaded file on error
      try {
        await fs.unlink(req.file.path);
      } catch (fileErr) {
        console.error('Error deleting newly uploaded file after failed DB update:', fileErr);
      }
    }
    res.status(500).json({ message: 'Server error: Failed to update profile.', error: err.message });
  }
});

// Investor login route
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required.' });
  }
  try {
    const [rows] = await pool.query('SELECT id, email, password FROM investors WHERE email = ?', [email]);
    if (rows.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }
    const investor = rows[0];
    // NOTE: In production, use bcrypt to compare hashed passwords!
    if (investor.password !== password) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }
    res.json({ id: investor.id, email: investor.email });
  } catch (err) {
    console.error('Error in investor login:', err);
    res.status(500).json({ error: 'Server error: Failed to login.' });
  }
});


export default router;