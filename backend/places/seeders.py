import requests
from places.models import Place

def fetch_and_seed_places_for_city(city_name):
    """
    Hedef şehrin koordinatlarını bulur, etrafındaki 30km yarıçaptaki 
    mekanları Overpass API (Ücretsiz/API Key gerektirmez) ile çeker ve kaydeder.
    """
    try:
        nom_url = f"https://nominatim.openstreetmap.org/search?q={city_name}&format=json&limit=1"
        nom_res = requests.get(nom_url, headers={'User-Agent': 'TravelPlannerApp/1.0'})
        
        if nom_res.status_code != 200 or not nom_res.json():
            print(f"Could not find coordinates for {city_name}")
            return False
            
        lat = float(nom_res.json()[0]['lat'])
        lon = float(nom_res.json()[0]['lon'])
        
        overpass_url = "http://overpass-api.de/api/interpreter"
        
        overpass_query = f"""
        [out:json][timeout:25];
        (
          node["tourism"](around:30000,{lat},{lon});
          node["historic"](around:30000,{lat},{lon});
          node["amenity"="restaurant"](around:30000,{lat},{lon});
          node["amenity"="cafe"](around:30000,{lat},{lon});
          node["leisure"="park"](around:30000,{lat},{lon});
          node["shop"="mall"](around:30000,{lat},{lon});
        );
        out body limit 150;
        """
        
        op_res = requests.get(overpass_url, params={'data': overpass_query})
        
        if op_res.status_code != 200:
            print("Overpass API server error")
            return False
            
        elements = op_res.json().get('elements', [])
        
        for el in elements:
            tags = el.get('tags', {})
            name = tags.get('name')
            
            if not name:
                continue
                
            place_id = str(el.get('id'))
            place_lat = el.get('lat')
            place_lon = el.get('lon')
            
            category = 'tourism' 
            
            if 'historic' in tags or tags.get('tourism') == 'museum':
                category = 'history'
            elif tags.get('tourism') == 'museum':
                category = 'museum'
            elif tags.get('amenity') == 'restaurant':
                category = 'restaurant'
            elif tags.get('amenity') == 'cafe':
                category = 'cafe'
            elif 'leisure' in tags or tags.get('leisure') == 'park':
                category = 'park'
            elif 'shop' in tags:
                category = 'shopping'
            elif tags.get('tourism') in ['viewpoint', 'nature_reserve'] or tags.get('natural'):
                category = 'nature'
                
            Place.objects.get_or_create(
                source_place_id=place_id,
                defaults={
                    'place_name': name,
                    'latitude': place_lat,
                    'longitude': place_lon,
                    'category': category,
                    'rating': 4.0, 
                    'estimated_visit_duration': 60,
                    'source': 'overpass_api'
                }
            )
            
        print(f"Successfully seeded places for {city_name} via Overpass API")
        return True
        
    except Exception as e:
        print(f"Error fetching places for {city_name}: {e}")
        return False