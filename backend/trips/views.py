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
    GenerateFullRouteSerializer,
    )
from places.models import Place
from route_optimizer.services import generate_full_route_for_trip, generate_day_route_for_trip
from route_optimizer.time_estimator import estimate_travel_time_minutes, add_minutes_to_time
from route_optimizer.graph_builder import build_weighted_graph
from route_optimizer.nearest_neighbor import nearest_neighbor_route
from route_optimizer.scoring import get_route_mode_weights

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
            trip = Trip.objects.get(
                trip_id=trip_id,
                user=request.user
            )
        except Trip.DoesNotExist:
            return Response(
                {"error": "Trip not found."},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = GenerateRouteSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        start_place = serializer.validated_data.get("start_place")
        categories = serializer.validated_data.get("categories", [])
        day_number = serializer.validated_data["day_number"]
        date = serializer.validated_data["date"]
        start_time = serializer.validated_data.get("start_time", time(9, 0))
        end_time = serializer.validated_data.get("end_time", time(18, 0))

        route_mode = serializer.validated_data.get("route_mode", "balanced")
        mode_weights = get_route_mode_weights(route_mode)

        distance_weight = serializer.validated_data.get("distance_weight", mode_weights["distance_weight"])
        score_weight = serializer.validated_data.get("score_weight", mode_weights["score_weight"])

        try:
            result = generate_day_route_for_trip(
                trip=trip,
                start_place=start_place,
                categories=categories,
                day_number=day_number,
                date=date,
                start_time=start_time,
                end_time=end_time,
                distance_weight=distance_weight,
                score_weight=score_weight,
                route_mode=route_mode,
            )
        except ValueError as error:
            return Response(
                {"error": str(error)},
                status=status.HTTP_400_BAD_REQUEST
            )

        response_serializer = DayPlanSerializer(
            result["day_plan"],
            context={
                "preferred_categories": categories,       
                 "weather_context": result["summary"].get("weather_context"),
            }
        )

        return Response(
            {
                "message": "Route generated successfully.",
                "start_time": start_time,
                "end_time": end_time,
                "summary": result["summary"],
                "day_plan": response_serializer.data
            },
            status=status.HTTP_201_CREATED
        )
    
class GenerateFullRouteAPIView(APIView):
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

        serializer = GenerateFullRouteSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        start_place = serializer.validated_data.get("start_place")
        categories = serializer.validated_data.get("categories", [])
        start_time = serializer.validated_data.get("start_time", time(9, 0))
        end_time = serializer.validated_data.get("end_time", time(18, 0))

        route_mode = serializer.validated_data.get("route_mode", "balanced")
        mode_weights = get_route_mode_weights(route_mode)

        distance_weight = serializer.validated_data.get("distance_weight", mode_weights["distance_weight"])
        score_weight = serializer.validated_data.get("score_weight", mode_weights["score_weight"])

        try:
            result = generate_full_route_for_trip(
                trip=trip,
                start_place=start_place,
                categories=categories,
                start_time=start_time,
                end_time=end_time,
                distance_weight=distance_weight,
                score_weight=score_weight,
                route_mode=route_mode,
            )
        except ValueError as error:
            return Response(
                {"error": str(error)},
                status=status.HTTP_400_BAD_REQUEST
            )

        response_serializer = DayPlanSerializer(
            result["day_plans"],
            many=True,
            context={
                "preferred_categories": categories,
                "weather_context": result["summary"].get("weather_context"),
            }
        )

        return Response(
            {
                "message": "Full route generated successfully.",
                "trip_id": trip.trip_id,
                "destination": trip.destination,
                "start_date": trip.start_date,
                "end_date": trip.end_date,
                "total_days": result["total_days"],
                "start_time": start_time,
                "end_time": end_time,
                "summary": result["summary"],
                "day_plans": response_serializer.data
            },
            status=status.HTTP_201_CREATED
        )