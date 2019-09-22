
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
ΚΥΡΙΕΣ ΣΥΝΑΡΤΗΣΕΙΣ
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------


--##################################################################################################
--ΛΕΙΤΟΥΡΓΙΑ 1.1  
--##################################################################################################
--Εισάγει τυχαίο αριθμό φοιτητών στον πίνακα Student
CREATE OR REPLACE FUNCTION insert1_student(num integer, entry_date date)
RETURNS VOID AS
$$
BEGIN
	INSERT INTO "Student"(amka,name,surname,father_name,am,email,entry_date)
	SELECT create_st_amka(n.id),name,adapt_surname(surname,sex),give_fathername(),create_am(entry_date,n.id),
		create_student_email(create_am(entry_date,n.id)),entry_date
	FROM random_names(num) n JOIN random_surnames(num) s USING (id);	
END;
$$
LANGUAGE 'plpgsql' VOLATILE;

--Εισάγει τυχαίο αριθμό καθηγητών στον πίνακα Professor
CREATE OR REPLACE FUNCTION insert1_professor(num integer)
RETURNS VOID AS
$$
BEGIN

	INSERT INTO "Professor"(amka,name,surname,father_name,"labJoins",rank,email)
	SELECT create_pro_amka(n.id),name,adapt_surname(surname,sex),give_fathername(),random_lab(),random_rank(),create_professor_email(n.id)
	FROM random_names(num) n JOIN random_surnames(num) s USING (id);
	
END;
$$
LANGUAGE 'plpgsql' VOLATILE;

--Εισάγει τυχαίο αριθμό εργαστηριακού προσωπικού στον πίνακα LabStaff
CREATE OR REPLACE FUNCTION insert1_labstaff(num integer)
RETURNS VOID AS
$$
BEGIN

	INSERT INTO "LabStaff"(amka,name,surname,father_name,labworks,level,email)
	SELECT create_lab_amka(n.id),name,adapt_surname(surname,sex),give_fathername(),random_lab(),random_level(),create_lab_email(n.id)
	FROM random_names(num) n JOIN random_surnames(num) s USING (id);
	
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 1.2 
--##################################################################################################
--Εισαγωγή βαθμολογίας σε μαθήματα του τρέχοντος εξαμήνου
CREATE OR REPLACE FUNCTION insert2()
RETURNS VOID AS
$$
DECLARE
flag integer;
BEGIN
flag=1;
	--Εισαγωγή βαθμολογίας γραπτής εξέτασης
	UPDATE "Register" 
	SET exam_grade=trunc(random() * 9 + 1)::int 
	WHERE course_code IN(SELECT c.course_code FROM "CourseRun" c WHERE c.semesterrunsin IN(SELECT s.semester_id 
		FROM "Semester" s WHERE s.semester_status='present'))
		AND serial_number IN(SELECT c.serial_number FROM "CourseRun" c WHERE c.semesterrunsin IN(SELECT s.semester_id 
		FROM "Semester" s WHERE s.semester_status='present'))
		AND register_status='approved' 
		AND exam_grade IS null; 
		
		
	--Εισαγωγή βαθμολογίας εργαστηρίου	
	UPDATE "Register" 	
	SET lab_grade=trunc(random() * 9 + 1)::int 
	WHERE course_code IN(SELECT c.course_code FROM "CourseRun" c WHERE c.semesterrunsin IN(SELECT s.semester_id 
		FROM "Semester" s WHERE s.semester_status='present')
	AND c.labuses IS NOT NULL)						
	AND serial_number IN(SELECT c.serial_number FROM "CourseRun" c WHERE c.semesterrunsin IN(SELECT s.semester_id 
		FROM "Semester" s WHERE s.semester_status='present')
	AND c.labuses IS NOT NULL)						   
	AND register_status='approved' 
	AND lab_grade IS null;
		
		
	UPDATE "Register" 
	SET final_grade= calc_grade(foo.exam_grade,foo.exam_min,foo.lab_grade,foo.lab_min,foo.exam_percentage,foo.labuses) 
	FROM (	SELECT table1.amka,table1.serial_number,table1.course_code,table1.exam_grade,table1.lab_grade,table2.exam_min,table2.lab_min,table2.labuses,table2.exam_percentage 
			FROM (	SELECT * 
					FROM "Register" r
					WHERE r.register_status='approved' 
					AND r.final_grade IS null 
					AND r.course_code IN(	SELECT c.course_code 
											FROM "CourseRun" c  
											WHERE c.semesterrunsin IN(	SELECT s.semester_id 
																		FROM "Semester" s 
																		WHERE s.semester_status='present')
										)
					AND r.serial_number IN(		SELECT c.serial_number 
												FROM "CourseRun" c 
												WHERE c.semesterrunsin IN(	SELECT s.semester_id 
																			FROM "Semester" s 
																			WHERE s.semester_status='present')	
										)
				) AS table1 
				INNER JOIN						
				(	SELECT * 
					FROM "CourseRun" c 
					WHERE c.semesterrunsin IN(	SELECT s.semester_id 
												FROM "Semester" s 
												WHERE s.semester_status='present')
				) AS table2
			ON table1.course_code=table2.course_code
		)AS foo
	WHERE foo.amka="Register".amka AND foo.course_code="Register".course_code AND foo.serial_number="Register".serial_number;				
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 1.3
--##################################################################################################
CREATE OR REPLACE FUNCTION insert3()
RETURNS VOID AS
$$
DECLARE
current_year int;
BEGIN
	current_year=extract(year FROM (SELECT s.start_date FROM  "Semester" s WHERE
		s.semester_status='present'))::int;

		UPDATE "Diploma" 
		SET thesis_grade= trunc(random()* 5 + 5)::int
		WHERE (current_year-(extract(year FROM (SELECT st.entry_date FROM
		"Student" st WHERE st.amka="Diploma".amka))::int))>=5
		AND "Diploma".thesis_grade IS NULL ;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 1.4
