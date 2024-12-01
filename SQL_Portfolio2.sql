--Basic Queries
--List All Teams
SELECT team_long_name
FROM Team;

--List All Players
-- List All Teams
SELECT team_long_name
FROM Team;

-- List All Players
SELECT player_name
FROM Player;

-- List All Leagues
SELECT name
FROM League;

-- Count of Matches in Each Season
SELECT season, COUNT(*) AS match_count
FROM Match
GROUP BY season;


--Intermediate Queries

--League Comparisons
SELECT 
    l.name AS League,
    AVG(m.home_team_goal + m.away_team_goal) AS AvgGoalsPerGame,
    AVG(CASE WHEN m.home_team_goal > m.away_team_goal THEN 1 ELSE 0 END) AS HomeWinRate,
    AVG(CASE WHEN m.away_team_goal > m.home_team_goal THEN 1 ELSE 0 END) AS AwayWinRate
FROM 
    Match AS m
JOIN 
    League AS l ON m.league_id = l.id
GROUP BY 
    League
ORDER BY 
    AvgGoalsPerGame DESC;


-- Top Scoring Teams
SELECT t.team_long_name AS Team, SUM(m.home_team_goal + m.away_team_goal) AS TotalGoals
FROM Match m
JOIN Team t ON t.team_api_id = m.home_team_api_id
GROUP BY Team
ORDER BY TotalGoals DESC
LIMIT 10;

-- Total Goals Per Season
SELECT 
    strftime('%Y', date) AS Season,
    SUM(home_team_goal + away_team_goal) AS TotalGoals
FROM Match
GROUP BY Season
ORDER BY Season;

-- Goals Scored Per Team Each Season
SELECT 
    t.team_long_name AS Team,
    strftime('%Y', m.date) AS Season,
    SUM(CASE WHEN m.home_team_api_id = t.team_api_id THEN m.home_team_goal ELSE 0 END 
        + CASE WHEN m.away_team_api_id = t.team_api_id THEN m.away_team_goal ELSE 0 END) AS TotalGoals
FROM Team t
JOIN Match m ON t.team_api_id = m.home_team_api_id OR t.team_api_id = m.away_team_api_id
GROUP BY Team, Season
ORDER BY Team, Season;

-- Average Goals Per Season
SELECT season, AVG(home_team_goal + away_team_goal) AS avg_goals
FROM Match
GROUP BY season
ORDER BY season;

-- Highest Scoring Matches
SELECT m.match_api_id, t1.team_long_name AS HomeTeam, t2.team_long_name AS AwayTeam,
       m.home_team_goal, m.away_team_goal, 
       (m.home_team_goal + m.away_team_goal) AS TotalGoals
FROM Match m
JOIN Team t1 ON t1.team_api_id = m.home_team_api_id
JOIN Team t2 ON t2.team_api_id = m.away_team_api_id
ORDER BY TotalGoals DESC
LIMIT 10;

--Advanced Queries
--- Best Players Based on Average Overall Rating
SELECT 
    p.player_name AS Player,
    ROUND(AVG(pa.overall_rating), 2) AS AvgRating
FROM Player_Attributes pa
JOIN Player p ON p.player_api_id = pa.player_api_id
GROUP BY Player
ORDER BY AvgRating DESC
LIMIT 10;

-- Best Young Player Each Season
WITH PlayerRatings AS (
    SELECT 
        p.player_name AS Player,
        strftime('%Y', pa.date) AS Season,
        AVG(pa.overall_rating) AS AvgRating,
        (strftime('%Y', pa.date) - strftime('%Y', p.birthday)) AS Age
    FROM Player_Attributes pa
    JOIN Player p ON pa.player_api_id = p.player_api_id
    GROUP BY p.player_name, Season
    HAVING Age <= 23
)
SELECT Season, Player, AvgRating, Age
FROM PlayerRatings
WHERE (Season, AvgRating) IN (
    SELECT Season, MAX(AvgRating)
    FROM PlayerRatings
    GROUP BY Season
)
ORDER BY Season;

