from django.urls import path
from .views import NearestRouteAPIView


urlpatterns = [
    path("nearest-route/", NearestRouteAPIView.as_view(), name="nearest-route"),
]