--##################################################################################################
CREATE OR REPLACE FUNCTION insert4(my_date date)
RETURNS VOID AS
$$
BEGIN

		UPDATE "Diploma" 
		SET graduation_date=my_date, diploma_num=create_diploma_num(s.id), 
			diploma_grade=(sum_grade(s.amka)*0.8+"Diploma".thesis_grade*0.2)
		FROM  (SELECT * FROM search8()) AS s
		WHERE "Diploma".amka=s.amka AND "Diploma".diploma_num IS NULL;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 1.5 
--##################################################################################################
CREATE OR REPLACE FUNCTION insert5()
RETURNS VOID AS
$$
BEGIN
INSERT INTO "Register" (amka,serial_number,course_code,register_status)
SELECT s.amka,se.semester_id,prop_courses(s.amka),'proposed' 
FROM "Student" s,"Semester" se WHERE se.semester_status='present';
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 1.5 
--##################################################################################################
CREATE OR REPLACE FUNCTION insert6()
RETURNS TRIGGER AS 
$BODY$

BEGIN
 INSERT INTO "CourseRun"(course_code,serial_number,semesterrunsin,exam_min,lab_min,
	exam_percentage,labuses,amka_prof1,amka_prof2)
	SELECT  resent_courses.course_code,NEW.semester_id,NEW.semester_id,resent_courses.exam_min,
			resent_courses.lab_min,resent_courses.exam_percentage,resent_courses.labuses,resent_courses.amka_prof1,
			resent_courses.amka_prof2
	FROM (SELECT t2.course_code,t2.serial_number,t2.exam_min,t2.lab_min,t2.exam_percentage,t2.labuses,t2.amka_prof1,t2.amka_prof2 FROM
			(SELECT c.course_code, MAX(c.serial_number) AS serial_number
			FROM "CourseRun" c WHERE c.course_code IN(SELECT c2.course_code FROM "Course" c2
			WHERE c2.typical_season=NEW.academic_season) GROUP BY c.course_code) AS t1
			INNER JOIN
			"CourseRun" t2
			ON t1.course_code=t2.course_code AND t1.serial_number=t2.serial_number)AS resent_courses;
RETURN NEW;
 END;
 $BODY$
 LANGUAGE 'plpgsql' VOLATILE;


CREATE TRIGGER check_trigger_future_sem
AFTER INSERT ON "Semester" 
FOR EACH ROW
WHEN (NEW.semester_status='future')
EXECUTE PROCEDURE insert6();

--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 2.1
--##################################################################################################
-Eπιστρέφει το ονοματεπώνυμο και το μαιλ των καθηγητών με βάση το εργαστήριο που διευθύνουν
CREATE OR REPLACE FUNCTION search1 (my_lab_code int)
RETURNS TABLE (name char(30),surname char(30),email char(30)) AS
$$ 
BEGIN 
RETURN QUERY
SELECT p.name,p.surname,p.email FROM "Professor" p WHERE  my_lab_code=p."labJoins";
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
--Eπιστρέφει το ονοματεπώνυμο και το μαιλ των καθηγητών με βάση κωδικό μαθήματος,ακαδημαϊκό έτος και εξάμηνο
CREATE OR REPLACE FUNCTION search1(my_course_code char(7),my_academic_year int,my_academic_season semester_season_type )
RETURNS TABLE (name char(30),surname char(30),email char(30)) AS
$$ 
BEGIN 
RETURN QUERY
SELECT p.name,p.surname,p.email FROM "Professor" p WHERE p.amka IN(SELECT amka_prof1 
	FROM "CourseRun" c WHERE c.course_code IN(SELECT co.course_code FROM "Course" co
	WHERE co.typical_year=my_academic_year AND co.typical_season=my_academic_season 
	AND co.course_code=my_course_code))
	OR p.amka IN (SELECT amka_prof2 FROM "CourseRun" c WHERE c.course_code IN(SELECT co.course_code FROM "Course" co
	WHERE co.typical_year=my_academic_year AND co.typical_season=my_academic_season 
	AND co.course_code=my_course_code));
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 2.2
--##################################################################################################
CREATE OR REPLACE FUNCTION search2(my_course_code char(7),my_academic_year int,
my_academic_season semester_season_type,type_of_grade char )
RETURNS TABLE (name char(30),surname char(30),am char(10), grade numeric) AS
$$
BEGIN

IF(type_of_grade='final') THEN
	RETURN QUERY
		SELECT foo.name,foo.surname,foo.am,foo.final_grade 
	FROM 
	(	
		(	SELECT r.amka, r.final_grade 
			FROM 
			(																												
				(	SELECT c.course_code,c.serial_number 
					FROM "CourseRun" c 
					WHERE c.course_code=my_course_code AND c.semesterrunsin IN (SELECT s.semester_id 
																			FROM "Semester" s 
																			WHERE s.academic_year=my_academic_year AND s.academic_season=my_academic_season)
				)AS temp_course
				INNER JOIN 
				"Register"
				ON "Register".course_code= temp_course.course_code AND "Register".serial_number=temp_course.serial_number
			) AS r
		) AS table1
		INNER JOIN
		"Student" s ON s.amka=table1.amka
	) AS foo;
	
ELSIF(type_of_grade='exam') THEN 
		RETURN QUERY
		SELECT foo.name,foo.surname,foo.am,foo.exam_grade 
	FROM 
	(	
		(	SELECT r.amka, r.exam_grade 
			FROM 
			(																												
				(	SELECT c.course_code,c.serial_number 
					FROM "CourseRun" c 
					WHERE c.course_code=my_course_code AND c.semesterrunsin IN (SELECT s.semester_id 
																			FROM "Semester" s 
																			WHERE s.academic_year=my_academic_year AND s.academic_season=my_academic_season)
				)AS temp_course
				INNER JOIN 
				"Register"
				ON "Register".course_code= temp_course.course_code AND "Register".serial_number=temp_course.serial_number
			) AS r
		) AS table1
		INNER JOIN
		"Student" s ON s.amka=table1.amka
	) AS foo;
	
