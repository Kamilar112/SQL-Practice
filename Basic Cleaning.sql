/* Basic SQL Data Cleaning
https://www.kaggle.com/datasets/swaptr/layoffs-2022 */


-- The table is small so we will first create a copy to work on

create table layoffs_stage1 
like layoffs;

insert layoffs_stage1 
select * from world_layoffs;

-- We first look for any duplicate rows
-- There's no primary key so we will number the rows with ROW_NUMBER()

select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_stage1;

-- We have partitioned by every column, now any duplicates should have row_num > 1

-- We'll now copy the table again, have row_num as a permanent column and simply delete any rows where row_num > 1

CREATE TABLE `layoffs_stage2` (
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

insert into layoffs_stage2
select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_stage1;

delete from layoffs_stage2
where row_num > 1;

-- There's some spaces in the company column so we trim it quickly

select company, TRIM(company)
from layoffs_stage2;

update layoffs_stage2
set company = TRIM(company), location = TRIM(location),
industry = TRIM(industry), stage = TRIM(stage), country = TRIM(country);

select distinct industry
from layoffs_stage2
order by 1;

-- There seem to be two "Crypto" like industries so let's fix that next

update layoffs_stage2
set industry = 'Crypto'
where industry like 'Crypto%';

select distinct location
from layoffs_stage2
order by location;

-- This column looks ok with the exception of "Malmo" and "Malma" with a funny accent on the "a"
-- A google search shows this to be a city in Sweden 

select *
from layoffs_stage2
where location like 'Malm%';

-- As we can see it all checks out, all we want to do is change the funny accent

update layoffs_stage2
set location = 'Malmo'
where location like 'Malm%';

-- We now continue checking the same for a few other columns

select distinct industry
from layoffs_stage2
order by industry;

select distinct country
from layoffs_stage2
order by country;

-- There seem to be two versions of the "United States" so it's just an easy trim

update layoffs_stage2
set country = TRIM(trailing '.' from country)
where country like 'United States%';

-- We now change the date column into the correct format

update layoffs_stage2
set `date` = str_to_date(`date`,'%m/%d/%Y');

alter table layoffs_stage2
modify column `date` DATE;

-- We noticed some blanks in the industry column so let's see if we can populate that using the other columns

select *
from layoffs_stage2
order by industry;

-- Maybe some companies had multiple layoffs, if the company/location columns agree there's a good chance the industry is the same
-- Let's first fill in any blanks with NULL

update layoffs_stage2
set industry = null
where industry = '';

select *
from layoffs_stage1 l1
join layoffs_stage2 l2
on l1.company = l2.company
where l1.industry is null
and l2.industry is not null;

-- Now to update the table

update layoffs_stage2 l1
join layoffs_stage2 l2
on l1.company = l2.company
set l1.industry = l2.industry
where l1.industry is null
and l2.industry is not null;

-- We can also drop the row_num column now

alter table layoffs_stage2
drop column row_num;

