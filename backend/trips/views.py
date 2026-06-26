from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from datetime import time
from django.db import transaction

from .models import Trip, DayPlan, RouteItem
from .serializers import (
    TripSerializer, 
    TripCreateSerializer, 
    DayPlanSerializer, 
    DayPlanCreateSerializer, 
    RouteItemCreateSerializer, 
    RouteItemSerializer,
    GenerateRouteSerializer,
    )

from places.models import Place
from route_optimizer.graph_builder import build_weighted_graph
from route_optimizer.nearest_neighbor import nearest_neighbor_route
from route_optimizer.time_estimator import estimate_travel_time_minutes, add_minutes_to_time

class TripListAPIView(APIView):
    def get(self, request):
        trips = Trip.objects.filter(user=request.user)
        serializer = TripSerializer(trips, many=True)
        return Response(serializer.data)
    
    def post(self, request):
        serializer = TripCreateSerializer(data=request.data)

        if serializer.is_valid():
            trip = serializer.save(user=request.user)
            response_serializer = TripSerializer(trip)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class TripDetailAPIView(APIView):
    def get(self, request, trip_id):
        try:
            trip = Trip.objects.get(
                trip_id=trip_id,
                user=request.user
                )
        except Trip.DoesNotExist:
            return Response(
                {"error": "Trip not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        
        serializer = TripSerializer(trip)
        return Response(serializer.data)
    
    def delete(self, request, trip_id):
        try:
            trip = Trip.objects.get(
                trip_id=trip_id,
                user=request.user
            )
        except Trip.DoesNotExist:
            return Response(
                {"error": "Trip not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        
        trip.delete()

        return Response(
            {"message": "Trip deleted successfully."},
            status=status.HTTP_200_OK
        )
    
class DayPlanCreateAPIView(APIView):
    def post(self, request, trip_id):
        try:
            trip = Trip.objects.get(
                trip_id=trip_id,
                user=request.user
            )
        except Trip.DoesNotExist:
            return Response(
                {"error": "Trip not found."},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = DayPlanCreateSerializer(data=request.data)

        if serializer.is_valid():
            day_plan = serializer.save(trip=trip)
            response_serializer = DayPlanSerializer(day_plan)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class RouteItemCreateAPIView(APIView):
    def post(self, request, plan_id):
        try:
            day_plan = DayPlan.objects.get(
                plan_id=plan_id,
                trip__user=request.user
            )
        except DayPlan.DoesNotExist:
            return Response(
                {"error": "Day plan not found."},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = RouteItemCreateSerializer(data=request.data)

        if serializer.is_valid():
            route_item = serializer.save(day_plan=day_plan)
            response_serializer = RouteItemSerializer(route_item)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class GenerateRouteAPIView(APIView):
    def post(self, request, trip_id):
        try:
            trip = Trip.objects.get(trip_id=trip_id,user=request.user)
        except Trip.DoesNotExist:
            return Response(
                {"error": "Trip not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        
        serializer = GenerateRouteSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        start_place = serializer.validated_data["start_place"]
        categories = serializer.validated_data.get("categories", [])
        day_number = serializer.validated_data["day_number"]
        date = serializer.validated_data["date"]

        start_time = serializer.validated_data.get("start_time", time(9, 0))
        end_time = serializer.validated_data.get("end_time", time(18, 0))

        places_queryset = Place.objects.all()

        if categories:
            places_queryset = places_queryset.filter(category__in=categories)

        places = list(places_queryset)

        if not places:
            return Response(
                {"error": "No places found for given categories."},
                status=status.HTTP_404_NOT_FOUND
            )
        
        place_names = [place.place_name for place in places]

        if start_place not in place_names:
            return Response(
                {
                    "error": "Start place not found in selected places.",
                    "available_places": place_names
                },
                status=status.HTTP_404_NOT_FOUND
            )
        
        graph = build_weighted_graph(places)
        route = nearest_neighbor_route(graph, start_place)

        try:
            with transaction.atomic():
                exisiting_day_plan = DayPlan.objects.filter(
                    trip=trip,
                    day_number=day_number
                ).first()

                if exisiting_day_plan:
                    exisiting_day_plan.delete()

                day_plan = DayPlan.objects.create(
                    trip=trip,
                    day_number=day_number,
                    date=date
                )

                place_map = {place.place_name: place for place in places}

                route_items = []

                total_distance_km = 0
                total_travel_time_minutes = 0
                total_visit_duration_minutes = 0

                current_time = time(9, 0)
                visit_order = 1

                for index, place_name in enumerate(route):
                    place = place_map[place_name]

                    if index == 0:
                        arrival_time = current_time
                        distance_km = 0
                        travel_minutes = 0
                    else:
                        previous_place_name = route[index - 1]
                        distance_km = graph[previous_place_name][place_name]
                        travel_minutes = estimate_travel_time_minutes(distance_km)
                        arrival_time = add_minutes_to_time(current_time, travel_minutes)
                    
                    visit_duration = place.estimated_visit_duration or 60
                    depature_time = add_minutes_to_time(arrival_time, visit_duration)

                    if depature_time > end_time:
                        break

                    route_item = RouteItem.objects.create(
                        day_plan=day_plan,
                        place=place_map[place_name],
                        visit_order=index + 1,
                        arrival_time=arrival_time,
                        departure_time=depature_time
                    )

                    route_items.append(route_item)

                    total_distance_km = distance_km
                    total_travel_time_minutes += travel_minutes
                    total_visit_duration_minutes += visit_duration

                    visit_order += 1
                    current_time = depature_time
            
                if not route_items:
                    raise ValueError("Daily time window is too short for selected place.")
        except ValueError as error:
            return Response(
                {"error": str(error)},
                status=status.HTTP_400_BAD_REQUEST
            )

        response_serializer = DayPlanSerializer(day_plan)

        return Response(
            {
                "message": "Route generated successfully.",
                "start_time": start_time,
                "end_time": end_time,
                "summary": {
                    "total_distance_km": round(total_distance_km, 2),
                    "total_travel_time_minutes": total_travel_time_minutes,
                    "total_visit_duration_minutes": total_visit_duration_minutes,
                    "total_plan_duration_minutes": (
                        total_travel_time_minutes + total_visit_duration_minutes
                    ),
                    "number_of_places": len(route_items),
                },
                "day_plan": response_serializer.data
            },
            status=status.HTTP_201_CREATED
        )