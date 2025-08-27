/*
-- Dataset: USHouseholdIncome from Analyst Builder
-- Source: https://www.analystbuilder.com/
-- Queried using: MySQL Workbench
*/


-- Data Cleaning Steps that we gonna automate --

/*
-- Remove Duplicates
DELETE FROM us_household_income_clean 
WHERE 
	row_id IN (
	SELECT row_id
FROM (
	SELECT row_id, id,
		ROW_NUMBER() OVER (
			PARTITION BY id
			ORDER BY id) AS row_num
	FROM 
		us_household_income_clean
) duplicates
WHERE 
	row_num > 1
);

-- Fixing some data quality issues by fixing typos and general standardization
UPDATE us_household_income_clean
SET State_Name = 'Georgia'
WHERE State_Name = 'georia';

UPDATE us_household_income_clean
SET County = UPPER(County);

UPDATE us_household_income_clean
SET City = UPPER(City);

UPDATE us_household_income_clean
SET Place = UPPER(Place);

UPDATE us_household_income_clean
SET State_Name = UPPER(State_Name);

UPDATE us_household_income_clean
SET `Type` = 'CDP'
WHERE `Type` = 'CPD';

UPDATE us_household_income_clean
SET `Type` = 'Borough'
WHERE `Type` = 'Boroughs';

SELECT * 
FROM ushouseholdincome_cleaned
;
*/

-- Automation process start -- 

-- Creating Procedure

	DELIMITER $$
    DROP PROCEDURE IF EXISTS Copy_and_clean_data;
	CREATE PROCEDURE Copy_and_clean_data()
	BEGIN

-- CREATING OUR STAGING TABLE

	CREATE TABLE IF NOT EXISTS `us_household_income_clean` (
	  `row_id` int DEFAULT NULL,
	  `id` int DEFAULT NULL,
	  `State_Code` int DEFAULT NULL,
	  `State_Name` text,
	  `State_ab` text,
	  `County` text,
	  `City` text,
	  `Place` text,
	  `Type` text,
	  `Primary` text,
	  `Zip_Code` int DEFAULT NULL,
	  `Area_Code` int DEFAULT NULL,
	  `ALand` int DEFAULT NULL,
	  `AWater` int DEFAULT NULL,
	  `Lat` double DEFAULT NULL,
	  `Lon` double DEFAULT NULL,
	  `TimeStamp` TIMESTAMP DEFAULT NULL -- we are adding time stamp in case we gonna encounter any issues. It's easier to find and debug it when we have timestamp here 
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
    
-- COPY DATA TO NEW TABLE

	INSERT INTO us_household_income_clean
	SELECT *, current_timestamp()
	FROM ushouseholdincome;
    
-- DATA CLEANING STEPS

	-- Remove Duplicates
DELETE FROM us_household_income_clean 
WHERE 
	row_id IN (
	SELECT row_id
FROM (
	SELECT row_id, id,
		ROW_NUMBER() OVER (
			PARTITION BY id
			ORDER BY id) AS row_num
	FROM 
		us_household_income_clean
) duplicates
WHERE 
	row_num > 1
);

	-- Fixing some data quality issues by fixing typos and general standardization
UPDATE us_household_income_clean
SET State_Name = 'Georgia'
WHERE State_Name = 'georia';

UPDATE us_household_income_clean
SET County = UPPER(County);

UPDATE us_household_income_clean
SET City = UPPER(City);

UPDATE us_household_income_clean
SET Place = UPPER(Place);

UPDATE us_household_income_clean
SET State_Name = UPPER(State_Name);

UPDATE us_household_income_clean
SET `Type` = 'CDP'
WHERE `Type` = 'CPD';

UPDATE us_household_income_clean
SET `Type` = 'Borough'
WHERE `Type` = 'Boroughs';
    
END $$
DELIMITER ;

-- CALLING OUR PROCEDURE
CALL Copy_and_clean_data(); 


-- DEBUGGING /CHECKING WHETHER EVERYTHING WORKED

-- before
SELECT COUNT(row_id) FROM ushouseholdincome; -- 32292 rows
SELECT State_Name, COUNT(State_Name) FROM ushouseholdincome GROUP BY State_Name; -- Georgia issue 
SELECT row_id, id FROM (SELECT row_id, id, ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) AS row_num FROM ushouseholdincome) AS duplicates WHERE row_num > 1; -- 6 duplicates

-- after
SELECT COUNT(row_id) FROM us_household_income_clean; -- 32286 rows [6 duplicate rows were deleted]
SELECT State_Name, COUNT(State_Name) FROM us_household_income_clean GROUP BY State_Name; -- Georgia issue fixed, upper case letters added
SELECT row_id, id FROM (SELECT row_id, id, ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) AS row_num FROM us_household_income_clean) AS duplicates WHERE row_num > 1; -- 0 duplicates

-- CREATING AN EVENT that gonna schedule our stored procedure every 1 day

CREATE EVENT run_data_cleaning
	ON SCHEDULE EVERY 1 DAY
    DO CALL Copy_and_clean_data();

-- checking whether everything was created properly 

SELECT * FROM ushouseholdincome;
SELECT * FROM us_household_income_clean; 
SELECT DISTINCT TimeStamp FROM us_household_income_clean;

