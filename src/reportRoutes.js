import express from 'express';
import pool from './db.js';

const router = express.Router();

// Get yearly contributions for all investors with interest calculations
router.get('/reports/yearly-investments', async (req, res) => {
  try {
    const { year } = req.query;
    const selectedYear = year || new Date().getFullYear();

    // Get all approved transactions for the selected year
    const [transactions] = await pool.query(`
      SELECT
        t.id,
        t.investor_id,
        i.name as investor_name,
        t.amount,
        t.date,
        t.created_at
      FROM transactions t
      JOIN investors i ON t.investor_id = i.id
      WHERE t.status = 'approved'
      AND YEAR(t.date) = ?
      ORDER BY t.date ASC
    `, [selectedYear]);

    // Get interest rates for the selected year
    const [interestRates] = await pool.query(`
      SELECT rate, start_date, end_date
      FROM interest_rates
      WHERE YEAR(start_date) <= ? AND (YEAR(end_date) >= ? OR end_date IS NULL)
      ORDER BY start_date DESC
    `, [selectedYear, selectedYear]);

    // Calculate interest for each transaction
    const transactionsWithInterest = transactions.map(transaction => {
      const transactionDate = new Date(transaction.date);
      const applicableRate = interestRates.find(rate => {
        const startDate = new Date(rate.start_date);
        const endDate = rate.end_date ? new Date(rate.end_date) : new Date();
        return transactionDate >= startDate && transactionDate <= endDate;
      });

      const interestRate = applicableRate ? applicableRate.rate : 0;
      const interestAmount = (transaction.amount * interestRate) / 100;

      return {
        ...transaction,
        interest_rate: interestRate,
        interest_amount: interestAmount,
        total_with_interest: transaction.amount + interestAmount
      };
    });

    // Group by investor and calculate totals
    const investorTotals = {};
    let grandTotal = 0;
    let grandTotalInterest = 0;

    transactionsWithInterest.forEach(transaction => {
      if (!investorTotals[transaction.investor_id]) {
        investorTotals[transaction.investor_id] = {
          investor_id: transaction.investor_id,
          investor_name: transaction.investor_name,
          transactions: [],
          total_contribution: 0,
          total_interest: 0,
          total_with_interest: 0
        };
      }

      investorTotals[transaction.investor_id].transactions.push(transaction);
      investorTotals[transaction.investor_id].total_contribution += transaction.amount;
      investorTotals[transaction.investor_id].total_interest += transaction.interest_amount;
      investorTotals[transaction.investor_id].total_with_interest += transaction.total_with_interest;

      grandTotal += transaction.amount;
      grandTotalInterest += transaction.interest_amount;
    });

    res.json({
      success: true,
      message: 'Yearly investments retrieved successfully',
      data: {
        year: selectedYear,
        transactions: transactionsWithInterest,
        investor_totals: Object.values(investorTotals),
        summary: {
          total_contribution: grandTotal,
          total_interest: grandTotalInterest,
          total_with_interest: grandTotal + grandTotalInterest
        }
      }
    });
  } catch (error) {
    console.error('Error fetching yearly investments:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch yearly investments',
      error: error.message
    });
  }
});

// Get contribution history for a specific investor
router.get('/reports/investor-history/:investorId', async (req, res) => {
  try {
    const { investorId } = req.params;

    const [rows] = await pool.query(`
      SELECT
        id,
        amount,
        type,
        status,
        date,
        created_at
      FROM transactions
      WHERE investor_id = ? AND status IN ('approved', 'pending')
      ORDER BY created_at DESC
    `, [investorId]);

    res.json({
      success: true,
      message: 'Investor contribution history retrieved successfully',
      data: rows
    });
  } catch (error) {
    console.error('Error fetching investor history:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch investor contribution history',
      error: error.message
    });
  }
});

export default router;
