const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const app = express();

// MySQL Database connection setup
const db = mysql.createConnection({
  host: 'your-database-host', // e.g., localhost
  user: 'your-database-user',
  password: 'your-database-password',
  database: 'attendance_management_db'
});

// Middleware to parse JSON
app.use(bodyParser.json());

// API endpoint for school login
app.post('/login', (req, res) => {
  const { email, password } = req.body;

  // Query to validate the school registration email and password
  db.query('SELECT * FROM schools WHERE email = ? AND password = ?', [email, password], (err, results) => {
    if (err) {
      return res.status(500).json({ message: 'Database error', error: err });
    }
    if (results.length > 0) {
      return res.status(200).json({ success: true, message: 'Login successful' });
    } else {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }
  });
});

// Start the server
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
