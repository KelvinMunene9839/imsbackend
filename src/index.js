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

dotenv.config();

const app = express();
app.use(express.json());
app.use(express.json({ extended: true }));
app.use(cors({
  origin: 'http://localhost:5173', // React frontend URL
  credentials: true
}));


// Serve static files from uploads directory
app.use('/uploads', express.static('uploads/documents'));
const storage = multer.diskStorage({
  destination: './uploads/documents',
  filename: (_, file, cb) =>
    cb(null, Date.now() + '-' + Math.round(Math.random() * 1e9) + '-' + file.originalname),
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
app.get('/', (req, res) => {
  res.send('Investor Management System API is running. ');
});


app.use('/api/auth', authRoutes);
app.use('/api/investor', investorRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/admin', assetRoutes);
app.use('/api/admin', investorAdminRoutes);
app.use('/api/admin', interestPenaltyRoutes);
app.use('/api/admin', reportRoutes);
app.use('/api/admin', bondRoutes);

const PORT = process.env.PORT || 4000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
