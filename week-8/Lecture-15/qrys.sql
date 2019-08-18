# Exploring the data a little
SELECT * 
FROM food_des 
LIMIT 5;

# Just exploring some specific columns
SELECT ndb_no, shrt_desc, comname, fat_factor 
FROM food_des 
LIMIT 5;

# What type of data do we expect in this field?
SELECT DISTINCT comname 
FROM food_des 
LIMIT 5;

# Okay, lets view the nutrition data just for Butter.
SELECT ndb_no, nutr_no, nutr_val, num_data_pts, std_error 
FROM nut_data 
WHERE ndb_no = '01001';

# Just the nutrition data for butter where we have evidence
SELECT ndb_no, nutr_no, nutr_val, num_data_pts, std_error 
FROM nut_data 
WHERE ndb_no = '01001' AND num_data_pts > 0;

# What about all the dairy products - how does the fd_group correlate?
SELECT * 
FROM fd_group;

# Okay, so we have a fdgrp_co, and the ndb_no is prefixed as well
# Lets use the prefix for the moment, to show LIKE
SELECT ndb_no, nutr_no, nutr_val, num_data_pts, std_error 
FROM nut_data 
WHERE ndb_no LIKE '01%' AND num_data_pts > 0;

# Seems like some of the data is still not amazing, lets only
# grab those that have a recorded error, and find which stats
# we should probably discard (where the error is >20% of the
# recorded information)
SELECT ndb_no, nutr_no, nutr_val, num_data_pts, std_error 
FROM nut_data 
WHERE ndb_no LIKE '01%' AND num_data_pts > 0 
AND std_error > 0 AND std_error/nutr_val > 0.2;

# How prevalent is it? lets check for the first two categories
SELECT ndb_no, nutr_no, nutr_val, num_data_pts, std_error 
FROM nut_data 
WHERE (ndb_no LIKE '01%' OR ndb_no LIKE '02%') 
AND num_data_pts > 0 AND std_error > 0 
AND std_error/nutr_val > 0.2;

# Seems like nutrition science isnt great! Lets grab the 
# nutrient names as well, using a join on to the nutrient data.
SELECT ndb_no, nutr_no, nutr_val, num_data_pts, std_error, nutrdesc
FROM nut_data JOIN nutr_def 
		ON nut_data.nutr_no = nutr_def.nutr_no
WHERE (ndb_no LIKE '01%' OR ndb_no LIKE '02%') 
AND num_data_pts > 0 AND std_error > 0 
AND std_error/nutr_val > 0.2;
(errors)

# Ahh, some mistakes! Turns out SQL cant figure out which table we
# want to pull the columns with identical names from.
# Lets specify the table for nutr_no in the SELECT.
SELECT ndb_no, nut_data.nutr_no, nutr_val, num_data_pts, std_error, nutrdesc
FROM nut_data JOIN nutr_def 
		ON nut_data.nutr_no = nutr_def.nutr_no
WHERE (ndb_no LIKE '01%' OR ndb_no LIKE '02%') 
AND num_data_pts > 0 AND std_error > 0 
AND std_error/nutr_val > 0.2;

# While we're here, lets rename some of the columns to have 
# better names
SELECT ndb_no AS food_id, nut_data.nutr_no AS nut_id, nutrdesc AS nutrient, nutr_val AS value, num_data_pts AS data_count, std_error
FROM nut_data JOIN nutr_def 
		ON nut_data.nutr_no = nutr_def.nutr_no
WHERE (ndb_no LIKE '01%' OR ndb_no LIKE '02%') 
AND num_data_pts > 0 AND std_error > 0 
AND std_error/nutr_val > 0.2;

# Okay, so we have this ref_ndb_no in nutrient data. Seems like
# some foods are borrowing nutrient data from others. Since we
# need two copies of the food_des table to get those names
# for two separate joins, we need to alias the second copy
# (ie give it a different name), lets call it ref_food
# (or reference_food)
SELECT food_des.shrt_desc as food, ref_food.shrt_desc as reference_food, nutr_no, nutr_val 
FROM food_des INNER JOIN nut_data 
		ON nut_data.ndb_no = food_des.ndb_no 
	INNER JOIN food_des AS ref_food 
		ON ref_food.ndb_no = nut_data.ref_ndb_no
WHERE food_des.ndb_no LIKE '11%';

# Hmm, seems like some foods borrow from themselves. A quirk of
# the data. Lets be explicit that the ref_no needs to be
# different to the actual nbn_no by adding an extra AND to the end
SELECT food_des.shrt_desc as food, ref_food.shrt_desc as reference_food, nutr_no, nutr_val 
FROM food_des INNER JOIN nut_data 
		ON nut_data.ndb_no = food_des.ndb_no 
	INNER JOIN food_des AS ref_food 
		ON ref_food.ndb_no = nut_data.ref_ndb_no
WHERE food_des.ndb_no LIKE '11%'
AND food_des.ndb_no <> ref_food.ndb_no;


# Something different - lets grab a count of the number of
# foods in each fdgrp. Dont forget to tell SQL to partition
# the table along an axis - i.e. fdgrp_cd - we do this with
# GROUP BY, so the COUNT knows what the count along.
SELECT COUNT(ndb_no), fdgrp_cd FROM food_des GROUP BY fdgrp_cd;

# Just those where we have a lot of foods?
# We need to use a HAVING here, since WHERE doesn't work
# on aggregate queries
SELECT COUNT(ndb_no), fdgrp_cd 
FROM food_des 
GROUP BY fdgrp_cd
HAVING COUNT(ndb_no) > 300;

# Lastly, lets join to the fd_group table to grab
# the names - dont forget to also tell psql to
# keep that in the partitions.
SELECT COUNT(ndb_no), food_deqs.fdgrp_cd, fddrp_desc 
FROM food_des INNER JOIN fd_group 
 ON fd_group.fdgrp_cd = food_des.fdgrp_cd 
GROUP BY food_des.fdgrp_cd, fddrp_desc;