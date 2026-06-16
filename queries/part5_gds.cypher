// ==========================================
// Part 5: Graph Data Science (GDS) Algorithms
// ==========================================

// ------------------------------------------
// 5.1. PageRank on Movie Graph
// ------------------------------------------

// Step 1: Materialize movie-movie edges (CO_RATED) through shared users
MATCH (m1:Movie)<-[r1:RATED]-(u:User)-[r2:RATED]->(m2:Movie)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(m1) < id(m2)
WITH m1, m2, count(u) AS weight
WHERE size([(m1)<-[:RATED]-() | 1]) > 20
  AND size([(m2)<-[:RATED]-() | 1]) > 20
WITH m1, m2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (m1)-[co:CO_RATED]-(m2)
SET co.weight = weight;

// Step 2: Create projection for PageRank
CALL gds.graph.project(
  'movieGraph',
  'Movie',
  { CO_RATED: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// Step 3: Run PageRank on the projected movie graph
CALL gds.pageRank.stream('movieGraph', {
  relationshipWeightProperty: 'weight',
  maxIterations: 20,
  dampingFactor: 0.85
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).title AS title, score
ORDER BY score DESC
LIMIT 15;

// Step 4: Drop the projection and clean up materialized relationships
CALL gds.graph.drop('movieGraph', false);
MATCH ()-[co:CO_RATED]-() DELETE co;


// ------------------------------------------
// 5.2. Louvain Community Detection
// ------------------------------------------

// Step 1: Materialize user-user similarity edges (SIMILAR) through shared movies
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight,
    sim.cost = 1000.0 / toFloat(weight); // pre-calculate cost for Dijkstra

// Step 2: Create projection for Louvain
CALL gds.graph.project(
  'userSimilarity',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: ['weight', 'cost'] } }
)
YIELD graphName, nodeCount, relationshipCount;

// Step 3: Run Louvain community detection and stream community sizes
CALL gds.louvain.stream('userSimilarity', {
  relationshipWeightProperty: 'weight'
})
YIELD nodeId, communityId
RETURN communityId, count(*) AS communitySize
ORDER BY communitySize DESC
LIMIT 10;

// Step 4: Write communityId to User nodes to aggregate top genres per community
CALL gds.louvain.write('userSimilarity', {
  relationshipWeightProperty: 'weight',
  writeProperty: 'communityId'
})
YIELD communityCount, modularity;

// Aggregate top 3 genres for each of the top communities
MATCH (u:User)-[r:RATED]->(m:Movie)-[:HAS_GENRE]->(g:Genre)
WHERE r.rating >= 4 AND u.communityId IS NOT NULL
WITH u.communityId AS community, g.name AS genre, count(r) AS genreCount
ORDER BY community ASC, genreCount DESC
WITH community, collect({genre: genre, count: genreCount})[..3] AS topGenres
RETURN community, topGenres
ORDER BY community ASC;

// Step 5: Clean up projection and properties
CALL gds.graph.drop('userSimilarity', false);
MATCH ()-[sim:SIMILAR]-() DELETE sim;
MATCH (u:User) REMOVE u.communityId;


// ------------------------------------------
// 5.3. Dijkstra Shortest Path between Users
// ------------------------------------------

// Step 1: Re-create SIMILAR relationships
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight,
    sim.cost = 1000.0 / toFloat(weight);

// Step 2: Create userGraph projection
CALL gds.graph.project(
  'userGraph',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: ['weight', 'cost'] } }
)
YIELD graphName, nodeCount, relationshipCount;

// Step 3: Run Dijkstra shortest path between User 1 and User 100
MATCH (source:User {userId: 1}), (target:User {userId: 100})
CALL gds.shortestPath.dijkstra.stream('userGraph', {
  sourceNode: source,
  targetNode: target,
  relationshipWeightProperty: 'cost'
})
YIELD index, sourceNode, targetNode, totalCost, nodeIds, costs
RETURN 
  index,
  gds.util.asNode(sourceNode).userId AS sourceUserId,
  gds.util.asNode(targetNode).userId AS targetUserId,
  round(totalCost, 2) AS totalCost,
  [nodeId in nodeIds | gds.util.asNode(nodeId).userId] AS pathUserIds,
  [c in costs | round(c, 2)] AS incrementalCosts;

// Step 4: Drop userGraph projection and clean up
CALL gds.graph.drop('userGraph', false);
MATCH ()-[sim:SIMILAR]-() DELETE sim;
