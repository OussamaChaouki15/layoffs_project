-- Preparation (Create Tables and Insert Data)

-- Create a working table similar to 'layoffs'
CREATE TABLE layoffs_work LIKE layoffs;

-- Copy data from 'layoffs' to 'layoffs_work'
INSERT INTO layoffs_work
SELECT * FROM layoffs;

-- Data Cleaning (Duplicate Removal, Standardizing Entries)

-- Identify duplicate entries
SELECT *
FROM (
    SELECT 
        company, location, industry, total_laid_off, percentage_laid_off, `date`, 
        stage, country, funds_raised_millions,
        ROW_NUMBER() OVER (
            PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,
            `date`, stage, country, funds_raised_millions
        ) AS row_num
    FROM layoffs_work
) duplicates
WHERE row_num > 1;

-- Delete duplicates (keep the first instance)
DELETE FROM layoffs_work
WHERE row_num > 1;

-- Create a secondary table to store duplicates if needed
CREATE TABLE layoffs_work2 (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off INT DEFAULT NULL,
    percentage_laid_off TEXT,
    date TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions INT DEFAULT NULL,
    row_num INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Data Transformation: Cleaning and Standardizing Data
-- Trim spaces in the 'company' column
UPDATE layoffs_work
SET company = TRIM(company);

-- Standardize industry values
UPDATE layoffs_work
SET industry = 'crypto'
WHERE industry LIKE 'crypto%';

-- Standardize country names
UPDATE layoffs_work
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United states%';

-- Convert `date` column to a DATE format
UPDATE layoffs_work
SET `date` = STR_TO_DATE(`date`, '%Y-%m-%d');

ALTER TABLE layoffs_work
MODIFY COLUMN `date` DATE;

-- 3. Analysis Queries: Insights and Aggregations

-- Check for null values in 'total_laid_off' and 'percentage_laid_off'
SELECT *
FROM layoffs_work
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- Maximum and minimum layoffs percentage
SELECT MAX(total_laid_off) FROM layoffs_work;
SELECT MAX(percentage_laid_off), MIN(percentage_laid_off)
FROM layoffs_work
WHERE percentage_laid_off IS NOT NULL;

-- Top 5 companies by total layoffs
SELECT company, total_laid_off
FROM layoffs_work
ORDER BY total_laid_off DESC
LIMIT 5;

-- Total layoffs by location
SELECT location, SUM(total_laid_off) AS total_location
FROM layoffs_work
GROUP BY location
ORDER BY total_location DESC
LIMIT 10;

-- Total layoffs by industry
SELECT industry, SUM(total_laid_off) AS total_industry
FROM layoffs_work
GROUP BY industry
ORDER BY total_industry DESC;

-- Layoffs by country
SELECT country, SUM(total_laid_off) AS total_country
FROM layoffs_work
GROUP BY country
ORDER BY total_country DESC;

-- Layoffs by year
SELECT YEAR(date) AS year, SUM(total_laid_off) AS total_year
FROM layoffs_work
GROUP BY year
ORDER BY year ASC;

-- Top companies by layoffs each year (top 3)
WITH Company_Year AS (
    SELECT 
        company, YEAR(date) AS year, 
        SUM(total_laid_off) AS total_laid_off
    FROM layoffs_work
    GROUP BY company, YEAR(date)
), Company_Year_Rank AS (
    SELECT 
        company, year, total_laid_off,
        DENSE_RANK() OVER (PARTITION BY year ORDER BY total_laid_off DESC) AS ranking
    FROM Company_Year
)
SELECT company, year, total_laid_off, ranking
FROM Company_Year_Rank
WHERE ranking <= 3
ORDER BY year ASC, total_laid_off DESC;

-- Rolling layoffs total by month
     SELECT 
        SUBSTRING(date, 1, 7) AS month, 
        SUM(total_laid_off) AS total_off
    FROM layoffs_work 
    GROUP BY month
    ORDER BY month ASC
)
SELECT 
    month, 
    total_off,
    SUM(total_off) OVER (ORDER BY month) AS rolling_total
FROM rolling_total;

SELECT *
FROM layoffs;



