from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny

from .geoapify_service import GeoapifyService
from places.models import Place
from route_optimizer.utils import calculate_distance_km


def find_duplicate_place(place_name, latitude, longitude, source=None, source_place_id=None, max_distance_km=0.1):
    """
    Checks whether a place with the same name exists near the given coordinates.

    max_distance_km=0.1 means approximately 100 meters.
    """

    if source and source_place_id:
        existing_by_source = Place.objects.filter(source=source, source_place_id=source_place_id).first()

        if existing_by_source: 
            return existing_by_source
        
    possible_duplicates = Place.objects.filter(place_name__iexact=place_name)

    for existing_place in possible_duplicates:
        distance = calculate_distance_km(
            latitude,
            longitude,
            existing_place.latitude,
            existing_place.longitude
        )

        if distance <= max_distance_km:
            return existing_place
        
    return None


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
        

class GeoapifyImportPlaceAPIView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        city_name = request.data.get("city")
        categories = request.data.get("categories")
        radius = request.data.get("radius", 10000)
        limit = request.query_params.get("limit", 20)

        if not city_name:
            return Response(
                {"error": "City names is required. Use ?city=City Name"},
                status=status.HTTP_400_BAD_REQUEST
                )
        if categories is None:
            categories = ["tourism.sights"]

        try:
            radius = int(radius)
            limit = int(limit)
        except ValueError as error:
            return Response(
                {"error": "radius and limit must be valid integers."}, 
                status=status.HTTP_400_BAD_REQUEST
                )
        
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
        
        imported_places = []
        skipped_places = []

        for place_data in result["places"]:
            place_name = place_data["place_name"]

            existing_place = find_duplicate_place(
                place_name=place_data["place_name"],
                latitude=place_data["latitude"],
                longitude=place_data["longitude"],
                source=place_data.get("source"),
                source_place_id=place_data.get("source_place_id"),
            )

            if existing_place:
                skipped_places.append({
                    "place_name": place_data["place_name"],
                    "reason": "duplicate",
                    "existing_place_id": existing_place.place_id,
                })
                continue

            place = Place.objects.create(
                place_name=place_data["place_name"],
                latitude=place_data["latitude"],
                longitude=place_data["longitude"],
                category=place_data["category"],
                rating=place_data["rating"],
                estimated_visit_duration=place_data["estimated_visit_duration"],
                source=place_data.get("source", "geoapify"),
                source_place_id=place_data.get("source_place_id"),
            )

            imported_places.append({
                "place_id": place.place_id,
                "place_name": place.place_name,
                "category": place.category,
                "latitude": place.latitude,
                "longitude": place.longitude,
                "estimated_visit_duration": place.estimated_visit_duration,
                "source": place_data.get("source"),
                "source_place_id": place_data.get("source_place_id"),
            })

        return Response(
            {
                "message": "Places imported successfully.",
                "city": result["city"],
                "requested_categories": result.get("requested_categories"),
                "geoapify_categories": result.get("geoapify_categories"),
                "raw_place_count": result["raw_place_count"],
                "normalized_place_count": result["normalized_place_count"],
                "imported_count": len(imported_places),
                "skipped_count": len(skipped_places),
                "imported_places": imported_places,
                "skipped_places": skipped_places
            },
            status=status.HTTP_201_CREATED
        )
        
        