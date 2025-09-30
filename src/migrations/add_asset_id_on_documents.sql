ALTER TABLE asset_documents 
ADD COLUMN asset_id INT,
ADD CONSTRAINT fk_asset_documents_asset 
FOREIGN KEY (asset_id) REFERENCES assets(id);