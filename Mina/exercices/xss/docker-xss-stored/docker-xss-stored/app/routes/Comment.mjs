import { getAllComments, addNewComment } from "../controllers/CommentController.mjs";
import express from "express";

const router = express.Router();


router.get('/', async (req, res) => {
  try {
    const comments = await getAllComments();
    res.status(200).json(comments);
  } catch (error) {
    console.error('Erreur lors de la récupération des commentaires :', error);
    res.status(500).send('Erreur serveur');
  }
});

router.post('/', async (req, res) => {
    const { comTitle, comText } = req.body;
    try {
      await addNewComment(comTitle, comText);
      res.status(200).send('Commentaire ajouté avec succès');;
    } catch (error) {
      console.error('Erreur lors de l\'ajout du commentaire :', error);
      res.status(500).send('Erreur serveur');
    }
});

export default router;