// ==========================================
// Part 3: Cypher Queries
// ==========================================

// Query 1: Find all movies of the "Thriller" genre with an average rating above 4.0
MATCH (m:Movie)-[:HAS_GENRE]->(g:Genre {name: "Thriller"})
MATCH (u:User)-[r:RATED]->(m)
WITH m, avg(r.rating) AS avgRating, count(r) AS ratingCount
WHERE avgRating > 4.0
RETURN m.movieId AS id, m.title AS title, round(avgRating, 2) AS avgRating, ratingCount
ORDER BY avgRating DESC;


// Query 2: Find users who rated 5 (placed a rating of 5) on more than 50 movies
MATCH (u:User)-[r:RATED]->(m:Movie)
WHERE r.rating = 5
WITH u, count(m) AS ratingCount
WHERE ratingCount > 50
RETURN u.userId AS userId, ratingCount
ORDER BY ratingCount DESC;


// Query 3: Find movies that both users (userId=1 and userId=2) rated highly (rating >= 4)
MATCH (u1:User {userId: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User {userId: 2})
WHERE r1.rating >= 4 AND r2.rating >= 4
RETURN m.movieId AS id, m.title AS title, r1.rating AS user1_rating, r2.rating AS user2_rating;


// Query 4: Find genres whose movies consistently get high ratings — average rating and number of ratings
MATCH (g:Genre)<-[:HAS_GENRE]-(m:Movie)<-[r:RATED]-(u:User)
WITH g, count(r) AS ratingCount, avg(r.rating) AS avgRating
RETURN g.name AS genre, ratingCount, round(avgRating, 2) AS avgRating
ORDER BY avgRating DESC;


// Query 5: Collaborative filtering recommendations: "users with similar tastes also watched"
// For User 1, find movies they haven't watched yet, but which were highly rated by users with similar tastes (similar tastes defined by co-rating the same movies with rating >= 4)
MATCH (u1:User {userId: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND u1 <> u2
WITH u1, u2, count(m) AS similarity
ORDER BY similarity DESC
LIMIT 10
MATCH (u2)-[r3:RATED]->(m2:Movie)
WHERE r3.rating >= 4 AND NOT (u1)-[:RATED]->(m2)
RETURN m2.movieId AS id, m2.title AS title, count(u2) AS recommendationScore, round(avg(r3.rating), 2) AS avgRating
ORDER BY recommendationScore DESC, avgRating DESC
LIMIT 10;


// Query 6: Find the shortest path of communication between two users (e.g. userId=1 and userId=100) through shared movies
MATCH p = shortestPath((u1:User {userId: 1})-[:RATED*..6]-(u2:User {userId: 100}))
RETURN p;