-- Team Performance Over Time
SELECT 
    t.team_long_name AS Team,
    m.season AS Season,
    SUM(CASE 
            WHEN m.home_team_api_id = t.team_api_id THEN 
                CASE WHEN m.home_team_goal > m.away_team_goal THEN 3 
                     WHEN m.home_team_goal = m.away_team_goal THEN 1 ELSE 0 
                END
            WHEN m.away_team_api_id = t.team_api_id THEN 
                CASE WHEN m.away_team_goal > m.home_team_goal THEN 3 
                     WHEN m.away_team_goal = m.home_team_goal THEN 1 ELSE 0 
                END
        END) AS Points
FROM Match m
JOIN Team t ON t.team_api_id = m.home_team_api_id OR t.team_api_id = m.away_team_api_id
GROUP BY Team, Season
ORDER BY Season, Points DESC;

-- Home vs. Away Performance Analysis
SELECT 
    t.team_long_name AS Team,
    COUNT(CASE WHEN m.home_team_api_id = t.team_api_id THEN 1 END) AS HomeGames,
    AVG(CASE WHEN m.home_team_api_id = t.team_api_id THEN m.home_team_goal ELSE NULL END) AS AvgHomeGoals,
    COUNT(CASE WHEN m.away_team_api_id = t.team_api_id THEN 1 END) AS AwayGames,
    AVG(CASE WHEN m.away_team_api_id = t.team_api_id THEN m.away_team_goal ELSE NULL END) AS AvgAwayGoals,
    SUM(CASE WHEN m.home_team_api_id = t.team_api_id AND m.home_team_goal > m.away_team_goal THEN 1 ELSE 0 END) AS HomeWins,
    SUM(CASE WHEN m.away_team_api_id = t.team_api_id AND m.away_team_goal > m.home_team_goal THEN 1 ELSE 0 END) AS AwayWins
FROM Match AS m
JOIN Team AS t ON t.team_api_id = m.home_team_api_id OR t.team_api_id = m.away_team_api_id
GROUP BY Team
ORDER BY HomeWins DESC, AwayWins DESC;

-- Player Consistency Analysis Over Seasons
SELECT 
    p.player_name AS Player,
    strftime('%Y', pa.date) AS Season,
    ROUND(AVG(pa.overall_rating), 2) AS AvgRating
FROM Player_Attributes pa
JOIN Player p ON pa.player_api_id = p.player_api_id
GROUP BY Player, Season
HAVING COUNT(Season) >= 3
ORDER BY AvgRating DESC
LIMIT 20;

-- Recruitment Analysis for Clubs
--Recruitment for Strikers
SELECT DISTINCT 
    p.player_name AS Player,
    strftime('%Y', pa.date) AS Season,
    pa.finishing AS Finishing,
    pa.shot_power AS ShotPower,
    pa.positioning AS Positioning,
    pa.overall_rating AS Rating
FROM 
    Player_Attributes AS pa
JOIN 
    Player AS p ON pa.player_api_id = p.player_api_id
WHERE 
    pa.finishing >= 80 AND 
    pa.shot_power >= 75 AND 
    pa.positioning >= 70
ORDER BY 
    Rating DESC, Finishing DESC, ShotPower DESC
LIMIT 50;


-- Recruitment Analysis for Wingers
SELECT DISTINCT 
    p.player_name AS Player,
    strftime('%Y', pa.date) AS Season,
    pa.dribbling AS Dribbling,
    pa.crossing AS Crossing,
    pa.acceleration AS Acceleration,
    pa.overall_rating AS Rating
FROM Player_Attributes AS pa
JOIN Player AS p ON pa.player_api_id = p.player_api_id
WHERE pa.dribbling >= 80 AND pa.crossing >= 75 AND pa.acceleration >= 70
ORDER BY Rating DESC, Dribbling DESC, Crossing DESC
LIMIT 50;

