// ETML
// Auteur : bulle SecDevOps
// Date : 26.03.2024


// Librairies et ressources
import path from "path";
import express from "express";
import commentRoute from "./routes/Comment.mjs";
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();



app.use(express.json());

// Les routes
app.use('/comment', commentRoute);


app.get('/', async(req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Démarrage du serveur
app.listen(8086, () => {
    console.log('server running on port 8086');
});