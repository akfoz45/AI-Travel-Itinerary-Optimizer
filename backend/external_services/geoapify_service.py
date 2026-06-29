import requests
from django.conf import settings


class GeoapifyService:
    def __init__(self):
        self.api_key = settings.GEOAPIFY_API_KEY
        self.base_url = settings.GEOAPIFY_BASE_URL

    def _get(self, endpoint, params=None):
        if not self.api_key:
            raise ValueError("Geoapify API key is missing.")

        if params is None:
            params = {}

        params["apiKey"] = self.api_key

        url = f"{self.base_url}{endpoint}"

        response = requests.get(url, params=params, timeout=10)

        if response.status_code != 200:
            raise ValueError(
                f"Geoapify API request failed with status code {response.status_code}."
            )

        return response.json()

    def get_city_coordinates(self, city_name):
        data = self._get(
            endpoint="/v1/geocode/search",
            params={
                "text": city_name,
                "limit": 1,
            },
        )

        features = data.get("features", [])

        if not features:
            raise ValueError(f"No coordinates found for city: {city_name}")

        properties = features[0].get("properties", {})

        return {
            "city": city_name,
            "formatted": properties.get("formatted"),
            "latitude": properties.get("lat"),
            "longitude": properties.get("lon"),
        }

    def get_places_by_coordinates(
        self,
        latitude,
        longitude,
        categories=None,
        radius=10000,
        limit=20,
    ):
        
        if categories is None:
            categories = ["tourism.sights"]

        params = {
            "categories": ",".join(categories),
            "filter": f"circle:{longitude},{latitude},{radius}",
            "bias": f"proximity:{longitude},{latitude}",
            "limit": limit,
        }

        data = self._get(
            endpoint="/v2/places",
            params=params,
        )

        return data.get("features", [])

    def search_places_by_city(
        self,
        city_name,
        categories=None,
        radius=10000,
        limit=20,
    ):

        city = self.get_city_coordinates(city_name)

        places = self.get_places_by_coordinates(
            latitude=city["latitude"],
            longitude=city["longitude"],
            categories=categories,
            radius=radius,
            limit=limit,
        )

        return {
            "city": city,
            "places": places,
        }