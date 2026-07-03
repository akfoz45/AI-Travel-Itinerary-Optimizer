from datetime import timedelta
from django.db import transaction
from django.db.models import Q

from trips.models import DayPlan, RouteItem, Hotel
from places.models import Place
from route_optimizer.utils import calculate_distance_km
from route_optimizer.graph_builder import build_weighted_graph
from route_optimizer.time_estimator import (
    estimate_travel_time_minutes,
    add_minutes_to_time,
)
from route_optimizer.scoring import calculate_place_score, get_route_mode_note
from weather.weather_service import OpenMeteoWeatherService
from route_optimizer.score_based_route import score_based_nearest_neighbor_route


def filter_places_by_categories(categories):
    places_queryset = Place.objects.all()

    if not categories:
        return places_queryset
    
    query = Q()

    for category in categories:
        query |= Q(category__iexact=category)

    return places_queryset.filter(query)


def find_place_name_case_insensitive(places, start_place):
    for place in places:
        if place.place_name.lower() == start_place.lower():
            return place.place_name
        
    return None


def prepare_route_data(
    start_place,
    categories,
    hotel=None,
    distance_weight=1.0,
    score_weight=0.3,
    weather_context=None,
):
    """
    Prepares common route data.

    This function:
    - filters places by categories
    - validates start place
    - builds weighted graph
    - generates ordered route
    - creates place map
    """

    places_queryset = filter_places_by_categories(categories)
    places = list(places_queryset)

    for place in places:
        place.recommendation_score = calculate_place_score(
            place, 
            preferred_categories=categories, 
            weather_context=weather_context
            )

    if not places:
        raise ValueError("No places found for given categories.")
    
    place_names = [place.place_name for place in places]

    if start_place:
        matched_start_place = find_place_name_case_insensitive(places, start_place)            

        if matched_start_place is None:
            raise ValueError(f"Start place not found in selected places. Available places: {place_names}") 
        
    else:
        if hotel is None:
            raise ValueError(
            "Start place is required when trip has no hotel."
        )

        nearest_place = find_nearest_place_to_hotel(hotel=hotel, places=places)

        if nearest_place is None:
            raise ValueError("No suitable start place found.")
        
        matched_start_place = nearest_place.place_name
    
    graph = build_weighted_graph(places)
    route = score_based_nearest_neighbor_route(
        graph=graph, 
        places=places,
        start_node=matched_start_place,
        distance_weight=distance_weight,
        score_weight=score_weight
        )

    place_map = {place.place_name: place for place in places}

    return {
        "places": places,
        "place_name": place_names,
        "matched_start_place": matched_start_place,
        "graph": graph,
        "route": route,
        "place_map": place_map,
    }


def prepare_places_for_route(categories):
    places_queryset = filter_places_by_categories(categories)
    places = list(places_queryset)

    if not places:
        raise ValueError("No places found for given categories.")

    return places

