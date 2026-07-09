from django.urls import path
from .views import RegisterAPIView
from .views import ChangePasswordView, UserProfileAPIView

urlpatterns = [
    path("register/", RegisterAPIView.as_view(), name="register"),
    path("change-password/", ChangePasswordView.as_view(), name="change-password"),
    path("profile/", UserProfileAPIView.as_view(), name="profile")
]