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
    preferences = serializers.ListField(
        child=serializers.CharField(max_length=100),
        write_only=True,
        required=False
    )

    hotel = HotelSerializer(
        write_only=True,
        required=False
    )

    class Meta:
        model = Trip
        fields = [
            "trip_id",
            "destination",
            "start_date",
            "end_date",
            "preferences",
            "hotel",
        ]
        read_only_fields = ["trip_id"]

    def create(self, validated_data):
        preferences_data = validated_data.pop("preferences", [])
        hotel_data = validated_data.pop("hotel", None)

        trip = Trip.objects.create(**validated_data)

        for preference in preferences_data:
            TripPreference.objects.create(
                trip=trip,
                preference=preference
            )

        if hotel_data:
            Hotel.objects.create(
                trip=trip,
                **hotel_data
            )

        return trip
    
class DayPlanCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = DayPlan
        fields = [
            "plan_id",
            "day_number",
            "date",
        ]
        read_only_fields = ["plan_id"]

class RouteItemCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = RouteItem
        fields = [
            "route_id",
            "place",
            "visit_order",
            "arrival_time",
            "departure_time",
        ]
        read_only_fields = ["route_id"]

class GenerateRouteSerializer(serializers.Serializer):
    start_place = serializers.CharField(
        max_length=255,
        required=False,
        allow_blank=True
        )

    categories = serializers.ListField(
        child=serializers.CharField(max_length=100),
        required=False
    )

    day_number = serializers.IntegerField()
    date = serializers.DateField()

    start_time = serializers.TimeField(required=False)
    end_time = serializers.TimeField(required=False)


class GenerateFullRouteSerializer(serializers.Serializer):
    start_place = serializers.CharField(
        max_length=255,
        required=False,
        allow_blank=True
        )

    categories = serializers.ListField(
        child=serializers.CharField(max_length=100), 
        required=False
        )

    start_time = serializers.TimeField(required=False)
    end_time = serializers.TimeField(required=False)