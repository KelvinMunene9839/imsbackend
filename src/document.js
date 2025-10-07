import express from 'express';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import pool from './db.js';
import multer from 'multer';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = express.Router();

// ✅ ADDED: Multer configuration for document uploads
const storage = multer.diskStorage({
  destination: './uploads/documents',
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    cb(null, 'doc-' + uniqueSuffix + ext);
  }
});

const allowedMimeTypes = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg'];
const upload = multer({
  storage,
  fileFilter: (req, file, cb) => {
    if (allowedMimeTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only PDF, JPG, PNG, JPEG files are allowed'), false);
    }
  },
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
});

// Upload documents for an asset
router.post('/upload', upload.array('documents', 10), async (req, res) => {
  try {
    const { asset_id } = req.body;
    console.log('=== DOCUMENT UPLOAD DEBUG ===');
    console.log('Asset ID from body:', asset_id);
    console.log('Files received:', req.files?.length);
    
    if (!asset_id) {
      console.log('ERROR: No asset_id provided');
      return res.status(400).json({ error: 'asset_id is required' });
    }

    if (!req.files?.length) {
      console.log('ERROR: No files uploaded');
      return res.status(400).json({ error: 'No files uploaded' });
    }

    // Check if asset exists
    const [assets] = await pool.query('SELECT id FROM assets WHERE id = ?', [asset_id]);
    if (assets.length === 0) {
      console.log('ERROR: Asset not found');
      return res.status(404).json({ error: 'Asset not found' });
    }

    console.log('Asset exists, proceeding with upload...');

    const inserts = req.files.map((f) => [
      asset_id,
      f.originalname,
      f.filename, // Store just filename in documents folder
      f.mimetype,
      f.size,
      new Date()
    ]);

    console.log('Inserting documents:', inserts);

    await pool.query(
      'INSERT INTO asset_documents (asset_id, file_name, file_path, mime_type, file_size, uploaded_at) VALUES ?',
      [inserts]
    );

    console.log('Documents inserted successfully');

    res.json({
      message: 'Files uploaded successfully',
      files: req.files.map((f) => ({ 
        name: f.originalname, 
        url: `/uploads/documents/${f.filename}` 
      })),
    });
  } catch (err) {
    console.error('Upload failed:', err);
    res.status(500).json({ error: 'Upload failed: ' + err.message });
  }
});

// Get documents for an asset
router.get('/assets/:assetId', async (req, res) => {
  try {
    const { assetId } = req.params;
    console.log(`Fetching documents for asset ID: ${assetId}`);
    
    const [documents] = await pool.query(
      `SELECT id, file_name as fileName, file_path as filePath, mime_type as mimeType, 
              file_size as fileSize, uploaded_at as uploadedAt, asset_id as assetId
       FROM asset_documents 
       WHERE asset_id = ? 
       ORDER BY uploaded_at DESC`,
      [assetId]
    );

    console.log(`Found ${documents.length} documents for asset ${assetId}`);
    
    // Update file paths to include the correct folder
    const updatedDocuments = documents.map(doc => ({
      ...doc,
      filePath: `documents/${doc.filePath}` // Add documents folder to path
    }));

    res.json(updatedDocuments || []);
  } catch (error) {
    console.error('Error fetching documents:', error);
    res.status(500).json({ error: 'Failed to fetch documents' });
  }
});

// View document (for images preview)
router.get('/view/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const [documents] = await pool.query(
      `SELECT file_path as filePath, file_name as fileName, 
              mime_type as mimeType, file_size as fileSize 
       FROM asset_documents WHERE id = ?`,
      [id]
    );

    if (!documents || documents.length === 0) {
      return res.status(404).json({ error: 'Document not found' });
    }

    const document = documents[0];
    // UPDATED: Look in documents folder
    const filePath = path.join(process.cwd(), 'uploads/documents', document.filePath);

    // Check if file exists
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: 'File not found' });
    }

    // Get file stats for accurate information
    const stats = fs.statSync(filePath);

    // Set appropriate headers
    res.setHeader('Content-Type', document.mimeType);
    res.setHeader('Content-Length', stats.size);
    
    // For images, allow them to be embedded
    if (document.mimeType.startsWith('image/')) {
      res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
      res.setHeader('Cache-Control', 'public, max-age=3600');
    } else {
      res.setHeader('Cache-Control', 'no-cache');
    }

    // Stream the file with error handling
    const fileStream = fs.createReadStream(filePath);
    
    fileStream.on('error', (error) => {
      console.error('File stream error:', error);
      if (!res.headersSent) {
        res.status(500).json({ error: 'Error streaming file' });
      }
    });

    fileStream.pipe(res);

  } catch (error) {
    console.error('Error viewing document:', error);
    if (!res.headersSent) {
      res.status(500).json({ error: 'Failed to view document' });
    }
  }
});

// Download document
router.get('/download/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const [documents] = await pool.query(
      `SELECT file_path as filePath, file_name as fileName, 
              mime_type as mimeType, file_size as fileSize 
       FROM asset_documents WHERE id = ?`,
      [id]
    );

    if (!documents || documents.length === 0) {
      return res.status(404).json({ error: 'Document not found' });
    }

    const document = documents[0];
    // UPDATED: Look in documents folder
    const filePath = path.join(process.cwd(), 'uploads/documents', document.filePath);

    // Check if file exists
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: 'File not found' });
    }

    // Get file stats for accurate size
    const stats = fs.statSync(filePath);
    
    // Set download headers with proper encoding
    const encodedFileName = encodeURIComponent(document.fileName);
    res.setHeader('Content-Disposition', `attachment; filename="${encodedFileName}"; filename*=UTF-8''${encodedFileName}`);
    res.setHeader('Content-Type', document.mimeType);
    res.setHeader('Content-Length', stats.size);
    res.setHeader('Cache-Control', 'no-cache');

    // Stream the file with error handling
    const fileStream = fs.createReadStream(filePath);
    
    fileStream.on('error', (error) => {
      console.error('File stream error:', error);
      if (!res.headersSent) {
        res.status(500).json({ error: 'Error downloading file' });
      }
    });

    fileStream.pipe(res);

  } catch (error) {
    console.error('Error downloading document:', error);
    if (!res.headersSent) {
      res.status(500).json({ error: 'Failed to download document' });
    }
  }
});

// Delete document
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log('DELETE document request for ID:', id);
    
    const [documents] = await pool.query(
      'SELECT file_path as filePath FROM asset_documents WHERE id = ?',
      [id]
    );

    if (!documents || documents.length === 0) {
      console.log('Document not found in database');
      return res.status(404).json({ error: 'Document not found' });
    }

    const document = documents[0];
    console.log('Found document:', document);

    // Delete from database first
    await pool.query('DELETE FROM asset_documents WHERE id = ?', [id]);
    console.log('Deleted from database');

    // Delete file from filesystem - UPDATED: documents folder
    const filePath = path.join(process.cwd(), 'uploads/documents', document.filePath);
    console.log('Looking for file at:', filePath);
    
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
      console.log('File deleted successfully');
    } else {
      console.log('File not found at path, but database record deleted');
    }

    res.json({ message: 'Document deleted successfully' });
  } catch (error) {
    console.error('Error deleting document:', error);
    res.status(500).json({ error: 'Failed to delete document: ' + error.message });
  }
});

// Test endpoint to verify router is working
router.get('/test', (req, res) => {
  res.json({ message: 'Documents router is working!' });
});

export { router as documentRouter };