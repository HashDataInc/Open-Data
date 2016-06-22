library(ggplot2)
library(ggmap)
library(dplyr)
library(reshape2)
library(zoo)
library(scales)
library(extrafont)
library(grid)
library(RPostgreSQL)
library(rgdal)
library(maptools)
gpclibPermit()

# helper variables and functions

boroughs = c("Manhattan", "Brooklyn", "Queens", "Bronx", "Staten Island")
yellow_hex = "#f7b731"
green_hex = "#3f9e4d"
uber_hex = "#222222"

if (all(c("Open Sans", "PT Sans") %in% fonts())) {
  font_family = "Open Sans"
  title_font_family = "PT Sans"
} else {
  font_family = "Arial"
  title_font_family = "Arial"
}

add_credits = function(fontsize = 12, color = "#777777", xpos = 0.99) {
  grid.text("www.hashdata.cn",
            x = xpos,
            y = 0.02,
            just = "right",
            gp = gpar(fontsize = fontsize, col = color, fontfamily = font_family))
}

title_with_subtitle = function(title, subtitle = "") {
  ggtitle(bquote(atop(bold(.(title)), atop(.(subtitle)))))
}

to_slug = function(string) {
  gsub("-", "_", gsub(" ", "_", tolower(string)))
}

theme_tws = function(base_size = 12) {
  bg_color = "#f4f4f4"
  bg_rect = element_rect(fill = bg_color, color = bg_color)

  theme_bw(base_size) +
    theme(text = element_text(family = font_family),
          plot.title = element_text(family = title_font_family),
          plot.background = bg_rect,
          panel.background = bg_rect,
          legend.background = bg_rect,
          panel.grid.major = element_line(colour = "grey80", size = 0.25),
          panel.grid.minor = element_line(colour = "grey80", size = 0.25),
          legend.key.width = unit(1.5, "line"),
          legend.key = element_blank())
}

theme_dark_map = function(base_size = 12) {
  theme_bw(base_size) +
    theme(text = element_text(family = font_family, color = "#ffffff"),
          rect = element_rect(fill = "#000000", color = "#000000"),
          plot.background = element_rect(fill = "#000000", color = "#000000"),
          panel.background = element_rect(fill = "#000000", color = "#000000"),
          plot.title = element_text(family = title_font_family),
          panel.grid = element_blank(),
          panel.border = element_blank(),
          axis.text = element_blank(),
          axis.title = element_blank(),
          axis.ticks = element_blank())
}

theme_tws_map = function(...) {
  theme_tws(...) +
    theme(panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.border = element_blank(),
          axis.text = element_blank(),
          axis.title = element_blank(),
          axis.ticks.length = unit(0, "cm"),
          plot.margin = unit(c(1, 1, 1, 0.5), "lines"))
}

nta_display_name = function(ntacode) {
  c(BK33 = "Carroll Gardens-Red Hook",
    BK38 = "DUMBO-Downtown-Boerum Hill",
    BK73 = "Williamsburg",
    MN03 = "Central Harlem North",
    MN13 = "Chelsea-Flatiron-Union Square",
    MN17 = "Midtown",
    MN24 = "SoHo-TriBeCa-Little Italy",
    MN25 = "Battery Park-Lower Manhattan",
    MN40 = "Upper East Side",
    MN50 = "Stuyvesant Town",
    QN31 = "Hunters Point-Sunnyside",
    QN68 = "Long Island City")[ntacode]
}

# NOTE: PostgreSQL connection to HashData, please replace with the correct dbname, host, port, user and password
con = dbConnect(dbDriver("PostgreSQL"), dbname = "nyc_taxi_data", host = "192.168.1.1", port=5432, user="gpadmin", password="Changeit04")
query = function(sql) { fetch(dbSendQuery(con, sql), n = 1e8) }

# this script assumes that queries in prepare_data.sql have been run

# import spatial data for census tracts and neighborhoods
tracts = spTransform(readOGR("./nyct2010", layer = "nyct2010"), CRS("+proj=longlat +datum=WGS84"))
tracts@data$id = as.character(as.numeric(rownames(tracts@data)) + 1)
tracts.points = fortify(tracts, region = "id")
tracts.map = inner_join(tracts.points, tracts@data, by = "id")

nyc_map = tracts.map
ex_staten_island_map = filter(tracts.map, BoroName != "Staten Island")
manhattan_map = filter(tracts.map, BoroName == "Manhattan")

# NYC dot maps
pickups = query("SELECT * FROM trips_by_lat_long_cab_type ORDER BY count")
pickups = mutate(pickups, cab_type_id = factor(cab_type_id))

alpha_range = c(0.14, 0.75)
size_range = c(0.134, 0.173)