def generate_full_route_for_trip(
    trip,
    start_place,
    categories,
    start_time,
    end_time,
    distance_weight=1.0,
    score_weight=0.3,
    route_mode="balanced"
):
    """
    Generates a full multi-day route for a trip.

    Daily weather-aware version:
    - gets forecast for trip date range
    - calculates recommendation scores separately for each day
    - generates a new score-based route for each day
    - removes planned places from remaining_places
    """

    hotel = get_trip_hotel(trip)

    if not hotel and not start_place:
        raise ValueError("Start place is required when trip has no hotel.")

    forecast_by_date = get_weather_forecast_context_for_trip(trip)

    if forecast_by_date is None:
        forecast_by_date = {}

    first_day_weather_context = get_weather_context_for_date(
        forecast_by_date=forecast_by_date,
        date=trip.start_date,
    )

    places = prepare_places_for_route(categories)
    remaining_places = places.copy()

    total_days = (trip.end_date - trip.start_date).days + 1

    if total_days <= 0:
        raise ValueError("Trip date range is invalid.")

    created_day_plans = []

    total_distance_km = 0
    total_travel_time_minutes = 0
    total_visit_duration_minutes = 0
    total_route_items = 0
    total_return_to_hotel_minutes = 0
    total_return_to_hotel_distance_km = 0

    selected_start_place = None

    with transaction.atomic():
        existing_day_plans = DayPlan.objects.filter(trip=trip)
        existing_day_plans.delete()

        for day_offset in range(total_days):
            if not remaining_places:
                break

            current_date = trip.start_date + timedelta(days=day_offset)

            daily_weather_context = get_weather_context_for_date(
                forecast_by_date=forecast_by_date,
                date=current_date,
            )

            daily_route_data = generate_weather_aware_route_for_day(
                places=remaining_places,
                categories=categories,
                start_place=start_place if day_offset == 0 else None,
                hotel=hotel,
                weather_context=daily_weather_context,
                distance_weight=distance_weight,
                score_weight=score_weight,
            )

            graph = daily_route_data["graph"]
            route = daily_route_data["route"]
            place_map = daily_route_data["place_map"]
            matched_start_place = daily_route_data["matched_start_place"]

            if selected_start_place is None:
                selected_start_place = matched_start_place

            day_plan = DayPlan.objects.create(
                trip=trip,
                day_number=day_offset + 1,
                date=current_date
            )

            current_time = start_time
            visit_order = 1
            route_items = []

            daily_distance_km = 0
            daily_travel_time_minutes = 0
            daily_visit_duration_minutes = 0

            previous_place_name = None

            for place_name in route:
                place = place_map[place_name]

                if visit_order == 1:
                    if hotel:
                        distance_km = calculate_distance_from_hotel_to_place(
                            hotel,
                            place
                        )
                        travel_minutes = estimate_travel_time_minutes(distance_km)
                        arrival_time = add_minutes_to_time(
                            current_time,
                            travel_minutes
                        )
                    else:
                        distance_km = 0
                        travel_minutes = 0
                        arrival_time = current_time
                else:
                    distance_km = graph[previous_place_name][place_name]
                    travel_minutes = estimate_travel_time_minutes(distance_km)
                    arrival_time = add_minutes_to_time(
                        current_time,
                        travel_minutes
                    )

                visit_duration = place.estimated_visit_duration or 60
                departure_time = add_minutes_to_time(arrival_time, visit_duration)

                if hotel:
                    return_distance_km = calculate_distance_from_place_to_hotel(
                        place,
                        hotel
                    )
                    return_minutes = estimate_travel_time_minutes(return_distance_km)
                    estimated_day_finish_time = add_minutes_to_time(
                        departure_time,
                        return_minutes
                    )
                else:
                    return_distance_km = 0
                    return_minutes = 0
                    estimated_day_finish_time = departure_time

                if estimated_day_finish_time > end_time:
                    break

                route_item = RouteItem.objects.create(
                    day_plan=day_plan,
                    place=place,
                    visit_order=visit_order,
                    arrival_time=arrival_time,
                    departure_time=departure_time
                )

                route_item.recommendation_score = getattr(
                    place,
                    "recommendation_score",
                    None
                )

                route_items.append(route_item)

                if place in remaining_places:
                    remaining_places.remove(place)

                total_distance_km += distance_km
                total_travel_time_minutes += travel_minutes
                total_visit_duration_minutes += visit_duration
                total_route_items += 1

                daily_distance_km += distance_km
                daily_travel_time_minutes += travel_minutes
                daily_visit_duration_minutes += visit_duration

                previous_place_name = place_name
                visit_order += 1
                current_time = departure_time

            daily_return_to_hotel_distance_km = 0
            daily_return_to_hotel_minutes = 0

            if route_items and hotel:
                last_place = route_items[-1].place

                daily_return_to_hotel_distance_km = (
                    calculate_distance_from_place_to_hotel(last_place, hotel)
                )

                daily_return_to_hotel_minutes = estimate_travel_time_minutes(
                    daily_return_to_hotel_distance_km
                )

                total_return_to_hotel_distance_km += daily_return_to_hotel_distance_km
                total_return_to_hotel_minutes += daily_return_to_hotel_minutes

            if not route_items:
                day_plan.delete()
            else:
                day_plan.daily_summary = {
                    "day_number": day_offset + 1,
                    "date": current_date,
                    "number_of_places": len(route_items),
                    "total_distance_km": round(daily_distance_km, 2),
                    "total_travel_time_minutes": daily_travel_time_minutes,
                    "total_visit_duration_minutes": daily_visit_duration_minutes,
                    "return_to_hotel_distance_km": round(
                        daily_return_to_hotel_distance_km,
                        2
                    ),
                    "return_to_hotel_minutes": daily_return_to_hotel_minutes,
                    "route_algorithm": "daily_weather_aware_score_based_nearest_neighbor",
                    "weather_used_for_scoring": daily_weather_context is not None,
                    "weather_context": daily_weather_context,
                    "weather_note": get_weather_note_for_context(
                        daily_weather_context
                    ),
                }

                created_day_plans.append(day_plan)

        if not created_day_plans:
            raise ValueError("Daily time window is too short for selected places.")

    unplanned_place_names = [
        place.place_name
        for place in remaining_places
    ]

    summary = {
        "generated_days": len(created_day_plans),
        "number_of_places": total_route_items,
        "total_distance_km": round(total_distance_km, 2),
        "total_travel_time_minutes": total_travel_time_minutes,
        "total_visit_duration_minutes": total_visit_duration_minutes,
        "return_to_hotel_distance_km": round(total_return_to_hotel_distance_km, 2),
        "return_to_hotel_minutes": total_return_to_hotel_minutes,
        "total_plan_duration_minutes": (
            total_travel_time_minutes
            + total_visit_duration_minutes
            + total_return_to_hotel_minutes
        ),
        "unplanned_place_count": len(unplanned_place_names),
        "unplanned_places": unplanned_place_names,
        "hotel_used_as_start": hotel.name if hotel else None,
        "selected_start_place": selected_start_place,
        "start_place_source": (
            "hotel_nearest_place"
            if not start_place and hotel
            else "user_input"
        ),
        "route_algorithm": "daily_weather_aware_score_based_nearest_neighbor",
        "route_mode": route_mode,
        "route_quality_note": get_route_mode_note(route_mode),
        "distance_weight": distance_weight,
        "score_weight": score_weight,
        "weather_source": "forecast",
        "weather_forecast_available": bool(forecast_by_date),
        "weather_forecast_dates": list(forecast_by_date.keys()),
        "weather_used_for_scoring": first_day_weather_context is not None,
        "weather_context": first_day_weather_context,
        "weather_note": get_weather_note_for_context(first_day_weather_context),
    }

    return {
        "day_plans": created_day_plans,
        "summary": summary,
        "total_days": total_days,
    }


