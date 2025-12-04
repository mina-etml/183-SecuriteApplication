-- --------------------------------------------------------
-- RAPPEL : Vue v_absentStudents (créée dans l'exercice précédent)
-- --------------------------------------------------------

-- Cette vue doit déjà exister dans votre base de données
-- Si ce n'est pas le cas, voici le code pour la créer :

CREATE OR REPLACE VIEW `v_absentStudents` AS
SELECT 
    s.stuName AS nom,
    s.stuFirstName AS prenom,
    a.absDate AS jour_absence,
    a.absPeriodStart AS periode_debut,
    a.absPeriodEnd AS periode_fin,
    r.reaDescription AS motif
FROM 
    t_absence a
    INNER JOIN t_student s ON a.idStudent = s.idStudent
    INNER JOIN t_reason r ON a.idReason = r.idReason
ORDER BY 
    a.absDate DESC, s.stuName, s.stuFirstName;

-- --------------------------------------------------------
-- 1.1. Création de la table t_audit_access_absences
-- --------------------------------------------------------

CREATE TABLE `t_audit_access_absences` (
  `idAuditAbsences` int NOT NULL,
  `audAbsDate` datetime NOT NULL,
  `audAbsUser` varchar(50) NOT NULL
);

ALTER TABLE `t_audit_access_absences`
  ADD PRIMARY KEY (`idAuditAbsences`),
  ADD KEY `idx_date` (`audAbsDate`),
  ADD KEY `idx_user` (`audAbsUser`);

ALTER TABLE `t_audit_access_absences`
  MODIFY `idAuditAbsences` int NOT NULL AUTO_INCREMENT;

-- --------------------------------------------------------
-- 1.2. Création de la procédure stockée sp_get_absences
-- --------------------------------------------------------

DELIMITER $$

DROP PROCEDURE IF EXISTS `sp_get_absences`$$

CREATE PROCEDURE `sp_get_absences`()
BEGIN
    -- Insérer l'audit AVANT de lire les données
    -- USER() retourne 'utilisateur'@'host'
    INSERT INTO t_audit_access_absences (audAbsDate, audAbsUser)
    VALUES (NOW(), USER());
    
    -- Lire et retourner toutes les données de la vue v_absentStudents
    SELECT * FROM v_absentStudents;
END$$

DELIMITER ;

-- --------------------------------------------------------
-- 2. GESTION DES PERMISSIONS
-- --------------------------------------------------------

-- 2.1. Créer l'utilisateur John avec mot de passe John
-- Il peut se connecter depuis n'importe quel ordinateur (%)
DROP USER IF EXISTS 'John'@'%';
CREATE USER 'John'@'%' IDENTIFIED BY 'John';

-- 2.2. Créer l'utilisateur teacher (s'il n'existe pas déjà)
-- Il peut se connecter depuis n'importe quel ordinateur
DROP USER IF EXISTS 'teacher'@'%';
CREATE USER 'teacher'@'%' IDENTIFIED BY 'teacher';

-- 2.3. Permissions pour John
-- John peut UNIQUEMENT exécuter la procédure sp_get_absences
GRANT EXECUTE ON PROCEDURE db_students.sp_get_absences TO 'John'@'%';

-- 2.4. Permissions pour teacher
-- teacher peut consulter la vue v_absentStudents directement
-- ET exécuter la procédure sp_get_absences
GRANT SELECT ON db_students.v_absentStudents TO 'teacher'@'%';
GRANT EXECUTE ON PROCEDURE db_students.sp_get_absences TO 'teacher'@'%';

-- Appliquer les changements
FLUSH PRIVILEGES;

-- ============================================================================
-- TESTS ET VÉRIFICATIONS
-- ============================================================================

/*
TEST 1 : Vérifier que la vue existe et contient des données (en tant qu'admin)
*/
SELECT * FROM v_absentStudents LIMIT 5;

/*
TEST 2 : Vérifier que la procédure fonctionne (en tant qu'admin)
*/
CALL sp_get_absences();

-- Vérifier l'audit
SELECT * FROM t_audit_access_absences ORDER BY audAbsDate DESC;

/*
TEST 3 : Se connecter avec John et tester

Dans un nouveau terminal ou client MySQL :
    mysql -u John -pJohn -h localhost db_students

Tester la procédure (DOIT FONCTIONNER) :
    CALL sp_get_absences();
    
Résultat attendu : La liste des absences s'affiche

Tester l'accès direct à la vue (DOIT ÉCHOUER) :
    SELECT * FROM v_absentStudents;
    
Erreur attendue : SELECT command denied to user 'John'@'%' for table 'v_absentStudents'

Tester l'accès aux tables (DOIT ÉCHOUER) :
    SELECT * FROM t_absence;
    
Erreur attendue : SELECT command denied to user 'John'@'%' for table 't_absence'
*/

/*
TEST 4 : Se connecter avec teacher et tester

Dans un nouveau terminal ou client MySQL :
    mysql -u teacher -pteacher -h localhost db_students

Tester l'accès direct à la vue (DOIT FONCTIONNER) :
    SELECT * FROM v_absentStudents;
    
Résultat attendu : La liste des absences s'affiche
NOTE : Cet accès n'est PAS audité car teacher accède directement à la vue

Tester la procédure (DOIT FONCTIONNER) :
    CALL sp_get_absences();
    
Résultat attendu : La liste des absences s'affiche
NOTE : Cet accès EST audité car il passe par la procédure

Tester l'accès aux tables (DOIT ÉCHOUER) :
    SELECT * FROM t_absence;
    
Erreur attendue : SELECT command denied to user 'teacher'@'%' for table 't_absence'
*/

-- --------------------------------------------------------
-- VÉRIFICATION DE L'AUDIT (en tant qu'admin)
-- --------------------------------------------------------

