import express from 'express';
import { connectToDatabase } from '../utils/dbUtils.mjs';


export async function getAllComments() {
  try {
    const connection = await connectToDatabase();
    const [rows] = await connection.execute('SELECT * FROM t_comment');
    connection.end();
    return rows;
  } catch (error) {
    console.error('Erreur lors de la récupération des commentaires :', error);
    throw error;
  }
}

export async function addNewComment(title, comment) {
  try {
    const connection = await connectToDatabase();
    console.log("ajout dans la db");
    await connection.execute('INSERT INTO t_comment (comTitle, comText) VALUES (?, ?)', [title, comment]);
    connection.end();
  } catch (error) {
    console.error('Erreur lors de l\'ajout du commentaire :', error);
    throw error;
  }
}

