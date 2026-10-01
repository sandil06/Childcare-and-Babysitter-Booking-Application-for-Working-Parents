const multer = require('multer');
const path = require('node:path');

const storage = multer.diskStorage({
  destination: 'uploads/',
  filename: (req, file, callback) => callback(null, `${Date.now()}-${file.originalname.replace(/[^a-zA-Z0-9.-]/g, '_')}`),
});

module.exports = multer({ storage, limits: { fileSize: 5 * 1024 * 1024 }, fileFilter: (req, file, callback) => {
  const allowed = /jpeg|jpg|png|pdf/.test(path.extname(file.originalname).toLowerCase()) && /image|application/.test(file.mimetype);
  callback(allowed ? null : new Error('Only JPG, PNG, and PDF files are allowed'), allowed);
} });
