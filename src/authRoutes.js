import express from 'express';
import { registerInvestor, loginInvestor, loginAdmin, getUser } from './authController.js';

const router = express.Router();

// Investor registration
router.post('/investor/register', registerInvestor);
// Investor login
router.post('/investor/login', loginInvestor);
// Admin login
router.post('/admin/login', loginAdmin);
router.get('/investor/profile', getUser);

export default router;
