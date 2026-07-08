from django.urls import path
from .views import (
    TripListAPIView,
    TripDetailAPIView,
    DayPlanCreateAPIView,
    RouteItemCreateAPIView,
    GenerateRouteAPIView,
    GenerateFullRouteAPIView,
    ReorderRouteItemsAPIView,
)

urlpatterns = [
    path("", TripListAPIView.as_view(), name="trip-list"),
    path("<int:trip_id>/", TripDetailAPIView.as_view(), name="trip-detail"),
    path("<int:trip_id>/day-plans/", DayPlanCreateAPIView.as_view(), name="day-plan-create"),
    path("day-plans/<int:plan_id>/route-items/", RouteItemCreateAPIView.as_view(), name="route-item-create"),
    path("<int:trip_id>/generate-route/", GenerateRouteAPIView.as_view(), name="generate-route"),
    path("<int:trip_id>/generate-full-route/", GenerateFullRouteAPIView.as_view(), name="generate-full-route"),
    path("day-plans/<int:plan_id>/reorder/", ReorderRouteItemsAPIView.as_view(), name="route-item-reorder"),
]