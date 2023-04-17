1.
/*Q1*/
SELECT 
	country_name, 
    year, 
    forest_area_sqkm
FROM
	forest_area
WHERE
	year = 1990 AND 
    country_name = 'World'
GROUP BY 
	1, 2, 3;
/*Q2*/
SELECT 
	country_name, 
    year, 
    forest_area_sqkm
FROM
	forest_area
WHERE
	year = 2016 AND 
    country_name = 'World'
GROUP BY 
	1, 2, 3;

/*Q3*/
SELECT DISTINCT
	(SELECT
     	forest_area_sqkm
     FROM
     	forest_area
     WHERE
     	year = 1990 AND
     	country_name = 'World'
     ) - (SELECT
     	forest_area_sqkm
     FROM
     	forest_area
     WHERE
     	year = 2016 AND
     	country_name = 'World'
     ) AS area_change
FROM 
	forest_area

/*Q4*/

SELECT DISTINCT
	((SELECT
     	forest_area_sqkm
     FROM
     	forest_area
     WHERE
     	year = 1990 AND
     	country_name = 'World'
     ) - (SELECT
     	forest_area_sqkm
     FROM
     	forest_area
     WHERE
     	year = 2016 AND
     	country_name = 'World'
     )) * 100 / (SELECT
     	forest_area_sqkm
     FROM
     	forest_area
     WHERE
     	year = 1990 AND
     	country_name = 'World'
     )
     AS percent_area_change
FROM 
	forest_area

/*Q5*/

SELECT 
	(SELECT
     	forest_area_sqkm
     FROM
     	forest_area
     WHERE
     	year = 1990 AND
     	country_name = 'World'
     ) - (SELECT
     	forest_area_sqkm
     FROM
     	forest_area
     WHERE
     	year = 2016 AND
     	country_name = 'World'
     )
     AS area_change, l.country_name, (l.total_area_sq_mi *2.58) AS land_area_in_km
FROM 
	forest_area AS f
JOIN land_area AS l
ON f.country_code = l.country_code AND 
l.year = 2016
WHERE (l.total_area_sq_mi * 2.58) <= (SELECT
     	forest_area_sqkm
     FROM
     	forest_area
     WHERE
     	year = 1990 AND
     	country_name = 'World'
     ) - (SELECT
     	forest_area_sqkm
     FROM
     	forest_area
     WHERE
     	year = 2016 AND
     	country_name = 'World'
     )
ORDER BY l.total_area_sq_mi DESC;

/*2.*/

CREATE TABLE per_fa AS (
SELECT
    	r.region,
  		SUM(CASE WHEN f.year = 1990 THEN forest_area_sqkm ELSE 0 END) /
  		(SUM(CASE WHEN f.year = 1990 THEN total_area_sq_mi ELSE 0 END) *2.59)
  		AS per_area_1990,
  		SUM(CASE WHEN f.year = 2016 THEN forest_area_sqkm ELSE 0 END) /
  		(SUM(CASE WHEN f.year = 2016 THEN total_area_sq_mi ELSE 0 END) * 2.59)
  		AS per_area_2016
    FROM
    	forest_area AS f
        JOIN land_area AS l
        ON f.country_code=l.country_code
        AND (f.year = 1990 OR f.year = 2016)
        JOIN regions AS r
        ON r.country_code=l.country_code
    GROUP BY 1

)

/*2a*/

SELECT region, ROUND((per_area_2016*100)::numeric, 2)
FROM per_fa
ORDER BY 2 DESC;

/*2b*/

SELECT region, ROUND((per_area_1990*100)::numeric, 2)
FROM per_fa
ORDER BY 2 DESC;

/*2c*/

ALTER TABLE per_fa ADD COLUMN per_change numeric;

UPDATE per_fa SET per_change = ((per_area_1990 - per_area_2016)/per_area_1990)*100;

SELECT region,
ROUND((per_area_1990*100)::numeric, 2) AS A1990,
ROUND((per_area_2016*100)::numeric, 2) AS A2016,
ROUND((per_change)::numeric, 2) AS TOTALCHANGE
FROM per_fa
ORDER BY per_change DESC;

/* 3 a*/

CREATE TABLE fa_change AS (
SELECT DISTINCT
  t1.country_name,
  r.region,
  t1.forest_area_sqkm AS fa_1990,
  t2.forest_area_sqkm AS fa_2016,
  (t1.forest_area_sqkm - t2.forest_area_sqkm) AS A_change,
  (((t1.forest_area_sqkm - t2.forest_area_sqkm) / t1.forest_area_sqkm) * 100) AS pct_change
FROM
  (SELECT * FROM forest_area WHERE year = 1990) AS t1
FULL JOIN
  (SELECT * FROM forest_area WHERE year = 2016) AS t2
  ON
  t1.country_name = t2.country_name
JOIN regions AS r
  ON r.country_code = t2.country_code
ORDER BY 1, 2
)

/* 3b */

SELECT country_name, region, ROUND(pct_change::numeric,2)
FROM fa_change
ORDER BY pct_change DESC

/* 3.1 */

SELECT country_name, region,
ROUND(a_change::numeric,2) AS area_change,
ROUND(pct_change::numeric,2) AS per_cha
FROM fa_change
ORDER BY a_change DESC

/* 3.2 */

SELECT country_name, region,
ROUND(a_change::numeric,2) AS area_change,
ROUND(pct_change::numeric,2) AS per_cha
FROM fa_change
ORDER BY pct_change DESC

/* 3.3 */

SELECT quartile, COUNT(fa_2016)
FROM (
  SELECT DISTINCT
    NTILE(4) OVER (ORDER BY pct_change) AS quartile,
    fa_2016
  FROM
    fa_change
) AS t
GROUP BY quartile
ORDER BY quartile;

/* 3.4 */

SELECT country_name,
region,
quartile,
pc_cha
FROM (
  SELECT DISTINCT
  	country_name,
  region,
    NTILE(4) OVER (ORDER BY pct_change) AS quartile,
  ROUND((((fa_1990 - fa_2016)/fa_1990)*100) :: numeric,2) AS pc_cha
  FROM
    fa_change
) AS t
GROUP BY country_name, region, quartile, pc_cha
ORDER BY quartile;