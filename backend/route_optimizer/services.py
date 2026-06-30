from datetime import timedelta
from django.db import transaction
from django.db.models import Q

from trips.models import DayPlan, RouteItem, Hotel
from places.models import Place
from route_optimizer.utils import calculate_distance_km
from route_optimizer.graph_builder import build_weighted_graph
from route_optimizer.nearest_neighbor import nearest_neighbor_route
from route_optimizer.time_estimator import (
    estimate_travel_time_minutes,
    add_minutes_to_time,
)
from route_optimizer.scoring import calculate_place_score, get_route_mode_note
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
        place.recommendation_score = calculate_place_score(place, preferred_categories=categories)

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

    This function:
    - filters places by categories
    - builds a weighted graph
    - generates an ordered route using nearest neighbor
    - splits the route into trip days
    - creates DayPlan and RouteItem records
    - returns generated day plans and summary data
    """

    hotel = get_trip_hotel(trip)

    route_data = prepare_route_data(
        start_place=start_place,
        categories=categories,
        hotel=hotel,
        distance_weight=distance_weight,
        score_weight=score_weight,
    )

    graph = route_data["graph"]
    route = route_data["route"]
    place_map = route_data["place_map"]
    matched_start_place = route_data["matched_start_place"]

    hotel = get_trip_hotel(trip)

    total_days = (trip.end_date - trip.start_date).days + 1

    if total_days <= 0:
        raise ValueError("Trip date range is invalid.")

    route_index = 0
    created_day_plans = []

    total_distance_km = 0
    total_travel_time_minutes = 0
    total_visit_duration_minutes = 0
    total_route_items = 0
    total_return_to_hotel_minutes = 0
    total_return_to_hotel_distance_km = 0

    with transaction.atomic():
        existing_day_plans = DayPlan.objects.filter(trip=trip)
        existing_day_plans.delete()

        for day_offset in range(total_days):
            if route_index >= len(route):
                break

            current_date = trip.start_date + timedelta(days=day_offset)
            day_number = day_offset + 1

            day_plan = DayPlan.objects.create(
                trip=trip,
                day_number=day_number,
                date=current_date
            )

            current_time = start_time
            visit_order = 1
            route_items = []

            daily_distance_km = 0
            daily_travel_time_minutes = 0
            daily_visit_duration_minutes = 0

            while route_index < len(route):
                place_name = route[route_index]
                place = place_map[place_name]

                if visit_order == 1:
                    if hotel:
                        distance_km = calculate_distance_from_hotel_to_place(hotel, place)
                        travel_minutes = estimate_travel_time_minutes(distance_km)
                        arrival_time = add_minutes_to_time(current_time, travel_minutes)
                    else:
                        distance_km = 0
                        travel_minutes = 0
                        arrival_time = current_time
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
                total_route_items += 1

                daily_distance_km += distance_km
                daily_travel_time_minutes += travel_minutes
                daily_visit_duration_minutes += visit_duration

                visit_order += 1
                current_time = departure_time
                route_index += 1

            daily_return_to_hotel_distance_km = 0
            daily_return_to_hotel_minutes = 0

            if route_items and hotel:
                last_place = route_items[-1].place
                daily_return_to_hotel_distance_km = calculate_distance_from_place_to_hotel(
                    last_place,
                    hotel
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
                    "number_of_places": len(route_items),
                    "total_distance_km": round(daily_distance_km, 2),
                    "travel_time_minutes": daily_travel_time_minutes,
                    "visit_duration_minutes": daily_visit_duration_minutes,
                    "return_to_hotel_distance_km": round(daily_return_to_hotel_distance_km, 2),
                    "return_to_hotel_minutes": daily_return_to_hotel_minutes,
                    "total_day_duration_minutes": (
                        daily_travel_time_minutes
                        + daily_visit_duration_minutes
                        + daily_return_to_hotel_minutes
                    ),
               }
                created_day_plans.append(day_plan)

        if not created_day_plans:
            raise ValueError("Daily time window is too short for selected places.")

    unplanned_place_names = route[route_index:]

    summary = {
        "generated_days": len(created_day_plans),
        "number_of_places": total_route_items,
        "total_distance_km": round(total_distance_km, 2),
        "total_travel_time_minutes": total_travel_time_minutes,
        "total_visit_duration_minutes": total_visit_duration_minutes,
        "return_to_hotel_distance_km": round(total_return_to_hotel_distance_km, 2),
        "return_to_hotel_minutes": total_return_to_hotel_minutes,
        "total_plan_duration_minutes": (total_travel_time_minutes + total_visit_duration_minutes + total_return_to_hotel_minutes),
        "unplanned_place_count": len(unplanned_place_names),
        "unplanned_places": unplanned_place_names,
        "hotel_used_as_start": hotel.name if hotel else None,
        "selected_start_place": matched_start_place,
        "start_place_source": "hotel_nearest_place" if not start_place and hotel else "user_input",
        "route_algorithm": "score_based_nearest_neighbor",
        "route_mode": route_mode,
        "route_quality_note": get_route_mode_note(route_mode),
        "distance_weight": distance_weight,
        "score_weight": score_weight,
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

    route_data = prepare_route_data(
        start_place=start_place,
        categories=categories,
        hotel=hotel,
        distance_weight=distance_weight,
        score_weight=score_weight,
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
        "route_algorithm": "score_based_nearest_neighbor",
        "route_mode": route_mode,
        "route_quality_note": get_route_mode_note(route_mode),
        "distance_weight": distance_weight,
        "score_weight": score_weight,
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