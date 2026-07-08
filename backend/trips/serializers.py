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
    place_id = serializers.IntegerField(source="place.place_id", read_only=True)
    place_name = serializers.CharField(source="place.place_name", read_only=True)
    category = serializers.CharField(source="place.category", read_only=True)
    source = serializers.CharField(source="place.source", read_only=True)
    recommendation_score = serializers.SerializerMethodField()
    latitude = serializers.FloatField(source="place.latitude", read_only=True)
    longitude = serializers.FloatField(source="place.longitude", read_only=True)

    class Meta:
        model = RouteItem
        fields = [
            "route_id",
            "place_id",
            "visit_order",
            "place_name",
            "category",
            "source",
            "latitude",
            "longitude",
            "recommendation_score",
            "arrival_time",
            "departure_time",
        ]
    

    def get_recommendation_score(self, obj):
        preferred_categories = self.context.get("preferred_categories", [])
        weather_context = self.context.get("weather_context")

        return calculate_place_score(
            obj.place,
            preferred_categories=preferred_categories,
            weather_context=weather_context,
        )


class DayPlanSerializer(serializers.ModelSerializer):
    route_items = serializers.SerializerMethodField()
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
        if getattr(obj, "daily_summary", None) is not None:
            return obj.daily_summary
        
        items = list(obj.route_items.all().select_related().order_by("visit_order"))
        total_distance = 0.0

        for i in range(len(items) - 1):
            p1 = items[i].place
            p2 = items[i + 1].place

            if p1.latitude and p1.longitude and p2.latitude and p2.longitude:
                import math
                R = 6371.0 
                dlat = math.radians(p2.latitude - p1.latitude)
                dlon = math.radians(p2.longitude - p1.longitude)
                
                a = (math.sin(dlat / 2) ** 2 + 
                     math.cos(math.radians(p1.latitude)) * math.cos(math.radians(p2.latitude)) * math.sin(dlon / 2) ** 2)
                c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
                
                total_distance += R * c
                
        return {
            "total_distance_km": round(total_distance, 1),
            "weather_note": getattr(obj, "weather_note", None) 
        }
    
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
            "is_pinned",
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
    
    def update(self, instance, validated_data):
        preferences_data = validated_data.pop("preferences", None)
        hotel_data = validated_data.pop("hotel", None)

        instance.destination = validated_data.get("destination", instance.destination)
        instance.start_date = validated_data.get("start_date", instance.start_date)
        instance.end_date = validated_data.get("end_date", instance.end_date)
        instance.save()

        if preferences_data is not None:
            instance.preferences.all().delete()

            for preference in preferences_data:
                TripPreference.objects.create(
                    trip=instance,
                    preference=preference
                )

        if hotel_data is not None:
            instance.hotels.all().delete()

            Hotel.objects.create(
                trip=instance,
                **hotel_data
            )

        return instance
    
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

    route_mode = serializers.ChoiceField(
        choices=["balanced", "shortest", "recommended"],
        required=False
    )

    distance_weight = serializers.FloatField(required=False, min_value=0)
    score_weight = serializers.FloatField(required=False, min_value=0)