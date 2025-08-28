/*
-- Dataset: layoffs from Alex the Analyst
-- Source: https://github.com/AlexTheAnalyst/MySQL-YouTube-Series/blob/main/layoffs.csv
-- Queried using: MySQL Workbench
*/

-- Creating new database called "world_layoffs"

CREATE SCHEMA `world_layoffs`;

-- Creating new table with Excel raw data called "layoffs" using Table Data Import Wizard 

-- Before starting the cleaning process I will make a copy of the "layoffs" table and call it "layoffs_staging" and from now on this will be the table that I will be working on while "layoffs" will be my backup table with raw data

CREATE TABLE `layoffs_staging`
LIKE layoffs; -- table creation

-- Inserting data to the newly created table

INSERT INTO layoffs_staging 
SELECT * 
FROM layoffs;

-- Making sure that everything was created correctly 

SELECT * FROM layoffs;
SELECT * FROM layoffs_staging;

-- Now we can start cleaning data with the following steps: 1) Remove Duplicates 2) Standarize the data 3) Find and remove NULL values and Blank values 4) Remove unnecessary rows and columns -- 

-- STEP 1 Remove Duplicates

-- First thing that we need to do it to find our duplicate records to do so we will create another table with additional column row_num [row number] that will allow us the identify duplicates due to the lack of exclusive values such as company_id

-- Creating new table called layoffs_staging2

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Checking whether ROW_NUMBER() will be working correctly before updating the newly created table 

SELECT ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage,  country, funds_raised_millions) 
FROM layoffs_staging;


-- Uploading the data

INSERT INTO layoffs_staging2
SELECT *,  ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage,  country, funds_raised_millions) 
FROM layoffs_staging;

-- Checking whether everything was uploaded correctly 

SELECT * 
FROM layoffs_staging2;

-- Checking repeated values [5 duplicate records found]

SELECT * 
FROM layoffs_staging2 
WHERE row_num > 1;

-- Deleting duplicate record from the table

DELETE FROM layoffs_staging2 
WHERE row_num > 1;

-- Checking whether duplicates were deleted correctly 

SELECT * 
FROM layoffs_staging2 
WHERE row_num > 1;  -- 0 records which means that they were deleted correctly 

-- STEP 2 Standarizing data 

-- Checking sections to find standarization issues such as dots, spaces etc. 

SELECT * FROM layoffs_staging2;

-- company 
SELECT DISTINCT company 
FROM layoffs_staging2 
ORDER BY 1; -- found space bars before couple of the company names 

-- Trimming this names 

SELECT DISTINCT LTRIM(company)
FROM layoffs_staging2; -- it works so we can update the table 

-- Updating the company table 

UPDATE layoffs_staging2
SET company = LTRIM(company)
WHERE company LIKE ' %'; -- 2 rows affect which means that it worked 

-- Making sure that update worked correctly 

SELECT DISTINCT company 
FROM layoffs_staging2 
ORDER BY 1;

-- location
SELECT DISTINCT location
FROM layoffs_staging2 
ORDER BY location ASC; -- no issues found 

SELECT DISTINCT industry
FROM layoffs_staging2 
ORDER BY industry ASC; -- Found issue in the industry column since we have stndarization issue related to the crypto industry, now I will be checking what it the exact issue and how to fix it 

-- Checking all of the crypto variants 

SELECT DISTINCT industry 
FROM layoffs_staging2 
WHERE industry 
LIKE 'Crypto%'; -- We have Crypto, CryptoCurrency and Crypto Currency so we can change all of them to "Crypto" since most of them have this industry naming 

-- Updating industry accordingly 

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry 
LIKE 'Crypto%';

-- Checking whether industry was updated correctly 

SELECT DISTINCT industry 
FROM layoffs_staging2 
WHERE industry 
LIKE 'Crypto%'; -- it returns only 'Crypto' industry now so we can tell that it was amended correctly 

-- Checking other sections and looking for a standarization issues

-- country
SELECT DISTINCT country 
FROM layoffs_staging2 
ORDER BY country ASC; -- Found issue in the country table due to the dot at the end of the United states country in one of the records 

-- Checking all of the country variants

SELECT DISTINCT country 
FROM layoffs_staging2
WHERE country LIKE 'United States%';

-- Updating country accordingly 

UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';

-- Checking whether United States was updated correctly

SELECT DISTINCT country 
FROM layoffs_staging2
WHERE country LIKE 'United States%'; -- it returns only 1 row which means that the issue was fixed 

-- date 
SELECT `date` 
FROM layoffs_staging2;

-- Checking data types 
DESCRIBE layoffs_staging2; -- date have text type 

-- We need to standarize the dates for the time series/visualizations purposes also we need to change date format to DATE 

-- Checking whether it will work before updating the date column

SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2; -- it works so now we can update the table accordingly

-- Updating date table accoridngly 

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y'); -- 2355 rows affected so it worked 

-- Checking whether date column was updated correctly

SELECT `date` 
FROM layoffs_staging2; -- it worked correctly

-- Now we can change data type to DATE

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Checking whether it worked

DESCRIBE layoffs_staging2; -- date is now type date so we can see that it worked correctly 

-- STEP 3 Find and remove NULL values and Blank values

-- We need to check which values can't be NULL or Blank, in this case data are related to layoffs so we can assume that in case total_laid_off column and percentage_laid_off column are empty then this data won't be usefull for us in the data analysis process 
SELECT * 
FROM layoffs_staging2
WHERE (total_laid_off IS NULL OR total_laid_off = '')
AND (percentage_laid_off IS NULL OR total_laid_off = '');

