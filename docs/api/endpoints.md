# API Endpoints

## Purpose

This document defines the initial REST API design for the AI-Powered Travel Planner.

The mobile application will communicate with the backend using JSON-based HTTP requests.

---

# Base URL

```text
/api/
```

---

# Main Test Scenario

The primary test scenario is:

> Plan a 3-night Montenegro trip in spring.

---

# 1. Create Trip Plan

## Endpoint

```http
POST /api/trip-plan/
```

## Purpose

Creates a new trip plan based on user input.

The backend will:

1. Save the trip request.
2. Retrieve places from external APIs.
3. Retrieve weather data.
4. Build a graph.
5. Optimize the route.
6. Create daily plans.
7. Return the generated itinerary.

---

## Request Body

```json
{
  "destination": "Montenegro",
  "start_date": "2026-04-10",
  "end_date": "2026-04-13",
  "preferences": [
    "Nature",
    "History"
  ],
  "budget": 500,
  "hotel": {
    "name": "Kotor Hotel",
    "latitude": 42.4247,
    "longitude": 18.7712
  }
}
```

---

## Response Body

```json
{
  "trip_id": 1,
  "destination": "Montenegro",
  "start_date": "2026-04-10",
  "end_date": "2026-04-13",
  "daily_plans": [
    {
      "day_number": 1,
      "date": "2026-04-10",
      "route_items": [
        {
          "visit_order": 1,
          "place_name": "Kotor Old Town",
          "category": "History",
          "arrival_time": "09:00",
          "departure_time": "11:00"
        },
        {
          "visit_order": 2,
          "place_name": "Kotor Fortress",
          "category": "History",
          "arrival_time": "11:30",
          "departure_time": "13:00"
        },
        {
          "visit_order": 3,
          "place_name": "Perast",
          "category": "History",
          "arrival_time": "14:00",
          "departure_time": "16:00"
        }
      ]
    }
  ]
}
```

---

# 2. List User Trips

## Endpoint

```http
GET /api/trips/
```

## Purpose

Returns all trips created by the authenticated user.

---

## Response Body

```json
[
  {
    "trip_id": 1,
    "destination": "Montenegro",
    "start_date": "2026-04-10",
    "end_date": "2026-04-13"
  }
]
```

---

# 3. Retrieve Trip Detail

## Endpoint

```http
GET /api/trips/{trip_id}/
```

## Purpose

Returns the full details of a specific trip.

---

## Response Body

```json
{
  "trip_id": 1,
  "destination": "Montenegro",
  "start_date": "2026-04-10",
  "end_date": "2026-04-13",
  "preferences": [
    "Nature",
    "History"
  ],
  "daily_plans": [
    {
      "day_number": 1,
      "date": "2026-04-10",
      "route_items": [
        {
          "visit_order": 1,
          "place_name": "Kotor Old Town",
          "arrival_time": "09:00",
          "departure_time": "11:00"
        }
      ]
    }
  ]
}
```

---

# 4. List Places

## Endpoint

```http
GET /api/places/
```

## Purpose

Returns places stored in the system.

This endpoint is useful for testing, debugging, and future map-based features.

---

## Query Parameters

```text
destination=Montenegro
category=History
```

Example:

```http
GET /api/places/?destination=Montenegro&category=History
```

---

## Response Body

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

# 5. Delete Trip

## Endpoint

```http
DELETE /api/trips/{trip_id}/
```

## Purpose

Deletes a trip created by the authenticated user.

---

## Response Body

```json
{
  "message": "Trip deleted successfully."
}
```

---

# Authentication

The API will use token-based authentication.

Possible options:

* JWT Authentication
* Django REST Framework Token Authentication

For this project, JWT Authentication is recommended.

---

# Initial Endpoint List

| Method | Endpoint              | Purpose                    |
| ------ | --------------------- | -------------------------- |
| POST   | /api/trip-plan/       | Create optimized trip plan |
| GET    | /api/trips/           | List user trips            |
| GET    | /api/trips/{trip_id}/ | Retrieve trip detail       |
| GET    | /api/places/          | List places                |
| DELETE | /api/trips/{trip_id}/ | Delete trip                |

---

# Notes

* All responses will be returned as JSON.
* The mobile app will consume these endpoints.
* The first version will focus on trip planning and route generation.
* User authentication endpoints will be added separately.
