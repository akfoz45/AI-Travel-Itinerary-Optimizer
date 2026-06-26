from datetime import timedelta
from django.db import transaction

from trips.models import DayPlan, RouteItem
from places.models import Place
from route_optimizer.graph_builder import build_weighted_graph
from route_optimizer.nearest_neighbor import nearest_neighbor_route
from route_optimizer.time_estimator import (
    estimate_travel_time_minutes,
    add_minutes_to_time,
)


def generate_full_route_for_trip(trip, start_place, categories, start_time, end_time):
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

    place_queryset = Place.objects.all()

    if categories:
        place_queryset = place_queryset.filter(category__in=categories)

    places = list(place_queryset)

    if not places:
        raise ValueError("No place found for given categories.")
    
    place_names = [place.place_name for place in places]

    if start_place not in place_names:
        raise ValueError(f"Start place not found in selected places. Available places: {place_names}")
    
    graph = build_weighted_graph(places)
    route = nearest_neighbor_route(graph, start_place)

    total_days = (trip.end_date - trip.start_date).days + 1

    if total_days <= 0:
        raise ValueError("Trip date range is invalid.")
    
    place_map = {place.place_name: place for place in places}

    route_index = 0
    created_day_plans = []

    total_distance_km = 0
    total_travel_time_minutes = 0
    total_visit_duration_minutes = 0
    total_route_items = 0

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

            while route_index < len(route):
                place_name = route[route_index]
                place = place_map[place_name]

                if visit_order == 1:
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

                if departure_time > end_time:
                    break

                route_item = RouteItem.objects.create(
                    day_plan=day_plan,
                    place=place,
                    visit_order=visit_order,
                    arrival_time=arrival_time,
                    departure_time=departure_time
                )

                route_items.append(route_item)

                total_distance_km += distance_km
                total_travel_time_minutes += travel_minutes
                total_visit_duration_minutes += visit_duration
                total_route_items += 1

                visit_order += 1
                current_time = departure_time
                route_index += 1

            if not route_items:
                day_plan.delete()
            else:
                created_day_plans.append(day_plan)

        if not created_day_plans:
            raise ValueError("Daily time window is too short for selected places.")

    summary = {
        "generated_days": len(created_day_plans),
        "number_of_places": total_route_items,
        "total_distance_km": round(total_distance_km, 2),
        "total_travel_time_minutes": total_travel_time_minutes,
        "total_visit_duration_minutes": total_visit_duration_minutes,
        "total_plan_duration_minutes": (
            total_travel_time_minutes + total_visit_duration_minutes
        ),
        "unplanned_places": len(route) - route_index,
    }

    return {
        "day_plans": created_day_plans,
        "summary": summary,
        "total_days": total_days,
    }