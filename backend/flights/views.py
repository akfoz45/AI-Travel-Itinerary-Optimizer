from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .services import FlightPricePredictionService

class PredictFlightPriceAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def pst(self, request):
        try:
            depature_time = request.data.get("depature_time")
            arrival_time = request.data.get("arrival_time")
            flight_class = request.data.get("class")
            stops = request.data.get("stops")
            duration = request.data.get("duration")
            days_left = request.data.get("days_left")


            if not all([depature_time, arrival_time, flight_class, stops, duration, days_left]):
                return Response(
                    {"error": "You submitted incomplete parameters. Please fill in all fields."},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            service = FlightPricePredictionService()
            estimated_price = service.predict_price(
                depature_time, arrival_time, flight_class, stops, duration, days_left
            )
            
            return Response({
                "message": "Price prediction was successful.",
                "estimated_price": estimated_price,
                "currency": "INR"
            })
        
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)