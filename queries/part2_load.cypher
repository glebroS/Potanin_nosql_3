// ==========================================
// Part 2: Database Setup & Data Loading
// ==========================================

// 1. Create constraints (uniqueness) to optimize searches and prevent duplicates
CREATE CONSTRAINT IF NOT EXISTS FOR (u:User) REQUIRE u.userId IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (m:Movie) REQUIRE m.movieId IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (g:Genre) REQUIRE g.name IS UNIQUE;


// 2. Load Movie nodes (using MERGE to prevent duplicates)
LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
MERGE (m:Movie {movieId: toInteger(row.movieId)})
SET m.title = row.title;


// 3. Load Genre nodes and create HAS_GENRE relationships
LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
WITH row, split(row.genres, '|') AS genreList
UNWIND genreList AS genreName
MERGE (g:Genre {name: genreName})
WITH row, g
MATCH (m:Movie {movieId: toInteger(row.movieId)})
MERGE (m)-[:HAS_GENRE]->(g);


// 4. Load User nodes (excluding zip code)
LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (u:User {userId: toInteger(row.userId)})
SET u.gender = row.gender,
    u.age = toInteger(row.age),
    u.occupation = toInteger(row.occupation);


// 5. Load Rating relationships using apoc.periodic.iterate (batch size 10000, parallel: false)
// We use parallel: false to prevent write locks and deadlocks since multiple threads
// might try to update the same nodes or create overlapping relationships concurrently.
CALL apoc.periodic.iterate(
  "LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS row RETURN row",
  "MATCH (u:User {userId: toInteger(row.userId)})
   MATCH (m:Movie {movieId: toInteger(row.movieId)})
   MERGE (u)-[r:RATED]->(m)
   SET r.rating = toInteger(row.rating),
       r.timestamp = toInteger(row.timestamp)",
  {batchSize: 10000, parallel: false}
)
YIELD batches, total, errorMessages;
