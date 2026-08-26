-- International trends analysis

-- View table
select * 
from dim_countries as a
inner join fact_student_enrollments as b
on a.country_id = b.country_id
inner join dim_faculties as c
on b.faculty_id = c.faculty_id

--1.Analyze Yoy growth & Market momentum --
--key analytical insight
--Prevents blanket marketing spend by evaluating continuous annual growth. Enables precision budget allocation toward High-Growth Target Markets.	
with yearly_sale as (
select 
a.country_id,
a.country_name,
b.year,
sum(b.student_count) as current_year_student,
lag(sum(b.student_count),1) over(partition by country_id 
order by year asc) as previous_year_student
from dim_countries as a
inner join fact_student_enrollments as b
on a.country_id = b.country_id
group by a.country_id,a.country_name, b.year
)

select
country_name,
year,
current_year_student,
previous_year_student,
round((current_year_student - previous_year_student)/ nullif(previous_year_student, 0) * 100,2 )as Yoy_growth_rate
from yearly_sale 
order by country_name asc,
		 year asc
	
--2.Dynamic Market Share & Regional Faculty Ranking and find top faculty in their region with calculate market share--
--key analytical insight--
--Eliminates one-size-fits-all academic offerings. 
--Identifies top-ranked faculties and market share (%) by region (e.g., Southeast Asia vs. East Asia) to tailor scholarships and programs effectively.	
with top_region as (
select 
a.region,
c.faculty_name,
sum(b.student_count) as top_student,
dense_rank() over(partition by a.region order by sum(b.student_count) desc) as faculty_rank
from dim_countries as a
inner join fact_student_enrollments as b
on a.country_id = b.country_id
inner join dim_faculties as c
on b.faculty_id = c.faculty_id
where b.year = 2025
group by a.region ,
		 c.faculty_name 
)

select
region,
faculty_name,
top_student,
faculty_rank
from top_region
where faculty_rank <= 3
order by region asc,
         faculty_rank asc;

--3 - Market Concentration & Risk Diversification Analysis--
--key analytical insight--
--Mitigates revenue risk caused by single-country student dependency (>40% threshold). Drives targeted student diversification and fosters campus internationalization.
with country_faculty_summary as (
select
c.faculty_name,
c.faculty_id,
a.country_name ,
sum(b.student_count) as country_students,
dense_rank() over(partition by c.faculty_id order by sum(b.student_count) desc) as country_rank,
sum(sum(b.student_count)) over(partition by c.faculty_id) as faculty_total_students
from dim_countries as a
inner join fact_student_enrollments as b
on a.country_id = b.country_id
inner join dim_faculties as c
on b.faculty_id = c.faculty_id
where year = 2025
group by c.faculty_id,
		 c.faculty_name, 
		 a.country_id, 
         a.country_name
)

select
faculty_name,
country_name,
country_students,
faculty_total_students,
round(sum(country_students / faculty_total_students * 100),2) as concentration_pct, 
'High_Concentration_risk' as Risk_status
from country_faculty_summary
where country_rank = 1 and
(country_students * 100) / faculty_total_students  > 40
group by faculty_name, country_name
order by concentration_pct desc; 


--4.moving average & time specification--
--key analytical insight
--Smooths out short-term fluctuations for accurate enrollment forecasting. Optimizes resource allocation across faculty headcount, housing, and facilities.	
select
a.faculty_name,
b.year,
avg(sum(b.student_count)) over(partition by a.faculty_id 
order by b.year asc 
Rows between 2 preceding and current row) as moving_avg_3yr 
from dim_faculties as a
inner join fact_student_enrollments as b
on a.faculty_id = b.faculty_id
where faculty_name = 'Engineering'
group by a.faculty_name, b.year
order by b.year asc
	
--5.Executive cross-tabulation & data pivoting--
--key analytical insight
--Transforms complex multi-dimensional data into an Executive Matrix View. Categorizes countries into Strategic Tiers (Tier A, B, C) for instant high-level decision-making.
with pivot_data as (
select
a.country_name,
sum(case when c.faculty_name = 'Engineering' then b.student_count else 0 end) as engineering_student,
sum(case when c.faculty_name = 'Business and administration' then b.student_count else 0 end) as business_student,
sum(case when c.faculty_name = 'Information and communication technologies' then b.student_count else 0 end) as ict_student,
sum(b.student_count) as total_student
from dim_countries as a
inner join fact_student_enrollments as b
on a.country_id = b.country_id
inner join dim_faculties as c
on b.faculty_id = c.faculty_id
where b.year = 2025
group by a.country_name
)

select
country_name,
engineering_student,
business_student,
ict_student,
total_student,
case 
when total_student > 1000 then 'Tier A'
when total_student >= 300 then 'Tier B'
else 'Tier C'	
end as market_tier
from pivot_data
order by total_student desc
