-- International trends analysis

-- View table
select * 
from dim_countries as a
inner join fact_student_enrollments as b
on a.country_id = b.country_id
inner join dim_faculties as c
on b.faculty_id = c.faculty_id

--1.Analyze Yoy growth & Market momentum --
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
