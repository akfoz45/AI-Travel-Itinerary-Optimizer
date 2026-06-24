from rest_framework import serializers
from .models import Trip, TripPreference, DayPlan, RouteItem, Hotel

class TripPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = TripPreference
        fields = [
            "preference_id",
            "preference"
        ]

class RouteItemSerializer(serializers.ModelSerializer):
    place_name = serializers.CharField(source="place.place_name", read_only=True)
    category = serializers.CharField(source="place.category", read_only=True)

    class Meta:
        model = RouteItem
        fields = [
            "route_id",
            "visit_order",
            "place_name",
            "category",
            "arrival_time",
            "departure_time",
        ]

class DayPlanSerializer(serializers.ModelSerializer):
    route_items = RouteItemSerializer(many=True, read_only=True)

    class Meta:
        model = DayPlan
        fields = [
            "plan_id",
            "day_number",
            "date",
            "route_items",
        ]

class HotelSerializer(serializers.ModelSerializer):
    class Meta:
        model = Hotel
        fields = [
            "hotel_id",
            "name",
            "latitude",
            "longitude",
            "rating",
        ]       

class TripSerializer(serializers.ModelSerializer):
    preferences = TripPreferenceSerializer(many=True, read_only=True)
    day_plans = DayPlanSerializer(many=True, read_only=True)
    hotels = HotelSerializer(many=True, read_only=True)

    class Meta:
        model = Trip
        fields = [
            "trip_id",
            "destination",
            "start_date",
            "end_date",
            "preferences",
            "day_plans",
            "hotels",
        ]

class TripCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Trip
        fields = [
            "trip_id",
            "user",
            "destination",
            "start_date",
            "end_date",
        ]
        read_only_fields = ["trip_id"]