-- We can delete above NULL/Blank records

DELETE 
FROM layoffs_staging2
WHERE (total_laid_off IS NULL OR total_laid_off = '')
AND (percentage_laid_off IS NULL OR total_laid_off = ''); -- 361 rows affected so it worked

-- Double checking whether blank records were deleted correctly 

SELECT * 
FROM layoffs_staging2
WHERE (total_laid_off IS NULL OR total_laid_off = '')
AND (percentage_laid_off IS NULL OR total_laid_off = ''); -- 0 rows returns which means that they were deleted correctly 

-- We should populate missing data if possible so now we gonna go through the data to identify blanks that we can populate 

SELECT * FROM layoffs_staging2;

-- company
SELECT DISTINCT *, company
FROM layoffs_staging2
WHERE (company IS NULL OR company = ''); -- no nulls in the company column

-- location
SELECT DISTINCT *, location
FROM layoffs_staging2
WHERE (location IS NULL OR location = ''); -- no nulls in the location column

-- industry
SELECT DISTINCT *, industry
FROM layoffs_staging2
WHERE (industry IS NULL OR industry = ''); -- we have found empty industry fields in the 4 rows [AirBnb, Bally's Interactive, Carvana and Juul]

-- We gonna check whether we can update this fields accordingly

-- Juul
SELECT industry, company 
FROM layoffs_staging2 
WHERE company 
LIKE 'Juul%'; -- there are 2 records so we can take it from 2nd Juul record 

SELECT t1.industry, t2.industry, t1.company, t1.location
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
ON t1.company = t2.company
AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND (t2.industry IS NOT NULL or t2.industry != ''); -- checked whether we can take industry information from the 2nd row

-- updating the data accoridngly 

UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
ON t1.company = t2.company
AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND (t2.industry IS NOT NULL or t2.industry != '');

-- checking whether it worked

SELECT industry, company 
FROM layoffs_staging2 
WHERE company 
LIKE 'Juul%';

-- It doesn't worked so now we gonna change all of the blank values to NULLs as it should fix the problem 

-- Setting blanks as NULLS

UPDATE layoffs_staging2
SET industry = NULL 
WHERE industry = '';

-- Checking whether it worked 

SELECT industry, company 
FROM layoffs_staging2 
WHERE company 
LIKE 'Juul%'; -- it worked since empty industry became NULL 

-- Now trying to once more change industries but right now only basing on the NULL values 

UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
ON t1.company = t2.company
AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL; -- 3 rows changed so most probably it worked

-- Checking whether update was applied correctly

-- Juul
SELECT industry, company 
FROM layoffs_staging2 
WHERE company 
LIKE 'Juul%'; -- we can see that it worked 

-- Airbnb
SELECT industry, company 
FROM layoffs_staging2 
WHERE company 
LIKE 'AirBnB'; -- it worked 

-- Carvana
SELECT industry, company 
FROM layoffs_staging2 
WHERE company 
LIKE 'Carvana%'; -- it worked 

-- Bally's Interactive
SELECT industry, company 
FROM layoffs_staging2 
WHERE company 
LIKE 'Bally%'; -- there is only 1 record in the database, so we can gather it from the public domain serach 

-- Checking industries from the databased so I can pick the correct one based on the web check table

SELECT DISTINCT industry
FROM layoffs_staging2 
ORDER BY 1; -- OTHER category seems to be the most accurate since the company is involved in gambling, betting, and interactive entertainment and we don't have such a industy categories in our database 

-- Updating the data based on the public domain

UPDATE layoffs_staging2
SET industry = 'Other'
WHERE company
LIKE 'Bally%';

-- Chcecking whether it was updated correctly

SELECT DISTINCT industry
FROM layoffs_staging2
WHERE company
LIKE 'Bally%'
ORDER BY 1; -- it worked 

-- we can't populate total_laid_off, percentage_laid_off,date and funds_raised_millions columns so they will not be checked here 

-- stage
SELECT DISTINCT *, stage
FROM layoffs_staging2
WHERE (stage IS NULL OR stage = ''); -- we have found empty stage fields in the 5 rows [Advata, Gatherly, Relevel, Verily, Zapp]

-- Checking whether we can gather them from the other rows 

SELECT t1.stage, t2.stage, t1.company, t1.location
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
ON t1.company = t2.company
AND t1.location = t2.location
WHERE (t1.stage IS NULL OR t1.stage = '')
AND (t2.stage IS NOT NULL or t2.stage != ''); -- checked whether we can take stage information from the 2nd row and we it occured that we can't gather this informations so no further action taken here 

-- country
SELECT DISTINCT *, country
FROM layoffs_staging2
WHERE (country IS NULL OR country = ''); -- no nulls in the country column

-- STEP 4 Remove unnecessary rows and columns

-- Now we should check whether there are any row or columns that won't be useful anymore for example now we can delete our column row_num as it will not be useful anymore 

SELECT * FROM layoffs_staging2; -- checking what it the exact name of the column that we want to delete 

ALTER TABLE layoffs_staging2 
DROP COLUMN row_num; -- deleting row_num column as it will be not useful for us anymore 

-- Checking whether column was deleted correctly 

SELECT * FROM layoffs_staging2; -- we can see that row_num column was deleted correctly since funds_raised_millions column is the last one 

-- Raw data was cleaned so now I can perform Exploratory Data Analysis using cleaned data
