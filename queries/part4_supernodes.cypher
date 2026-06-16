// ==========================================
// Part 4: Supernodes Detection & Analysis
// ==========================================

// 1. Identify Top 10 Movie Supernodes (Movies with highest incoming degree)
MATCH (m:Movie)<-[r:RATED]-()
RETURN m.movieId AS id, m.title AS title, count(r) AS degree
ORDER BY degree DESC
LIMIT 10;


// 2. Identify Top 10 User Supernodes (Users with highest outgoing degree)
MATCH (u:User)-[r:RATED]->()
RETURN u.userId AS id, count(r) AS degree
ORDER BY degree DESC
LIMIT 10;


// 3. Identify Genre Node Degrees (Connecting movies to genres)
MATCH (g:Genre)<-[r:HAS_GENRE]-()
RETURN g.name AS name, count(r) AS degree
ORDER BY degree DESC;


// 4. Calculate Average Node Degrees for Reference
// Average ratings per User (outgoing degree)
MATCH (u:User)-[r:RATED]->()
WITH u, count(r) AS degree
RETURN round(avg(degree), 2) AS avgUserDegree;

// Average ratings per Movie (incoming degree)
MATCH (m:Movie)<-[r:RATED]-()
WITH m, count(r) AS degree
RETURN round(avg(degree), 2) AS avgMovieDegree;