p = ggplot() +
  geom_polygon(data = ex_staten_island_map,
               aes(x = long, y = lat, group = group),
               fill = "#080808", color = "#080808") +
  geom_point(data = pickups,
             aes(x = pickup_long, y = pickup_lat, alpha = count, size = count, color = cab_type_id)) +
  scale_alpha_continuous(range = alpha_range, trans = "log", limits = range(pickups$count)) +
  scale_size_continuous(range = size_range, trans = "log", limits = range(pickups$count)) +
  scale_color_manual(values = c("#ffffff", green_hex)) +
  coord_map(xlim = range(ex_staten_island_map$long), ylim = range(ex_staten_island_map$lat)) +
  title_with_subtitle("New York City Taxi Pickups", "2009–2015") +
  theme_dark_map(base_size = 24) +
  theme(legend.position = "none")

fname = "taxi_pickups_map.png"
png(filename = fname, width = 490, height = 759, bg = "black")
print(p)
add_credits(color = "#dddddd", xpos = 0.98)
dev.off()

dropoffs = query("SELECT * FROM dropoff_by_lat_long_cab_type ORDER BY count")
dropoffs = mutate(dropoffs, cab_type_id = factor(cab_type_id))

p = ggplot() +
  geom_polygon(data = ex_staten_island_map,
               aes(x = long, y = lat, group = group),
               fill = "#080808", color = "#080808") +
  geom_point(data = dropoffs,
             aes(x = dropoff_long, y = dropoff_lat, alpha = count, size = count, color = cab_type_id)) +
  scale_alpha_continuous(range = alpha_range, trans = "log", limits = range(dropoffs$count)) +
  scale_size_continuous(range = size_range, trans = "log", limits = range(dropoffs$count)) +
  scale_color_manual(values = c("#ffffff", green_hex)) +
  coord_map(xlim = range(ex_staten_island_map$long), ylim = range(ex_staten_island_map$lat)) +
  title_with_subtitle("New York City Taxi Drop Offs", "2009–2015") +
  theme_dark_map(base_size = 24) +
  theme(legend.position = "none")

fname = "taxi_dropoffs_map.png"
png(filename = fname, width = 490, height = 759, bg = "black")
print(p)
add_credits(color = "#dddddd", xpos = 0.98)
dev.off()

p = ggplot() +
  geom_polygon(data = ex_staten_island_map,
               aes(x = long, y = lat, group = group),
               fill = "#080808", color = "#080808", size = 0) +
  geom_point(data = pickups,
             aes(x = pickup_long, y = pickup_lat, alpha = count, size = count, color = cab_type_id)) +
  scale_alpha_continuous(range = alpha_range, trans = "log", limits = range(pickups$count)) +
  scale_size_continuous(range = size_range, trans = "log", limits = range(pickups$count)) +
  scale_color_manual(values = c(yellow_hex, green_hex)) +
  coord_map(xlim = range(ex_staten_island_map$long), ylim = range(ex_staten_island_map$lat)) +
  title_with_subtitle("New York City Taxi Pickups", "2009–2015") +
  theme_dark_map(base_size = 72) +
  theme(legend.position = "none")

fname = "taxi_pickups_map_hires.png"
png(filename = fname, width = 2880, height = 4068, bg = "black")
print(p)
dev.off()

p = ggplot() +
  geom_polygon(data = ex_staten_island_map,
               aes(x = long, y = lat, group = group),
               fill = "#080808", color = "#080808", size = 0) +
  geom_point(data = dropoffs,
             aes(x = dropoff_long, y = dropoff_lat, alpha = count, size = count, color = cab_type_id)) +
  scale_alpha_continuous(range = alpha_range, trans = "log", limits = range(dropoffs$count)) +
  scale_size_continuous(range = size_range, trans = "log", limits = range(dropoffs$count)) +
  scale_color_manual(values = c(yellow_hex, green_hex)) +
  coord_map(xlim = range(ex_staten_island_map$long), ylim = range(ex_staten_island_map$lat)) +
  title_with_subtitle("New York City Taxi Drop Offs", "2009–2015") +
  theme_dark_map(base_size = 72) +
  theme(legend.position = "none")

fname = "taxi_dropoffs_map_hires.png"
png(filename = fname, width = 2880, height = 4068, bg = "black")
print(p)
dev.off()

