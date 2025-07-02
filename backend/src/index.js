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
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json({ extended: true }));

app.get('/', (req, res) => {
  res.send('Investor Management System API is running.');
});

// FIX: Serve uploads from the correct directory (one level up from src)
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));
app.use('/api/auth', authRoutes);
app.use('/api/investor', investorRoutes);
// app.use('api/auth/investor/login',)
app.use('/api/admin', adminRoutes);
app.use('/api/admin', assetRoutes);
app.use('/api/admin', investorAdminRoutes);
app.use('/api/admin', interestPenaltyRoutes);
app.use('/api/admin', reportRoutes);
app.get('/uploads-test/:filename', (req, res) => {
  const filePath = path.join(__dirname, 'uploads', req.params.filename);
  res.sendFile(filePath, err => {
    if (err) {
      res.status(404).send('File not found');
    }
  });
});

console.log('Serving uploads from:', path.join(__dirname, 'uploads'));

const PORT = process.env.PORT || 4000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
