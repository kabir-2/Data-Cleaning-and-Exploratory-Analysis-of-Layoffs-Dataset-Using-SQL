-- Data Cleaning

SELECT * 
FROM layoffs;

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values or blank values
-- 4. Remove any columns


-- Create Staging Table

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT * 
FROM layoffs_staging;

INSERT layoffs_staging
SELECT * 
FROM layoffs;

-- Remove Duplicates

-- Find Duplicates by adding row_num
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Select duplicates
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

-- Verify a duplicate value
SELECT * 
FROM layoffs_staging
WHERE company = 'Yahoo';

-- Create another staging table to delete duplicate values in 
CREATE TABLE `layoffs_staging_2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging_2;

INSERT layoffs_staging_2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Delete the duplicate values
DELETE
FROM layoffs_staging_2 
WHERE row_num > 1;

-- Standardizing data

-- Remove extra spaces from the company column
SELECT company, TRIM(company)
FROM layoffs_staging_2;

UPDATE layoffs_staging_2
SET company = TRIM(company);

-- Standardize the industry column
SELECT DISTINCT industry
FROM layoffs_staging_2
ORDER BY industry;

-- Fixing Crypto industry error
SELECT * 
FROM layoffs_staging_2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging_2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Standardize the country column
SELECT DISTINCT country
FROM layoffs_staging_2
ORDER BY 1;

-- Fix Trailing . in United States
SELECT *
FROM layoffs_staging_2
WHERE country LIKE 'United States%';

UPDATE layoffs_staging_2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Converting the date format
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging_2;

UPDATE layoffs_staging_2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Modifying the date data type from text to date in the staging table
ALTER TABLE layoffs_staging_2
MODIFY COLUMN `date` DATE;

-- Null values or blanks

-- Search for null or blanks in industry
SELECT * 
FROM layoffs_staging_2
WHERE industry IS NULL
OR industry = '';

-- Update blanks to null
UPDATE layoffs_staging_2
SET industry = NULL
WHERE industry = '';

-- Check if a company did multiple laid offs
SELECT *
FROM layoffs_staging_2
WHERE company = 'Airbnb';

-- Find companies with multiple laid offs which don't have industry as Null
SELECT *
FROM layoffs_staging_2 t1
JOIN layoffs_staging_2 t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Update industry null values with appropriate values
UPDATE layoffs_staging_2 t1
JOIN layoffs_staging_2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Bally's Interactive only did a single laid off(It's industry value cannot be fixed)
SELECT *
FROM layoffs_staging_2
WHERE company LIKE 'Bally%';

-- Remove any useless rows and columns

SELECT * 
FROM layoffs_staging_2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

DELETE FROM layoffs_staging_2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

ALTER TABLE layoffs_staging_2
DROP COLUMN row_num;

SELECT * 
FROM layoffs_staging_2;
