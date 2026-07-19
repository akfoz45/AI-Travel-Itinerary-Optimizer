import os
import pickle
import pandas as pd
from django.conf import settings

class FlightPricePredictionService:
    def __init__(self):
        model_path = os.path.join(settings.BASE_DIR, "ml_model", "flight_price_model.pkl")

        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model file not found: {model_path}")
        
        with open(model_path, "rb") as file:
            self.model = pickle.load(file)

    def predict_price(self, departure_time, arrival_time, flight_class, stops, duration, days_left):
        input_data = pd.DataFrame([{
            "departure_time": departure_time, 
            "arrival_time": arrival_time, 
            "class": flight_class,
            "stops": stops,
            "duration": float(duration),
            "days_left": int(days_left)
        }])

        predict_price = self.model.predict(input_data)[0]

        return max(0, round(predict_price, 2))