import express from 'express';
import cors from 'cors';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
import { openDb, initDb } from './db.js';
import path from 'path';
import { fileURLToPath } from 'url';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'supersecretkey';
const ADMIN_JWT_SECRET = process.env.ADMIN_JWT_SECRET || 'adminsupersecretkey';
const TOKEN_EXPIRY = '1d';

// For serving static admin GUI
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ADMIN_DIR = path.join(__dirname, 'admin');

app.use(cors());
app.use(express.json());
app.use('/admin', express.static(ADMIN_DIR));

await initDb();

// Utility: get expiry days from settings
async function getExpiryDays() {
  const db = await openDb();
  const row = await db.get(`SELECT value FROM settings WHERE key = 'user_expiry_days'`);
  return row ? parseInt(row.value, 10) : 30;
}

// Utility: update expiry days in settings
async function setExpiryDays(days) {
  const db = await openDb();
  await db.run(`UPDATE settings SET value = ? WHERE key = 'user_expiry_days'`, String(days));
}

// JWT for user and admin
function generateToken(username) {
  return jwt.sign({ username }, JWT_SECRET, { expiresIn: TOKEN_EXPIRY });
}
function generateAdminToken(username) {
  return jwt.sign({ username }, ADMIN_JWT_SECRET, { expiresIn: '8h' });
}

// Middleware for user token
async function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Token required' });

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    const db = await openDb();
    const user = await db.get('SELECT * FROM users WHERE username = ?', payload.username);

    // Check session, status, expiry
    if (!user || user.last_active_token !== token || user.status !== 'approved') {
      return res.status(401).json({ error: 'Session expired or user not approved' });
    }
    // Check expiry
    if (user.expiry_date && new Date(user.expiry_date) < new Date()) {
      // Auto mark as expired
      await db.run(`UPDATE users SET status = 'expired' WHERE id = ?`, user.id);
      return res.status(403).json({ error: 'Account expired' });
    }
    req.user = user;
    next();
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
}

// Middleware for admin token
async function authenticateAdmin(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Admin token required' });
  try {
    const payload = jwt.verify(token, ADMIN_JWT_SECRET);
    const db = await openDb();
    const admin = await db.get('SELECT * FROM admins WHERE username = ?', payload.username);
    if (!admin) return res.status(401).json({ error: 'Invalid admin' });
    req.admin = admin;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid admin token' });
  }
}

// User Registration
app.post('/api/register', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password)
    return res.status(400).json({ error: 'Username and password required' });

  const db = await openDb();
  const existing = await db.get('SELECT * FROM users WHERE username = ?', username);
  if (existing)
    return res.status(409).json({ error: 'Username is already taken.' });

  const hashed = await bcrypt.hash(password, 10);
  await db.run(
    `INSERT INTO users (username, password, status, registration_date) VALUES (?, ?, 'pending', datetime('now'))`,
    username,
    hashed
  );
  res.status(201).json({ message: 'User registered. Awaiting admin approval.' });
});

// Username Availability
app.get('/api/check-username', async (req, res) => {
  const { username } = req.query;
  if (!username) return res.status(400).json({ error: 'Username required' });
  const db = await openDb();
  const user = await db.get('SELECT * FROM users WHERE username = ?', username);
  res.json({ available: !user });
});

// User Login (with status/expiry enforcement and IP logging)
app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;
  const userIp = req.headers['x-forwarded-for'] || req.connection.remoteAddress;

  if (!username || !password)
    return res.status(400).json({ error: 'Username and password required' });

  const db = await openDb();
  const user = await db.get('SELECT * FROM users WHERE username = ?', username);
  if (!user) return res.status(401).json({ error: 'Invalid credentials' });

  const valid = await bcrypt.compare(password, user.password);
  if (!valid) return res.status(401).json({ error: 'Invalid credentials' });

  // Check approval, deactivation, expiry
  if (user.status === 'pending')
    return res.status(403).json({ error: 'Account not yet approved by admin.' });
  if (user.status === 'deactivated')
    return res.status(403).json({ error: 'Account deactivated. Contact admin.' });
  if (user.status === 'expired' ||
      (user.expiry_date && new Date(user.expiry_date) < new Date())) {
    // Auto mark as expired
    await db.run(`UPDATE users SET status = 'expired' WHERE id = ?`, user.id);
    return res.status(403).json({ error: 'Account expired.' });
  }

  // Single-session: invalidate previous session by updating token
  const token = generateToken(username);
  await db.run(
    `UPDATE users SET last_active_token = ?, last_login_ip = ?, status = 'approved' WHERE username = ?`,
    token,
    userIp,
    username
  );
  // Always return username as well as token
  res.json({ token, username });
});

// Logout (optional)
app.post('/api/logout', authenticateToken, async (req, res) => {
  const db = await openDb();
  await db.run(`UPDATE users SET last_active_token = NULL WHERE id = ?`, req.user.id);
  res.json({ message: 'Logged out' });
});

