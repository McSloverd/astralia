import sqlite3 from 'sqlite3';
import { open } from 'sqlite';

export async function openDb() {
  return open({
    filename: './users.db',
    driver: sqlite3.Database
  });
}

export async function initDb() {
  const db = await openDb();
  // Users table
  await db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',           -- pending, approved, deactivated, expired
      registration_date TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      approval_date TEXT,
      expiry_date TEXT,
      last_login_ip TEXT,
      last_active_token TEXT
    );
  `);

  // Admins table
  await db.run(`
    CREATE TABLE IF NOT EXISTS admins (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL
    );
  `);

  // Settings table
  await db.run(`
    CREATE TABLE IF NOT EXISTS settings (
      key TEXT PRIMARY KEY,
      value TEXT
    );
  `);

  // Insert default expiry period (30 days) if not set
  const expiry = await db.get(`SELECT value FROM settings WHERE key = 'user_expiry_days'`);
  if (!expiry) {
    await db.run(`INSERT INTO settings (key, value) VALUES ('user_expiry_days', '30')`);
  }

  // Insert default admin if none exist (username: admin, password: admin123)
  const admin = await db.get(`SELECT * FROM admins LIMIT 1`);
  if (!admin) {
    // Default password is 'admin123' hashed with bcrypt
    const bcrypt = await import('bcrypt');
    const hash = await bcrypt.hash('admin123', 10);
    await db.run(`INSERT INTO admins (username, password) VALUES (?, ?)`, 'admin', hash);
  }
}
