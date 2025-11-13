import express from "express";
import bcrypt from 'bcrypt';
import { connectToDatabase } from "../utils/dbUtils.mjs";


const router = express.Router();

// Middleware pour la connexion à la base de données
const connectToDatabaseMiddleware = async (req, res, next) => {
  try {
    req.dbConnection = await connectToDatabase();
    next();
  } catch (error) {
    console.error("Error connecting to the database:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

router.post('/register', connectToDatabaseMiddleware, async (req, res) => {

  const { username, password } = req.body;
  const pepper = process.env.PEPPER_SECRET;

  const hashedPassword = await bcrypt.hash(password + pepper, 10);

  const insertQuery = "INSERT INTO t_users (useName, usePassword) VALUES (?, ?)";

  try {
    await req.dbConnection.query(insertQuery, [username, hashedPassword]);
    res.status(201).json({ message: "User registered successfully" });
  } catch (error) {
    console.error("Error registering user:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// router.post('/', connectToDatabaseMiddleware, async (req, res) => {
//   const { username, password } = req.body;

//   //const queryString = `SELECT * FROM t_users WHERE useName = '${username}' AND usePassword = '${password}'`; 

//   const queryString = 'SELECT * FROM t_users WHERE useName = ? AND usePassword = ?';

//   try {
//     const [rows] = await req.dbConnection.query(queryString, [username, password]); // add [username, password] here
//     if (rows.length > 0) {
//       res.status(200).json({ message: "Authentication successful" });
//     } else {
//       res.status(401).json({ error: "Invalid username or password" });
//     }
//   } catch (error) {
//     console.error("Error authenticating user:", error);
//     res.status(500).json({ error: "Internal Server Error"+error });
//   }
// });


router.post('/', connectToDatabaseMiddleware, async (req, res) => {
  const pepper = process.env.PEPPER_SECRET;
  const { username, password } = req.body;

  const queryString = 'SELECT * FROM t_users WHERE useName = ?';

  try {
    const [rows] = await req.dbConnection.query(queryString, [username]);

    if (rows.length === 0) {
      return res.status(401).json({ error: "Invalid username or password" });
    }

    const user = rows[0];
    const passwordMatch = await bcrypt.compare(password + pepper, user.usePassword); // compare hashed password

    if (!passwordMatch) {
      return res.status(401).json({ error: "Invalid username or password" });
    }

    res.status(200).json({ message: "Authentication successful" });
  } catch (error) {
    console.error("Error authenticating user:", error);
    res.status(500).json({ error: "Internal Server Error"});
  }
});
export default router;
