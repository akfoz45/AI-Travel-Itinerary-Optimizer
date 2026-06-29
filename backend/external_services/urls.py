from django.urls import path
from .views import GeoapifyCityAPIView, GeoapifyPlacesAPIView

urlpatterns = [
    path("geoapify/city/", GeoapifyCityAPIView.as_view(), name="geoapify-city"),
    path("geoapify/places/", GeoapifyPlacesAPIView.as_view(), name="geoapify-places"),
]