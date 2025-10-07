import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './authRoutes.js';
import investorRoutes from './investorRoutes.js';
import adminRoutes from './adminRoutes.js';
import assetRoutes from './assetRoutes.js';
import investorAdminRoutes from './investorAdminRoutes.js';
import interestPenaltyRoutes from './interestPenaltyRoutes.js';
import reportRoutes from './reportRoutes.js';
import bondRoutes from './bondRoutes.js';
import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import { documentRouter } from './document.js';
import fs from 'fs';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// Create upload directories if they don't exist
const uploadDirs = ['uploads/profiles', 'uploads/documents'];
uploadDirs.forEach(dir => {
  const dirPath = path.join(process.cwd(), dir);
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
});

// Middleware
app.use(express.json()); 
app.use(express.urlencoded({ extended: true })); 

app.use(cors({
  origin: 'http://localhost:5173',
  credentials: true
}));

// Multer configuration - UPDATED for separate folders
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Default to documents folder for backward compatibility
    cb(null, './uploads/documents');
  },
  filename: (_, file, cb) =>
    cb(null, Date.now() + '-' + Math.round(Math.random() * 1e9) + '-' + file.originalname)
});

const allowed = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg'];
const upload = multer({
  storage,
  fileFilter: (_, file, cb) =>
    allowed.includes(file.mimetype)
      ? cb(null, true)
      : cb(new Error('Only PDF, JPG, PNG, JPEG allowed')),
  limits: { fileSize: 10 * 1024 * 1024 },
});

// Serve static files from separate directories - UPDATED
app.use('/uploads/profiles', express.static(path.join(process.cwd(), 'uploads/profiles')));
app.use('/uploads/documents', express.static(path.join(process.cwd(), 'uploads/documents')));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/investor', investorRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/admin', assetRoutes);
app.use('/api/admin', investorAdminRoutes);
app.use('/api/admin', interestPenaltyRoutes);
app.use('/api/admin', reportRoutes);
app.use('/api/admin', bondRoutes);
app.use('/api/documents', documentRouter);

// Health check
app.get('/', (req, res) => {
  res.send('Investor Management System API is running.');
});

// Error handling middleware
app.use((error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({ error: 'File too large' });
    }
  }
  if (error.message === 'Only PDF, JPG, PNG, JPEG allowed') {
    return res.status(400).json({ error: error.message });
  }
  console.error('Unhandled error:', error);
  res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});