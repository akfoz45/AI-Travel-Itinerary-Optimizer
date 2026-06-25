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
    )

class TripListAPIView(APIView):
    def get(self, request):
        trips = Trip.objects.all()
        serializer = TripSerializer(trips, many=True)
        return Response(serializer.data)
    
    def post(self, request):
        serializer = TripCreateSerializer(data=request.data)

        if serializer.is_valid():
            trip = serializer.save()
            response_serializer = TripSerializer(trip)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class TripDetailAPIView(APIView):
    def get(self, request, trip_id):
        try:
            trip = Trip.objects.get(trip_id=trip_id)
        except Trip.DoesNotExist:
            return Response(
                {"error": "Trip not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        
        serializer = TripSerializer(trip)
        return Response(serializer.data)
    
class DayPlanCreateAPIView(APIView):
    def post(self, request, trip_id):
        try:
            trip = Trip.objects.get(trip_id=trip_id)
        except Trip.DoesNotExist:
            return Response(
                {"error": "Trip not found."},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = DayPlanCreateSerializer(data=request.data)

        if serializer.is_valid():
            day_plan = serializer.save(trip=trip)
            response_serializer = DayPlanSerializer(day_plan)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class RouteItemCreateAPIView(APIView):
    def post(self, request, plan_id):
        try:
            day_plan = DayPlan.objects.get(plan_id=plan_id)
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
        
        return Response(response_serializer.errors, status=status.HTTP_400_BAD_REQUEST)