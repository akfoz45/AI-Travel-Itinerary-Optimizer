# API Endpoints Documentation

This document describes the REST API endpoints of the **AI-Powered Travel Planner** backend.

## Base URL

```http
http://127.0.0.1:8000/api/
```

---

# 1. Authentication

## Register User

Creates a new user account.

```http
POST /api/auth/register/
```

### Request Body

```json
{
  "username": "akif",
  "email": "akif@example.com",
  "password": "StrongPassword123"
}
```

### Success Response

```json
{
  "message": "User registered successfully.",
  "user": {
    "id": 1,
    "username": "akif",
    "email": "akif@example.com"
  }
}
```

---

## Obtain JWT Token

Authenticates the user and returns access and refresh tokens.

```http
POST /api/auth/token/
```

### Request Body

```json
{
  "username": "akif",
  "password": "StrongPassword123"
}
```

### Success Response

```json
{
  "refresh": "refresh_token_here",
  "access": "access_token_here"
}
```

---

## Refresh JWT Token

Generates a new access token using the refresh token.

```http
POST /api/auth/token/refresh/
```

### Request Body

```json
{
  "refresh": "refresh_token_here"
}
```

### Success Response

```json
{
  "access": "new_access_token_here"
}
```

---

# 2. Places

## List Places

Returns all places.

```http
GET /api/places/
```

### Query Parameters

| Parameter    | Type   | Required | Description                      |
| ------------ | ------ | -------- | -------------------------------- |
| `category`   | string | No       | Filters places by category       |
| `min_rating` | number | No       | Filters places by minimum rating |

### Example

```http
GET /api/places/?category=History&min_rating=4
```

### Success Response

```json
[
  {
    "place_id": 1,
    "place_name": "Kotor Old Town",
    "latitude": 42.4247,
    "longitude": 18.7712,
    "category": "History",
    "rating": 4.8,
    "estimated_visit_duration": 120
  }
]
```

---

# 3. Trips

All trip endpoints require JWT authentication.

## Authorization Header

```http
Authorization: Bearer <access_token>
```

---

## List User Trips

Returns trips owned by the authenticated user.

```http
GET /api/trips/
```

### Success Response

```json
[
  {
    "trip_id": 1,
    "destination": "Montenegro",
    "start_date": "2026-04-10",
    "end_date": "2026-04-13",
    "preferences": [
      {
        "preference_id": 1,
        "preference": "Nature"
      }
    ],
    "day_plans": [],
    "hotels": [
      {
        "hotel_id": 1,
        "name": "Kotor Hotel",
        "latitude": 42.4247,
        "longitude": 18.7712,
        "rating": 4.5
      }
    ]
  }
]
```

---

## Create Trip

Creates a new trip for the authenticated user.

```http
POST /api/trips/
```

### Request Body

```json
{
  "destination": "Montenegro",
  "start_date": "2026-04-10",
  "end_date": "2026-04-13",
  "preferences": ["Nature", "History"],
  "hotel": {
    "name": "Kotor Hotel",
    "latitude": 42.4247,
    "longitude": 18.7712,
    "rating": 4.5
  }
}
```

### Success Response

```json
{
  "trip_id": 1,
  "destination": "Montenegro",
  "start_date": "2026-04-10",
  "end_date": "2026-04-13",
  "preferences": [
    {
      "preference_id": 1,
      "preference": "Nature"
    },
    {
      "preference_id": 2,
      "preference": "History"
    }
  ],
  "day_plans": [],
  "hotels": [
    {
      "hotel_id": 1,
      "name": "Kotor Hotel",
      "latitude": 42.4247,
      "longitude": 18.7712,
      "rating": 4.5
    }
  ]
}
```

---

## Get Trip Detail

Returns a specific trip owned by the authenticated user.

```http
GET /api/trips/{trip_id}/
```

### Success Response

```json
{
  "trip_id": 1,
  "destination": "Montenegro",
  "start_date": "2026-04-10",
  "end_date": "2026-04-13",
  "preferences": [],
  "day_plans": [],
  "hotels": []
}
```

---

## Delete Trip

Deletes a specific trip owned by the authenticated user.

```http
DELETE /api/trips/{trip_id}/
```

### Success Response

```json
{
  "message": "Trip deleted successfully."
}
```

---

# 4. Manual Day Plan Management

## Create Day Plan

Creates a day plan manually for a trip.

```http
POST /api/trips/{trip_id}/day-plans/
```

### Request Body

```json
{
  "day_number": 1,
  "date": "2026-04-10"
}
```

### Success Response

```json
{
  "plan_id": 1,
  "day_number": 1,
  "date": "2026-04-10",
  "daily_summary": null,
  "route_items": []
}
```

---

## Add Route Item

Adds a place manually to a day plan.

```http
POST /api/trips/day-plans/{plan_id}/route-items/
```

### Request Body

```json
{
  "place": 1,
  "visit_order": 1,
  "arrival_time": "09:00",
  "departure_time": "11:00"
}
```

### Success Response

```json
{
  "route_id": 1,
  "visit_order": 1,
  "place_name": "Kotor Old Town",
  "category": "History",
  "arrival_time": "09:00:00",
  "departure_time": "11:00:00"
}
```

