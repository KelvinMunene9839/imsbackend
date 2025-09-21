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
-- Migration: Add date_of_joining and national_id_number to investors table
-- Date: 2024
-- Description: Adding new fields for investor information

USE ims;

-- Add new columns to investors table
ALTER TABLE investors
ADD COLUMN date_of_joining DATE DEFAULT NULL AFTER status,
ADD COLUMN national_id_number VARCHAR(50) UNIQUE AFTER date_of_joining;

-- Add index for national_id_number for better query performance
CREATE INDEX idx_investors_national_id ON investors(national_id_number);

-- Add index for date_of_joining for better query performance
CREATE INDEX idx_investors_date_of_joining ON investors(date_of_joining);
