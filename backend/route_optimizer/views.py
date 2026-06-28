from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny

from places.models import Place
from .graph_builder import build_weighted_graph
from .nearest_neighbor import nearest_neighbor_route

class NearestRouteAPIView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        start_node = request.query_params.get("start")
        categories_param = request.query_params.get("categories")
        category = request.query_params.get("category")

        if not start_node:
            return Response(
                {"error": "Start place is required. Use ?start=Place Name"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        places_queryset = Place.objects.all()

        if categories_param:
            categories = [
                item.strip()
                for item in categories_param.split(",")
                if item.strip()
            ]

            places_queryset = places_queryset.filter(category__in=categories)

        elif category:
            places_queryset = places_queryset.filter(category__iexact=category)
            categories = [category]
        else:
            categories = []
        
        places = list(places_queryset)

        if not places:
            return Response(
                {"error": "No places found."},
                status=status.HTTP_404_NOT_FOUND
            )
        
        place_names = [place.place_name for place in places]

        if start_node not in place_names:
            return Response(
                {
                    "error": "Start place not found.",
                    "available_places": place_names
                },
                status=status.HTTP_404_NOT_FOUND
            )
        
        graph = build_weighted_graph(places)
        route = nearest_neighbor_route(graph, start_node)

        total_distance = 0

        route_details = []

        for index, place_name in enumerate(route):
            if index == 0:
                distance_from_previous = 0
            else:
                previous_place = route[index - 1]
                distance_from_previous = graph[previous_place][place_name]
                total_distance += distance_from_previous

            route_details.append(
                {
                    "visit_order": index + 1,
                    "place_name": place_name,
                    "distance_from_previous_km": distance_from_previous
                }
            )            

        return Response(
            {
                "start": start_node,
                "route": route_details,
                "total_distance_km": round(total_distance, 2)
            },
            status=status.HTTP_200_OK
        )
    