--Recruitment for Midfielders
SELECT DISTINCT 
    p.player_name AS Player,
    strftime('%Y', pa.date) AS Season,
    pa.short_passing AS ShortPassing,
    pa.vision AS Vision,pa.long_passing AS LongPassing,
    pa.ball_control AS BallControl,
    pa.overall_rating AS Rating
FROM 
    Player_Attributes AS pa
JOIN 
    Player AS p ON pa.player_api_id = p.player_api_id
WHERE 
    pa.short_passing >= 80 AND 
    pa.vision >= 75 AND 
	pa.long_passing >= 75 AND
    pa.ball_control >= 70
ORDER BY 
    Rating DESC, ShortPassing DESC, Vision DESC
LIMIT 50;

--Recruitment for Defenders
SELECT DISTINCT 
    p.player_name AS Player,
    strftime('%Y', pa.date) AS Season,
    pa.interceptions AS Interceptions,
    pa.standing_tackle AS StandingTackle,
    pa.marking AS Marking,
    pa.overall_rating AS Rating
FROM 
    Player_Attributes AS pa
JOIN 
    Player AS p ON pa.player_api_id = p.player_api_id
WHERE 
    pa.interceptions >= 80 AND 
    pa.standing_tackle >= 75 AND 
    pa.marking >= 70
ORDER BY 
    Rating DESC, Interceptions DESC, StandingTackle DESC
LIMIT 50;

-- Goalkeeper
SELECT 
    p.player_name AS Goalkeeper,
    ROUND(AVG(pa.gk_diving), 2) AS AvgDiving,
    ROUND(AVG(pa.gk_handling), 2) AS AvgHandling,
    ROUND(AVG(pa.gk_positioning), 2) AS AvgPositioning,
    ROUND(AVG(pa.gk_reflexes), 2) AS AvgReflexes
FROM 
    Player_Attributes AS pa
JOIN 
    Player AS p ON pa.player_api_id = p.player_api_id
WHERE 
    pa.gk_diving IS NOT NULL 
    AND pa.gk_handling IS NOT NULL 
    AND pa.gk_positioning IS NOT NULL 
    AND pa.gk_reflexes IS NOT NULL
GROUP BY 
    Goalkeeper
ORDER BY 
    AvgReflexes DESC, AvgHandling DESC, AvgDiving DESC
LIMIT 10;

--Top Goalkeepers by Season
SELECT 
    p.player_name AS Goalkeeper,
    strftime('%Y', pa.date) AS Season,
    ROUND(AVG(pa.gk_diving), 2) AS AvgDiving,
    ROUND(AVG(pa.gk_handling), 2) AS AvgHandling,
    ROUND(AVG(pa.gk_positioning), 2) AS AvgPositioning,
    ROUND(AVG(pa.gk_reflexes), 2) AS AvgReflexes
FROM 
    Player_Attributes AS pa
JOIN 
    Player AS p ON pa.player_api_id = p.player_api_id
WHERE 
    pa.gk_diving IS NOT NULL 
    AND pa.gk_handling IS NOT NULL 
    AND pa.gk_positioning IS NOT NULL 
    AND pa.gk_reflexes IS NOT NULL
GROUP BY 
    Goalkeeper, Season
ORDER BY 
    Season, AvgReflexes DESC, AvgHandling DESC
LIMIT 10;

--Expected Goals (xG) Model for Player Evaluation
SELECT 
    p.player_name AS Player,
    pa.shot_power AS ShotPower,
    pa.finishing AS Finishing,
    pa.positioning AS Positioning,
    pa.overall_rating AS Rating,
    ROUND((pa.shot_power + pa.finishing + pa.positioning) / 3.0, 2) AS ExpectedGoals
FROM 
    Player_Attributes pa
JOIN 
    Player p ON pa.player_api_id = p.player_api_id
