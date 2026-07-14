import requests
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from datetime import time
from django.db import transaction
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
from django.conf import settings
from .models import Trip, DayPlan, RouteItem, TripCollaborator
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
            trip = Trip.objects.get(
                Q(user=request.user) | Q(collaborators=request.user),
                trip_id=trip_id
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
    
    def put(self, request, trip_id):
        try:
            trip = Trip.objects.get(
                Q(user=request.user) | Q(tripcollaborator__user=request.user, tripcollaborator__role='editor'),
                trip_id=trip_id
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
                Q(user=request.user) | Q(tripcollaborator__user=request.user, tripcollaborator__role='editor'),
                trip_id=trip_id
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
                Q(trip__user=request.user) | Q(trip__tripcollaborator__user=request.user, trip__tripcollaborator__role='editor'),
                plan_id=plan_id
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
                Q(user=request.user) | Q(tripcollaborator__user=request.user, tripcollaborator__role='editor'),
                trip_id=trip_id
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
                Q(user=request.user) | Q(tripcollaborator__user=request.user, tripcollaborator__role='editor'),
                trip_id=trip_id
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
            day_plan = DayPlan.objects.get(
                Q(trip__user=request.user) | Q(trip__tripcollaborator__user=request.user, trip__tripcollaborator__role='editor'),
                plan_id=plan_id
            )
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

    def post(self, request):
        invite_code = request.data.get("invite_code")

        if not invite_code:
            return Response({"error": "Invite code is required."}, status=status.HTTP_400_BAD_REQUEST)
        
        trip = Trip.objects.filter(invite_code=invite_code).first()
        role = 'editor'
        
        if not trip:
            trip = Trip.objects.filter(viewer_invite_code=invite_code).first()
            role = 'viewer'
            
        if not trip:
            return Response({"error": "Invalid invite code."}, status=status.HTTP_404_NOT_FOUND)

        if trip.user == request.user:
            return Response(
                {"error": "You are already the owner of this trip. You cannot join this trip."}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        collaborator, created = TripCollaborator.objects.update_or_create(
            trip=trip, user=request.user,
            defaults={'role': role}
        )

        notify_trip_update(trip.trip_id)
        return Response(
            {"message": f"Successfully joined as {role}!", "trip_id": trip.trip_id, "role": role}, 
            status=status.HTTP_200_OK
        )
    
class LeaveTripAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, trip_id):
        collab = TripCollaborator.objects.filter(trip_id=trip_id, user=request.user).first()

        if collab:
            collab.delete()
            notify_trip_update(trip_id)
            return Response({"message": "Successfully left the trip."}, status=status.HTTP_200_OK)
        
        is_owner = Trip.objects.filter(trip_id=trip_id, user=request.user).exists()
        if is_owner:
            return Response(
                {"error": "You are the owner of this trip. You cannot leave it, you must delete it."}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        return Response(
            {"error": "You are not a participant of this trip."}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
class RemoveCollaboratorAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, trip_id, username):
        try:
            trip = Trip.objects.get(trip_id=trip_id, user=request.user)
        except Trip.DoesNotExist:
            return Response(
                {"error": "Trip not found or you do not have permission to remove users."}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        collab = TripCollaborator.objects.filter(trip=trip, user__username=username).first()
        
        if collab:
            collab.delete()
            notify_trip_update(trip_id)
            return Response({"message": f"{username} removed from the trip."}, status=status.HTTP_200_OK)
            
        return Response({"error": "User is not in this trip."}, status=status.HTTP_404_NOT_FOUND)
    
class PlaceAutocompleteAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        query = request.query_params.get("q", "")
        place_type = request.query_params.get("type", "city")

        if not query or len(query) < 3:
            return Response({"predictions": []}, status=status.HTTP_200_OK)
        
        api_key = getattr(settings, "GOOGLE_PLACES_API_KEY", None)
        if not api_key:
            return Response(
                {"error": "The Google Places API key has not been set."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        types_param = "(cities)" if place_type == "city" else "lodging"

        url = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        params = {
            'input': query,
            'types': types_param,
            'key': api_key,
            'language': 'en'
        }

        try:
            response = requests.get(url, params=params)
            if response.status_code == 200:
                data = response.json()
                predictions = [p["description"] for p in data.get("predictions", [])]
                return Response({"predictions": predictions}, status=status.HTTP_200_OK)
            else:
                return Response({"error": "Could not retrieve data from Google API."}, status=response.status_code)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)