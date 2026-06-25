def near_neighbor_route(graph, start_node):
    """
    Generates a route using the nearest neighbor algorithm.

    Args:
        graph (dict): Weighted graph represented as adjacency dictionary.
        start_node (str): Starting node name.

    Returns:
        list: Ordered route as a list of node names.
    """

    if start_node not in graph:
        raise ValueError(f"Start node '{start_node}' does not exist in graph.")
    
    visited = set()
    route = []

    current_node = start_node

    while len(visited) < len(graph):
        visited.add(current_node)
        route.append(current_node)

        neighbors = graph[current_node]

        nearest_node = None
        nearest_distance = float("inf")
        
        for neighbor, distance in neighbors.items():
            if neighbor not in visited and distance < nearest_distance:
                nearest_node = neighbor
                nearest_distance = distance

        if nearest_node is None:
            break

        current_node = nearest_node

    return route