GROUP BY 
    Player
ORDER BY 
    ExpectedGoals DESC
LIMIT 10;

--Top 10 Most Improved Players Over Time
WITH PlayerImprovements AS (
    SELECT 
        p.player_name AS Player,
        strftime('%Y', pa.date) AS Season,
        pa.overall_rating AS Rating,
        LEAD(pa.overall_rating) OVER (PARTITION BY pa.player_api_id ORDER BY pa.date) - pa.overall_rating AS RatingImprovement
    FROM 
        Player_Attributes pa
    JOIN 
        Player p ON pa.player_api_id = p.player_api_id
)
SELECT 
    Player,
    Season,
    Rating,
    RatingImprovement
FROM 
    PlayerImprovements
WHERE 
    RatingImprovement > 0
ORDER BY 
    RatingImprovement DESC
LIMIT 10;


--Age-Based Performance Decline Analysis
SELECT 
    (strftime('%Y', pa.date) - strftime('%Y', p.birthday)) AS Age,
    ROUND(AVG(pa.overall_rating), 2) AS AvgRating,
    ROUND(AVG(pa.stamina), 2) AS AvgStamina,
    ROUND(AVG(pa.acceleration), 2) AS AvgAcceleration,
    ROUND(AVG(pa.sprint_speed), 2) AS AvgSprintSpeed
FROM 
    Player_Attributes pa
JOIN 
    Player p ON pa.player_api_id = p.player_api_id
GROUP BY 
    Age
HAVING 
    Age > 18  -- Analyzing professional ages only
ORDER BY 
    Age ASC;


--Player Consistency Analysis
SELECT 
    p.player_name AS Player,
    strftime('%Y', pa.date) AS Season,
    ROUND(AVG(pa.overall_rating), 2) AS AvgRating
FROM 
    Player_Attributes AS pa
JOIN 
    Player p ON pa.player_api_id = p.player_api_id
GROUP BY 
    Player, Season
HAVING 
    COUNT(Season) >= 3  -- Only players with data over multiple seasons
ORDER BY 
    AvgRating DESC
LIMIT 20;

--Player Growth Potential Analysis
WITH PlayerRatingGrowth AS (
    SELECT 
        p.player_name AS Player,
        pa.player_api_id,
        strftime('%Y', pa.date) AS Season,
        AVG(pa.overall_rating) AS AvgRating,
        (strftime('%Y', pa.date) - strftime('%Y', p.birthday)) AS Age
    FROM 
        Player_Attributes pa
    JOIN 
        Player p ON pa.player_api_id = p.player_api_id
    GROUP BY 
        p.player_name, pa.player_api_id, Season
)
SELECT 
    Player,
    MIN(Age) AS StartAge,
    MAX(Age) AS CurrentAge,
    MAX(AvgRating) - MIN(AvgRating) AS RatingGrowth
FROM 
    PlayerRatingGrowth
GROUP BY 
    Player
HAVING 
    StartAge <= 23 AND RatingGrowth > 5  -- Young players with significant growth
ORDER BY 
    RatingGrowth DESC
LIMIT 10;


--Scouting Analysis for Future Stars
WITH PlayerGrowth AS (
    SELECT 
        p.player_name AS Player,
        ROUND(AVG(pa.potential - pa.overall_rating), 2) AS GrowthPotential,
        AVG(pa.overall_rating) AS CurrentRating,
        AVG(pa.potential) AS Potential,
        p.birthday AS Birthdate
    FROM 
        Player_Attributes pa
    JOIN 
        Player p ON pa.player_api_id = p.player_api_id
    GROUP BY 
        p.player_name
    HAVING 
        GrowthPotential > 5  -- Lowered threshold for potential growth
)
SELECT 
    Player,
    GrowthPotential,
    CurrentRating,
    Potential,
    (strftime('%Y', 'now') - strftime('%Y', Birthdate)) AS Age
FROM 
    PlayerGrowth
