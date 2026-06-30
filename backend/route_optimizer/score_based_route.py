def score_based_nearest_neighbor_route(graph, places, start_node, distance_weight=1.0, score_weight=0.3):
    if start_node not in graph:
        raise ValueError(f"Start node '{start_node}' does not exist in graph.")
    
    place_map = {place.place_name: place for place in places}

    visited = set()
    route = []
    current_node = start_node

    while len(visited) < len(graph):
        visited.add(current_node)
        route.append(current_node)

        neighbors = graph[current_node]

        best_node = None
        best_cost = float("inf")

        for neighbor, distance in neighbors.items():
            if neighbor in visited:
                continue

            neighbor_place = place_map.get(neighbor)

            recommendation_score = getattr(neighbor_place, "recommendation_score", 0)

            route_cost = (distance_weight * distance - score_weight * recommendation_score)

            if route_cost < best_cost:
                best_cost = route_cost
                best_node = neighbor

        if best_node is None:
            break
            
        current_node = best_node

    return route