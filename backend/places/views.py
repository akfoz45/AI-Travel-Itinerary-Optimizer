from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Place
from .serializers import PlaceSerializer

class PlaceListAPIView(APIView):
    def get(self, request):
        places = Place.objects.all()

        category = request.query_params.get("category")
        min_rating = request.query_params.get("min_rating")

        if category:
            places = places.filter(category__iexact=category)

        if min_rating:
            min_rating = min_rating.filter(rating__gte=min_rating)

        serializer = PlaceSerializer(places, many=True)
        return Response(serializer.data)