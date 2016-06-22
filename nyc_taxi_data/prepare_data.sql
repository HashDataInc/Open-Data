\timing on

-- This query calculates the pickup number
DROP TABLE IF EXISTS trips_by_lat_long_cab_type CASCADE;
CREATE TABLE trips_by_lat_long_cab_type WITH (appendonly=true, orientation=column) AS
SELECT
  cab_type_id,
  ROUND(pickup_longitude, 4) AS pickup_long,
  ROUND(pickup_latitude, 4) AS pickup_lat,
  COUNT(*) AS count
FROM trips
WHERE pickup_nyct2010_gid IS NOT NULL
  AND cab_type_id IN (1, 2)
GROUP BY cab_type_id, pickup_long, pickup_lat
ORDER BY cab_type_id, count
DISTRIBUTED RANDOMLY;

-- This query calculates the dropoff number
DROP TABLE IF EXISTS dropoff_by_lat_long_cab_type CASCADE;
CREATE TABLE dropoff_by_lat_long_cab_type WITH (appendonly=true, orientation=column) AS
SELECT
  cab_type_id,
  ROUND(dropoff_longitude, 4) AS dropoff_long,
  ROUND(dropoff_latitude, 4) AS dropoff_lat,
  COUNT(*) AS count
FROM trips
WHERE dropoff_nyct2010_gid IS NOT NULL
GROUP BY cab_type_id, dropoff_long, dropoff_lat
ORDER BY cab_type_id, count
DISTRIBUTED RANDOMLY;

-- This query calculates the hourly pickup number
DROP TABLE IF EXISTS hourly_pickups CASCADE;
CREATE TABLE hourly_pickups WITH (appendonly=true, orientation=column) AS
SELECT
  date_trunc('hour', pickup_datetime) AS pickup_hour,
  cab_type_id,
  pickup_nyct2010_gid,
  COUNT(*)
FROM trips
WHERE pickup_nyct2010_gid IS NOT NULL
GROUP BY pickup_hour, cab_type_id, pickup_nyct2010_gid
DISTRIBUTED RANDOMLY;

-- This query calculates the hourly dropoff number
DROP TABLE IF EXISTS hourly_dropoffs CASCADE;
CREATE TABLE hourly_dropoffs WITH (appendonly=true, orientation=column) AS
SELECT
  date_trunc('hour', dropoff_datetime) AS dropoff_hour,
  cab_type_id,
  dropoff_nyct2010_gid,
  COUNT(*)
FROM trips
WHERE dropoff_nyct2010_gid IS NOT NULL
  AND dropoff_datetime IS NOT NULL
  AND dropoff_datetime > '2008-12-31'
  AND dropoff_datetime < '2016-01-02'
GROUP BY dropoff_hour, cab_type_id, dropoff_nyct2010_gid
DISTRIBUTED RANDOMLY;

-- This query calculates the daily pickup number
DROP TABLE IF EXISTS daily_pickups_by_borough_and_type CASCADE;
CREATE TABLE daily_pickups_by_borough_and_type WITH (appendonly=true, orientation=column) AS
SELECT
  date(pickup_hour) AS date,
  boroname,
  cab_types.type,
  SUM(count) AS trips
FROM hourly_pickups, nyct2010, cab_types
WHERE hourly_pickups.pickup_nyct2010_gid = nyct2010.gid
  AND hourly_pickups.cab_type_id = cab_types.id
GROUP BY date, boroname, cab_types.type
DISTRIBUTED RANDOMLY;

CREATE TABLE daily_dropoffs_by_borough WITH (appendonly=true, orientation=column) AS
SELECT
  date(dropoff_hour) AS date,
  boroname,
  cab_types.type,
  SUM(count) AS trips
FROM hourly_dropoffs, nyct2010, cab_types
WHERE hourly_dropoffs.dropoff_nyct2010_gid = nyct2010.gid
  AND hourly_dropoffs.cab_type_id = cab_types.id
GROUP BY date, boroname, cab_types.type
ORDER BY date, boroname
DISTRIBUTED RANDOMLY;

-- For calculating the fastest growing census tracts
DROP TABLE IF EXISTS pickups_comparison CASCADE;
CREATE TABLE pickups_comparison WITH (appendonly=true, orientation=column) AS
SELECT
  pickup_nyct2010_gid,
  ntacode,
  cab_type_id,
  CASE WHEN pickup_hour >= '2009-01-01' AND pickup_hour < '2010-01-01' THEN 0 ELSE 1 END AS period,
  SUM(count) AS pickups
FROM hourly_pickups, nyct2010
WHERE pickup_nyct2010_gid = gid
  AND cab_type_id IN (1, 2)
  AND (   (pickup_hour >= '2009-01-01' AND pickup_hour < '2010-01-01')
       OR (pickup_hour >= '2015-01-01' AND pickup_hour < '2016-01-01'))
