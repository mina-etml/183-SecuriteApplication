-- ============================================================================
-- Exercice simple pour pratiquer les triggers
-- ============================================================================

-- --------------------------------------------------------
-- 1. Création de la table de log
-- --------------------------------------------------------

CREATE TABLE `t_log` (
  `idLog` int NOT NULL,
  `logDate` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `logComment` varchar(255) NOT NULL
);

ALTER TABLE `t_log`
  ADD PRIMARY KEY (`idLog`);

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

SELECT * FROM t_log ORDER BY logDate DESC;


