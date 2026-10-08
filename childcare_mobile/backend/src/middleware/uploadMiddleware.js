const multer = require('multer');
const path = require('node:path');
const fs = require('node:fs');

const uploadDir = path.resolve('uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, callback) => callback(null, uploadDir),
  filename: (req, file, callback) => callback(null, `${Date.now()}-${file.originalname.replace(/[^a-zA-Z0-9.-]/g, '_')}`),
});

module.exports = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, callback) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const allowed = /jpeg|jpg|png|webp|pdf/.test(ext) && (/image\//.test(file.mimetype) || /application\/pdf/.test(file.mimetype));
    callback(allowed ? null : new Error('Only JPG, JPEG, PNG, WEBP, and PDF files are allowed'), allowed);
  },
});
