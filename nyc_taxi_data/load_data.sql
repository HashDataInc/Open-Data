CREATE TABLE trips (
	cab_type_id INT,
	vendor_id VARCHAR(16),
	pickup_datetime TIMESTAMP WITHOUT TIME ZONE,
	dropoff_datetime TIMESTAMP WITHOUT TIME ZONE,
	store_and_fwd_flag CHAR,
	rate_code_id INT,
	pickup_longitude NUMERIC,
	pickup_latitude NUMERIC,
	dropoff_longitude NUMERIC,
	dropoff_latitude NUMERIC,
	passenger_count INT,
	trip_distance NUMERIC,
	fare_amount NUMERIC,
	extra NUMERIC,
	mta_tax NUMERIC,
	tip_amount NUMERIC,
	tolls_amount NUMERIC,
	ehail_fee NUMERIC,
	improvement_surcharge NUMERIC,
	total_amount NUMERIC,
	payment_type VARCHAR(12),
	trip_type INT,
	pickup_nyct2010_gid INT,
	dropoff_nyct2010_gid INT
) 
WITH (appendonly=true, orientation=column)
DISTRIBUTED RANDOMLY;

CREATE READABLE EXTERNAL TABLE e_green_trips_2013 (LIKE trips)
LOCATION('qs://pek3a.qingstor.com/hashdata-public/open_data/nyc_taxi_data/green_trips_2013') FORMAT 'CSV';

INSERT INTO trips SELECT * FROM e_green_trips_2013;

CREATE READABLE EXTERNAL TABLE e_green_trips_2014 (LIKE trips)
LOCATION('qs://pek3a.qingstor.com/hashdata-public/open_data/nyc_taxi_data/green_trips_2014') FORMAT 'CSV';

INSERT INTO trips SELECT * FROM e_green_trips_2014;

CREATE READABLE EXTERNAL TABLE e_green_trips_2015 (LIKE trips)
LOCATION('qs://pek3a.qingstor.com/hashdata-public/open_data/nyc_taxi_data/green_trips_2015') FORMAT 'CSV';

INSERT INTO trips SELECT * FROM e_green_trips_2015;

CREATE READABLE EXTERNAL TABLE e_yellow_trips_2009 (LIKE trips)
LOCATION ('qs://pek3a.qingstor.com/hashdata-public/open_data/nyc_taxi_data/yellow_trips_2009') FORMAT 'CSV';

INSERT INTO trips SELECT * FROM e_yellow_trips_2009;

CREATE READABLE EXTERNAL TABLE e_yellow_trips_2010 (LIKE trips)
LOCATION ('qs://pek3a.qingstor.com/hashdata-public/open_data/nyc_taxi_data/yellow_trips_2010') FORMAT 'CSV';

INSERT INTO trips SELECT * FROM e_yellow_trips_2010;

CREATE READABLE EXTERNAL TABLE e_yellow_trips_2011 (LIKE trips)
LOCATION ('qs://pek3a.qingstor.com/hashdata-public/open_data/nyc_taxi_data/yellow_trips_2011') FORMAT 'CSV';

INSERT INTO trips SELECT * FROM e_yellow_trips_2011;

CREATE READABLE EXTERNAL TABLE e_yellow_trips_2012 (LIKE trips)
LOCATION ('qs://pek3a.qingstor.com/hashdata-public/open_data/nyc_taxi_data/yellow_trips_2012') FORMAT 'CSV';

INSERT INTO trips SELECT * FROM e_yellow_trips_2012;

CREATE READABLE EXTERNAL TABLE e_yellow_trips_2013 (LIKE trips)
LOCATION ('qs://pek3a.qingstor.com/hashdata-public/open_data/nyc_taxi_data/yellow_trips_2013') FORMAT 'CSV';

INSERT INTO trips SELECT * FROM e_yellow_trips_2013;

CREATE READABLE EXTERNAL TABLE e_yellow_trips_2014 (LIKE trips)
LOCATION ('qs://pek3a.qingstor.com/hashdata-public/open_data/nyc_taxi_data/yellow_trips_2014') FORMAT 'CSV';

INSERT INTO trips SELECT * FROM e_yellow_trips_2014;

CREATE READABLE EXTERNAL TABLE e_yellow_trips_2015 (LIKE trips)
LOCATION ('qs://pek3a.qingstor.com/hashdata-public/open_data/nyc_taxi_data/yellow_trips_2015') FORMAT 'CSV';

INSERT INTO trips SELECT * FROM e_yellow_trips_2015;

CREATE TABLE cab_types (
	id INT,
	type VARCHAR(10)
)
DISTRIBUTED BY (id);

