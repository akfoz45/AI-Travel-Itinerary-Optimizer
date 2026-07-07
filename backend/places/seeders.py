import requests
from places.models import Place
from external_services.google_places_service import GooglePlaceService

def fetch_and_seed_places_for_city(city_name):
    try:
        nom_url = f"https://nominatim.openstreetmap.org/search?q={city_name}&format=json&limit=1"
        nom_res = requests.get(nom_url, headers={'User-Agent': 'TravelPlannerApp/1.0'})
        
        if nom_res.status_code != 200 or not nom_res.json():
            print(f"Could not find coordinates for {city_name}")
            return False
            
        lat = float(nom_res.json()[0]['lat'])
        lon = float(nom_res.json()[0]['lon'])
        
        google_service = GooglePlaceService()

        target_categories = [
            "tourism", "history", "nature", 
            "museum", "religious", "restaurant", 
            "cafe", "shopping"
        ]
        
        print(f"Fetching Google Places for {city_name} (Lat: {lat}, Lon: {lon})...")

        raw_places = google_service.get_places_by_coordinates(
            latitude=lat,
            longitude=lon,
            categories=target_categories,
            radius=30000  
        )
        
        saved_count = 0
        
        for raw_place in raw_places:
            normalized_place = google_service.normalize_place(raw_place)
            
            if not normalized_place or not normalized_place.get("place_name"):
                continue
                
            Place.objects.get_or_create(
                source_place_id=normalized_place["source_place_id"],
                defaults={
                    'place_name': normalized_place["place_name"],
                    'latitude': normalized_place["latitude"],
                    'longitude': normalized_place["longitude"],
                    'category': normalized_place["category"],
                    'rating': normalized_place["rating"], 
                    'estimated_visit_duration': normalized_place["estimated_visit_duration"],
                    'source': normalized_place["source"]
                }
            )
            saved_count += 1
            
        print(f"Successfully seeded {saved_count} places for {city_name} via Google Places API")
        return True
        
    except Exception as e:
        print(f"Error fetching places for {city_name}: {e}")
        return False