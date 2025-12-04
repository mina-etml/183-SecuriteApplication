-- ============================================================================
-- Script d'échauffement : Logging des opérations sur t_absence
-- Exercice simple pour comprendre les triggers
-- ============================================================================

-- --------------------------------------------------------
-- 1. Création de la table de log
-- --------------------------------------------------------

CREATE TABLE `t_log` (
  `idLog` int NOT NULL,
  `logDate` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `logComment` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Index pour la table `t_log`
--
ALTER TABLE `t_log`
  ADD PRIMARY KEY (`idLog`);

--
-- AUTO_INCREMENT pour la table `t_log`
--
ALTER TABLE `t_log`
  MODIFY `idLog` int NOT NULL AUTO_INCREMENT;

-- --------------------------------------------------------
-- 2. Trigger AFTER INSERT - Log quand on ajoute une absence
-- --------------------------------------------------------

DELIMITER $$

DROP TRIGGER IF EXISTS `trg_log_absence_insert`$$

CREATE TRIGGER `trg_log_absence_insert`
AFTER INSERT ON `t_absence`
FOR EACH ROW
BEGIN
    INSERT INTO t_log (logComment)
    VALUES (CONCAT('INSERT : Absence ajoutée pour étudiant ', NEW.idStudent, 
                   ' le ', NEW.absDate));
END$$

DELIMITER ;

-- --------------------------------------------------------
-- 3. Trigger AFTER UPDATE - Log quand on modifie une absence
-- --------------------------------------------------------

DELIMITER $$

DROP TRIGGER IF EXISTS `trg_log_absence_update`$$

CREATE TRIGGER `trg_log_absence_update`
AFTER UPDATE ON `t_absence`
FOR EACH ROW
BEGIN
    INSERT INTO t_log (logComment)
    VALUES (CONCAT('UPDATE : Absence #', OLD.idAbsence, 
                   ' modifiée pour étudiant ', NEW.idStudent));
END$$

DELIMITER ;

-- --------------------------------------------------------
-- 4. Trigger AFTER DELETE - Log quand on supprime une absence
-- --------------------------------------------------------

DELIMITER $$

DROP TRIGGER IF EXISTS `trg_log_absence_delete`$$

CREATE TRIGGER `trg_log_absence_delete`
AFTER DELETE ON `t_absence`
FOR EACH ROW
BEGIN
    INSERT INTO t_log (logComment)
    VALUES (CONCAT('DELETE : Absence #', OLD.idAbsence, 
                   ' supprimée pour étudiant ', OLD.idStudent, 
                   ' du ', OLD.absDate));
END$$

DELIMITER ;

-- ============================================================================
-- Instructions d'utilisation
-- ============================================================================

/*
UTILISATION SIMPLE :

1. Exécuter ce script dans votre base de données

2. Tester avec des opérations sur t_absence :

   -- Test INSERT
   INSERT INTO t_absence (idStudent, absDate, absPeriodStart, absPeriodEnd, idReason)
   VALUES (1, '2024-12-05', 1, 1, 1);
   
   -- Test UPDATE
   UPDATE t_absence 
   SET absPeriodEnd = 2 
   WHERE idAbsence = 1;
   
   -- Test DELETE
   DELETE FROM t_absence 
   WHERE idAbsence = 1;

3. Consulter les logs :
   SELECT * FROM t_log ORDER BY logDate DESC;

EXEMPLE DE RÉSULTAT :

+-------+---------------------+---------------------------------------------------+
| idLog | logDate             | logComment                                        |
+-------+---------------------+---------------------------------------------------+
|     3 | 2024-12-03 15:30:45 | DELETE : Absence #1 supprimée pour étudiant 1... |
|     2 | 2024-12-03 15:30:30 | UPDATE : Absence #1 modifiée pour étudiant 1     |
|     1 | 2024-12-03 15:30:15 | INSERT : Absence ajoutée pour étudiant 1 le ...  |
+-------+---------------------+---------------------------------------------------+

POUR NETTOYER LES LOGS :
   TRUNCATE TABLE t_log;

AVANTAGES PÉDAGOGIQUES :
✅ Très simple à comprendre
✅ On voit en temps réel ce qui se passe
✅ Utile pour déboguer
✅ Bon exercice d'échauffement avant les triggers complexes

AMÉLIORATION POSSIBLE :
Vous pourriez ajouter une colonne pour stocker le type d'opération :
   `logOperation` ENUM('INSERT', 'UPDATE', 'DELETE')
*/