WHERE 
    Age <= 26  -- Focus on young talent
ORDER BY 
    GrowthPotential DESC
LIMIT 10;

--Team Stability
SELECT 
    t.team_long_name AS Team,
    strftime('%Y', m.date) AS Season,
    COUNT(DISTINCT CASE WHEN m.home_team_api_id = t.team_api_id THEN m.home_player_X1 END 
          || CASE WHEN m.away_team_api_id = t.team_api_id THEN m.away_player_X1 END) AS UniquePlayers
FROM 
    Match m
JOIN 
    Team t ON t.team_api_id = m.home_team_api_id OR t.team_api_id = m.away_team_api_id
GROUP BY 
    Team, Season
ORDER BY 
    UniquePlayers DESC
LIMIT 50;

--Team Consistency in Win Rate Over Seasons
SELECT 
    t.team_long_name AS Team,
    strftime('%Y', m.date) AS Season,
    AVG(CASE WHEN (m.home_team_api_id = t.team_api_id AND m.home_team_goal > m.away_team_goal) 
              OR (m.away_team_api_id = t.team_api_id AND m.away_team_goal > m.home_team_goal) 
              THEN 1 ELSE 0 END) AS WinRate
FROM 
    Match m
JOIN 
    Team t ON t.team_api_id = m.home_team_api_id OR t.team_api_id = m.away_team_api_id
GROUP BY 
    Team, Season
HAVING 
    WinRate > 0.5
ORDER BY 
    Season, WinRate DESC;

	
--Seasonal Consistency for Teams
WITH TeamSeasonPoints AS (
    SELECT 
        t.team_long_name AS Team,
        m.season AS Season,
        SUM(CASE 
                WHEN m.home_team_api_id = t.team_api_id THEN 
                    CASE WHEN m.home_team_goal > m.away_team_goal THEN 3 
                         WHEN m.home_team_goal = m.away_team_goal THEN 1 
                         ELSE 0 
                    END
                WHEN m.away_team_api_id = t.team_api_id THEN 
                    CASE WHEN m.away_team_goal > m.home_team_goal THEN 3 
                         WHEN m.away_team_goal = m.home_team_goal THEN 1 
                         ELSE 0 
                    END
            END) AS Points
    FROM 
        Match m
    JOIN 
        Team t ON t.team_api_id = m.home_team_api_id OR t.team_api_id = m.away_team_api_id
    GROUP BY 
        Team, Season
),
TeamStatistics AS (
    SELECT 
        Team,
        AVG(Points) AS AvgPoints,
        AVG(Points * Points) AS AvgPointsSquared
    FROM 
        TeamSeasonPoints
    GROUP BY 
        Team
)
SELECT 
    Team,
    AvgPoints,
    ROUND(SQRT(AvgPointsSquared - AvgPoints * AvgPoints), 2) AS ConsistencyScore -- Standard deviation calculation
FROM 
    TeamStatistics
ORDER BY 
    ConsistencyScore ASC, AvgPoints DESC
LIMIT 100;


--Predicting Match Outcomes Based on Player Ratings
SELECT 
    t1.team_long_name AS HomeTeam,
    t2.team_long_name AS AwayTeam,
    m.season AS Season,
    CASE 
        WHEN m.home_team_goal > m.away_team_goal THEN 'Home Win'
        WHEN m.home_team_goal < m.away_team_goal THEN 'Away Win'
        ELSE 'Draw'
    END AS ActualOutcome,
    AVG(hp.overall_rating) AS HomeAvgRating,
    AVG(ap.overall_rating) AS AwayAvgRating,
    CASE 
        WHEN AVG(hp.overall_rating) > AVG(ap.overall_rating) THEN 'Home Favored'
        ELSE 'Away Favored'
    END AS PredictedOutcome
FROM 
    Match m
JOIN 
    Team t1 ON t1.team_api_id = m.home_team_api_id