# borough trends
daily_pickups_borough_type = query("
  SELECT
    *,
    boroname || type AS group_for_monthly_total
  FROM daily_pickups_by_borough_and_type
  WHERE boroname != 'New Jersey'
  ORDER BY boroname, type, date
")

cab_type_levels = c("yellow", "green")
cab_type_labels = c("Yellow taxi", "Green taxi")

daily_pickups_borough_type = daily_pickups_borough_type %>%
  mutate(type = factor(type, levels = cab_type_levels, labels = cab_type_labels)) %>%
  group_by(group_for_monthly_total) %>%
  mutate(monthly = rollsum(trips, k = 28, na.pad = TRUE, align = "right"))

daily_dropoffs_borough = query("
  SELECT *
  FROM daily_dropoffs_by_borough
  WHERE boroname != 'New Jersey'
  ORDER BY boroname, date
")

daily_dropoffs_borough = daily_dropoffs_borough %>%
  mutate(type = factor(type, levels = cab_type_levels[1:2], labels = cab_type_labels[1:2])) %>%
  group_by(boroname, type) %>%
  mutate(monthly = rollsum(trips, k = 28, na.pad = TRUE, align = "right"))

for (b in boroughs) {
  p = ggplot(data = filter(daily_pickups_borough_type, boroname == b),
         aes(x = date, y = monthly, color = type)) +
        geom_line(size = 1) +
        scale_x_date("") +
        scale_y_continuous("pickups, trailing 28 days\n", labels = comma) +
        scale_color_manual("", values = c(yellow_hex, green_hex)) +
        title_with_subtitle(paste(b, "Monthly Taxi Pickups"), "Based on NYC TLC trip data") +
        expand_limits(y = 0) +
        theme_tws(base_size = 20) +
        theme(legend.position = "bottom")

  png(filename = paste0("taxi_pickups_", to_slug(b), ".png"), width = 640, height = 420)
  print(p)
  add_credits()
  dev.off()

  p = ggplot(data = filter(daily_dropoffs_borough, boroname == b),
             aes(x = date, y = monthly, color = type)) +
        geom_line(size = 1) +
        scale_x_date("") +
        scale_y_continuous("drop offs, trailing 28 days\n", labels = comma) +
        scale_color_manual("", values = c(yellow_hex, green_hex)) +
        title_with_subtitle(paste(b, "Monthly Taxi Drop Offs"), "Based on NYC TLC trip data") +
        expand_limits(y = 0) +
        theme_tws(base_size = 20) +
        theme(legend.position = "bottom")

  png(filename = paste0("taxi_dropoffs_", to_slug(b), ".png"), width = 640, height = 420)
  print(p)
  add_credits()
  dev.off()
}

# weather
weather = query("SELECT * FROM pickups_and_weather ORDER BY date")
weather = weather %>%
  mutate(precip_bucket = cut(precipitation, breaks = c(0, 0.0001, 0.2, 0.4, 0.6, 6), right = FALSE),
         snow_bucket = cut(snowfall, breaks = c(0, 0.0001, 2, 4, 6, 13), right = FALSE),
         taxi_week_avg = rollmean(taxi, k = 7, na.pad = TRUE, align = "right"))

precip = weather %>%
  group_by(precip_bucket) %>%
  summarize(taxi = mean(taxi), days = n())

snowfall = weather %>%
  group_by(snow_bucket) %>%
  summarize(taxi = mean(taxi), days = n())

p1 = ggplot(data = precip, aes(x = precip_bucket, y = taxi)) +
  geom_bar(stat = "identity") +
  scale_x_discrete("\nprecipitation in inches", labels = c(0, "0–0.2", "0.2–0.4", "0.4–0.6", ">0.6")) +
  scale_y_continuous("average daily trips\n", labels = comma) +
  title_with_subtitle("Precipitation vs. NYC Daily Taxi Trips", "Based on NYC TLC data 2009–2015") +
  theme_tws(base_size = 20)

p2 = ggplot(data = snowfall, aes(x = snow_bucket, y = taxi)) +
  geom_bar(stat = "identity") +
  scale_x_discrete("\nsnowfall in inches", labels = c(0, "0–2", "2–4", "4–6", ">6")) +
  scale_y_continuous("average daily taxi trips\n", labels = comma) +
  title_with_subtitle("Snowfall vs. NYC Daily Taxi Trips", "Based on NYC TLC data 2009–2015") +
  theme_tws(base_size = 20)

png(filename = "daily_trips_precipitation.png", width = 640, height = 420)
print(p1)
add_credits()
dev.off()

png(filename = "daily_trips_snowfall.png", width = 640, height = 420)
print(p2)
add_credits()
dev.off()

# Williamsburg Northside
northside = query("
  SELECT
    date(pickup_hour) AS date,
    SUM(count) AS pickups
  FROM hourly_pickups
  WHERE pickup_nyct2010_gid = 1100
    AND cab_type_id IN (1, 2)
  GROUP BY date
  ORDER BY date
")

northside = northside %>%
  mutate(monthly = rollsum(pickups, k = 28, na.pad = TRUE, align = "right"))

png(filename = "northside_williamsburg_pickups.png", width = 640, height = 420)
ggplot(data = northside, aes(x = date, y = monthly)) +
  geom_line(size = 1) +
  scale_x_date("") +
  scale_y_continuous("pickups, trailing 28 days\n", labels = comma) +
  title_with_subtitle("Northside Williamsburg Taxi Pickups", "N 7th to N 14th, East River to Berry St, based on NYC TLC data") +
  theme_tws(base_size = 20) +
  theme(legend.position = "bottom")
add_credits()
dev.off()

northside_pickup_locations = query("
  SELECT
    pickup_longitude,
    pickup_latitude,
    pickup_datetime,
    month
  FROM northside_pickups
  ORDER BY pickup_datetime
")

northside_map = get_googlemap(center = c(-73.9579, 40.7215), zoom = 17)

periods = list(
  c("2009-01-01", "2010-01-01", "2009"),
  c("2010-01-01", "2011-01-01", "2010"),
  c("2011-01-01", "2012-01-01", "2011"),
  c("2012-01-01", "2013-01-01", "2012"),
  c("2013-01-01", "2014-01-01", "2013"),
  c("2014-01-01", "2015-01-01", "2014"),
  c("2015-01-01", "2016-01-01", "2015")
)

for (months in periods) {
  p = ggmap(northside_map, extent = "device") +
        geom_point(data = filter(northside_pickup_locations, pickup_datetime >= months[1], pickup_datetime < months[2]),
               aes(x = pickup_longitude, y = pickup_latitude),
               alpha = 0.007,
               size = 2.5,
               color = "#d00000") +
    title_with_subtitle(months[3], "Taxi pickups in Northside Williamsburg") +
    theme_tws_map(base_size = 20)

  png(filename = paste0("northside_", months[1], ".png"), bg = "#f4f4f4", width = 480, height = 550)
  print(p)
  add_credits()
  dev.off()
}

# convert to animated gif with ImageMagick
# convert -delay 50 -loop 0 northside_20*-01-01.png animation.gif

# cash vs. credit
payments = query("
  WITH pt AS (
  SELECT
    date(month) AS month,
    CASE
      WHEN LOWER(payment_type) IN ('2', 'csh', 'cash', 'cas') THEN 'cash'
      WHEN LOWER(payment_type) IN ('1', 'crd', 'credit', 'cre') THEN 'credit'
    END AS payment_type,
    SUM(count) AS trips
  FROM payment_types
  GROUP BY month, payment_type
  )
  SELECT
    month,
    SUM(CASE WHEN payment_type = 'credit' THEN trips ELSE 0 END) / SUM(trips) AS frac_credit
  FROM pt
  GROUP BY month
  ORDER BY month
")

payments_split = query("
  WITH pt AS (
  SELECT
    date(month) AS month,
    total_amount_bucket,
    CASE
      WHEN LOWER(payment_type) IN ('2', 'csh', 'cash', 'cas') THEN 'cash'
      WHEN LOWER(payment_type) IN ('1', 'crd', 'credit', 'cre') THEN 'credit'
    END AS payment_type,
    SUM(count) AS trips
  FROM payment_types
  GROUP BY month, payment_type, total_amount_bucket
  )
  SELECT
    month,
    total_amount_bucket,
    SUM(CASE WHEN payment_type = 'credit' THEN trips ELSE 0 END) / SUM(trips) AS frac_credit
  FROM pt
  WHERE total_amount_bucket BETWEEN 0 AND 30
  GROUP BY month, total_amount_bucket
  ORDER BY month, total_amount_bucket
")

png(filename = "cash_vs_credit.png", width = 640, height = 420)
ggplot(data = payments, aes(x = month, y = frac_credit)) +
  geom_line(size = 1) +
  scale_y_continuous("% paying with credit card\n", labels = percent) +
  scale_x_date("") +
  title_with_subtitle("Cash vs. Credit NYC Taxi Payments", "Based on NYC TLC data") +
  expand_limits(y = 0) +
  theme_tws(base_size = 20)
add_credits()
dev.off()

payments_split = payments_split %>%
  mutate(total_amount_bucket = factor(total_amount_bucket, labels = c("$0–$10  ", "$10–$20  ", "$20–$30  ", "$30–$40  ")))

png(filename = "cash_vs_credit_split.png", width = 640, height = 420)
ggplot(data = payments_split, aes(x = month, y = frac_credit, color = total_amount_bucket)) +
  geom_line(size = 1) +
  scale_y_continuous("% paying with credit card\n", labels = percent) +
  scale_x_date("") +
  scale_color_discrete("Fare amount") +
  title_with_subtitle("Cash vs. Credit by Total Fare Amount", "Based on NYC TLC data") +
  expand_limits(y = 0) +
  theme_tws(base_size = 20) +
  theme(legend.position = "bottom")
add_credits()
dev.off()
