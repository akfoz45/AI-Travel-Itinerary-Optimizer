from .utils import calculate_distance_km

def build_weighted_graph(places):
    """
    Builds a weighted complete graph from a list of places.

    Args:
        places (list): List of Place objects.

    Returns:
        dict: Weighted graph represented as an adjacency dictionary.
    """
    graph = {}

    for origin in places:
        graph[origin.place_name] = {}

        for destination in places:
            if origin.place_id == destination.place_id:
                continue

            distance = calculate_distance_km(
                origin.latitude,
                origin.longitude,
                destination.latitude,
                destination.longitude
            )

            graph[origin.place_name][destination.place_name] = distance
    
    return graph
