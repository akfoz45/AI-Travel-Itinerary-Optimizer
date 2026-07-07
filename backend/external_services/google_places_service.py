import requests
from django.conf import settings

class GooglePlaceService:
    def __init__(self):
        self.api_key = getattr(settings, "GOOGLE_PLACES_API_KEY", None)
        self.base_url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"

    def get_places_by_coordinates(self, latitude, longitude, categories=None, radius=10000):
        if not self.api_key:
            raise ValueError("Google Places API key is missing.")
        
        google_types = self.map_internal_categories_to_google_types(categories)

        all_results = []

        for place_type in google_types:
            params = {
                "location": f"{latitude},{longitude}",
                "radius": radius,
                "type": place_type,
                "key": self.api_key,
                "language": "tr",
            }

            response = requests.get(self.base_url, params=params, timeout=10)

            if response.status_code != 200:
                raise ValueError(f"Google Places API request failed with status {response.status_code}.")
            
            data = response.json()
            results = data.get("results", [])
            all_results.extend(results)

        unique_places = {place['place_id']: place for place in all_results}
        
        return list(unique_places.values())
    
    def normalize_place(self, feature):
        geometry = feature.get("geometry", {})
        location = geometry.get("location", {})

        lat = location.get("lat")
        lng = location.get("lng")

        if not lat or not lng:
            return None
        
        raw_categories = feature.get("types", [])
        internal_category = self.map_google_type_to_internal_category(raw_categories)

        return {
            "place_name": feature.get("name"),
            "latitude": lat,
            "longitude": lng,
            "category": internal_category,
            "rating": feature.get("rating", 4.0),
            "estimated_visit_duration": self.estimate_visit_duration_by_category(internal_category),
            "source": "google_places",
            "source_place_id": feature.get("place_id"),
            "formatted_address": feature.get("vicinity") or feature.get("formatted_address", ""),
            "raw_categories": raw_categories,
        }
    

    def map_internal_categories_to_google_types(self, categories):
        if not categories:
            return ["tourist_attraction"]
        
        category_map = {
            "history": ["tourist_attraction", "museum"],
            "historic": ["tourist_attraction"],
            "nature": ["park", "natural_feature"],
            "natural": ["park"],
            "tourism": ["tourist_attraction"],
            "sight": ["tourist_attraction"],
            "museum": ["museum", "art_gallery"],
            "religious": ["mosque", "church", "hindu_temple", "synagogue"],
            "food": ["restaurant", "cafe"],
            "restaurant": ["restaurant"],
        }

        google_types = set()

        for category in categories:
            normalized_category = category.strip().lower()
            mapped_types = category_map.get(normalized_category, ["tourist_attraction"])
            google_types.update(mapped_types)

        return list(google_types)
    
    def map_google_type_to_internal_category(self, types):  
        if not types:
            return "tourism"
            
        types_str = " ".join(types).lower()

        if "museum" in types_str or "art_gallery" in types_str:
            return "museum"
        if "park" in types_str or "natural_feature" in types_str:
            return "nature"
        if "mosque" in types_str or "church" in types_str or "place_of_worship" in types_str:
            return "religious"
        if "restaurant" in types_str or "food" in types_str:
            return "restaurant"
        if "cafe" in types_str:
            return "cafe"
        if "shopping_mall" in types_str:
            return "shopping"
        if "tourist_attraction" in types_str:
            if "ruins" in types_str or "hindu_temple" in types_str:
                return "history"
            return "tourism"

        return "tourism"

    def estimate_visit_duration_by_category(self, category):
        duration_map = {
            "history": 120,
            "nature": 180,
            "tourism": 90,
            "museum": 120,
            "religious": 60,
            "restaurant": 90,
            "cafe": 45,
            "shopping": 120,
        }
        return duration_map.get(category.lower(), 60)