-- Voir tous les accès enregistrés
SELECT * FROM t_audit_access_absences ORDER BY audAbsDate DESC;

-- Compter les accès par utilisateur
SELECT 
    audAbsUser,
    COUNT(*) AS nombre_acces,
    MIN(audAbsDate) AS premier_acces,
    MAX(audAbsDate) AS dernier_acces
FROM t_audit_access_absences
GROUP BY audAbsUser;

-- Voir les accès d'aujourd'hui
SELECT * FROM t_audit_access_absences 
WHERE DATE(audAbsDate) = CURDATE()
ORDER BY audAbsDate DESC;

-- Voir uniquement les accès de John
SELECT * FROM t_audit_access_absences 
WHERE audAbsUser LIKE 'John@%'
ORDER BY audAbsDate DESC;

-- Voir uniquement les accès de teacher
SELECT * FROM t_audit_access_absences 
WHERE audAbsUser LIKE 'teacher@%'
ORDER BY audAbsDate DESC;

-- --------------------------------------------------------
-- REQUÊTES UTILES POUR L'ADMINISTRATEUR
-- --------------------------------------------------------

-- Vérifier les permissions de John
SHOW GRANTS FOR 'John'@'%';
-- Résultat attendu : GRANT EXECUTE ON PROCEDURE `db_students`.`sp_get_absences`

-- Vérifier les permissions de teacher
SHOW GRANTS FOR 'teacher'@'%';
-- Résultat attendu : 
-- GRANT SELECT ON `db_students`.`v_absentStudents`
-- GRANT EXECUTE ON PROCEDURE `db_students`.`sp_get_absences`

-- Voir tous les utilisateurs
SELECT User, Host FROM mysql.user WHERE User IN ('John', 'teacher');

-- --------------------------------------------------------
-- NETTOYAGE (si besoin de recommencer)
-- --------------------------------------------------------

/*
-- Supprimer les utilisateurs
DROP USER IF EXISTS 'John'@'%';
DROP USER IF EXISTS 'teacher'@'%';

-- Vider la table d'audit
TRUNCATE TABLE t_audit_access_absences;

-- Supprimer la table d'audit
DROP TABLE IF EXISTS t_audit_access_absences;

-- Supprimer la procédure
DROP PROCEDURE IF EXISTS sp_get_absences;

-- Supprimer la vue (attention, peut affecter d'autres exercices)
DROP VIEW IF EXISTS v_absentStudents;
*/

-- ============================================================================
-- TABLEAU RÉCAPITULATIF DES PERMISSIONS
-- ============================================================================

/*
+----------------------------+-------+---------+
| Action                    -| John  | teacher |
+----------------------------+-------+---------+
| SELECT sur v_absentStudents| 0     |   1     |
| CALL sp_get_absences()     | 1     |  1      |
| SELECT sur t_absence       | 0     | 0       |
| SELECT sur t_student       | 0     | 0       |
| INSERT dans tables         | 0     | 0       |
| Accès audité               | 1*    | 1*      |
+----------------------------+-------+---------+

* Uniquement quand ils utilisent CALL sp_get_absences()
  Les accès directs de teacher à la vue ne sont PAS audités

DIFFÉRENCES CLÉS :

John :
- Doit OBLIGATOIREMENT utiliser la procédure
- Tous ses accès sont audités
- Ne peut PAS accéder directement aux données

teacher :
- Peut accéder à la vue directement (non audité)
- Peut aussi utiliser la procédure (audité)
- Plus de flexibilité mais moins de traçabilité
*/
/*

QUESTIONS intéressantes :

1. Pourquoi les accès directs de teacher à la vue ne sont-ils pas audités ?
   Réponse : Car il accède directement à la vue, pas via la procédure

2. Comment forcer l'audit de TOUS les accès de teacher ?
   Réponse : Retirer le droit SELECT sur la vue, ne garder que EXECUTE

3. Quel est l'avantage de donner SELECT sur la vue à teacher ?
   Réponse : Plus rapide, pas de surcharge de la table d'audit

4. Quel est l'inconvénient ?
   Réponse : Perte de traçabilité pour certains accès

5. Dans quel cas utiliserait-on l'approche de John pour tout le monde ?
   Réponse : Données très sensibles (médicales, financières), 
             exigences réglementaires strictes, audit obligatoire
*/
