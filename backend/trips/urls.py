from django.urls import path
from .views import (
    TripListAPIView,
    TripDetailAPIView,
    DayPlanCreateAPIView,
    RouteItemCreateAPIView,
    GenerateRouteAPIView,
    GenerateFullRouteAPIView,
    ReorderRouteItemsAPIView,
    JoinTripAPIView,
    LeaveTripAPIView,
    RemoveCollaboratorAPIView,
    PlaceAutocompleteAPIView,
)

urlpatterns = [
    path("", TripListAPIView.as_view(), name="trip-list"),
    path("<int:trip_id>/", TripDetailAPIView.as_view(), name="trip-detail"),
    path("<int:trip_id>/day-plans/", DayPlanCreateAPIView.as_view(), name="day-plan-create"),
    path("day-plans/<int:plan_id>/route-items/", RouteItemCreateAPIView.as_view(), name="route-item-create"),
    path("<int:trip_id>/generate-route/", GenerateRouteAPIView.as_view(), name="generate-route"),
    path("<int:trip_id>/generate-full-route/", GenerateFullRouteAPIView.as_view(), name="generate-full-route"),
    path("day-plans/<int:plan_id>/reorder/", ReorderRouteItemsAPIView.as_view(), name="route-item-reorder"),
    path("join/", JoinTripAPIView.as_view(), name="join_trip"),
    path("<int:trip_id>/leave/", LeaveTripAPIView.as_view(), name="leave-trip"),
    path("<int:trip_id>/collaborators/<str:username>/", RemoveCollaboratorAPIView.as_view(), name="remove-collaborator"),
    path("places/autocomplete/", PlaceAutocompleteAPIView.as_view(), name="place-autocomplete")
]