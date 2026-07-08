from rest_framework import serializers
from .models import Place, FavoritePlace

class PlaceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Place
        fields = [
            "place_id",
            "place_name",
            "latitude",
            "longitude",
            "category",
            "rating",
            "estimated_visit_duration",
            "source",
            "source_place_id",
        ]

class FavoritePlaceSerializer(serializers.ModelSerializer):
    place_id = serializers.IntegerField(source="place.place_id", read_only=True)
    place_name = serializers.CharField(source="place.place_name", read_only=True)
    category = serializers.CharField(source="place.category", read_only=True)
    source = serializers.CharField(source="place.source", read_only=True)
    latitude = serializers.FloatField(source="place.latitude", read_only=True)
    longitude = serializers.FloatField(source="place.longitude", read_only=True)

    class Meta:
        model = FavoritePlace
        fields = [
            "favorite_id",
            "place_id",
            "place_name",
            "category",
            "source",
            "latitude",
            "longitude",
            "created_at",
        ]