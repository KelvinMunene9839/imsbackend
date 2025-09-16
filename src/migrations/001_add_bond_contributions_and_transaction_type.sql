-- Migration: Add bond_contributions table, type column to transactions, and rename total_contributions to total_bonds

ALTER TABLE transactions ADD COLUMN type ENUM('contribution', 'interest') DEFAULT 'contribution';

ALTER TABLE investors CHANGE COLUMN total_contributions total_bonds DECIMAL(15,2) DEFAULT 0;

CREATE TABLE IF NOT EXISTS bond_contributions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    investor_id INT NOT NULL,
    bond_amount DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    maturity_months INT NOT NULL,
    start_date DATE NOT NULL,
    status ENUM('active', 'matured') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (investor_id) REFERENCES investors(id)
);
