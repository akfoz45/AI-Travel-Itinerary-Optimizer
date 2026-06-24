from rest_framework import serializers
from .models import Place

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
        ]