JOIN 
    Team t2 ON t2.team_api_id = m.away_team_api_id
JOIN 
    Player_Attributes hp ON hp.player_api_id IN (
        m.home_player_1, m.home_player_2, m.home_player_3, m.home_player_4,
        m.home_player_5, m.home_player_6, m.home_player_7, m.home_player_8,
        m.home_player_9, m.home_player_10, m.home_player_11
    ) AND hp.date = (
        SELECT MAX(date) FROM Player_Attributes 
        WHERE player_api_id = hp.player_api_id AND date <= m.date
    )
JOIN 
    Player_Attributes ap ON ap.player_api_id IN (
        m.away_player_1, m.away_player_2, m.away_player_3, m.away_player_4,
        m.away_player_5, m.away_player_6, m.away_player_7, m.away_player_8,
        m.away_player_9, m.away_player_10, m.away_player_11
    ) AND ap.date = (
        SELECT MAX(date) FROM Player_Attributes 
        WHERE player_api_id = ap.player_api_id AND date <= m.date
    )
GROUP BY 
    HomeTeam, AwayTeam, Season, ActualOutcome
ORDER BY 
    Season, HomeTeam;

		
--Evaluating Game-Impactful Player Traits
SELECT 
    pa.overall_rating,
    pa.stamina,
    pa.aggression,
    pa.marking,
    pa.vision,
    (CASE 
        WHEN m.home_team_goal > m.away_team_goal THEN 1 
        ELSE 0 
    END) AS Win
FROM 
    Player_Attributes pa
JOIN 
    Match m ON m.home_team_api_id = pa.player_api_id OR m.away_team_api_id = pa.player_api_id
WHERE 
    pa.stamina IS NOT NULL
    AND pa.aggression IS NOT NULL
    AND pa.marking IS NOT NULL
ORDER BY 
    Win DESC;

--Impact of Key Midfielder Attributes on Passing Success	
SELECT 
    p.player_name AS Midfielder,
    AVG(pa.vision) AS AvgVision,
    AVG(pa.short_passing) AS AvgShortPassing,
    AVG(pa.long_passing) AS AvgLongPassing,
    COUNT(CASE WHEN pa.short_passing > 80 AND pa.vision > 75 THEN 1 END) AS SuccessfulPasses,
    COUNT(CASE WHEN pa.long_passing > 80 THEN 1 END) AS KeyPasses
FROM 
    Player_Attributes pa
JOIN 
    Player p ON pa.player_api_id = p.player_api_id
GROUP BY 
    Midfielder
ORDER BY 
    SuccessfulPasses DESC, KeyPasses DESC
LIMIT 10;
	
--Offensive vs Defensive Teams Comparison
SELECT 
    t.team_long_name AS Team,
    AVG(CASE 
            WHEN t.team_api_id = m.home_team_api_id THEN m.home_team_goal 
            WHEN t.team_api_id = m.away_team_api_id THEN m.away_team_goal 
        END) AS AvgGoalsPerGame,
    AVG(CASE 
            WHEN t.team_api_id = m.home_team_api_id THEN m.home_team_goal - m.away_team_goal 
        END) AS HomeGoalDifference,
    AVG(CASE 
            WHEN t.team_api_id = m.away_team_api_id THEN m.away_team_goal - m.home_team_goal 
        END) AS AwayGoalDifference,
    CASE 
        WHEN AVG(CASE 
                     WHEN t.team_api_id = m.home_team_api_id THEN m.home_team_goal 
                     WHEN t.team_api_id = m.away_team_api_id THEN m.away_team_goal 
                 END) > 2 THEN 'Offensive'
        ELSE 'Defensive'
    END AS TeamStyle
FROM 
    Match m
JOIN 
    Team t ON t.team_api_id = m.home_team_api_id OR t.team_api_id = m.away_team_api_id
GROUP BY 
    Team
ORDER BY 
    AvgGoalsPerGame DESC;

	

	
	