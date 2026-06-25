from .utils import calculate_distance_km


def build_distance_matrix(places):
    """
    Builds a distance matrix for a list of places.

    Args:
        places (list): List of Place objects.

    Returns:
        list: Distance matrix as a 2D list.
    """

    matrix = []

    for origin in places:
        row = []

        for destination in places:
            distance = calculate_distance_km(
                origin.latitude,
                origin.longitude,
                destination.latitude,
                destination.longitude
            )

            row.append(distance)

        matrix.append(row)

    return matrix