ELSIF(type_of_grade='lab') THEN
		RETURN QUERY
		SELECT foo.name,foo.surname,foo.am,foo.lab_grade 
	FROM 
	(
		(	SELECT r.amka, r.lab_grade 
			FROM 
			(																											
				(	SELECT c.course_code,c.serial_number 
					FROM "CourseRun" c 
					WHERE c.course_code=my_course_code AND c.semesterrunsin IN (SELECT s.semester_id 
																			FROM "Semester" s 
																			WHERE s.academic_year=my_academic_year AND s.academic_season=my_academic_season)
				)AS temp_course
				INNER JOIN 
				"Register"
				ON "Register".course_code= temp_course.course_code AND "Register".serial_number=temp_course.serial_number
			) AS r
		) AS table1
		INNER JOIN
		"Student" s ON s.amka=table1.amka
	) AS foo;
ELSE
	RAISE NOTICE 'Type of grade can only be final,exam or lab. Please try again';
END IF;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 2.3
--##################################################################################################
CREATE OR REPLACE FUNCTION search3()
RETURNS TABLE (name char(30),surname char(30),rank rank_type) AS
$$ 
BEGIN 
RETURN QUERY
SELECT p.name,p.surname,p.rank FROM "Professor" p WHERE p.amka IN
	(	SELECT c.amka_prof1 FROM "CourseRun" c WHERE c.semesterrunsin IN 
		(SELECT s.semester_id FROM "Semester" s WHERE s.semester_status='present')
	)
	OR p.amka IN
	(	SELECT c.amka_prof2 FROM "CourseRun" c WHERE c.semesterrunsin IN 
		(SELECT s.semester_id FROM "Semester" s WHERE s.semester_status='present')
	)
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 2.4
--##################################################################################################
CREATE OR REPLACE FUNCTION search4()
RETURNS TABLE (course_code char(7), course_title char(100), active char)(3) AS
$$ 
BEGIN 
RETURN QUERY
SELECT * FROM 
(SELECT table1.course_code AS course_code,table1.course_title AS course_title,'NAI'::char(3) AS active
FROM	(SELECT c1.course_code, c1.course_title
		FROM "Course" c1 
		WHERE EXISTS (SELECT 
				FROM(	SELECT c.course_code, c.serial_number 
						FROM "CourseRun" c 
							WHERE c.semesterrunsin IN (SELECT s.semester_id FROM "Semester" s WHERE s.semester_status='present')
					)AS c2
				WHERE c1.course_code=c2.course_code )) AS table1
UNION
SELECT table2.course_code AS course_code, table2.course_title AS course_title,'OXI'::char(3) AS active
FROM (	SELECT c1.course_code,c1.course_title 
	  	FROM "Course" c1
		WHERE c1.course_code NOT IN (SELECT table1.course_code
										FROM (	SELECT c.course_code, c.serial_number 
												FROM "CourseRun" c 
												WHERE c.semesterrunsin IN (	SELECT s.semester_id 
																			FROM "Semester" s 
																			WHERE s.semester_status='present')
											)AS table1
	  									INNER JOIN  "Course" ON table1.course_code="Course".course_code)
	AND c1.typical_season IN(SELECT s.academic_season 
							FROM "Semester" s 
							WHERE s.semester_status='present'))AS table2)AS foo;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 2.5
--##################################################################################################
CREATE OR REPLACE FUNCTION search5 (myamka int)
RETURNS TABLE  (course_code char(7), course_title char(100)) AS
$$ 
BEGIN 
RETURN QUERY 
SELECT DISTINCT table1.course_code,table2.course_title FROM ((SELECT r.course_code FROM "Register" r WHERE r.amka=myamka) AS table1
						INNER JOIN
 					 (SELECT c.course_code,c.course_title FROM "Course" c WHERE c.obligatory=true)AS table2 ON table1.course_code=table2.course_code )
 				 WHERE table1.course_code NOT IN
										(SELECT r.course_code FROM "Register" r WHERE r.amka=4 AND  r.course_code IN
  										(SELECT c.course_code FROM "Course" c WHERE c.obligatory=true) AND register_status='pass' ORDER BY course_code);

END;
$$
LANGUAGE 'plpgsql' VOLATILE;
--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 2.6
--##################################################################################################
CREATE OR REPLACE FUNCTION  search6()
RETURNS TABLE (field_code char(3), field char) AS
$$ 
BEGIN 
RETURN QUERY 
SELECT f.field_code,f.field FROM "Fields" f WHERE f.field_code IN(	
	SELECT all_fields.field_code FROM
	(SELECT foo.field_code, COUNT(*) AS freq FROM(SELECT  l.field_code FROM "Lab_fields"  l 
	WHERE l.lab_code IN(SELECT p."labJoins" FROM "Professor" p WHERE p.amka IN(SELECT d.amka_super FROM "Diploma" d)))AS foo
	GROUP BY foo.field_code) AS all_fields
	INNER JOIN
	(SELECT foo.field_code, COUNT(*) AS freq FROM(SELECT  l.field_code FROM "Lab_fields"  l 
	WHERE l.lab_code IN(SELECT p."labJoins" FROM "Professor" p WHERE p.amka IN(SELECT d.amka_super FROM "Diploma" d)))AS foo
	GROUP BY foo.field_code ORDER BY freq DESC LIMIT 1)AS most_popular
	ON most_popular.freq=all_fields.freq);

