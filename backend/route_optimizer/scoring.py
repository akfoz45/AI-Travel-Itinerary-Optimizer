ROUTE_MODE_WEIGHTS = {
    "balanced": {
        "distance_weight": 1.0,
        "score_weight": 0.3,
    },
    "shortest": {
        "distance_weight": 1.5,
        "score_weight": 0.1,
    },
    "recommended": {
        "distance_weight": 0.8,
        "score_weight": 0.6,
    },
}


def calculate_place_score(place, preferred_categories=None, weather_context=None):
    if preferred_categories is None:
        preferred_categories = []

    normalized_preferences = [
        category.strip().lower() for category in preferred_categories
    ]

    score = 0

    if place.category and place.category.lower() in normalized_preferences:
        score += 50
    
    category_score = {
        "Nature": 40,
        "History": 35,
        "Museum": 30,
        "Religious": 20,
        "Tourism": 15,
        "Food": 10,
        "Other": 0,
    }

    score += category_score.get(place.category, 0)

    if place.rating:
        score += place.rating * 5

    if place.source == "manuel":
        score += 10
    elif place.source == "geoapify":
        score += 5

    if place.estimated_visit_duration:
        if 45 <= place.estimated_visit_duration <= 180:
            score += 5
        elif place.estimated_visit_duration > 240:
            score -= 10

    score += calculate_weather_score_adjustment(place=place, weather_context=weather_context)

    return round(score, 2)


def get_route_mode_weights(route_mode):
    if not route_mode:
        route_mode = "balanced"

    normalized_mode = route_mode.lower()

    if normalized_mode not in ROUTE_MODE_WEIGHTS:
        raise ValueError("Invalid route_mode. Allowed values are: balanced, shortest, recommended.")
    
    return ROUTE_MODE_WEIGHTS[normalized_mode]


def get_route_mode_note(route_mode):
    if not route_mode:
        route_mode = "balanced"

    normalized_mode = route_mode.strip().lower()

    notes = {
        "balanced": (
            "This route balances travel distance and recommendation score."
        ),
        "shortest": (
            "This route prioritizes shorter travel distance."
        ),
        "recommended": (
            "This route prioritizes places with higher recommendation scores."
        ),
    }

    if normalized_mode not in notes:
        raise ValueError(
            "Invalid route_mode. Allowed values are: balanced, shortest, recommended."
        )

    return notes[normalized_mode]


def calculate_weather_score_adjustment(place, weather_context=None):
    if not weather_context:
        return 0
    
    category = place.category

    is_rainy = weather_context.get("is_rainy", False)
    is_good_for_outdoor = weather_context.get("is_good_for_outdoor", False)

    outdoor_categories = {"Nature", "Tourism"}

    indoor_friendly_categories = {"Museum", "Religious", "Food"}

    adjustment = 0

    if is_rainy:
        if category in outdoor_categories:
            adjustment -= 25

        if category in indoor_friendly_categories:
            adjustment += 20

    elif is_good_for_outdoor:
        if category == "Nature":
            adjustment += 20

        if category == "Tourism":
            adjustment += 10

    return adjustment