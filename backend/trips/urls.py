from django.urls import path
from .views import (
    TripListAPIView,
    TripDetailAPIView,
    DayPlanCreateAPIView,
    RouteItemCreateAPIView,
)

urlpatterns = [
    path("", TripListAPIView.as_view(), name="trip-list"),
    path("<int:trip_id>/", TripDetailAPIView.as_view(), name="trip-detail"),
    path("<int:trip_id>/day-plans/", DayPlanCreateAPIView.as_view(), name="day-plan-create"),
    path("day-plans/<int:plan_id>/route-items/", RouteItemCreateAPIView.as_view(), name="route-item-create"),
]