def generate_day_route_for_trip(
    trip,
    start_place,
    categories,
    day_number,
    date,
    start_time,
    end_time,
    distance_weight=1.0,
    score_weight=0.3,
    route_mode="balanced",
):
    """
    Generates a route for a single day of a trip.

    This function:
    - filters places by categories
    - builds a weighted graph
    - generates an ordered route using nearest neighbor
    - creates one DayPlan
    - creates RouteItem records
    - returns created day plan and summary data
    """
    hotel = get_trip_hotel(trip)

    if not hotel and not start_place:
        return ValueError("Start place is required when trip has no hotel.")
    
    forecast_by_date = get_weather_forecast_context_for_trip(trip)

    weather_context = get_weather_context_for_date(
        forecast_by_date=forecast_by_date,
        date=date
    )

    route_data = prepare_route_data(
        start_place=start_place,
        categories=categories,
        hotel=hotel,
        distance_weight=distance_weight,
        score_weight=score_weight,
        weather_context=weather_context,
    )

    graph = route_data["graph"]
    route = route_data["route"]
    place_map = route_data["place_map"]
    matched_start_place = route_data["matched_start_place"]

    hotel = get_trip_hotel(trip)

    total_distance_km = 0
    total_travel_time_minutes = 0
    total_visit_duration_minutes = 0
    total_return_to_hotel_minutes = 0
    total_return_to_hotel_distance_km = 0

    with transaction.atomic():
        existing_day_plan = DayPlan.objects.filter(
            trip=trip,
            day_number=day_number
        ).first()

        if existing_day_plan:
            existing_day_plan.delete()

        day_plan = DayPlan.objects.create(
            trip=trip,
            day_number=day_number,
            date=date
        )

        route_items = []

        current_time = start_time
        visit_order = 1
        route_index = 0

        while route_index < len(route):
            place_name = route[route_index]
            place = place_map[place_name]

            if visit_order == 1:
                if hotel:
                    distance_km = calculate_distance_from_hotel_to_place(hotel, place)
                    travel_minutes = estimate_travel_time_minutes(distance_km)
                    arrival_time = add_minutes_to_time(current_time, travel_minutes)
                else:
                    arrival_time = current_time
                    distance_km = 0
                    travel_minutes = 0
            else:
                previous_place_name = route[route_index - 1]
                distance_km = graph[previous_place_name][place_name]
                travel_minutes = estimate_travel_time_minutes(distance_km)
                arrival_time = add_minutes_to_time(current_time, travel_minutes)

            visit_duration = place.estimated_visit_duration or 60
            departure_time = add_minutes_to_time(arrival_time, visit_duration)

            if hotel:
                return_distance_km = calculate_distance_from_place_to_hotel(place, hotel)
                return_minutes = estimate_travel_time_minutes(return_distance_km)
                estimated_day_finish_time = add_minutes_to_time(departure_time, return_minutes)
            else:
                return_distance_km = 0
                return_minutes = 0
                estimated_day_finish_time = departure_time

            if estimated_day_finish_time > end_time:
                break

            route_item = RouteItem.objects.create(
                day_plan=day_plan,
                place=place,
                visit_order=visit_order,
                arrival_time=arrival_time,
                departure_time=departure_time
            )

            route_item.recommendation_score = getattr(place, "recommendation_score", None)

            route_items.append(route_item)

            total_distance_km += distance_km
            total_travel_time_minutes += travel_minutes
            total_visit_duration_minutes += visit_duration

            visit_order += 1
            current_time = departure_time
            route_index += 1

        if not route_items:
            raise ValueError("Daily time window is too short for selected places.")

    unplanned_place_names = route[route_index:]

    if route_items and hotel:
        last_place = route_items[-1].place

        total_return_to_hotel_distance_km = calculate_distance_from_place_to_hotel(last_place, hotel)
        total_return_to_hotel_minutes = estimate_travel_time_minutes(total_return_to_hotel_distance_km)

    summary = {
        "total_distance_km": round(total_distance_km, 2),
        "total_travel_time_minutes": total_travel_time_minutes,
        "total_visit_duration_minutes": total_visit_duration_minutes,
        "total_plan_duration_minutes": (total_travel_time_minutes + total_visit_duration_minutes),
        "number_of_places": len(route_items),
        "unplanned_place_count": len(unplanned_place_names),
        "unplanned_places": unplanned_place_names,
        "hotel_used_as_start": hotel.name if hotel else None,
        "selected_start_place": matched_start_place,
        "start_place_source": "hotel_nearest_place" if not start_place and hotel else "user_input",
        "return_to_hotel_distance_km": round(total_return_to_hotel_distance_km, 2),
        "return_to_hotel_minutes": total_return_to_hotel_minutes,
        "total_plan_duration_minutes": (total_travel_time_minutes + total_visit_duration_minutes + total_return_to_hotel_minutes),
        "route_algorithm": "forecast_aware_score_based_nearest_neighbor",
        "route_mode": route_mode,
        "route_quality_note": get_route_mode_note(route_mode),
        "distance_weight": distance_weight,
        "score_weight": score_weight,
        "weather_source": "forecast",
        "weather_forecast_available": bool(forecast_by_date),
        "weather_forecast_dates": list(forecast_by_date.keys()),
        "weather_context": weather_context,
        "weather_used_for_scoring": weather_context is not None,
        "weather_note": get_weather_note_for_context(weather_context),
    }

    return {
        "day_plan": day_plan,
        "summary": summary,
    }

