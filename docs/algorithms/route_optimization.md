# Route Optimization

## Purpose

This document describes how the AI-Powered Travel Planner generates optimized travel itineraries.

The goal is not simply finding the shortest path between two locations.

The objective is to generate the best travel experience by considering:

* Distance
* Travel time
* User preferences
* Place popularity
* Weather conditions
* Daily time constraints

---

# Problem Definition

Given a set of places:

```text
Kotor Old Town
Kotor Fortress
Perast
Budva Old Town
Sveti Stefan
Tivat
Durmitor National Park
```

The system must determine:

1. Which places should be visited.
2. In what order they should be visited.
3. On which day they should be visited.

---

# Graph Construction

Each place becomes a node.

```text
Node = Place
```

Connections between places become edges.

```text
Edge = Travel Connection
```

The graph is modeled as a Complete Graph.

This means every place is connected to every other place.

Example:

```text
Kotor ↔ Perast
Kotor ↔ Budva
Kotor ↔ Tivat
Kotor ↔ Durmitor
...
```

This approach allows the optimizer to evaluate all possible travel routes.

---

# Why Dijkstra Is Not Enough

Dijkstra solves:

```text
Find the shortest path
from A to B
```

Example:

```text
Hotel → Kotor Fortress
```

However, our system must solve:

```text
Hotel
↓
Place 1
↓
Place 2
↓
Place 3
↓
Place 4
↓
Hotel
```

This is a route planning problem rather than a shortest path problem.

Therefore Dijkstra alone cannot generate a complete itinerary.

---

# Traveling Salesman Problem (TSP)

The itinerary generation process is closer to the Traveling Salesman Problem.

The optimizer must determine:

* Visit order
* Total travel cost
* Efficient route sequence

Example:

Bad Route:

```text
Kotor
↓
Budva
↓
Perast
↓
Tivat
```

Optimized Route:

```text
Kotor
↓
Perast
↓
Tivat
↓
Budva
```

The second route minimizes unnecessary travel.

---

# Route Scoring

Each place receives a score.

Example:

```text
Final Score =
Preference Score
+ Popularity Score
+ Weather Score
```

---

## Preference Score

Matches user interests.

Example:

User preferences:

```text
Nature
History
```

Scores:

```text
Kotor Fortress = 9
Durmitor National Park = 10
Shopping Mall = 2
```

---

## Popularity Score

Derived from ratings and reviews.

Example:

```text
Google Rating = 4.8
```

Higher ratings increase priority.

---

## Weather Score

Weather affects outdoor activities.

Example:

```text
Sunny Day:
Durmitor = +5

Rainy Day:
Durmitor = -5
```

---

# Daily Planning

After optimization, places are divided into days.

Example:

Trip Duration:

```text
3 Nights
4 Days
```

Generated Plan:

Day 1:

* Kotor Old Town
* Kotor Fortress
* Perast

Day 2:

* Tivat
* Budva Old Town

Day 3:

* Sveti Stefan

Day 4:

* Departure Activities

---

# Route Generation Pipeline

Step 1

Retrieve places from external APIs.

↓

Step 2

Build graph nodes.

↓

Step 3

Generate distance matrix.

↓

Step 4

Create weighted graph.

↓

Step 5

Calculate place scores.

↓

Step 6

Apply TSP-style optimization.

↓

Step 7

Split itinerary into days.

↓

Step 8

Generate RouteItem records.

↓

Step 9

Return JSON response.

---

# Future Improvements

The first version will use:

* Distance
* Preferences
* Popularity
* Weather

Future versions may include:

* Traffic information
* Public transportation
* Hotel proximity
* Opening hours
* Crowd prediction
* Real-time events

```
```
