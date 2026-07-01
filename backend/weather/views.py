from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from .weather_service import OpenMeteoWeatherService

class CurrentWeatherAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        latitude = request.query_params.get("latitude")
        longitude = request.query_params.get("longitude")

        if not latitude or not longitude:
            return Response(
                {
                    "error": "latitude and longitude query parameters are required."
                },
                status=400
            )
        
        try:
            service = OpenMeteoWeatherService()
            result = service.get_current_weather_by_coordinates(
                latitude=latitude,
                longitude=longitude,
            )

            return Response(result)

        except ValueError as error:
            return Response(
                {"error": str(error)},
                status=400
            )