END;
$$
LANGUAGE 'plpgsql' VOLATILE;
--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 2.7
--##################################################################################################
CREATE OR REPLACE FUNCTION search7(my_season semester_season_type,my_year integer) 
RETURNS TABLE (course_code char(7), course_title char(100), success_percentage integer) AS
$$
BEGIN
RETURN QUERY
SELECT perc.course_code,"Course".course_title,perc.perc_success FROM
	((SELECT table1.course_code,((table1.num_of_sucessful_students::float/((table1.num_of_sucessful_students+table2.num_of_failed_students)::float))*100)::int AS perc_success FROM
	((SELECT foo.course_code,COUNT(*) AS num_of_sucessful_students FROM
	(SELECT table1.course_code, table2.amka FROM
	((SELECT c.course_code,c.serial_number FROM "CourseRun" c 
		WHERE c.semesterrunsin IN (SELECT s.semester_id FROM "Semester" s WHERE s.academic_year=my_year AND s.academic_season=my_season))AS table1
	INNER JOIN (SELECT * FROM "Register" r WHERE r.register_status='pass')AS table2 ON table1.course_code=table2.course_code AND table1.serial_number=table2.serial_number))AS foo
	GROUP BY foo.course_code)AS table1
	INNER JOIN
	((SELECT foo.course_code,COUNT(*) AS num_of_failed_students FROM
	(SELECT table1.course_code, table2.amka FROM
	((SELECT c.course_code,c.serial_number FROM "CourseRun" c 
		WHERE c.semesterrunsin IN (SELECT s.semester_id FROM "Semester" s WHERE s.academic_year=my_year AND s.academic_season=my_season))AS table1
	INNER JOIN (SELECT * FROM "Register" r WHERE r.register_status='fail')AS table2 ON table1.course_code=table2.course_code AND table1.serial_number=table2.serial_number))AS foo
	GROUP BY foo.course_code))AS table2 ON table1.course_code=table2.course_code)) AS perc
	INNER JOIN "Course" ON "Course".course_code=perc.course_code)
	ORDER BY course_code;

END; 
$$
LANGUAGE  'plpgsql' VOLATILE;
--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 2.8
--##################################################################################################
CREATE OR REPLACE FUNCTION search8() 
RETURNS TABLE(id, int,amka int) AS
$$
BEGIN
	RETURN QUERY
 SELECT row_number() OVER ()::integer,s.amka FROM "Student" s WHERE s.amka IN(SELECT d.amka FROM "Diploma" d WHERE d.thesis_grade>=5)
	  	AND  (SELECT  COUNT(*) AS passed FROM "Register" sr WHERE sr.register_status='pass' 
			AND sr.amka=s.amka)>=(SELECT la.min_courses FROM "Graduation_rules" la WHERE la.year_rules=(EXTRACT(YEAR FROM s.entry_date)::int))
	  	AND (SELECT SUM(c.units) FROM "Course" c WHERE c.course_code IN(SELECT sr.course_code FROM "Register" sr
			WHERE sr.register_status='pass' AND sr.amka=s.amka))>=(SELECT la.min_units FROM "Graduation_rules" la
				WHERE la.year_rules=(EXTRACT(YEAR FROM s.entry_date)::int))
		ORDER BY amka;
END;		
$$
LANGUAGE  'plpgsql' VOLATILE;
--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 2.9
--##################################################################################################
CREATE OR REPLACE FUNCTION search9()
RETURNS TABLE(amka integer, surname character(30), name character(30), work_hours bigint) AS
$$ 
BEGIN
RETURN QUERY 
SELECT * FROM
(SELECT table2.amka,table2.surname,table2.name,SUM("Course".lab_hours) AS lab_hours FROM 	
	((SELECT table1.course_code,"LabStaff".amka,"LabStaff".surname,"LabStaff".name FROM
	((SELECT c.course_code,c.labuses FROM "CourseRun" c WHERE c.semesterrunsin IN(
		(SELECT s.semester_id FROM "Semester" s WHERE s.semester_status='present')) AND c.labuses IS NOT NULL ORDER BY c.course_code)AS table1
	INNER JOIN "LabStaff" ON "LabStaff".labworks=table1.labuses) )AS table2
INNER JOIN "Course" ON "Course".course_code=table2.course_code)	GROUP BY table2.amka,table2.surname,table2.name ) AS job
UNION
SELECT * FROM
(SELECT l.amka,l.surname,l.name,0 AS lab_hours FROM "LabStaff" l WHERE labworks IS null) AS no_job  
 ORDER BY amka;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 2.10
--##################################################################################################
CREATE OR REPLACE FUNCTION search10(mycourse_code char(7))
RETURNS TABLE(course_code char(7),course_title char(100)) AS
$$ 
BEGIN
RETURN QUERY 
SELECT DISTINCT r.needs,c.course_title FROM Req r,"Course" c WHERE r.mycourse=mycourse_code AND c.course_code= r.needs;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 2.11
--##################################################################################################
CREATE OR REPLACE FUNCTION search11()
RETURNS TABLE(amka int,name char(30),surname char(30)) AS
$$ 
BEGIN
RETURN QUERY 
SELECT s.amka,s.name,s.surname FROM "Student" s WHERE s.amka IN(
	SELECT amka
	FROM "Register" r NATURAL JOIN (SELECT * FROM plh_required()) AS c
	WHERE c.course_code=r.course_code AND r.register_status='pass' 
	GROUP BY amka
	HAVING COUNT(*)= (SELECT count(*) FROM (SELECT * FROM plh_required())AS c));
END;
$$
LANGUAGE 'plpgsql' VOLATILE;


--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 3.1
--##################################################################################################
CREATE OR REPLACE FUNCTION check_semester()
RETURNS TRIGGER AS 
$BODY$ 
DECLARE  
	presentFlag int;
	overlapFlag int;
	sequenceFlag int; 
