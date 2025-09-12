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

dotenv.config();

const app = express();
app.use(cors({
  origin: 'http://localhost:5173', // React frontend URL
  credentials: true
}));
app.use(express.json({ extended: true }));


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

const PORT = process.env.PORT || 4000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
