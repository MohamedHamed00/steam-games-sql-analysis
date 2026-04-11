-- Create a new table

CREATE TABLE IF NOT EXISTS steam_games 
	(
	    AppID INT PRIMARY KEY,    
	    Name TEXT,                    
	    Release_Date DATE,    
	    Primary_Genre VARCHAR(50),    
	    All_Tags TEXT,               
	    Price_USD NUMERIC(10, 2),     
	    Discount_Pct INT,    
	    Review_Score_Pct INT,    
	    Total_Reviews INT,        
	    Estimated_Owners INT,    
	    Peak_players_24h INT        
	);

-- I'm creating a new table to Practice JOIN on it
CREATE TABLE IF NOT EXISTS genres (
    genre_name VARCHAR(50) PRIMARY KEY,
    category   VARCHAR(50)
);

INSERT INTO genres VALUES
('Action',    'Core Gaming'),
('Indie',     'Indie Gaming'),
('RPG',       'Core Gaming'),
('Strategy',  'Core Gaming'),
('Simulation','Casual Gaming'),
('Racing',    'Casual Gaming'),
('Sports',    'Casual Gaming');


SELECT * FROM steam_games LIMIT 5;

-- How many unique game?

SELECT COUNT(DISTINCT Name)
FROM steam_games;


-- How many unique primary genre?

SELECT COUNT(DISTINCT(primary_genre))
FROM steam_games;

-- How many null?

SELECT COUNT(*) FROM steam_games WHERE release_date IS NULL;

-- With every genre, the avrage of the prices and sum of players

SELECT 
	primary_genre,
	ROUND(AVG(price_usd), 2) AS price_avg,
	SUM(peak_players_24h) AS sum_players
FROM steam_games
GROUP BY 1
ORDER BY 3 DESC;
-- Action => The most popular 
-- Racing => The most expensive


-- The number of games released each year

SELECT
	COUNT(NAME) AS count_games,
	EXTRACT(YEAR FROM release_date) AS year
FROM steam_games
GROUP BY EXTRACT(YEAR FROM release_date)
ORDER BY 1 DESC;

/*
Create a report that categorizes games into three groups based on their Discount_Pct:
'No Discount' (when the discount is exactly 0).
'Moderate Discount' (any discount between 1 and 40 inclusive).
'Deep Discount' (any discount above 40).
For each of these three groups, calculate:
The number of games in that category.
The average number of peak players (24h_Peak_Players).
Sort the final results to see which group has the highest average engagement.
*/

SELECT 
    CASE
        WHEN discount_pct = 0 THEN 'No Discount' 
        WHEN discount_pct BETWEEN 1 AND 40 THEN 'Moderate Discount' 
        ELSE 'Deep Discount'
    END AS discount_category,
    COUNT(*) AS count_games,
    ROUND(AVG(peak_players_24h), 0) AS avg_players
FROM steam_games
GROUP BY 1  
ORDER BY 3 DESC;


/*
Find the Top 3 Games in each Primary_Genre based on their Total_Reviews, 
but only for games that have a Review_Score_Pct higher than 85.
Required Task:
Filter the games to only include those with a score > 85.
For each genre, find the top 3 games with the most reviews.
Show the: Name, Primary_Genre, and Total_Reviews.
*/
WITH games_ranked AS (
    SELECT 
        name, 
        primary_genre, 
        total_reviews,
        review_score_pct,
        RANK() OVER(PARTITION BY primary_genre ORDER BY total_reviews DESC) as rnk
    FROM steam_games
    WHERE review_score_pct > 85 
	)   
SELECT 
    name, 
    primary_genre, 
    total_reviews
FROM games_ranked
WHERE rnk <= 3 
ORDER BY primary_genre, total_reviews DESC;
	

/*
Interview Question: User Retention Analysis
Scenario:
The marketing team wants to know which games have a "Loyal Fanbase". They define a loyal game as one where the number of Positive Reviews is at least 90% of the Total Reviews, 
BUT the game must also have a significant number of reviews to be taken seriously.
The Task:
Write a SQL query to find all games that meet the following criteria:
The game must have more than 1,000 Total Reviews.
The percentage of positive reviews must be 90% or higher.
The game was released before the year 2024.
*/

SELECT 
    name, 
    release_date, 
    total_reviews, 
    review_score_pct AS positive_percentage 
