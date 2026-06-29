"""
This code was written for the OpenTripMap API.
"""

import requests
from django.conf import settings

class OpenTripMapService:
    def __init__(self):
        self.api_key = settings.OPENTRIPMAP_API_KEY
        self.base_url = settings.OPENTRIPMAP_BASE_URL

    def _get(self, endpoint, params=None):
        if not self.api_key:
            raise ValueError("OpenTripMap API key is missing.")
        
        if params is None:
            params = {}

        params["apikey"] = self.api_key

        url = f"{self.base_url}{endpoint}"

        response = requests.get(url, params=params, timeout=10)

        if response.status_code != 200:
            raise ValueError(f"OpenTripMap API request failed with status code {response.status_code}.")
        
        return response.json()
    
    def get_city_coordinates(self, city_name):
        return self._get(
            endpoint="/places/geoname",
            params={
                "name": city_name
            }
        )
    
    def get_places_by_radius(self, latitude, longitude, radius=10000, limit=20, kinds=None, rate=2):
        params = {
            "lat": latitude,
            "lon": longitude,
            "radius": radius,
            "limit": limit,
            "rate": rate,
            "format": "json",
        }

        if kinds:
            params["kinds"] = kinds

        return self._get(endpoint="/places/radius", params=params)
    
    def get_place_detail(self, xid):
        return self._get(endpoint=f"/places/xid/{xid}")