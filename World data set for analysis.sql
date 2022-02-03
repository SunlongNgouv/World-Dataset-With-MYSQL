/* ========================
DATA ANALYSIS WITH MYSQL
+ Database: World.db
+ Prepared by Sunlong Ngouv
+ As of 01/28/2022
=========================== */

-- Initiate working database
USE world;

/* DATA WRANGLING */
update city
set name = 'A Coruña (La Coruña)'
where id = 670;

select * from city where district like '% Paulo' order by name;
update city
set district ='São Paulo'
where id in (326,	333,	328,	418,	420,	410,	305,	263,	438,	405,	388,	219,	251,	403,	355,	415,	257,	301,	357,	269,	381,	398,	411,	295,	217,	359,	358,	370,	385,	349,	276,	362,	396,	332,	267,	286,	315,	250,	256,	378,	228,	434,	380,	259,	454,	335,	318,	401,	237,	342,	433,	330,	230,	247,	225,	361,	316,	254,	234,	206,	270,	428,	238,	317,	313,	310,	439,	298,	446);

update city
set name ='Almoloya de Juárez', district = 'Mexico'
where id = 2654;

update city
set name = 'Béchar', district = 'Béchar'
where id = '49';

update country
set name = 'Réunion'
where code = 'REU';

-- find missing value and null
select count(*) from country where gnp = 0; 
select count(*) from country where gnpold is null; 
/* 	There were 4079 cities in this data set.
	There were 24 countries missing GNP information.
    There were 61 countries had null GNPOLD.
 */

/* DATA EXPLORATION */
-- ranking countries by GNP and GNPOLD
select rank() over (order by gnp desc) as gnp_rank, rank() over (order by gnpold desc) as gnp_old_rank, name, gnp, gnpold, lifeexpectancy from country order by gnp_rank;
/* 	Finding:
	- Top 10 GNP countries remained stable in ranking.
	- Despite able to maintain in the its ranking, Japan had suffered 9.67% drop, Brazil had 3.4% drop, and Canada had 4.28% drop.
*/

-- oldest life expectancy in the world
select co.name, co.continent, co.surfacearea, co.population, max(co.lifeexpectancy) as Max_lifeexpectancy, co.gnp, cl.language, cl.*, ci.*
from country as co
inner join countrylanguage as cl
on co.code = cl.countrycode
inner join city as ci
on cl.countrycode = ci.countrycode;
/* Finding:
	Aruba was the country with highest life expectancy at 83.5 years old. The country was an island with surface area at 193 mi2, and populations at 103,000.
Dutch was the official language spoken by 53% of local people. The capital was Oranjestad and had 29,034 people. */

-- find top life expectancy countries by continents, ranking by world's life expectancy
create view v_continent_rank as 
		select code, name, continent, region,  
			lifeexpectancy, rank() over (partition by continent order by lifeexpectancy desc) as life_con_rank, rank() over (order by lifeexpectancy desc) as life_rank, min(lifeexpectancy) over (partition by continent) as lowest_con_life,
			gnp, rank() over (partition by continent order by gnp desc) as gnp_con_rank, rank() over (order by gnp desc) as gnp_rank
		from country 
		order by continent, lifeexpectancy;

select * from v_continent_rank where lifeexpectancy is not null and life_con_rank =1 order by lifeexpectancy desc;
/* Finding:
The top life expectancy per continent: 
	1/ Andorra(Europe), 
    2/ Macao(Asia), 
    3/ Australia(Oceania), 
    4/ Canada(North America), 
    5/ Saint Helena(Africa), 
    6/ and French Guiana(South America). */

-- find top GNP countries by continents, ranking by world's GNP
select * from v_continent_rank where gnp >0 and gnp_con_rank =1 order by gnp desc;
/* 	Finding:
The top GNP countries per continent: 
	1/ USA(North America), 
    2/ Japan(Asia), 
    3/ Germany(Europe), 
    4/ Brazil(South America), 
    5/ Australia(Oceania), 
    6/ and South Africa(Africa).
What's special, Austalia has both high life expectancy and GNP. */

-- find top life expectancy countries limited by life expectancy over 80
select * from v_continent_rank where lifeexpectancy >80 order by lifeexpectancy desc;
/* 	Finding:
- Countries with high life expectancy above 80 years old were 1/Andorra, 2/Macao, 3/San Marino, 4/Japan, and 5/Singapore.
- Although the United State, Germany, France, and United Kingdom were ranked among top 5 GNP growth, they didn't have high life expectacy above 80. */ 

-- Lowest life expectancy countries below 45
select * from v_continent_rank where lifeexpectancy <=45 order by lifeexpectancy desc;
/* 	Finding:
There were 12 countries having lowest life expectancy below 45 which all locate in Africa continent. */

-- is there any high life expectancy amoung African countries?
select * from v_continent_rank where continent = 'africa' and lifeexpectancy >70 order by lifeexpectancy desc;
/*	Finding:
- There were 6 African countries with life expectancy above 70: Saint Helena, Libyan Arab Jamahiriya, Tunisia, Réunion, Mauritius, and Seychelles. 
- Saint Helena got the highest life expectancy with 76.8 compared to all African countries. */

-- find top 5 GNP countries in Africa
select * from v_continent_rank where continent = 'africa' order by gnp desc limit 5;
/*	Finding:
- Top 5 GNP countries in African were South Africa, Egypt, Nigeria, Algeria, and Libyan Arab Jamahiriya.
- Libyan Arab Jamahiriya was the most outstanding country in Africa for long life expectancy and high GNP growth. */

-- find lowest life expectancy by continents
select code, name, continent, region,  
	lifeexpectancy, rank() over (partition by continent order by lifeexpectancy desc) as life_con_rank, rank() over (order by lifeexpectancy desc) as life_rank, min(lifeexpectancy) over (partition by continent) as lowest_con_life,
	gnp, rank() over (partition by continent order by gnp desc) as gnp_con_rank, rank() over (order by gnp desc) as gnp_rank
from country
where lifeexpectancy is not null and gnp >0 
order by continent, lifeexpectancy;
/*	FindingL
Lowest life expectancy country by continents: 
	1/ Afghanistan(Asia)=45.9, 
	2/ Moldova(Europe)=64.5, 
    3/ Haiti(North American)=49.2, 
    4/ Zambia(Africa)=37.2, 
    5/ Kiribati(Oceania)=59.8, 
    6/ Brazil(South America)=62.9
*/

/* Reference */
-- search box by country name
delimiter $$
drop procedure if exists countrysearch;
create procedure countrysearch (in countryname varchar(200))
	begin
		select co.*, ci.*, cl.* from country as co
        inner join city as ci
        on co.code = ci.countrycode 
        inner join countrylanguage as cl
        on ci.countrycode = cl.countrycode
        where co.name = countryname;
	end $$
delimiter ;
call countrysearch ('United States');

-- show tables
select * from city;
select * from country;
select * from countrylanguage;
select co.*, ci.*, cl.* from country as co
        inner join city as ci
        on co.code = ci.countrycode 
        inner join countrylanguage as cl
        on ci.countrycode = cl.countrycode
        where co.name = countryname;