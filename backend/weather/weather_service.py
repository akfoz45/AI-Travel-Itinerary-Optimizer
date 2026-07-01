import requests
from django.conf import settings


class OpenMeteoWeatherService:
    def __init__(self):
        self.base_url = settings.WEATHER_BASE_URL

    def _get(self, endpoint, params=None):
        if params is None:
            params = {}

        url = f"{self.base_url}{endpoint}"

        response = requests.get(url, params=params, timeout=10)

        if response.status_code != 200:
            raise ValueError(
                f"Open-Meteo API request failed with status code "
                f"{response.status_code}. Response: {response.text}"
            )

        return response.json()

    def get_current_weather_by_coordinates(self, latitude, longitude):
        data = self._get(
            endpoint="/v1/forecast",
            params={
                "latitude": latitude,
                "longitude": longitude,
                "current": ",".join([
                    "temperature_2m",
                    "relative_humidity_2m",
                    "apparent_temperature",
                    "precipitation",
                    "rain",
                    "weather_code",
                    "wind_speed_10m",
                ]),
                "hourly": ",".join([
                    "temperature_2m",
                    "precipitation_probability",
                    "precipitation",
                    "weather_code",
                ]),
                "forecast_days": 1,
                "timezone": "auto",
            },
        )

        return self.normalize_current_weather(data)

    def normalize_current_weather(self, data):
        current = data.get("current", {})

        weather_code = current.get("weather_code")
        temperature = current.get("temperature_2m")
        precipitation = current.get("precipitation")
        rain = current.get("rain")
        wind_speed = current.get("wind_speed_10m")
        humidity = current.get("relative_humidity_2m")
        apparent_temperature = current.get("apparent_temperature")

        weather_description = self.get_weather_description(weather_code)

        is_rainy = self.is_rainy_weather(
            weather_code=weather_code,
            precipitation=precipitation,
            rain=rain,
        )

        is_good_for_outdoor = self.is_good_for_outdoor(
            weather_code=weather_code,
            temperature=temperature,
            wind_speed=wind_speed,
        )

        return {
            "latitude": data.get("latitude"),
            "longitude": data.get("longitude"),
            "timezone": data.get("timezone"),
            "time": current.get("time"),
            "temperature": temperature,
            "apparent_temperature": apparent_temperature,
            "humidity": humidity,
            "precipitation": precipitation,
            "rain": rain,
            "wind_speed": wind_speed,
            "weather_code": weather_code,
            "weather_description": weather_description,
            "is_rainy": is_rainy,
            "is_good_for_outdoor": is_good_for_outdoor,
        }

    def get_weather_description(self, weather_code):
        """
        Converts Open-Meteo WMO weather codes into readable labels.
        """

        weather_code_map = {
            0: "Clear sky",
            1: "Mainly clear",
            2: "Partly cloudy",
            3: "Overcast",

            45: "Fog",
            48: "Depositing rime fog",

            51: "Light drizzle",
            53: "Moderate drizzle",
            55: "Dense drizzle",

            56: "Light freezing drizzle",
            57: "Dense freezing drizzle",

            61: "Slight rain",
            63: "Moderate rain",
            65: "Heavy rain",

            66: "Light freezing rain",
            67: "Heavy freezing rain",

            71: "Slight snow fall",
            73: "Moderate snow fall",
            75: "Heavy snow fall",

            77: "Snow grains",

            80: "Slight rain showers",
            81: "Moderate rain showers",
            82: "Violent rain showers",

            85: "Slight snow showers",
            86: "Heavy snow showers",

            95: "Thunderstorm",
            96: "Thunderstorm with slight hail",
            99: "Thunderstorm with heavy hail",
        }

        return weather_code_map.get(weather_code, "Unknown")

    def is_rainy_weather(self, weather_code, precipitation=None, rain=None):
        rainy_codes = {
            51, 53, 55,
            56, 57,
            61, 63, 65,
            66, 67,
            80, 81, 82,
            95, 96, 99,
        }

        if weather_code in rainy_codes:
            return True

        if precipitation is not None and precipitation > 0:
            return True

        if rain is not None and rain > 0:
            return True

        return False

    def is_good_for_outdoor(self, weather_code, temperature, wind_speed=None):
        bad_weather_codes = {
            45, 48,
            51, 53, 55,
            56, 57,
            61, 63, 65,
            66, 67,
            71, 73, 75,
            77,
            80, 81, 82,
            85, 86,
            95, 96, 99,
        }

        if weather_code in bad_weather_codes:
            return False

        if temperature is None:
            return False

        if temperature < 5 or temperature > 35:
            return False

        if wind_speed is not None and wind_speed > 40:
            return False

        return True
    
    def get_weather_note(self, weather_context):
        if not weather_context:
            return "Weather data was not available. Route was generated without weather adjustment."
        
        is_rainy = weather_context.get("is_rainy", False)
        is_good_for_outdoor = weather_context.get("is_good_for_outdoor", False)
        weather_description = weather_context.get("weather_description")
        temperature = weather_context.get("temperature")

        if is_rainy:
            return (
                f"Rainy weather detected"
                f"{f' ({weather_description})' if weather_description else ''}. "
                "Outdoor places received a score penalty, while indoor-friendly places received a score bonus."
            )
        
        if is_good_for_outdoor:
            return (
                f"Good outdoor weather detected"
                f"{f' ({weather_description}, {temperature}°C)' if temperature is not None else ''}. "
                "Nature and tourism places received a score bonus."
            )

        return (
            f"Weather conditions are not ideal for outdoor activities"
            f"{f' ({weather_description}, {temperature}°C)' if temperature is not None else ''}. "
            "The route was adjusted conservatively."
        )