FROM steam_games
WHERE total_reviews > 1000               
  AND review_score_pct >= 90             
  AND EXTRACT(YEAR FROM release_date) < 2024 
ORDER BY positive_percentage DESC, total_reviews DESC;


/*
"Calculate the Estimated Gross Revenue for each genre, but only for games that are not free."
Task:
Calculate revenue for each game using: Price_USD * Total_Reviews. (Assume each review represents one sale).
Group the results by Primary_Genre.
Show the Total Revenue and Average Price for each genre.
Filter out any genre that has a total revenue less than $1,000,000.
*/

SELECT 
    primary_genre,
    AVG(price_usd) AS avg_price,
    SUM(price_usd * total_reviews) AS total_revenue
FROM steam_games
WHERE price_usd > 0                
GROUP BY primary_genre             
HAVING SUM(price_usd * total_reviews) >= 1000000 
ORDER BY total_revenue DESC;


/*
"Identify games that are overperforming in their genre."
Task:
Find games that have a Price_USD lower than the Average Price of their own Primary_Genre, 
but have Total_Reviews higher than the Average Reviews of that same genre.
*/

WITH genre_stats AS (
    SELECT 
        name,
        primary_genre,
        price_usd,
        total_reviews,
        AVG(price_usd) OVER(PARTITION BY primary_genre) as genre_avg_price,
        AVG(total_reviews) OVER(PARTITION BY primary_genre) as genre_avg_reviews
    FROM steam_games
)
SELECT 
    name, 
    primary_genre, 
    price_usd, 
    total_reviews
FROM genre_stats
WHERE price_usd < genre_avg_price 
  AND total_reviews > genre_avg_reviews;


/*
"The Marketing team wants a list of all games, but the names are messy. 
They want the names to be in Upper Case, and they want a new column called 'Market_ID'."
Task:
Generate a column Game_Name_Upper (all capital letters).
Generate a column Market_ID which is a combination of the first 3 letters of the Primary_Genre 
and the Price_USD 
(e.g., if genre is 'Action' and price is 20, the ID should be 'ACT-20').
Filter out any games where the Primary_Genre is missing (NULL).
*/

SELECT
	UPPER(name) AS Game_Name_Upper,
	primary_genre,
	CONCAT(LEFT(primary_genre,3), '-',price_usd) AS Market_ID
FROM steam_games
WHERE primary_genre IS NOT NULL;


--Fining any name that Includes 'indie'

SELECT 
    name,
    CASE 
        WHEN UPPER(primary_genre) LIKE '%INDIE%' THEN 'Yes'
        ELSE 'No'
    END AS Is_Indie
FROM steam_games;


/*
"Find the Average Price of games for each Release Quarter (Q1, Q2, Q3, Q4) of the year 2025."
Task:
Use the release_date to extract the Quarter.
Filter the data for only the year 2025.
Show the Quarter and its Average Price.
*/

SELECT 
    EXTRACT(QUARTER FROM release_date) AS release_quarter,
    ROUND(AVG(price_usd), 2) AS avg_price 
FROM steam_games
WHERE EXTRACT(YEAR FROM release_date) = 2025           
GROUP BY 1                                             
ORDER BY 1;           


-- REPLASE NULL with 0

SELECT 
	name,
	COALESCE(price_usd,0) AS Clean_Price
FROM steam_games;


/*
"Find the Most Expensive Game in each Primary_Genre."
Task:
Clean the Name to be all UPPER CASE.
If the Price_USD is NULL, treat it as 0.
Use a Window Function to rank games by price within each genre.
Show only the Top 1 most expensive game for each genre.
*/

WITH ranked_by_price  AS (
	SELECT
		name,
		primary_genre,
		COALESCE(price_usd, 0) AS clean_price, 
		RANK() OVER(PARTITION BY primary_genre ORDER BY COALESCE(price_usd, 0) DESC) as rnk
	FROM steam_games
)
SELECT 
	UPPER(name) AS Game_Name,
	primary_genre,
	clean_price
FROM ranked_by_price 
WHERE rnk = 1;	


-- Show each game's name, its price, and its category from the genres table. 
-- Only show games that have a matching genre.

SELECT	
	s.name,
	g.genre_name,
	g.category,
	s.price_usd
FROM genres g
JOIN steam_games s
ON
g.genre_name = s.primary_genre;
	

