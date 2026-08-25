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

--2.Dynamic Market Share & Regional Faculty Ranking and find top faculty in their region with calculate market share--
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
