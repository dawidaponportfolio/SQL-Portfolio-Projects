-- Amending column name 

ALTER TABLE `ushouseholdincome_statistics` 
RENAME COLUMN `ď»żid` TO `id`
;

-- Checking whether everything was uploaded correctly

SELECT * FROM `ushouseholdincome_statistics`;
SELECT * FROM `uus_household_income`;

SELECT COUNT(id) FROM `ushouseholdincome_statistics`;
SELECT COUNT(id) FROM `uus_household_income`;

-- creating backup tables

CREATE TABLE `ushouseholdincome_statistics_staging`
LIKE `ushouseholdincome_statistics`;

INSERT INTO `ushouseholdincome_statistics_staging`
SELECT * FROM `ushouseholdincome_statistics`;

CREATE TABLE `uus_household_income_staging`
LIKE `uus_household_income`;

INSERT INTO `uus_household_income_staging`
SELECT * FROM `uus_household_income`;

-- Looking for a duplicates

SELECT id, COUNT(id)
FROM uus_household_income_staging
GROUP BY id
HAVING COUNT(id) > 1
; -- found 6 of them

-- We can find them based on the below 2 queries

-- this one
SELECT id, row_id, COUNT(id)
FROM uus_household_income_staging
GROUP BY id
HAVING COUNT(id) = 2;

-- or this one 
SELECT row_id, id, ROW_NUMBER() OVER(PARTITION BY id) as Row_Num
FROM uus_household_income_staging;

SELECT * 
FROM
(SELECT row_id, id, ROW_NUMBER() OVER(PARTITION BY id) as Row_Num
FROM uus_household_income_staging) AS Row_Duplicates
WHERE Row_Num > 1
;

-- Now we can delete duplicates knowing their id and row_id

DELETE FROM uus_household_income_staging
WHERE row_id IN (
SELECT row_id 
FROM
(SELECT row_id, id, ROW_NUMBER() OVER(PARTITION BY id) as Row_Num
FROM uus_household_income_staging) AS Row_Duplicates
WHERE Row_Num > 1
);

-- checking whether it worked

SELECT row_id 
FROM
(SELECT row_id, id, ROW_NUMBER() OVER(PARTITION BY id) as Row_Num
FROM uus_household_income_staging) AS Row_Duplicates
WHERE Row_Num > 1
;

-- we can also check using this one
SELECT id, row_id, COUNT(id)
FROM uus_household_income_staging
GROUP BY id
HAVING COUNT(id) = 2;

-- Fixing state name issue (Georgia)

SELECT DISTINCT State_Name
FROM uus_household_income_staging
ORDER BY State_Name ASC;

SELECT row_id, id 
FROM uus_household_income_staging
WHERE State_Name = 'georia';

-- Updating relevant field 

UPDATE uus_household_income_staging
SET State_Name = 'Georgia'
WHERE row_id = 7833 AND id = 13022023;

-- checking

SELECT row_id, id 
FROM uus_household_income_staging
WHERE State_Name = 'georia';

SELECT DISTINCT State_Name
FROM uus_household_income_staging
ORDER BY State_Name ASC;

-- Fixing state name issue (Alabama)

SELECT row_id, id, State_Name
FROM uus_household_income_staging
WHERE State_Name = 'Alabama';

-- Updating relevant field 

UPDATE uus_household_income_staging
SET State_Name = 'Alabama'
WHERE State_Name = 'alabama';

-- checking

 SELECT row_id, id, State_Name
FROM uus_household_income_staging
WHERE State_Name = 'Alabama';


SELECT DISTINCT State_AB
FROM uus_household_income_staging; -- all good

-- missing info in place check

SELECT * 
FROM uus_household_income_staging 
WHERE Place = ''; -- 1 row with missing data found

-- checking whether we can populate blank data from other records

SELECT *
FROM uus_household_income_staging
WHERE County = 'Autauga County'; -- missing place IS 'Autaugaville'

-- Updating relevant field 

UPDATE uus_household_income_staging
SET Place = 'Autauga County'
WHERE Place = '' AND row_id = 32;

-- Checking 

SELECT * 
FROM uus_household_income_staging 
WHERE Place = '';


-- Checking type column

SELECT DISTINCT `Type`
FROM uus_household_income_staging ;

SELECT Type, COUNT(Type)
FROM uus_household_income_staging 
GROUP BY Type;

-- CPD and CDP are potentially a data issues [will not change without domain knowledge

-- 'Boroughs' seems to be misspelled 'Borough'

SELECT `Type`, row_id, id 
FROM uus_household_income_staging
WHERE Type = 'Boroughs';

-- Updating relevant field 

UPDATE uus_household_income_staging
SET Type = 'Borough'
WHERE Type = 'Boroughs' AND row_id = 24528 AND id = 42013656;

-- checking

SELECT Type, COUNT(Type)
FROM uus_household_income_staging 
GROUP BY Type;


-- now we can check ALand and AWater columns 

SELECT ALand, AWater
FROM uus_household_income_staging 
WHERE AWater =0 OR AWater = '' OR AWater IS NULL;

SELECT DISTINCT AWater
FROM uus_household_income_staging 
WHERE AWater =0 OR AWater = '' OR AWater IS NULL; -- there are only 0s no blank or NULL data

SELECT ALand, AWater
FROM uus_household_income_staging 
WHERE ALand =0 OR ALand = '' OR ALand IS NULL;

SELECT DISTINCT ALand
FROM uus_household_income_staging 
WHERE ALand =0 OR ALand = '' OR ALand IS NULL; -- there are only 0s no blank or NULL data


-- checking whether there are 0 in both land and water we potentially could be removed from the database 

SELECT ALand, AWater
FROM uus_household_income_staging 
WHERE (AWater =0 OR AWater = '' OR AWater IS NULL) AND (ALand =0 OR ALand = '' OR ALand IS NULL); -- 0 rows returned so no issue here 