from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny

from .geoapify_service import GeoapifyService

class GeoapifyCityAPIView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        city_name = request.query_params.get("name")

        if not city_name:
            return Response(
                {"error": "City name is required. Use ?name=City name"}, 
                status=status.HTTP_400_BAD_REQUEST
                )
        
        service = GeoapifyService()

        try:
            city_data = service.get_city_coordinates(city_name)
        except ValueError as error:
            return Response({"error": str(error)}, status=status.HTTP_400_BAD_REQUEST)
        
        return Response(city_data, status=status.HTTP_200_OK)
    
class GeoapifyPlacesAPIView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        city_name = request.query_params.get("city")
        categories_param = request.query_params.get("categories")
        radius = request.query_params.get("radius", 10000)
        limit = request.query_params.get("limit", 20)

        if not city_name:
            return Response(
                {"error": "City names is required. Use ?city=City Name"},
                status=status.HTTP_400_BAD_REQUEST
                )
        
        try:
            radius = int(radius)
            limit = int(limit)
        except ValueError as error:
            return Response(
                {"error": "radius and limit must be valid integers."}, 
                status=status.HTTP_400_BAD_REQUEST
                )
        
        categories = None

        if categories_param:
            categories = [
                category.strip() for category in categories_param.split(",") if category.strip()
            ]

        service = GeoapifyService()

        try:
            result = service.search_places_by_city(
                city_name=city_name,
                categories=categories,
                radius=radius,
                limit=limit
            )
        except ValueError as error:
            return Response(
                {"error": str(error)},
                status=status.HTTP_400_BAD_REQUEST
            )

        return Response(result, status=status.HTTP_200_OK)
        
