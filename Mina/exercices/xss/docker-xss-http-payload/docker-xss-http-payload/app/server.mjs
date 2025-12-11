// ETML
// Auteur : bulle SecDevOps
// Date : 26.03.2024


// Librairies et ressources
import path from "path";
import express from "express";
import { fileURLToPath } from 'url';
import { dirname } from 'path';

// Indice : utiliser un module pour �chapper les caract�res HTML
import escapeHtml from 'escape-html';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();


app.get('/', async(req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/search-results', (req, res) => {
    const searchTerm = req.query.q;    
    const searchResults = `<h1>Search results</h1><p>Search results for "${escapeHtml(searchTerm)}".</p>`;   
    res.send(searchResults);
});

// D�marrage du serveur
app.listen(8087, () => {
    console.log('server running on port 8087');
});
    