-- Show all games with their category. If a game's genre doesn't exist in the genres table, 
-- still show the game but with NULL in the category column.

SELECT
	s.name,
	g.category
FROM steam_games s
LEFT JOIN genres g
ON
g.genre_name = s.primary_genre;


-- Show each category (from the genres table) with the total number of games in it 
-- and the average review score. Sort by average review score descending.

SELECT
	g.category,
	COUNT(g.category) AS count_category,
	ROUND(AVG(s.review_score_pct),2) AS avg_score
FROM genres g
JOIN steam_games s
ON
g.genre_name = s.primary_genre
GROUP BY 1
ORDER BY avg_score DESC;


/*
Find all games that have a price higher than the average price of all games in the steam_games table.
Show the game name and price, sorted by price descending.
*/

SELECT
	name,
	price_usd
FROM steam_games
WHERE 
	price_usd > 
	(SELECT AVG(price_usd) AS avg_price FROM steam_games)
ORDER BY 2;


/*
Find all games that belong to a category called 'Core Gaming' — but use a subquery, not a JOIN.
Show the game name and its primary genre.
*/

SELECT name, primary_genre
FROM steam_games
WHERE primary_genre IN (SELECT genre_name 
                        FROM genres 
                        WHERE category = 'Core Gaming');


/*
Calculate the average number of total reviews per genre, then show only the genres where 
that average is higher than the overall average reviews across all genres.
Show the genre and its average reviews, sorted descending.
*/

SELECT primary_genre, avg_reviews
FROM (
    SELECT primary_genre, ROUND(AVG(total_reviews), 2) AS avg_reviews
    FROM steam_games
    GROUP BY primary_genre
	) AS genre_avg
WHERE avg_reviews > (SELECT AVG(total_reviews) FROM steam_games)
ORDER BY avg_reviews DESC;

/*
Write a query that shows how many rows have NULL in release_date and how many have NULL in all_tags.
Show the results in one query with two columns: missing_release_date and missing_tags.
*/

SELECT 
    COUNT(*) - COUNT(release_date) AS missing_release_date,
    COUNT(*) - COUNT(all_tags)     AS missing_tags
FROM steam_games;


-- Show all games with their name and release date. If release_date is NULL, replace it with '2024-01-01'.

SELECT
	name,
	COALESCE(release_date, '2024-01-01')
FROM steam_games;


/*
Show all games where all_tags is not NULL and price_usd is greater than 0 
and total_reviews is greater than 0.
Count how many clean games are left.
*/

SELECT COUNT(*) AS clean_games
FROM steam_games
WHERE all_tags IS NOT NULL
  AND price_usd > 0
  AND total_reviews > 0;


/*
Create a view called v_clean_games that contains only clean games where all_tags is not NULL, 
price_usd is greater than 0, and total_reviews is greater than 0.
Then write a SELECT to query from it.
*/

CREATE VIEW v_clean_games AS
	SELECT all_tags, price_usd, total_reviews
	FROM steam_games
	WHERE 	
		all_tags IS NOT NULL
		AND
		price_usd > 0
		AND
		total_reviews > 0;
SELECT * FROM v_clean_games;

-- Update the view v_clean_games

CREATE OR REPLACE VIEW v_clean_games AS
    SELECT name, all_tags, price_usd, total_reviews
    FROM steam_games
    WHERE 
        all_tags IS NOT NULL
        AND price_usd > 0
        AND total_reviews > 0;

-- Delete the view v_clean_games

DROP VIEW v_clean_games;


/*
The all_tags column has values like 'FPS;Shooter;Multiplayer'. 
Write a query that splits each game's tags into separate rows, 
showing the game name and one tag per row.
*/

SELECT 
    name,
    UNNEST(STRING_TO_ARRAY(all_tags, ';')) AS tag
FROM steam_games
WHERE all_tags IS NOT NULL;


/*
 Find the top 10 most common tags across all games. 
 Show the tag and how many games have it, sorted descending.
 */

WITH tags AS (
	SELECT UNNEST(STRING_TO_ARRAY(all_tags, ';')) AS tag
	FROM steam_games
	WHERE all_tags IS NOT NULL
	)
SELECT tag, COUNT(*) AS count_games
FROM tags
GROUP BY tag
ORDER BY count_games DESC
LIMIT 10;
