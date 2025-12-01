USE db_students;

CREATE VIEW v_studentsGrades AS SELECT stuName, stuFirstName, courName, evaDate, evaGrade 
FROM t_student 
JOIN t_evaluation 
ON t_student.idStudent=t_evaluation.idStudent 
JOIN t_course ON t_course.idCourse = t_evaluation.idCourse;

CREATE VIEW v_absentStudents AS SELECT stuName, stuFirstName, absDate, absPeriodStart, absPeriodEnd, reaDescription
FROM t_student 
JOIN t_absence
ON t_student.idStudent=t_absence.idStudent 
JOIN t_reason ON t_absence.idReason= t_reason.idReason;