BEGIN
	presentFlag=0;
	overlapFlag=0;
	sequenceFlag=0;
	
	
			
	IF (TG_OP = 'INSERT') THEN
	
		presentFlag=(SELECT COUNT(*)FROM "Semester" s WHERE s.semester_status='present');
	
		overlapFlag=(SELECT COUNT(*)
		FROM "Semester" s
		WHERE (s.end_date >= NEW.start_date AND NEW.end_date >= s.start_date) 
				OR (s.start_date <= NEW.start_date AND NEW.end_date <= s.end_date));
				
		IF(presentFlag<>0) THEN
			IF(overlapFlag=0 AND NEW.semester_status='future') THEN
				sequenceFlag=(SELECT COUNT(*) FROM "Semester" s WHERE s.semester_status='present'
				 AND NEW.start_date<=s.end_date);
				 
				IF(sequenceFlag<>0) THEN
					RAISE EXCEPTION 'Invalid Insert:SEQUENCE';
					RETURN NULL;
				ELSE 
					RETURN NEW;
				END IF; 
			ELSIF(overlapFlag=0 AND NEW.semester_status='present') THEN
					RAISE EXCEPTION 'Invalid Insert:PRESENT ALREADY EXISTS';
					RETURN NULL;
			ELSIF(overlapFlag=0 AND NEW.semester_status='past') THEN 
				sequenceFlag=(SELECT COUNT(*) FROM "Semester" s WHERE s.semester_status='present'
				 AND NEW.start_date>=s.start_date);
				 
				IF(sequenceFlag<>0) THEN
					RAISE EXCEPTION 'Invalid Insert:SEQUENCE';
					RETURN NULL;
				ELSE 
					RETURN NEW;
				END IF; 
			ELSE
					RAISE EXCEPTION'Invalid Insert:OVERLAP';
					RETURN NULL;
			END IF;
		ELSE
			IF(overlapFlag=0 AND NEW.semester_status='future') THEN
				
				sequenceFlag=(SELECT COUNT(*) FROM "Semester" s WHERE s.semester_status='past'
				 AND NEW.start_date<=s.end_date);
				 
				IF(sequenceFlag<>0) THEN
					RAISE EXCEPTION 'Invalid Insert:SEQUENCE';
					RETURN NULL;
				ELSE 
					RETURN NEW;
				END IF; 	
					
			ELSIF(overlapFlag=0 AND NEW.semester_status='present') THEN		
				sequenceFlag=(SELECT COUNT(*) FROM "Semester" s WHERE (s.semester_status='past' AND 
				NEW.start_date<=s.end_date)OR(s.semester_status='future' AND NEW.end_date>=s.start_date));	
				
				IF(sequenceFlag<>0) THEN
					RAISE EXCEPTION 'Invalid Insert:SEQUENCE';
					RETURN NULL;
				ELSE 
					RETURN NEW;
				END IF;
			ELSIF(overlapFlag=0 AND NEW.semester_status='past') THEN 	
				sequenceFlag=(SELECT COUNT(*) FROM "Semester" s WHERE s.semester_status='future'AND NEW.start_date>=s.start_date);
				 
				IF(sequenceFlag<>0) THEN
					RAISE EXCEPTION 'Invalid Insert:SEQUENCE';
					RETURN NULL;
				ELSE 
					RETURN NEW;
				END IF; 
				
			ELSE
				RAISE EXCEPTION'Invalid Insert:OVERLAP';
				RETURN NULL;
			END IF;
		END IF;
	ELSIF (TG_OP = 'UPDATE') THEN
			IF(NEW.semester_status='present') THEN
				UPDATE "Semester" 
				SET semester_status='past'
				WHERE semester_status='present';
				RETURN NEW;
			ELSIF(NEW.semester_status='past' AND OLD.semester_status='present') THEN
				RETURN NEW;
			ELSE
				RAISE EXCEPTION 'Invalid Update:ONLY PRESENT';
				RETURN NULL;
			END IF;
	END IF;

END;
$BODY$
LANGUAGE 'plpgsql';

CREATE TRIGGER check_trigger2
BEFORE INSERT OR UPDATE ON "Semester"
FOR EACH ROW
EXECUTE PROCEDURE check_semester();

--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 3.2
--##################################################################################################
CREATE OR REPLACE FUNCTION check_grade()
RETURNS TRIGGER AS 
$BODY$
BEGIN

	

	UPDATE "Register"
	SET final_grade= calc_grade(foo.exam_grade,foo.exam_min,foo.lab_grade,foo.lab_min,foo.exam_percentage,foo.labuses)	
	FROM (	SELECT table1.amka,table1.serial_number,table1.course_code,table1.exam_grade,table1.lab_grade,table2.exam_min,table2.lab_min,table2.labuses,table2.exam_percentage 
			FROM (	SELECT * 
					FROM "Register" r
					WHERE r.register_status='approved' 
					AND r.final_grade IS null 
					AND r.course_code IN(	SELECT c.course_code 
											FROM "CourseRun" c  
											WHERE c.semesterrunsin IN(	SELECT s.semester_id 
																		FROM "Semester" s 
																		WHERE s.semester_status='present')
										)
					AND r.serial_number IN(		SELECT c.serial_number 
												FROM "CourseRun" c 
												WHERE c.semesterrunsin IN(	SELECT s.semester_id 
																			FROM "Semester" s 
																			WHERE s.semester_status='present')	
										)
				) AS table1 
				INNER JOIN						
				(	SELECT * 
					FROM "CourseRun" c 
					WHERE c.semesterrunsin IN(	SELECT s.semester_id 
												FROM "Semester" s 
												WHERE s.semester_status='present')
				) AS table2
			ON table1.course_code=table2.course_code
		)AS foo
	WHERE foo.amka="Register".amka AND foo.course_code="Register".course_code AND foo.serial_number="Register".serial_number;

	
	UPDATE "Register"
	SET register_status=CAST('pass' AS register_status_type)
	FROM(SELECT * FROM "Register" r WHERE r.register_status='approved' 
	AND r.final_grade >=5  AND r.course_code IN(SELECT c.course_code FROM "CourseRun" c  
	WHERE c.semesterrunsin IN(	SELECT s.semester_id FROM "Semester" s WHERE s.semester_status='present'))
	AND r.serial_number IN(	SELECT c.serial_number FROM "CourseRun" c WHERE c.semesterrunsin IN(	SELECT s.semester_id 
	FROM "Semester" s WHERE s.semester_status='present'))) AS tb
	WHERE tb.amka="Register".amka AND tb.course_code="Register".course_code AND tb.serial_number="Register".serial_number;
	
	
	UPDATE "Register"
	SET register_status=CAST('fail' AS register_status_type)
	FROM(SELECT * FROM "Register" r WHERE r.register_status='approved' 
	AND r.final_grade <5  AND r.course_code IN(SELECT c.course_code FROM "CourseRun" c  
	WHERE c.semesterrunsin IN(	SELECT s.semester_id FROM "Semester" s WHERE s.semester_status='present'))
	AND r.serial_number IN(	SELECT c.serial_number FROM "CourseRun" c WHERE c.semesterrunsin IN(	SELECT s.semester_id 
	FROM "Semester" s WHERE s.semester_status='present'))) AS tb
	WHERE tb.amka="Register".amka AND tb.course_code="Register".course_code AND tb.serial_number="Register".serial_number;
	
	
	RETURN NEW;


