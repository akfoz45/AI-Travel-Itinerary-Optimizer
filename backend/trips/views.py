from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from datetime import time
from django.db import transaction
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
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
from route_optimizer.services import generate_full_route_for_trip, generate_day_route_for_trip
from route_optimizer.scoring import get_route_mode_weights
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync


def notify_trip_update(trip_id):
    channel_layer = get_channel_layer()
    async_to_sync(channel_layer.group_send)(
        f'trip_{trip_id}',
        {
            'type': 'trip_update',
            'action': 'route_updated'
        }
    )


class TripListAPIView(APIView):
    def get(self, request):
        trips = Trip.objects.filter(Q(user=request.user) | Q(collaborators=request.user)).distinct()
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
            trip = Trip.objects.get(Q(user=request.user) | Q(collaborators=request.user), trip_id=trip_id)
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
    
    def put(self, request, trip_id):
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

        serializer = TripCreateSerializer(
            trip,
            data=request.data
        )

        if serializer.is_valid():
            updated_trip = serializer.save()
            response_serializer = TripSerializer(updated_trip)

            notify_trip_update(updated_trip.trip_id)

            return Response(
                response_serializer.data,
                status=status.HTTP_200_OK
            )

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
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

        notify_trip_update(trip.trip_id)

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

        start_place = serializer.validated_data.get("start_place", "")
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

        notify_trip_update(trip.trip_id)

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
    

class ReorderRouteItemsAPIView(APIView):
    def put(self, request, plan_id):
        try:
            day_plan = DayPlan.objects.get(plan_id=plan_id, trip__user=request.user)
        except DayPlan.DoesNotExist:
            return Response({"error": "Day plan was not found"}, status=status.HTTP_404_NOT_FOUND)

        route_ids = request.data.get("route_ids")
        
        if not route_ids and hasattr(request.data, "getlist"):
            route_ids = request.data.getlist("route_ids")
            if not route_ids:
                route_ids = request.data.getlist("route_ids[]")

        if not route_ids or not isinstance(route_ids, list):
            return Response(
                {"error": "route_ids is missing or invalid."}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        updated_count = 0
        with transaction.atomic():
            for index, route_id in enumerate(route_ids):
                updated = RouteItem.objects.filter(pk=route_id).update(visit_order=index + 1)
                updated_count += updated
        
        notify_trip_update(day_plan.trip.trip_id)
        
        return Response(
            {
                "message": "Route items reordered successfully.",
                "updated_count": updated_count
            },
            status=status.HTTP_200_OK
        )
    

class TripViewSet(viewsets.ModelViewSet):
    serializer_class = TripSerializer

    def get_queryset(self):
        return Trip.objects.select_related('user').prefetch_related('places').all()
    

class JoinTripAPIView(APIView):
    permission_classes = [IsAuthenticated]

    # HATA DÜZELTİLDİ: psot -> post
    def post(self, request):
        invite_code = request.data.get("invite_code")

        if not invite_code:
            return Response({"error": "Invite code is required."}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            trip = Trip.objects.get(invite_code=invite_code)

            if trip.user == request.user or request.user in trip.collaborators.all():
                return Response(
                    {"message": "You are already in this trip.", "trip_id": trip.trip_id}, 
                    status=status.HTTP_200_OK
                )
            
            trip.collaborators.add(request.user)

            notify_trip_update(trip.trip_id)

            return Response(
                {"message": "Successfully joined the trip!", "trip_id": trip.trip_id}, 
                status=status.HTTP_200_OK
            )
        
        except Trip.DoesNotExist:
            return Response({"error": "Invalid invite code."}, status=status.HTTP_404_NOT_FOUND)