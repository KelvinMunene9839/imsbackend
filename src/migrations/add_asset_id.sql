ALTER TABLE transactions 
ADD COLUMN asset_id INT,
ADD CONSTRAINT fk_transactions_asset 
FOREIGN KEY (asset_id) REFERENCES assets(id);