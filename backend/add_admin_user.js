import bcrypt from 'bcrypt';
import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

async function addAdminUser() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'caleb',
    password: process.env.DB_PASSWORD || 'cA1eb@2612-2006',
    database: process.env.DB_NAME || 'ims',
  });

  const email = 'admin@example.com';
  const name = 'Admin User';
  const password = 'password123';

  const password_hash = await bcrypt.hash(password, 10);

  try {
    const [rows] = await connection.execute('SELECT id FROM admins WHERE email = ?', [email]);
    if (rows.length > 0) {
      console.log('Admin user already exists.');
    } else {
      await connection.execute(
        'INSERT INTO admins (name, email, password_hash) VALUES (?, ?, ?)',
        [name, email, password_hash]
      );
      console.log('Admin user added successfully.');
    }
  } catch (err) {
    console.error('Error adding admin user:', err);
  } finally {
    await connection.end();
  }
}

addAdminUser();
