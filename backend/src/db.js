import mysql from 'mysql2/promise';
import dotenv from 'dotenv';
dotenv.config();

// Connection configuration
const config = {
  host: process.env.MYSQLHOST,
  user: process.env.MYSQLUSER,
  password: process.env.MYSQLPASSWORD,
  database: process.env.MYSQLDATABASE,
  port: process.env.MYSQLPORT || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  connectTimeout: 10000, // 10 seconds
  ssl: {
    rejectUnauthorized: false
  } // Railway requires SSL
};

// Create connection pool
const pool = mysql.createPool(config);

// Test connection immediately
(async () => {
  try {
    const connection = await pool.getConnection();
    console.log('✅ Successfully connected to MySQL database on Railway');
    
    // Verify database access
    const [rows] = await connection.query('SHOW TABLES');
    console.log(`📊 Database contains ${rows.length} tables`);
    
    connection.release();
  } catch (error) {
    console.error('❌ MySQL connection error:', error.message);
    
    // Enhanced debugging
    if (error.code === 'ETIMEDOUT') {
      console.error('⏱️ Connection timeout - check your host/port');
    } else if (error.code === 'ER_ACCESS_DENIED_ERROR') {
      console.error('🔒 Authentication failed - check username/password');
    } else if (error.code === 'ER_BAD_DB_ERROR') {
      console.error('🗄️ Database does not exist - check database name');
    }
    
    console.error('ℹ️ Current connection config:', {
      ...config,
      password: '******' // Hide password in logs
    });
  }
})();

export default pool;
