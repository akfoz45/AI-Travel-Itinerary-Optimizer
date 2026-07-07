from django.urls import path
from .views import RegisterAPIView
from .views import ChangePasswordView

urlpatterns = [
    path("register/", RegisterAPIView.as_view(), name="register"),
    path("auth/change-password/", ChangePasswordView.as_view(), name="change-password"),
]