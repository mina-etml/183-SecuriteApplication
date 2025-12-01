CREATE USER 'teacher'@'%' IDENTIFIED BY 'pswteacher';

GRANT SELECT ON db_students.v_studentsGrades TO 'teacher'@'%';
GRANT SELECT ON db_students.v_absentStudents TO 'teacher'@'%';

FLUSH PRIVILEGES;
