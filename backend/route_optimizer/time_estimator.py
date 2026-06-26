from datetime import datetime, timedelta

def estimate_travel_time_minutes(distance_km):
    """
    Estimates travel time based on distance.

    Current assumption:
    1 km = 2 minutes

    Args:
        distance_km (float): Distance in kilometers.

    Returns:
        int: Estimated travel time in minutes.
    """
    return int(distance_km * 2)

def add_minutes_to_time(current_time, minutes):
    """
    Adds minutes to a time object.

    Args:
        current_time (datetime.time): Current time.
        minutes (int): Minutes to add.

    Returns:
        datetime.time: Updated time.
    """

    dummy_date = datetime.combine(datetime.today(), current_time)
    updated_datetime = dummy_date + timedelta(minutes=minutes)

    return updated_datetime.time()