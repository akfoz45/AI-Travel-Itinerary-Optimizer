from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from .serializers import RegisterSerializer
from rest_framework.permissions import IsAuthenticated
from .serializers import ChangePasswordSerializer

class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request, *args, **kwargs):
        serializer = ChangePasswordSerializer(data=request.data)

        if serializer.is_valid():
            user = request.user

            if not user.check_password(serializer.data.get("old_password")):
                return Response(
                    {"error": "Your current password is incorrect."}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            user.set_password(serializer.data.get("new_password"))
            user.save()

            return Response(
                {"message": "Your password has been successfully updated."}, 
                status=status.HTTP_200_OK
            )
            
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class RegisterAPIView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)

        if serializer.is_valid():
            user = serializer.save()

            return Response(
                {
                    "message": "User registered successfully.",
                    "user": {
                        "id": user.id,
                        "username": user.username,
                        "email": user.email,
                    }
                },
                status=status.HTTP_201_CREATED
            )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)