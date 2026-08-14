import multer from 'multer';
import path from 'path';
import fs from 'fs';

const audioDir = path.join(__dirname, '../../uploads/audio');
const artworkDir = path.join(__dirname, '../../uploads/artwork');

if (!fs.existsSync(audioDir)) {
  fs.mkdirSync(audioDir, { recursive: true });
}
if (!fs.existsSync(artworkDir)) {
  fs.mkdirSync(artworkDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    if (file.fieldname === 'audioFile') {
      cb(null, audioDir);
    } else if (file.fieldname === 'artworkFile') {
      cb(null, artworkDir);
    } else {
      cb(null, path.join(__dirname, '../../uploads'));
    }
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    const ext = path.extname(file.originalname);
    cb(null, `${file.fieldname}-${uniqueSuffix}${ext}`);
  },
});

export const uploadMediaMiddleware = multer({
  storage,
  limits: {
    fileSize: 250 * 1024 * 1024, // Max 250 MB per file (supports 2+ hour sermons)
  },
});
