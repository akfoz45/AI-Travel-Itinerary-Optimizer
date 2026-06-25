from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
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

        day_plan = DayPlan.objects.create(
            trip=trip,
            day_number=day_number,
            date=date
        )

        place_map = {place.place_name: place for place in places}

        route_items = []

        for index, place_name in enumerate(route):
            route_item = RouteItem.objects.create(
                day_plan=day_plan,
                place=place_map[place_name],
                visit_order=index + 1,
                arrival_time=None,
                departure_time=None
            )

            route_items.append(route_item)

        response_serializer = DayPlanSerializer(day_plan)

        return Response(
            {
                "message": "Route generated successfully.",
                "day_plan": response_serializer.data
            },
            status=status.HTTP_201_CREATED
        )