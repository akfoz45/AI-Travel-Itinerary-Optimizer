from django.urls import path
from .views import CurrentWeatherAPIView, ForecasWeatherAPIView

urlpatterns = [
    path("current/", CurrentWeatherAPIView.as_view(), name="current-weather"),  
    path("forecast/", ForecasWeatherAPIView.as_view(), name="forecast-weather"),
]