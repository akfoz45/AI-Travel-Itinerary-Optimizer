from django.urls import path
from .views import TripListAPIView, TripDetailAPIView

urlpatterns = [
    path("", TripListAPIView.as_view(), name="trip-list"),
    path("<int:trip_id>/", TripDetailAPIView.as_view(), name="trip-detail"),
]