def get_trip_hotel(trip):
    """
    Returns the first hotel for a trip.
    If no hotel exists, returns None.
    """

    return Hotel.objects.filter(trip=trip).first()


def calculate_distance_from_hotel_to_place(hotel, place):
    return calculate_distance_km(
        hotel.latitude,
        hotel.longitude,
        place.latitude,
        place.longitude
    )


def calculate_distance_from_place_to_hotel(place, hotel):
    return calculate_distance_km(
        place.latitude,
        place.longitude,
        hotel.latitude,
        hotel.longitude,
    )


def find_nearest_place_to_hotel(hotel, places):
    nearest_place = None
    nearest_distance = float("inf")

    for place in places:
        distance = calculate_distance_from_hotel_to_place(hotel, place)

        if distance < nearest_distance:
            nearest_distance = distance
            nearest_place = place

    return nearest_place

def get_weather_context_for_trip(trip):
    hotel = get_trip_hotel(trip)

    if not hotel:
        return None
    
    try:
        weather_service = OpenMeteoWeatherService()

        weather_context = weather_service.get_current_weather_by_coordinates(
            latitude=hotel.latitude,
            longitude=hotel.longitude
        )

        return weather_context
    
    except Exception:
        return None
    

def get_weather_note_for_context(weather_context):
    try:
        weather_service = OpenMeteoWeatherService()
        return weather_service.get_weather_note(weather_context)
    except Exception:
        return "Weather note could not be generated."
    

