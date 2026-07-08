from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Place, FavoritePlace
from .serializers import PlaceSerializer, FavoritePlaceSerializer

class PlaceListAPIView(APIView):
    def get(self, request):
        places = Place.objects.all()

        category = request.query_params.get("category")
        min_rating = request.query_params.get("min_rating")

        if category:
            places = places.filter(category__iexact=category)

        if min_rating:
            places = places.filter(rating__gte=min_rating)

        serializer = PlaceSerializer(places, many=True)
        return Response(serializer.data)
    

class FavoritePlaceListAPIView(APIView):
    def get(self, request):
        favorites = FavoritePlace.objects.filter(user=request.user).select_related("place").order_by("-created_at")

        serializer = FavoritePlaceSerializer(favorites, many=True)

        return Response(serializer.data)
    
class FavoritePlaceCreateAPIView(APIView):
    def post(self, request):
        place_id = request.data.get("place_id")

        if not place_id:
            return Response({"error": "place_id is required."},status=status.HTTP_400_BAD_REQUEST)
        
        try:
            place = Place.objects.get(place_id=place_id)
        except Place.DoesNotExist:
            return Response({"error": "Place not found"},status=status.HTTP_404_NOT_FOUND)
        
        favorite, created = FavoritePlace.objects.get_or_create(
            user=request.user,
            place=place,
        )

        serializer = FavoritePlaceSerializer(favorite)

        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK
        )

class FavoritePlaceDeleteAPIView(APIView):
    def delete(self, request, place_id):
        deleted_count, _ = FavoritePlace.objects.filter(
            user=request.user,
            place_id=place_id
        ).delete()

        if deleted_count == 0:
            return Response(
                {"error": "Favorite place not found."},
                status=status.HTTP_404_NOT_FOUND
            )

        return Response(
            {"message": "Favorite place removed successfully."},
            status=status.HTTP_200_OK
        ) 