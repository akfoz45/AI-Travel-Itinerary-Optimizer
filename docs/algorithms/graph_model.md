# Graph Model

## Purpose

This document explains how graph theory is used within the AI-Powered Travel Planner.

The route optimization engine represents locations as graph nodes and travel connections as graph edges.

The generated graph is used to create efficient travel itineraries.

---

# Why Graph Theory?

Travel planning is fundamentally a graph problem.

Each place becomes a node.

Each connection between places becomes an edge.

The goal is to find the most efficient route while considering:

* Distance
* Travel time
* User preferences
* Popularity
* Weather conditions

---

# Graph Representation

## Node

A node represents a place.

Examples:

* Kotor Old Town
* Kotor Fortress
* Perast
* Budva Old Town
* Sveti Stefan

```text
Node = Place
```

---

## Edge

An edge represents the connection between two places.

Examples:

```text
Kotor Old Town → Kotor Fortress

Distance: 1.2 km
Travel Time: 15 min
```

```text
Perast → Budva

Distance: 23 km
Travel Time: 30 min
```

---

# Montenegro Example

```text
Kotor Old Town
      |
      |
      |
Kotor Fortress
      |
      |
      |
Perast
      |
      |
      |
Budva Old Town
```

---

# Weighted Graph

The graph is weighted.

Each edge receives a score.

Example:

```text
Weight = Distance + Travel Time
```

Later versions may include:

```text
Weight =
Distance
+ Travel Time
+ Weather Penalty
- Popularity Bonus
```

---

# Distance Matrix

The routing service generates a distance matrix.

Example:

```
            Kotor   Fortress   Perast
```

Kotor           0       1.2        12

Fortress        1.2     0          13

Perast          12      13         0

This matrix becomes the foundation of the graph.

---

# Adjacency List

Internally the graph can be stored as:

```text
Kotor:
    Fortress (1.2)

Fortress:
    Kotor (1.2)
    Perast (13)

Perast:
    Fortress (13)
```

This representation is memory efficient.

---

# Route Generation Pipeline

1. Retrieve places from Google Places API.
2. Build nodes.
3. Calculate pairwise distances.
4. Create weighted graph.
5. Apply optimization algorithms.
6. Generate itinerary.

---

# Role in the System

Graph construction is the first step of route optimization.

The generated graph is later consumed by:

* Dijkstra Algorithm
* A* Search
* TSP Approximation
* Daily Planner
