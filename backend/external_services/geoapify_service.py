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

    def map_geoapify_category_to_internal_category(self, categories):
        if not categories:
            return "Other"

        category_text = " ".join(categories).lower()

        if "heritage" in category_text or "historic" in category_text:
            return "History"

        if "natural" in category_text or "nature" in category_text:
            return "Nature"

        if "museum" in category_text:
            return "Museum"

        if "religion" in category_text or "place_of_worship" in category_text:
            return "Religious"

        if "restaurant" in category_text or "catering" in category_text:
            return "Food"

        if "tourism" in category_text or "sights" in category_text:
            return "Tourism"

        return "Other"

    def estimate_visit_duration_by_category(self, category):
        duration_map = {
            "History": 120,
            "Nature": 180,
            "Tourism": 90,
            "Museum": 120,
            "Religious": 60,
            "Food": 90,
            "Other": 60,
        }

        return duration_map.get(category, 60)

    def normalize_place(self, feature):
        properties = feature.get("properties", {})
        geometry = feature.get("geometry", {})

        coordinates = geometry.get("coordinates", [])

        if len(coordinates) < 2:
            return None

        longitude = coordinates[0]
        latitude = coordinates[1]

        name = properties.get("name")

        if not name:
            name = properties.get("formatted")

        if not name:
            return None

        geoapify_categories = properties.get("categories", [])

        internal_category = self.map_geoapify_category_to_internal_category(
            geoapify_categories
        )

        return {
            "place_name": name,
            "latitude": latitude,
            "longitude": longitude,
            "category": internal_category,
            "rating": None,
            "estimated_visit_duration": self.estimate_visit_duration_by_category(
                internal_category
            ),
            "source": "geoapify",
            "source_place_id": properties.get("place_id"),
            "formatted_address": properties.get("formatted"),
            "raw_categories": geoapify_categories,
        }

    def normalize_places(self, features):
        normalized_places = []

        for feature in features:
            normalized_place = self.normalize_place(feature)

            if normalized_place:
                normalized_places.append(normalized_place)

        return normalized_places

    def search_places_by_city(
        self,
        city_name,
        categories=None,
        radius=10000,
        limit=20,
    ):
        city = self.get_city_coordinates(city_name)

        geoapify_categories = self.map_internal_categories_to_geoapify_categories(categories)

        places = self.get_places_by_coordinates(
            latitude=city["latitude"],
            longitude=city["longitude"],
            categories=geoapify_categories,
            radius=radius,
            limit=limit,
        )

        normalized_places = self.normalize_places(places)

        return {
            "city": city,
            "places": normalized_places,
            "raw_place_count": len(places),
            "normalized_place_count": len(normalized_places),
        }
    
    def map_internal_categories_to_geoapify_categories(self, categories):
        if not categories:
            return ["tourism.sights"]

        category_map = {
            "history": ["heritage", "tourism.sights"],
            "historic": ["heritage", "tourism.sights"],
            "nature": ["natural", "tourism.sights"],
            "natural": ["natural"],
            "tourism": ["tourism.sights"],
            "sight": ["tourism.sights"],
            "sights": ["tourism.sights"],
            "museum": ["entertainment.museum", "tourism.sights"],
            "religious": ["religion", "tourism.sights"],
            "religion": ["religion"],
            "food": ["catering.restaurant"],
            "restaurant": ["catering.restaurant"],
        }

        geoapify_categories = []

        for category in categories:
            normalized_category = category.strip().lower()

            mapped_categories = category_map.get(
                normalized_category,
                ["tourism.sights"]
            )

            geoapify_categories.extend(mapped_categories)

        return list(set(geoapify_categories))