END;
$BODY$
LANGUAGE 'plpgsql';


CREATE TRIGGER check_trigger3
BEFORE UPDATE ON "Semester"
FOR EACH ROW
WHEN (NEW.semester_status='past')
EXECUTE PROCEDURE check_grade();
--##################################################################################################
----ΛΕΙΤΟΥΡΓΙΑ 3.3
--##################################################################################################
CREATE OR REPLACE FUNCTION check_registration()
RETURNS TRIGGER AS 
$BODY$
DECLARE 
required_flag int;
lessons_num int;
BEGIN
	required_flag=1;
	lessons_num=0;	 

	
	IF ((SELECT COUNT(*) FROM required_courses(NEW.amka,NEW.course_code))<>0) THEN
		required_flag=(SELECT COUNT(*) FROM "Register" r  WHERE r.course_code IN(SELECT course_code 
			FROM required_courses(NEW.amka,NEW.course_code))
			AND r.register_status='pass'); 
	ELSE 
		required_flag=1;
	END IF;
	lessons_num=(SELECT COUNT(*) FROM "Register" r1 WHERE r1.amka=NEW.amka 
	AND r1.register_status='approved');
	
	IF(required_flag=0 OR lessons_num>7) THEN
		UPDATE "Register"
		SET register_status='rejected'
		WHERE  amka=NEW.amka AND course_code=NEW.course_code AND serial_number=NEW.serial_number;
		RETURN NULL;	
	ELSE	
		RETURN NEW;
	END IF;

END;
$BODY$
LANGUAGE 'plpgsql';

CREATE TRIGGER check_trigger4
BEFORE UPDATE ON "Register"
FOR EACH ROW
WHEN (NEW.register_status='approved' )
EXECUTE PROCEDURE check_registration();
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--ΒΟΗΘΗΤΙΚΕΣ ΣΥΝΑΡΤΗΣΕΙΣ
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--Επιστρέφει τα υποχρεωτικά μαθήματα ενός συ
CREATE OR REPLACE FUNCTION required_courses(my_amka int,c_code char(7))
RETURNS TABLE(course_code char(7)) AS
$$
BEGIN
	RETURN QUERY
	SELECT  d.main FROM "Course_depends" d WHERE d.mode='required' AND d.dependent IN (SELECT r1.course_code
		FROM "Register" r1 WHERE r1.amka=my_amka AND r1.course_code=c_code AND (r1.register_status='proposed' OR r1.register_status='requested'));
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE ;

--Επιστρέφει το μέσο όρο όλων των περασμένων μαθημάτων
CREATE OR REPLACE FUNCTION sum_grade(samka int)
RETURNS FLOAT AS 
$$
DECLARE 
res float;
BEGIN
 
	res= (SELECT ROUND(((SUM(foo.grade))/SUM(foo.weight))::numeric,1)  FROM
		(SELECT t1.course_code,t1.final_grade*t2.weight AS grade,t2.weight  FROM(
			(SELECT r.final_grade,r.course_code FROM 
			"Register" r WHERE r.amka=samka AND r.register_status='pass') AS t1
			 INNER JOIN 
			(SELECT c.course_code, c.weight FROM "Course" c) AS t2 ON t2.course_code=t1.course_code)) AS foo);
	
	RETURN res;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;
----------------------------------------------------------------------------------------------------
--Επιστρέφει τυχαία ονόματα
CREATE OR REPLACE FUNCTION random_names(n integer)
RETURNS TABLE(name character(30),sex character(1), id integer) AS
$$
BEGIN
	RETURN QUERY
	SELECT nam.name, nam.sex, row_number() OVER ()::integer
	FROM (SELECT "Name".name, "Name".sex FROM "Name" ORDER BY random() LIMIT n ) as nam;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
----------------------------------------------------------------------------------------------------
--Επιστρέφει τυχαία επώνυμα
CREATE OR REPLACE FUNCTION random_surnames(n integer)
RETURNS TABLE(surname character(30), id integer) AS
$$
BEGIN
RETURN QUERY
	SELECT snam.surname, row_number() OVER ()::integer
	FROM (SELECT "Surname".surname FROM "Surname" WHERE right("Surname".surname,1)='Σ'
		ORDER BY random() LIMIT n) as snam;
END;
$$
LANGUAGE 'plpgsql' VOLATILE; 
----------------------------------------------------------------------------------------------------
--Συνάρτηση δημιουργίας αριθμού μητρώου φοιτητή με βάση το έτος εισαγωγής και
--τον αύξοντα αριθμό του φοιτητή στο έτος
CREATE OR REPLACE FUNCTION create_am(entry_date date, id integer)
RETURNS character(10) AS
$$
DECLARE
 year integer;
 num integer;
 local_am character(10);
 last_student integer;
BEGIN
 year=extract(year from entry_date)::integer;
 SELECT MAX(st.am) INTO local_am FROM "Student" st WHERE  extract(year FROM st.entry_date)::integer= year;
 last_student=right(local_am,-4)::integer;
	IF EXISTS(SELECT 1 FROM "Student" s WHERE extract(year from s.entry_date)::integer = year) THEN
		num= id+ last_student;
		RETURN concat(year::character(4),lpad(num::text,6,'0'));
	ELSE
		num=id;
		RETURN concat(year::character(4),lpad(num::text,6,'0'));
	END IF;	
 
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE; 
----------------------------------------------------------------------------------------------------
--Συνάρτηση προσαρμογής επωνύμου σε αρσενικό ή θηλυκό γένος
CREATE OR REPLACE FUNCTION adapt_surname(surname character(30),
sex character(1)) RETURNS character(30) AS
$$
DECLARE
 result character(30);
BEGIN
	result = surname;
	IF right(surname,1)<>'Σ' THEN
		RAISE NOTICE 'Cannot handle this surname';
	ELSIF sex='F' THEN
		IF RIGHT(surname,2)<>'ΟΣ' THEN
			result = left(surname,-1);
		ELSE
			result = concat(left(surname,-1),'Υ');
		END IF;	
	ELSIF sex<>'M' THEN
		RAISE NOTICE 'Wrong sex parameter';
	END IF;
	
 RETURN result;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE; 
