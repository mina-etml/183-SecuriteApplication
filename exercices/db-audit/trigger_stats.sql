-- --------------------------------------------------------
-- 1. Création de la table pour stocker les statistiques mensuelles
-- --------------------------------------------------------

CREATE TABLE `t_absence_monthly_stats` (
  `idAbsenceMonthlyStats` int NOT NULL,
  `idStudent` int NOT NULL,
  `staYear` int NOT NULL,
  `staMonth` int NOT NULL,
  `staTotalAbsences` int NOT NULL DEFAULT '0',
  `staTotalPeriods` int NOT NULL DEFAULT '0',
  `staLastUpdate` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

--
-- Index pour la table `t_absence_monthly_stats` basé sur les 3 champs
--
ALTER TABLE `t_absence_monthly_stats`
  ADD PRIMARY KEY (`idAbsenceMonthlyStats`),
  ADD UNIQUE KEY `idStudent` (`idStudent`,`staYear`,`staMonth`),
  ADD KEY `idStudent_2` (`idStudent`);

--
-- AUTO_INCREMENT pour la table `t_absence_monthly_stats`
--
ALTER TABLE `t_absence_monthly_stats`
  MODIFY `idAbsenceMonthlyStats` int NOT NULL AUTO_INCREMENT;

ALTER TABLE `t_absence_monthly_stats`
  ADD CONSTRAINT `t_absence_monthly_stats_ibfk_1` FOREIGN KEY (`idStudent`) REFERENCES `t_student` (`idStudent`);

-- --------------------------------------------------------
-- 2. Procédure stockée pour faire le calcul (possibilité aussi avec ON DUPLICATE KEY UPDATE...)
-- --------------------------------------------------------

DELIMITER $$

DROP PROCEDURE IF EXISTS `sp_calculate_monthly_absences`$$

CREATE PROCEDURE `sp_calculate_monthly_absences`(
    IN p_idStudent INT,
    IN p_year INT,
    IN p_month INT
)
BEGIN
    DECLARE v_total_absences INT DEFAULT 0;
    DECLARE v_total_periods INT DEFAULT 0;
    
    -- Calculer les statistiques pour ce mois
    SELECT 
        COUNT(*),
        SUM(absPeriodEnd - absPeriodStart + 1)
    INTO 
        v_total_absences,
        v_total_periods
    FROM 
        t_absence
    WHERE 
        idStudent = p_idStudent
        AND YEAR(absDate) = p_year
        AND MONTH(absDate) = p_month;
    
    -- Gérer le cas NULL (aucune absence trouvée)
    IF v_total_absences IS NULL THEN
        SET v_total_absences = 0;
    END IF;
    
    IF v_total_periods IS NULL THEN
        SET v_total_periods = 0;
    END IF;
    
    -- Update ou Insert ?
    IF EXISTS (
        SELECT 1 
        FROM t_absence_monthly_stats 
        WHERE idStudent = p_idStudent 
            AND staYear = p_year 
            AND staMonth = p_month
    ) THEN
        -- La ligne existe : on fait un UPDATE
        UPDATE t_absence_monthly_stats
        SET 
            staTotalAbsences = v_total_absences,
            staTotalPeriods = v_total_periods,
            staLastUpdate = CURRENT_TIMESTAMP
        WHERE 
            idStudent = p_idStudent
            AND staYear = p_year
            AND staMonth = p_month;
    ELSE
        -- La ligne n'existe pas : on fait un INSERT
        INSERT INTO t_absence_monthly_stats 
            (idStudent, staYear, staMonth, staTotalAbsences, staTotalPeriods)
        VALUES 
            (p_idStudent, p_year, p_month, v_total_absences, v_total_periods);
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------
-- 3. Trigger AFTER INSERT
-- --------------------------------------------------------

DELIMITER $$

DROP TRIGGER IF EXISTS `trg_absence_after_insert`$$

CREATE TRIGGER `trg_absence_after_insert`
AFTER INSERT ON `t_absence`
FOR EACH ROW
BEGIN
    -- Appel automatique : pas besoin d'initialisation manuelle !
    CALL sp_calculate_monthly_absences(
        NEW.idStudent, 
        YEAR(NEW.absDate), 
        MONTH(NEW.absDate)
    );
END$$

DELIMITER ;

-- --------------------------------------------------------
-- 4. Trigger AFTER UPDATE
-- --------------------------------------------------------

DELIMITER $$

DROP TRIGGER IF EXISTS `trg_absence_after_update`$$

CREATE TRIGGER `trg_absence_after_update`
AFTER UPDATE ON `t_absence`
FOR EACH ROW
BEGIN
    -- Si l'étudiant ou la date a changé, recalculer l'ancien mois
    IF (OLD.idStudent != NEW.idStudent OR OLD.absDate != NEW.absDate) THEN
        CALL sp_calculate_monthly_absences(
            OLD.idStudent, 
            YEAR(OLD.absDate), 
            MONTH(OLD.absDate)
        );
    END IF;
    
    -- Recalculer le nouveau mois
    CALL sp_calculate_monthly_absences(
        NEW.idStudent, 
        YEAR(NEW.absDate), 
        MONTH(NEW.absDate)
    );
END$$

DELIMITER ;

-- --------------------------------------------------------
-- 5. Trigger AFTER DELETE
-- --------------------------------------------------------

DELIMITER $$

DROP TRIGGER IF EXISTS `trg_absence_after_delete`$$

CREATE TRIGGER `trg_absence_after_delete`
AFTER DELETE ON `t_absence`
FOR EACH ROW
BEGIN
    -- Recalculer les statistiques du mois concerné
    CALL sp_calculate_monthly_absences(
        OLD.idStudent, 
        YEAR(OLD.absDate), 
        MONTH(OLD.absDate)
    );
END$$

DELIMITER ;

-- --------------------------------------------------------
-- 6. Vue pour faciliter la consultation
-- --------------------------------------------------------

CREATE OR REPLACE VIEW `v_absence_monthly_report` AS
SELECT 
    s.idStudent,
    s.stuName,
    s.stuFirstName,
    ams.staYear,
    ams.staMonth,
    ams.staTotalAbsences,
    ams.staTotalPeriods,
    ams.staLastUpdate,
    CONCAT(s.stuName, ' ', s.stuFirstName) AS fullName,
    DATE_FORMAT(CONCAT(ams.staYear, '-', LPAD(ams.staMonth, 2, '0'), '-01'), '%M %Y') AS monthYear
FROM 
    t_absence_monthly_stats ams
    INNER JOIN t_student s ON ams.idStudent = s.idStudent
ORDER BY 
    s.stuName, s.stuFirstName, ams.staYear DESC, ams.staMonth DESC;