GROUP BY pickup_nyct2010_gid, ntacode, cab_type_id, period
ORDER BY pickup_nyct2010_gid, ntacode, cab_type_id, period
DISTRIBUTED RANDOMLY;

DROP VIEW IF EXISTS aggregates CASCADE;
CREATE VIEW aggregates AS (
  SELECT
    pickup_nyct2010_gid,
    period,
    SUM(pickups) AS total,
    SUM(CASE WHEN cab_type_id = 1 THEN pickups ELSE 0 END) AS yellow,
    SUM(CASE WHEN cab_type_id = 2 THEN pickups ELSE 0 END) AS green
  FROM pickups_comparison
  GROUP BY pickup_nyct2010_gid, period
);

DROP VIEW IF EXISTS wide_format CASCADE;
CREATE VIEW wide_format AS (
  SELECT
    pickup_nyct2010_gid,
    SUM(CASE WHEN period = 0 THEN total ELSE 0 END) AS total_0,
    SUM(CASE WHEN period = 1 THEN total ELSE 0 END) AS total_1,
    SUM(CASE WHEN period = 0 THEN yellow ELSE 0 END) AS yellow_0,
    SUM(CASE WHEN period = 1 THEN yellow ELSE 0 END) AS yellow_1,
    SUM(CASE WHEN period = 0 THEN green ELSE 0 END) AS green_0,
    SUM(CASE WHEN period = 1 THEN green ELSE 0 END) AS green_1
  FROM aggregates
  GROUP BY pickup_nyct2010_gid
);

DROP TABLE IF EXISTS census_tract_pickup_growth_2009_2015 CASCADE;
CREATE TABLE census_tract_pickup_growth_2009_2015 WITH (appendonly=true) AS
SELECT
  gid,
  boroname,
  ntaname,
  total_1,
  total_0,
  yellow_1,
  yellow_0,
  green_1,
  green_0
FROM wide_format, nyct2010
WHERE pickup_nyct2010_gid = gid
  AND (total_0 > 100000 OR total_1 > 100000)
DISTRIBUTED RANDOMLY;

-- Northside Williamsburg
DROP TABLE IF EXISTS northside_pickups CASCADE;
CREATE TABLE northside_pickups WITH (appendonly=true, orientation=column) AS
SELECT
  pickup_datetime, pickup_longitude, pickup_latitude, pickup_nyct2010_gid,
  date(date_trunc('month', pickup_datetime)) AS month
FROM trips
WHERE pickup_nyct2010_gid IN (1100, 275, 251, 1215, 267)
DISTRIBUTED RANDOMLY;

DROP VIEW IF EXISTS daily_trips CASCADE;
CREATE VIEW daily_pickups AS (
  SELECT
    date,
    SUM(CASE WHEN type IN ('yellow', 'green') THEN trips ELSE 0 END) AS taxi
  FROM daily_pickups_by_borough_and_type
  WHERE boroname != 'New Jersey'
  GROUP BY date
);


DROP TABLE IF EXISTS pickups_and_weather CASCADE;
CREATE TABLE pickups_and_weather WITH (appendonly=true, orientation=column) AS
SELECT
  d.*,
  w.precipitation,
  w.snow_depth,
  w.snowfall,
  w.max_temperature,
  w.min_temperature,
  w.average_wind_speed,
  EXTRACT(dow FROM d.date) AS dow,
  CASE WHEN EXTRACT(dow FROM d.date) BETWEEN 1 AND 5 THEN 'weekday' ELSE 'weekend' END AS dow_type,
  EXTRACT(year FROM d.date) AS year,
  EXTRACT(month FROM d.date) AS month,
  CASE
    WHEN EXTRACT(month FROM d.date) IN (12, 1, 2) THEN 'winter'
    WHEN EXTRACT(month FROM d.date) IN (3, 4, 5) THEN 'spring'
    WHEN EXTRACT(month FROM d.date) IN (6, 7, 8) THEN 'summer'
    WHEN EXTRACT(month FROM d.date) IN (9, 10, 11) THEN 'fall'
  END AS season
FROM
  daily_pickups d,
  central_park_weather_observations w
WHERE d.date = w.date
ORDER BY d.date
DISTRIBUTED RANDOMLY;

DROP TABLE IF EXISTS payment_types CASCADE;
CREATE TABLE payment_types WITH (appendonly=true, orientation=column) AS
SELECT
  date_trunc('month', pickup_datetime) AS month,
  FLOOR(total_amount / 10) * 10 AS total_amount_bucket,
  payment_type,
  COUNT(*) AS count
FROM trips
GROUP BY month, total_amount_bucket, payment_type
DISTRIBUTED RANDOMLY;