----------------------------------------------------------------------------------------------------
--Συνάρτηση δημιουργίας μοναδικού σειριακού αριθμού για κάθε δίπλωμα
CREATE OR REPLACE FUNCTION create_diploma_num(id integer)
RETURNS integer AS
$$
DECLARE
num integer;
BEGIN
	IF EXISTS(SELECT 1 FROM "Diploma") THEN
		num= id+(SELECT MAX(d.diploma_num) FROM "Diploma" d )::integer;
		RETURN num;
	ELSE
		RETURN id;
	END IF;	
 
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE; 

----------------------------------------------------------------------------------------------------
--Συνάρτηση δημιουργίας AMKA
CREATE OR REPLACE FUNCTION create_st_amka(id integer)
RETURNS integer AS
$$
DECLARE
num integer;
BEGIN
	IF EXISTS(SELECT 1 FROM "Student") THEN
		num= id+(SELECT MAX(st.amka) FROM "Student" st )::integer;
		RETURN num;
	ELSE
		RETURN id;
	END IF;	
 
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE; 
----------------------------------------------------------------------------------------------------
--Επιστρέφει ένα τυχαίο αντρικό όνομα 
CREATE OR REPLACE FUNCTION give_fathername()
RETURNS TABLE(name character(30)) AS
$$

BEGIN
 RETURN QUERY
	SELECT "Name".name 
	FROM "Name" WHERE "Name".sex='M' ORDER BY random() LIMIT 1;
		
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;
----------------------------------------------------------------------------------------------------
--Επιστρέφει το μαιλ φοιτητή
CREATE OR REPLACE FUNCTION create_student_email(am character(30))
RETURNS character(30) AS
$$
BEGIN
  RETURN concat('s',am,'@isc.tuc.gr');	
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;
-----------------------------------------------------------------------------------------------------
-- Eπιστρέφει μία τυχαία τιμή τύπου rank_type
CREATE OR REPLACE FUNCTION random_rank()
RETURNS TABLE (rand_rank rank_type) AS
$$

BEGIN 
RETURN QUERY
SELECT myrank FROM unnest(enum_range(NULL::rank_type)) myrank ORDER BY random() LIMIT 1;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;
-----------------------------------------------------------------------------------------------------
--Eπιστρέφει μία τυχαία τιμή από τα διαθέσιμα lab_codes
CREATE OR REPLACE FUNCTION random_lab()
RETURNS TABLE(mylab integer) AS
$$
BEGIN 
RETURN QUERY
SELECT "Lab".lab_code FROM "Lab" ORDER BY random() LIMIT 1;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;
-----------------------------------------------------------------------------------------------------
--Επιστρέφει το μαιλ ενός καθηγητή ή εργαστηριακού προσωπικού)
CREATE OR REPLACE FUNCTION create_professor_email(id integer)
RETURNS character(30) AS
$$
DECLARE
myamka integer;
BEGIN
  SELECT MAX(p.amka) INTO myamka FROM "Professor" p;
  myamka=myamka+id;
  RETURN concat('p','XXXX',lpad(myamka::text,6,'0'),'@isc.tuc.gr');	
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;
-----------------------------------------------------------------------------------------------------
--Συνάρτηση δημιουργίας AMKA καθηγητή
CREATE OR REPLACE FUNCTION create_pro_amka(id integer)
RETURNS integer AS
$$
DECLARE
num integer;
BEGIN
	IF EXISTS(SELECT 1 FROM "Professor") THEN
		num= id+(SELECT MAX(p.amka) FROM "Professor" p )::integer;
		RETURN num;
	ELSE
		RETURN id;
	END IF;	
 
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE; 
-----------------------------------------------------------------------------------------------------
--Συνάρτηση δημιουργίας AMKA εργαστηριακού προσωπικού
CREATE OR REPLACE FUNCTION create_lab_amka(id integer)
RETURNS integer AS
$$
DECLARE
num integer;
BEGIN
	IF EXISTS(SELECT 1 FROM "LabStaff") THEN
		num= id+(SELECT MAX(l.amka) FROM "LabStaff" l )::integer;
		RETURN num;
	ELSE
		RETURN id;
	END IF;	
 
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE; 
-----------------------------------------------------------------------------------------------------
--Επιστρέφει το μαιλ εργαστηριακού προσωπικού
CREATE OR REPLACE FUNCTION create_lab_email(id integer)
RETURNS character(30) AS
$$
DECLARE
myamka integer;
BEGIN
  SELECT MAX(l.amka) INTO myamka FROM "LabStaff" l;
  myamka=myamka+id;
  RETURN concat('l','XXXX',lpad(myamka::text,6,'0'),'@isc.tuc.gr');	
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;
-----------------------------------------------------------------------------------------------------
-- Eπιστρέφει μία τυχαία τιμή τύπου level_type
CREATE OR REPLACE FUNCTION random_level()
RETURNS TABLE (rand_level level_type) AS
$$
BEGIN 
RETURN QUERY
SELECT mylevel FROM unnest(enum_range(NULL::level_type)) mylevel ORDER BY random() LIMIT 1;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;
----------------------------------------------------------------------------------------------------
-- Υπολογίζει τον τελικό βαθμό
CREATE OR REPLACE FUNCTION calc_grade(exam numeric,exam_min numeric,lab numeric,lab_min numeric,perc numeric,haslab int)
RETURNS numeric AS
$$
DECLARE
res numeric;
BEGIN
IF(haslab IS Null) THEN
	res=exam;
ELSE 
	IF(exam<exam_min) THEN
		res=exam;
	ELSIF (lab<lab_min) THEN
		res=0;
	ELSE	
		res=exam*perc+lab*(1-perc);
	END IF;	
