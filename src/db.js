import mysql from 'mysql2/promise';
import dotenv from 'dotenv';
dotenv.config();

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT ? parseInt(process.env.DB_PORT) : 3306,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});
if(pool) console.log('connected');
else console.log('failed to connect');

export async function testConnection() {
  let connection;
  try {
    connection = await pool.getConnection();
    await connection.execute('SELECT 1');
    console.log('Database connection test successful');
  } catch (error) {
    console.error('Database connection test failed:', error.message);
  } finally {
    if (connection) connection.release();
  }
}

export default pool;
