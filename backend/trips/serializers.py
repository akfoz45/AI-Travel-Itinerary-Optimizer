from rest_framework import serializers
from .models import Trip, TripPreference, DayPlan, RouteItem, Hotel
from route_optimizer.scoring import calculate_place_score

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
    source = serializers.CharField(source="place.source", read_only=True)
    recommendation_score = serializers.SerializerMethodField()

    class Meta:
        model = RouteItem
        fields = [
            "route_id",
            "visit_order",
            "place_name",
            "category",
            "source",
            "recommendation_score",
            "arrival_time",
            "departure_time",
        ]
    

    def get_recommendation_score(self, obj):
        preferred_categories = self.context.get("preferred_categories", [])

        return calculate_place_score(
            obj.place,
            preferred_categories=preferred_categories
        )


class DayPlanSerializer(serializers.ModelSerializer):
    route_items = RouteItemSerializer(many=True, read_only=True)
    daily_summary = serializers.SerializerMethodField()

    class Meta:
        model = DayPlan
        fields = [
            "plan_id",
            "day_number",
            "date",
            "daily_summary",
            "route_items",
        ]
    
    def get_daily_summary(self, obj):
        return getattr(obj, "daily_summary", None)
    
    def get_route_items(self, obj):
        route_items = obj.route_items.all().order_by("visit_order")

        serializer = RouteItemSerializer(
            route_items,
            many=True,
            context=self.context
        )

        return serializer.data

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

    route_mode = serializers.ChoiceField(choices=["balanced", "shortest", "recommended"], required=False)

    distance_weight = serializers.FloatField(required=False, min_value=0)
    score_weight = serializers.FloatField(required=False, min_value=0)


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

    route_mode = serializers.ChoiceField(choices=["balanced", "shortest", "recommended"], required=False)

    distance_weight = serializers.FloatField(required=False, min_value=0)
    score_weight = serializers.FloatField(required=False, min_value=0)