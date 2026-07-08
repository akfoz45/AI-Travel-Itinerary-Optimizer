from django.urls import path
from .views import (
    PlaceListAPIView, 
    FavoritePlaceCreateAPIView, 
    FavoritePlaceDeleteAPIView, 
    FavoritePlaceListAPIView
)

urlpatterns = [
    path("", PlaceListAPIView.as_view(), name="place-list"),
    path("favorites/", FavoritePlaceListAPIView.as_view(), name="favorite-place-list"),
    path("favorites/add/", FavoritePlaceCreateAPIView.as_view(), name="favorite-place-add"),
    path("favorites/<int:place_id>/", FavoritePlaceDeleteAPIView.as_view(), name="favorite-place-delete"),
]