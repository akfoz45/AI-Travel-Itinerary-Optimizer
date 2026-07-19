from django.urls import path, include
from .views import PredictFlightPriceAPIView

urlpatterns = [
    path("predict/", PredictFlightPriceAPIView.as_view(), name="predict-flight-price"),
]