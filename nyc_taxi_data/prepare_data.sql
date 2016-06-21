-- This query calculates the pickup number

CREATE TABLE trips_by_lat_long_cab_type (appendonly=true, orientation=column) AS
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

CREATE TABLE dropoff_by_lat_long_cab_type (appendonly=true, orientation=column) AS
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

-- 
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
