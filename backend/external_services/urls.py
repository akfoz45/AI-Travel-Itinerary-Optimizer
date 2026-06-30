from django.urls import path
from .views import GeoapifyCityAPIView, GeoapifyPlacesAPIView, GeoapifyImportPlaceAPIView

urlpatterns = [
    path("geoapify/city/", GeoapifyCityAPIView.as_view(), name="geoapify-city"),
    path("geoapify/places/", GeoapifyPlacesAPIView.as_view(), name="geoapify-places"),
    path("geoapify/import-places/", GeoapifyImportPlaceAPIView.as_view(), name="geoapify-import-place"),
]