// Authenticated user info (for session polling)
app.get('/api/me', authenticateToken, async (req, res) => {
  // Return the current user's username and status (you can add more fields as needed)
  res.json({ username: req.user.username, status: req.user.status });
});

// Admin login
app.post('/api/admin/login', async (req, res) => {
  const { username, password } = req.body;
  const db = await openDb();
  const admin = await db.get('SELECT * FROM admins WHERE username = ?', username);
  if (!admin) return res.status(401).json({ error: 'Invalid admin credentials' });
  const valid = await bcrypt.compare(password, admin.password);
  if (!valid) return res.status(401).json({ error: 'Invalid admin credentials' });
  const token = generateAdminToken(username);
  res.json({ token });
});

// Admin: list users
app.get('/api/admin/users', authenticateAdmin, async (req, res) => {
  const db = await openDb();
  const users = await db.all(`
    SELECT id, username, status, registration_date, approval_date, expiry_date, last_login_ip
    FROM users
    ORDER BY registration_date DESC
  `);
  res.json({ users });
});

// Admin: approve user
app.post('/api/admin/users/:id/approve', authenticateAdmin, async (req, res) => {
  const db = await openDb();
  const { id } = req.params;
  const expiryDays = await getExpiryDays();
  const approvalDate = new Date();
  const expiryDate = new Date(approvalDate.getTime() + expiryDays * 24 * 60 * 60 * 1000);
  await db.run(
    `UPDATE users SET status = 'approved', approval_date = ?, expiry_date = ? WHERE id = ?`,
    approvalDate.toISOString(),
    expiryDate.toISOString(),
    id
  );
  res.json({ message: 'User approved', expiry: expiryDate.toISOString() });
});

// Admin: deactivate/reactivate user
app.post('/api/admin/users/:id/deactivate', authenticateAdmin, async (req, res) => {
  const db = await openDb();
  const { id } = req.params;
  await db.run(`UPDATE users SET status = 'deactivated' WHERE id = ?`, id);
  res.json({ message: 'User deactivated' });
});
app.post('/api/admin/users/:id/reactivate', authenticateAdmin, async (req, res) => {
  const db = await openDb();
  const { id } = req.params;
  const user = await db.get(`SELECT * FROM users WHERE id = ?`, id);
  if (!user) return res.status(404).json({ error: 'User not found' });
  // Extend expiry date by the configured period
  const expiryDays = await getExpiryDays();
  const approvalDate = new Date();
  const expiryDate = new Date(approvalDate.getTime() + expiryDays * 24 * 60 * 60 * 1000);
  await db.run(
    `UPDATE users SET status = 'approved', approval_date = ?, expiry_date = ? WHERE id = ?`,
    approvalDate.toISOString(),
    expiryDate.toISOString(),
    id
  );
  res.json({ message: 'User reactivated', expiry: expiryDate.toISOString() });
});

// Admin: change default expiry period
app.post('/api/admin/settings/expiry', authenticateAdmin, async (req, res) => {
  const { days } = req.body;
  if (!days || isNaN(days) || days < 1)
    return res.status(400).json({ error: 'Invalid expiry days' });
  await setExpiryDays(Number(days));
  res.json({ message: 'Expiry days updated' });
});

// Admin: add new admin
app.post('/api/admin/admins', authenticateAdmin, async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password)
    return res.status(400).json({ error: 'Username and password required' });
  const db = await openDb();
  const existing = await db.get('SELECT * FROM admins WHERE username = ?', username);
  if (existing)
    return res.status(409).json({ error: 'Admin username already taken.' });
  const hash = await bcrypt.hash(password, 10);
  await db.run('INSERT INTO admins (username, password) VALUES (?, ?)', username, hash);
  res.status(201).json({ message: 'Admin created' });
});

// Admin: list all admins
app.get('/api/admin/admins', authenticateAdmin, async (req, res) => {
  const db = await openDb();
  const admins = await db.all(
    `SELECT id, username FROM admins ORDER BY username`
  );
  res.json({ admins });
});

// Admin: delete another admin (cannot delete self)
app.delete('/api/admin/admins/:id', authenticateAdmin, async (req, res) => {
  const db = await openDb();
  const { id } = req.params;
  // Prevent deleting self
  const admin = await db.get('SELECT * FROM admins WHERE id = ?', id);
  if (!admin) return res.status(404).json({ error: 'Admin not found' });
  if (admin.username === req.admin.username) {
    return res.status(403).json({ error: "You can't delete your own admin account." });
  }
  await db.run('DELETE FROM admins WHERE id = ?', id);
  res.json({ message: 'Admin deleted' });
});

// Serve admin GUI
app.get('/admin/*', (req, res) => {
  res.sendFile(path.join(ADMIN_DIR, 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