CREATE READABLE EXTERNAL TABLE e_cab_types (LIKE cab_types)
LOCATION ('qs://pek3a.qingstor.com/hashdata-public/open_data/nyc_taxi_data/cab_types')
FORMAT 'CSV';

INSERT INTO cab_types SELECT * FROM e_cab_types;

CREATE TABLE central_park_weather_observations (
	date DATE,
	precipitation NUMERIC,
	snow_depth NUMERIC,
	snowfall NUMERIC,
	max_temperature NUMERIC,
	min_temperature NUMERIC,
	average_wind_speed NUMERIC
)
WITH (appendonly=true, orientation=column)
DISTRIBUTED RANDOMLY;

CREATE READABLE EXTERNAL TABLE e_central_park_weather_observations (LIKE central_park_weather_observations)
LOCATION('qs://pek3a.qingstor.com/hashdata-public/open_data/nyc_taxi_data/central_park_weather_observations') FORMAT 'CSV';

INSERT INTO central_park_weather_observations SELECT * FROM e_central_park_weather_observations;

CREATE TABLE nyct2010 (
	gid INT,
	ctlabel VARCHAR(7),
	borocode VARCHAR(1),
	boroname VARCHAR(32),
	ct2010 VARCHAR(6),
	boroct2010 VARCHAR(7),
	cdeligibil VARCHAR(1),
	ntacode VARCHAR(4),
	ntaname VARCHAR(75),
	puma VARCHAR(4),
	shape_leng NUMERIC,
	shape_area NUMERIC
)
WITH (appendonly=true, orientation=column)
DISTRIBUTED RANDOMLY;

CREATE READABLE EXTERNAL TABLE e_nyct2010 (LIKE nyct2010)
LOCATION ('qs://pek3a.qingstor.com/hashdata-public/open_data/nyc_taxi_data/nyct2010')
FORMAT 'CSV';

INSERT INTO nyct2010 SELECT * FROM e_nyct2010;
CREATE TABLE nyct2010_centroids (
	gid INT,
	long DOUBLE PRECISION,
	lat DOUBLE PRECISION 
)
WITH (appendonly=true, orientation=column)
DISTRIBUTED RANDOMLY;

CREATE READABLE EXTERNAL TABLE e_nyct2010_centroids (LIKE nyct2010_centroids)
LOCATION('qs://pek3a.qingstor.com/hashdata-public/open_data/nyc_taxi_data/centroids_nyct2010') FORMAT 'CSV';

INSERT INTO nyct2010_centroids SELECT * FROM e_nyct2010_centroids;
CREATE TABLE uber_taxi_zone_lookups (
	location_id INT,
	borough VARCHAR,
	zone VARCHAR,
	nyct2010_ntacode VARCHAR
)
WITH (appendonly=true, orientation=row)
DISTRIBUTED RANDOMLY;

CREATE READABLE EXTERNAL TABLE e_uber_taxi_zone_lookups (LIKE uber_taxi_zone_lookups)
LOCATION('qs://pek3a.qingstor.com/hashdata-public/open_data/nyc_taxi_data/uber_taxi_zone_lookups') FORMAT 'CSV';

INSERT INTO uber_taxi_zone_lookups SELECT * FROM e_uber_taxi_zone_lookups;
CREATE TABLE uber_trips_2014 (
	cab_type_id INT,
	vendor_id VARCHAR(16),
	pickup_datetime TIMESTAMP WITHOUT TIME ZONE,
	pickup_longitude NUMERIC,
	pickup_latitude NUMERIC,
	pickup_nyct2010_gid INT
)
WITH (appendonly=true, orientation=column)
DISTRIBUTED RANDOMLY;

CREATE READABLE EXTERNAL TABLE e_uber_trips_2014 (LIKE uber_trips_2014)
LOCATION('qs://pek3a.qingstor.com/hashdata-public/open_data/nyc_taxi_data/uber_trips_2014/') FORMAT 'CSV';

INSERT INTO uber_trips_2014 SELECT * FROM e_uber_trips_2014;

CREATE TABLE uber_trips_2015 (
	id INT,
	dispatching_base_num VARCHAR,
	pickup_datetime TIMESTAMP WITHOUT TIME ZONE,
	affiliated_base_num VARCHAR,
	location_id INT
)
WITH (appendonly=true, orientation=column)
DISTRIBUTED RANDOMLY;

CREATE READABLE EXTERNAL TABLE e_uber_trips_2015 (LIKE uber_trips_2015)
LOCATION('qs://pek3a.qingstor.com/hashdata-public/open_data/nyc_taxi_data/uber_trips_2015/') FORMAT 'CSV';

INSERT INTO uber_trips_2015 SELECT * FROM e_uber_trips_2015;


VACUUM ANALYZE;