def get_weather_forecast_context_for_trip(trip):
    """
    Gets daily weather forecast for the trip date range.

    If the trip has a hotel, hotel coordinates are used.
    If weather forecast cannot be fetched, an empty dictionary is returned.
    """

    hotel = get_trip_hotel(trip)

    if not hotel:
        return {}
    
    try:
        weather_service = OpenMeteoWeatherService()

        forecast_result = weather_service.get_daily_forecast_by_coordinates(
            latitude=hotel.latitude,
            longitude=hotel.longitude,
            start_date=trip.start_date.isoformat(),
            end_date=trip.end_date.isoformat()
        )

        daily_forecast = forecast_result.get("daily_forecast", [])

        forecast_by_date = {}

        for daily_weather in daily_forecast:
            forecast_by_date[daily_weather["date"]] = daily_weather

        return forecast_by_date
    
    except Exception:
        return {}
    
def get_weather_context_for_date(forecast_by_date, date):
    """
    Returns weather context for a specific date.
    """ 

    if not forecast_by_date:
         return None
    
    date_key = date.isoformat()

    return forecast_by_date.get(date_key)


def apply_recommendation_scores_to_places(places, categories, weather_context=None):
    """
    Applies temporary recommendation_score to places.
    Scores are calculated according to categories and weather context.
    """
    for place in places:
        place.recommendation_score = calculate_place_score(place, preferred_categories=categories, weather_context=weather_context)

    return places

def generate_weather_aware_route_for_day(
    places,
    categories,
    start_place,
    hotel,
    weather_context,
    distance_weight=1.0,
    score_weight=0.3,
):
    """
    Generates a route for one day using that day's weather context.
    """

    scored_places = apply_recommendation_scores_to_places(
        places=places,
        categories=categories,
        weather_context=weather_context,
    )

    if start_place:
        matched_start_place = find_place_name_case_insensitive(
            scored_places,
            start_place,
        )

        if not matched_start_place:
            raise ValueError(f"Start place '{start_place}' was not found.")

    else:
        if hotel:
            nearest_place = find_nearest_place_to_hotel(
                hotel=hotel,
                places=scored_places,
            )

            matched_start_place = nearest_place.place_name
        else:
            best_place = max(
                scored_places,
                key=lambda place: getattr(place, "recommendation_score", 0)
            )

            matched_start_place = best_place.place_name

    graph = build_weighted_graph(scored_places)

    route = score_based_nearest_neighbor_route(
        graph=graph,
        places=scored_places,
        start_node=matched_start_place,
        distance_weight=distance_weight,
        score_weight=score_weight,
    )

    place_map = {
        place.place_name: place
        for place in scored_places
    }

    return {
        "matched_start_place": matched_start_place,
        "graph": graph,
        "route": route,
        "place_map": place_map,
    }