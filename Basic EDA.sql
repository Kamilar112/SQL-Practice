-- This section is mostly exploring the data and answering potential questions


-- Let's first look at the different industries in relation to layoffs
select industry, avg(percentage_laid_off) , max(percentage_laid_off), min(percentage_laid_off)
from layoffs_stage2
group by industry
order by 2;

-- Here we look at the average/maximum/minimum layoffs across industries
-- We see a lot of 1 in the max column so let's see which companies had to let go all of their employees

select * from layoffs_stage2 where percentage_laid_off=1
order by funds_raised_millions desc;

-- We see the biggest company that went bust was Britishvolt


-- Let's now look at the companies with the highest layoffs

select company, sum(total_laid_off) from layoffs_stage2
group by company
order by 2 desc;

-- For each company let's add the locations with the least and most layoffs

select company, min(total_laid_off), max(total_laid_off) from layoffs_stage2
group by company
having min(total_laid_off) is not null and max(total_laid_off) is not null
order by 2;

-- If the min and max are the same it means the company had 1 single layoff so the location is unique anyways
-- Let's drop these companies

select company, min(total_laid_off), max(total_laid_off) from layoffs_stage2
group by company
having min(total_laid_off) is not null 
and max(total_laid_off) is not null
and min(total_laid_off)<>max(total_laid_off);
order by 2;

-- Now we'll join this to the original table and find the best/worst locations for layoffs

with t1 
as(select company, min(total_laid_off) as minimum, max(total_laid_off) as maximum from layoffs_stage2
group by company
having min(total_laid_off) is not null 
and max(total_laid_off) is not null
and min(total_laid_off)<>max(total_laid_off))
select copy1.company,copy1.location as least_layoffs, t1.minimum,copy2.location as most_layoffs, t1.maximum
from t1 join layoffs_stage2 copy1 
on t1.company=copy1.company
join layoffs_stage2 copy2 
on t1.company=copy2.company
where copy1.total_laid_off=t1.minimum
and copy2.total_laid_off=t1.maximum;

-- Next let's look at the companies with the most layoffs per year

select company, year(`date`), sum(total_laid_off)
from layoffs_stage2
group by company, year(`date`)
order by company asc;

-- Let's rank them by the highest layoffs per year

with company_year (company,`year`, total_laid_off) as
(select company, year(`date`), sum(total_laid_off)
from layoffs_stage2
group by company, year(`date`)
)
select *, dense_rank() over (partition by `year` order by total_laid_off desc) as ranking
from company_year
where `year` is not null
order by ranking asc;


-- This table starts in 2020 so let's say we're asked for the month where the total layoffs since 2020 exceeded 50000 in the United States

-- We're going to do a rolling total of the layoffs month to month and query off that

select substring(`date`,1,7) as `month`, sum(total_laid_off) as total
from (select * from layoffs_stage2 
		where country = 'United States') as states
where substring(`date`,1,7) is not null
group by `month`
order by `month` asc;

-- That is what we will use as our CTE

with rolling_total as
(select substring(`date`,1,7) as `month`, sum(total_laid_off) as total
from (select * from layoffs_stage2 
		where country = 'United States') as states
where substring(`date`,1,7) is not null
group by `month`
order by `month` asc
)
select `month`, sum(total) over(order by `month`) as rolling_layoffs
from rolling_total;

-- Lastly we 

select `month`, rolling_layoffs from
(with rolling_total as
(select substring(`date`,1,7) as `month`, sum(total_laid_off) as total
from (select * from layoffs_stage2 
		where country = 'United States') as states
where substring(`date`,1,7) is not null
group by `month`
order by `month` asc
)
select `month`, sum(total) over(order by `month`) as rolling_layoffs
from rolling_total
)as temp2 where rolling_layoffs >=50000
limit 1;



 





