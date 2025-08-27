SELECT * FROM world_life_expectancy.world_life_expectancy_staging;

SELECT country, year, ROW_NUMBER() OVER(PARTITION BY country, year) AS Row_Num
FROM world_life_expectancy_staging;

WITH CTE AS
(
SELECT country, year, ROW_NUMBER() OVER(PARTITION BY country, year) AS Row_Num
FROM world_life_expectancy_staging
)
SELECT country, year
FROM CTE
WHERE row_num > 1
;

CREATE TABLE `world_life_expectancy_staging2` (
  `Country` text,
  `Year` int DEFAULT NULL,
  `Status` text,
  `Life expectancy` text,
  `Adult Mortality` int DEFAULT NULL,
  `infant deaths` int DEFAULT NULL,
  `percentage expenditure` double DEFAULT NULL,
  `Measles` int DEFAULT NULL,
  `BMI` double DEFAULT NULL,
  `under-five deaths` int DEFAULT NULL,
  `Polio` int DEFAULT NULL,
  `Diphtheria` int DEFAULT NULL,
  `HIV/AIDS` double DEFAULT NULL,
  `GDP` int DEFAULT NULL,
  `thinness  1-19 years` double DEFAULT NULL,
  `thinness 5-9 years` double DEFAULT NULL,
  `Schooling` double DEFAULT NULL,
  `Row_ID` int DEFAULT NULL,
  `Row_Num` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO world_life_expectancy_staging2
SELECT *, ROW_NUMBER() OVER(PARTITION BY country, year) AS Row_Num
FROM world_life_expectancy_staging;

SELECT * FROM  world_life_expectancy_staging2;

SELECT * FROM  world_life_expectancy_staging2
WHERE Row_NUM > 1;

DELETE FROM world_life_expectancy_staging2
WHERE Row_NUM > 1;

SELECT * FROM  world_life_expectancy_staging2
WHERE Row_NUM > 1;

SELECT * FROM  world_life_expectancy_staging2;

SELECT DISTINCT status FROM world_life_expectancy_staging2; 

SELECT DISTINCT country, Status
FROM  world_life_expectancy_staging2
WHERE Status = ''
;

SELECT DISTINCT country, Status
FROM  world_life_expectancy_staging2
WHERE country IN ('Afghanistan', 'Albania', 'Georgia', 'United States of America', 'Vanuatu', 'Zambia');

-- update 1

UPDATE world_life_expectancy_staging2
SET Status = 'Developing'
WHERE Country IN ('Afghanistan', 'Albania', 'Georgia', 'Vanuatu', 'Zambia');


-- update 2

UPDATE world_life_expectancy_staging2
SET Status = 'Developed'
WHERE Country IN ('United States of America');

-- check 

SELECT * FROM  world_life_expectancy_staging2;

-- checking blank in life expectancy 

SELECT country, year `Life expectancy`
FROM  world_life_expectancy_staging2 
WHERE `Life expectancy` = ""
;

-- join to gather necessary data

SELECT 
t1.country, t1.year, t1.`Life expectancy`,
t2.country, t2.year, t2.`Life expectancy`,
t3.country, t3.year, t3.`Life expectancy`,
ROUND(((t2.`Life expectancy` + t3.`Life expectancy`)/2),1) 
FROM world_life_expectancy_staging2 t1
JOIN world_life_expectancy_staging2 t2
ON t1.country = t2.country
AND t1.year = t2.year -1 -- 2019
JOIN world_life_expectancy_staging2 t3
ON t1.country = t3.country
AND t1.year = t3.year +1 -- 2017
WHERE t1.`Life expectancy` = ''
;

-- update

UPDATE world_life_expectancy_staging2 t1
JOIN world_life_expectancy_staging2 t2
ON t1.country = t2.country
AND t1.year = t2.year -1 -- 2019
JOIN world_life_expectancy_staging2 t3
ON t1.country = t3.country
AND t1.year = t3.year +1 -- 2017
SET t1.`Life expectancy` = ROUND(((t2.`Life expectancy` + t3.`Life expectancy`)/2),1) 
WHERE t1.`Life expectancy` = ''
;

-- check

SELECT country, year
FROM world_life_expectancy_staging2
WHERE `Life expectancy` = ''
;