END IF;
RETURN res;
END;
$$
----------------------------------------------------------------------------------------------------
--Tα μαθήματα που διδάσκονται στο τρέχον εξάμηνο (course_code,serial_number,typical_year)
CREATE OR REPLACE FUNCTION present_courses()
RETURNS TABLE (course_code char(7),serial_number int, typical_year smallint ) AS
$$
BEGIN 
RETURN QUERY
SELECT  sem_courses.course_code, sem_courses.serial_number,all_courses.typical_year FROM
	((SELECT c.course_code, c.serial_number FROM "CourseRun" c WHERE c.semesterrunsin IN(
			SELECT s.semester_id FROM "Semester" s WHERE s.semester_status='present')) AS sem_courses
	INNER JOIN 
	(SELECT * FROM "Course") AS all_courses ON sem_courses.course_code=all_courses.course_code)
ORDER BY typical_year;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;

CREATE OR REPLACE FUNCTION present_courses()
RETURNS TABLE (amka int),serial_number int, typical_year smallint ) AS
$$
BEGIN
----------------------------------------------------------------------------------------------------
--Eπιστρέφει το έτος σπουδών για κάθε φοιτήτη
IF((SELECT academic_season FROM "Semester" WHERE semester_status='present' )='winter') THEN
	RETURN QUERY
	SELECT s1.amka,CAST((s2.academic_year - extract(YEAR from s1.entry_date)) AS smallint)AS study_year
		 FROM "Student" s1, "Semester" s2 WHERE s2.semester_status='present'; 
ELSE 
	RETURN QUERY
	SELECT s1.amka,CAST((s2.academic_year - extract(YEAR from s1.entry_date)+ 1) AS smallint)AS study_year
		 FROM "Student" s1, "Semester" s2 WHERE s2.semester_status='present'; 
END IF;

END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;
----------------------------------------------------------------------------------------------------
--ζεύγη κωδικών για μαθήματα που εξαρτώνται άμεσα ή έμμεσα 
-- το ένα από το άλλο μέσω προαπαιτουμένων μαθημάτων.
CREATE RECURSIVE VIEW Req(mycourse,needs) AS (
	SELECT dependent as mycourse ,main as needs
	FROM "Course_depends" 
	UNION
	SELECT r.mycourse as needs,d.main as needs
	FROM Req r, "Course_depends" d
	WHERE r.needs = d.dependent );
----------------------------------------------------------------------------------------------------	
--Επιστρέφει όλα τα υποχρεωτικά μαθήματα στον τομέα πληροφορικής
CREATE OR REPLACE FUNCTION plh_required()
RETURNS TABLE (course_code char(7)) AS
$$
BEGIN
RETURN QUERY 
SELECT DISTINCT c.main FROM "Course_depends" c WHERE  split_part(c.main::TEXT,' ', 1)='ΠΛΗ' AND c.mode='required';
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;
----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION prop_courses(myamka int)
RETURNS TABLE (course_code char(7)) AS
$$
BEGIN
RETURN QUERY 
--Επιστρέφει τα προτεινόμενα μαθήματα 
	SELECT p.course_code FROM present_courses() p WHERE p.typical_year<=(
 				SELECT (extract(YEAR from s2.end_date) - extract(YEAR from s1.entry_date))AS study_year 
				FROM "Student" s1, "Semester" s2 WHERE s2.semester_status='present' AND s1.amka=myamka)
	EXCEPT
	--Επιστρέφει τα περασμένα μαθήματα από τα πιθανά πορτεινόμενα για κάθε φοιτητή
	SELECT  r2.course_code FROM "Register" r2 WHERE r2.amka=myamka AND r2.register_status='pass' AND r2.course_code IN(
 			SELECT p.course_code FROM present_courses() p WHERE p.typical_year<=(
 				SELECT (extract(YEAR from s2.end_date) - extract(YEAR from s1.entry_date))AS study_year 
				FROM "Student" s1, "Semester" s2 WHERE s2.semester_status='present' AND s1.amka=r2.amka));
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;
----------------------------------------------------------------------------------------------------


CREATE OR REPLACE FUNCTION push_modifications()
  RETURNS trigger AS $BODY$
BEGIN
IF (TG_OP = 'UPDATE') THEN
	UPDATE "Student" 
	SET am=OLD.am,name=NEW.name,surname=NEW.surname,entry_date=concat(NEW.entry_year,'-',extract(MONTH from entry_date),'-',extract(DAY from entry_date))::date
	WHERE "Student".am=NEW.am;
	
		UPDATE "Diploma"
	SET thesis_grade=NEW.thesis_grade, amka_super=prof.amka
	FROM (SELECT * FROM "Professor" p WHERE p.name=split_part(NEW.supervisor_fullname, ' ', 1) AND p.surname=split_part(NEW.supervisor_fullname, ' ', 2)) AS prof
	WHERE "Diploma".amka IN(SELECT s.amka FROM "Student" s WHERE s.am=NEW.am);
	
	RETURN NEW;
END IF;
IF (TG_OP = 'INSERT') THEN
	
	INSERT INTO "Diploma"(amka,thesis_grade,amka_super) 
	SELECT s.amka,NEW.thesis_grade,p.amka 
	FROM "Professor" p,"Student" s
	WHERE p.name=split_part(NEW.supervisor_fullname, ' ', 1) AND p.surname=split_part(NEW.supervisor_fullname, ' ', 2)
	AND s.am=NEW.am AND NEW.am NOT IN(SELECT s.am FROM "Student" s WHERE s.amka IN(SELECT d.amka FROM "Diploma" d));
	
	UPDATE "Diploma" 
	SET  thesis_grade=NEW.thesis_grade, amka_super=prof.amka
	FROM (SELECT * FROM "Professor" p WHERE p.name=split_part(NEW.supervisor_fullname, ' ', 1) AND p.surname=split_part(NEW.supervisor_fullname, ' ', 2))AS prof
	WHERE "Diploma".amka IN(SELECT s.amka FROM "Student" s WHERE s.am=NEW.am);
	
  RETURN NEW;
END IF;
END;
$BODY$
LANGUAGE plpgsql; 

CREATE TRIGGER propagate_modifications 
INSTEAD OF INSERT OR UPDATE ON show_diplomas 
FOR EACH ROW 
EXECUTE PROCEDURE push_modifications();

	
	