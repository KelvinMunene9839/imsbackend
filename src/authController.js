import bcrypt from 'bcrypt';
import pool from './db.js';
import jwt from 'jsonwebtoken'
import dotenv from 'dotenv'

dotenv.config()
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
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required.'
      });
    }

    const [rows] = await pool.query('SELECT * FROM investors WHERE email = ?', [email]);

    if (rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid credentials.'
      });
    }

    const investor = rows[0];
    const match = await bcrypt.compare(password, investor.password_hash);

    if (!match) {
      return res.status(400).json({
        success: false,
        message: 'Invalid credentials.'
      });
    }

    // Generate token
    const token = jwt.sign(
      {id:investor.id,username:investor.name,email:investor.email},process.env.JWT_SECRET,{expiresIn:'1h'}
    );

    // Return consistent response structure
    res.status(200).json({
      success: true,
      token: token,
      role: "investor",
      investorId: investor.id,
      data: {
        id: investor.id,
        name: investor.name,
        email: investor.email
      },
      message: 'Login successful.'
    });

  } catch (err) {
    console.error('Error in loginInvestor:', err);
    res.status(500).json({
      success: false,
      message: 'Server error.'
    });
  }
}

export async function getUser(req,res){
  const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
        return res.status(401).json({message:"Token missing"});
    }
    try {
        const decoded = jwt.verify(token,process.env.JWT_SECRET);
        res.json({message:`Welcome, ${decoded.username}`});
    } catch (err) {
        res.status(403).json({message:'Invalid token',err});
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
    const token = jwt.sign(
      {id:admin.id,username:admin.username,password:admin.password},process.env.JWT_SECRET,{expiresIn:'1h'}
    );
    res.json({ message: 'Login successful.',token:token,role:"admin" });
  } catch (err) {
    console.error('Error in loginAdmin:', err);
    res.status(500).json({ message: 'Server error.' });
  }
}