---

# 5. Route Optimization

## Generate Single-Day Route

Generates an optimized route for a specific day of a trip.

```http
POST /api/trips/{trip_id}/generate-route/
```

### Request Body

```json
{
  "categories": ["history", "nature"],
  "day_number": 1,
  "date": "2026-04-10",
  "start_time": "09:00",
  "end_time": "18:00"
}
```

`start_place` is optional if the trip has a hotel. If omitted, the system selects the nearest suitable place to the hotel.

### Optional Request Body With Start Place

```json
{
  "start_place": "kotor old town",
  "categories": ["history", "nature"],
  "day_number": 1,
  "date": "2026-04-10",
  "start_time": "09:00",
  "end_time": "18:00"
}
```

### Success Response

```json
{
  "message": "Route generated successfully.",
  "start_time": "09:00:00",
  "end_time": "18:00:00",
  "summary": {
    "total_distance_km": 18.4,
    "total_travel_time_minutes": 36,
    "total_visit_duration_minutes": 240,
    "return_to_hotel_distance_km": 3.2,
    "return_to_hotel_minutes": 6,
    "total_plan_duration_minutes": 282,
    "number_of_places": 3,
    "unplanned_place_count": 1,
    "unplanned_places": ["Skadar Lake"],
    "hotel_used_as_start": "Kotor Hotel",
    "selected_start_place": "Kotor Old Town",
    "start_place_source": "hotel_nearest_place"
  },
  "day_plan": {
    "plan_id": 1,
    "day_number": 1,
    "date": "2026-04-10",
    "daily_summary": null,
    "route_items": [
      {
        "route_id": 1,
        "visit_order": 1,
        "place_name": "Kotor Old Town",
        "category": "History",
        "arrival_time": "09:08:00",
        "departure_time": "11:08:00"
      }
    ]
  }
}
```

---

## Generate Full Route

Generates an optimized multi-day route for the entire trip based on the trip start and end dates.

```http
POST /api/trips/{trip_id}/generate-full-route/
```

### Request Body

```json
{
  "categories": ["history", "nature"],
  "start_time": "09:00",
  "end_time": "18:00"
}
```

`start_place` is optional if the trip has a hotel. If omitted, the system selects the nearest suitable place to the hotel.

### Optional Request Body With Start Place

```json
{
  "start_place": "kotor old town",
  "categories": ["history", "nature"],
  "start_time": "09:00",
  "end_time": "18:00"
}
```

### Success Response

```json
{
  "message": "Full route generated successfully.",
  "trip_id": 1,
  "destination": "Montenegro",
  "start_date": "2026-04-10",
  "end_date": "2026-04-13",
  "total_days": 4,
  "start_time": "09:00:00",
  "end_time": "18:00:00",
  "summary": {
    "generated_days": 3,
    "number_of_places": 8,
    "total_distance_km": 82.4,
    "total_travel_time_minutes": 164,
    "total_visit_duration_minutes": 540,
    "return_to_hotel_distance_km": 18.2,
    "return_to_hotel_minutes": 36,
    "total_plan_duration_minutes": 740,
    "unplanned_place_count": 0,
    "unplanned_places": [],
    "hotel_used_as_start": "Kotor Hotel",
    "selected_start_place": "Kotor Old Town",
    "start_place_source": "hotel_nearest_place"
  },
  "day_plans": [
    {
      "plan_id": 1,
      "day_number": 1,
      "date": "2026-04-10",
      "daily_summary": {
        "number_of_places": 3,
        "total_distance_km": 18.4,
        "travel_time_minutes": 36,
        "visit_duration_minutes": 240,
        "return_to_hotel_distance_km": 3.2,
        "return_to_hotel_minutes": 6,
        "total_day_duration_minutes": 282
      },
      "route_items": [
        {
          "route_id": 1,
          "visit_order": 1,
          "place_name": "Kotor Old Town",
          "category": "History",
          "arrival_time": "09:08:00",
          "departure_time": "11:08:00"
        }
      ]
    }
  ]
}
```

---

# 6. Common Error Responses

## Trip Not Found

```json
{
  "error": "Trip not found."
}
```

---

## No Places Found

```json
{
  "error": "No places found for given categories."
}
```

---

## Invalid Start Place

```json
{
  "error": "Start place not found in selected places. Available places: [...]"
}
```

---

## Missing Start Place Without Hotel

```json
{
  "error": "Start place is required when trip has no hotel."
}
```

---

## Time Window Too Short

```json
{
  "error": "Daily time window is too short for selected places."
}
```

---

## Unauthorized

```json
{
  "detail": "Authentication credentials were not provided."
}
```

---

# 7. Notes

* Trip endpoints require JWT authentication.
* Place listing can be public.
* `start_place` is optional when the trip has a hotel.
* If `start_place` is omitted and the trip has a hotel, the system selects the nearest suitable place to the hotel.
* Route generation uses a weighted graph and nearest neighbor algorithm.
* Time window validation prevents unrealistic daily routes.
* Hotel-to-place and place-to-hotel travel times are included in the route summary.
* `daily_summary` is calculated dynamically and is not stored as a database column.
