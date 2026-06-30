# API Endpoints Documentation

This document describes the main REST API endpoints of the AI-Powered Travel Planner project.

Base URL for local development:

```http
http://127.0.0.1:8000
```

Most endpoints require JWT authentication.

Use the following header for protected endpoints:

```http
Authorization: Bearer <access_token>
```

---

# Authentication Endpoints

## Register User

Creates a new user account.

### Endpoint

```http
POST /api/auth/register/
```

### Authentication

Not required.

### Request Body

```json
{
  "username": "akif",
  "email": "akif@example.com",
  "password": "StrongPassword123"
}
```

### Example Response

```json
{
  "id": 1,
  "username": "akif",
  "email": "akif@example.com"
}
```

---

## Get JWT Token

Returns access and refresh tokens.

### Endpoint

```http
POST /api/auth/token/
```

### Authentication

Not required.

### Request Body

```json
{
  "username": "akif",
  "password": "StrongPassword123"
}
```

### Example Response

```json
{
  "refresh": "refresh_token_here",
  "access": "access_token_here"
}
```

---

## Refresh JWT Token

Generates a new access token using a refresh token.

### Endpoint

```http
POST /api/auth/token/refresh/
```

### Authentication

Not required.

### Request Body

```json
{
  "refresh": "refresh_token_here"
}
```

### Example Response

```json
{
  "access": "new_access_token_here"
}
```

---

# Places Endpoints

## List Places

Returns all available places.

### Endpoint

```http
GET /api/places/
```

### Authentication

Not required.

### Query Parameters

| Parameter | Type | Required | Description |
|---|---:|---:|---|
| `category` | string | No | Filters places by category. Case-insensitive. |
| `min_rating` | float | No | Filters places with rating greater than or equal to the given value. |

### Example Request

```http
GET /api/places/?category=Nature
```

### Example Response

```json
[
  {
    "place_id": 1,
    "place_name": "Lovcen National Park",
    "latitude": 42.399,
    "longitude": 18.837,
    "category": "Nature",
    "rating": null,
    "estimated_visit_duration": 180,
    "source": "geoapify",
    "source_place_id": "example-source-place-id"
  }
]
```

---

# Trip Endpoints

## List Trips

Returns trips owned by the authenticated user.

### Endpoint

```http
GET /api/trips/
```

### Authentication

Required.

### Example Response

```json
[
  {
    "trip_id": 1,
    "destination": "Kotor, Montenegro",
    "start_date": "2026-04-10",
    "end_date": "2026-04-12"
  }
]
```

---

## Create Trip

Creates a new trip for the authenticated user.

### Endpoint

```http
POST /api/trips/
```

### Authentication

Required.

### Request Body

```json
{
  "destination": "Kotor, Montenegro",
  "start_date": "2026-04-10",
  "end_date": "2026-04-12",
  "preferences": ["nature", "history"]
}
```

### Example Response

```json
{
  "trip_id": 1,
  "destination": "Kotor, Montenegro",
  "start_date": "2026-04-10",
  "end_date": "2026-04-12",
  "preferences": [
    {
      "preference_id": 1,
      "preference": "nature"
    },
    {
      "preference_id": 2,
      "preference": "history"
    }
  ]
}
```

---

## Retrieve Trip Detail

Returns a single trip with related data.

### Endpoint

```http
GET /api/trips/{trip_id}/
```

### Authentication

Required.

### Example Response

```json
{
  "trip_id": 1,
  "destination": "Kotor, Montenegro",
  "start_date": "2026-04-10",
  "end_date": "2026-04-12",
  "preferences": [
    {
      "preference_id": 1,
      "preference": "nature"
    }
  ],
  "hotels": [
    {
      "hotel_id": 1,
      "name": "Hotel Example",
      "latitude": 42.425,
      "longitude": 18.771,
      "rating": 4.5
    }
  ],
  "day_plans": []
}
```

---

## Delete Trip

Deletes a trip owned by the authenticated user.

### Endpoint

```http
DELETE /api/trips/{trip_id}/
```

### Authentication

Required.

### Example Response

```json
{
  "message": "Trip deleted successfully."
}
```

---

# Route Generation Endpoints

## Generate Route for a Single Day

Generates a route for a specific day of a trip.

This endpoint is useful when the client wants to manually create or regenerate only one day.

### Endpoint

```http
POST /api/trips/{trip_id}/generate-route/
```

### Authentication

Required.

```http
Authorization: Bearer <access_token>
```

### Request Body

```json
{
  "day_number": 1,
  "date": "2026-04-10",
  "categories": ["nature", "history"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "recommended"
}
```

### Request Body Fields

| Field | Type | Required | Description |
|---|---:|---:|---|
| `day_number` | integer | Yes | Day number inside the trip. |
| `date` | date | Yes | Date of the day plan. |
| `start_place` | string | No | Optional start place name. If not provided and the trip has a hotel, the nearest suitable place to the hotel is used. |
| `categories` | list[string] | No | Preferred categories. Example: `["nature", "history"]`. |
| `start_time` | time | No | Route start time. Default: `09:00`. |
| `end_time` | time | No | Route end time. Default: `18:00`. |
| `route_mode` | string | No | Allowed values: `balanced`, `shortest`, `recommended`. Default: `balanced`. |
| `distance_weight` | float | No | Optional manual distance weight. |
| `score_weight` | float | No | Optional manual recommendation score weight. |

### Route Modes

| Mode | Description | Distance Weight | Score Weight |
|---|---|---:|---:|
| `balanced` | Balances travel distance and recommendation score. | `1.0` | `0.3` |
| `shortest` | Prioritizes shorter travel distance. | `1.5` | `0.1` |
| `recommended` | Prioritizes places with higher recommendation scores. | `0.8` | `0.6` |

### Manual Weight Override

If `distance_weight` and `score_weight` are provided, they override the selected `route_mode`.

Example:

```json
{
  "day_number": 1,
  "date": "2026-04-10",
  "categories": ["nature", "history"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "recommended",
  "distance_weight": 2.0,
  "score_weight": 0.05
}
```

In this case, the route mode is still shown as `recommended`, but the custom weight values are used.

### Example Response

```json
{
  "message": "Route generated successfully.",
  "summary": {
    "day_number": 1,
    "date": "2026-04-10",
    "number_of_places": 4,
    "total_distance_km": 18.4,
    "total_travel_time_minutes": 37,
    "total_visit_duration_minutes": 300,
    "return_to_hotel_distance_km": 5.2,
    "return_to_hotel_minutes": 11,
    "total_plan_duration_minutes": 348,
    "unplanned_place_count": 2,
    "unplanned_places": [
      "Example Place"
    ],
    "hotel_used_as_start": "Hotel Example",
    "selected_start_place": "Kotor Old Town",
    "start_place_source": "hotel_nearest_place",
    "route_algorithm": "score_based_nearest_neighbor",
    "route_mode": "recommended",
    "route_quality_note": "This route prioritizes places with higher recommendation scores.",
    "distance_weight": 0.8,
    "score_weight": 0.6
  },
  "day_plan": {
    "plan_id": 5,
    "day_number": 1,
    "date": "2026-04-10",
    "daily_summary": {
      "day_number": 1,
      "number_of_places": 4,
      "total_distance_km": 18.4
    },
    "route_items": [
      {
        "route_id": 12,
        "visit_order": 1,
        "place_name": "Lovcen National Park",
        "category": "Nature",
        "source": "geoapify",
        "recommendation_score": 95,
        "arrival_time": "09:30:00",
        "departure_time": "12:30:00"
      }
    ]
  }
}
```

### Notes

- This endpoint creates or regenerates one specific day plan.
- The optimizer uses the selected categories, route mode, hotel location, travel distance, and recommendation score.
- If the trip has a hotel and `start_place` is not provided, the route starts from the nearest suitable place to the hotel.
- Places that cannot fit into the selected time window are returned in `unplanned_places`.

---

## Generate Full Route for a Trip

Generates a complete multi-day travel route for a trip.

The route optimizer considers:

- selected place categories
- hotel location, if available
- daily start and end time
- estimated visit duration
- travel distance between places
- recommendation score
- selected route mode

### Endpoint

```http
POST /api/trips/{trip_id}/generate-full-route/
```

### Authentication

Required.

Send JWT access token in the Authorization header:

```http
Authorization: Bearer <access_token>
```

### Request Body

```json
{
  "categories": ["nature", "museum", "history"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "balanced"
}
```

### Request Body Fields

| Field | Type | Required | Description |
|---|---:|---:|---|
| `start_place` | string | No | Optional start place name. If not provided, the nearest place to the trip hotel is used. |
| `categories` | list[string] | No | Preferred place categories. Example: `["nature", "history"]`. |
| `start_time` | time | No | Daily route start time. Default: `09:00`. |
| `end_time` | time | No | Daily route end time. Default: `18:00`. |
| `route_mode` | string | No | Route optimization mode. Allowed values: `balanced`, `shortest`, `recommended`. Default: `balanced`. |
| `distance_weight` | float | No | Optional manual override for distance importance. |
| `score_weight` | float | No | Optional manual override for recommendation score importance. |

### Route Modes

| Mode | Description | Distance Weight | Score Weight |
|---|---|---:|---:|
| `balanced` | Balances travel distance and recommendation score. | `1.0` | `0.3` |
| `shortest` | Prioritizes shorter travel distance. | `1.5` | `0.1` |
| `recommended` | Prioritizes places with higher recommendation scores. | `0.8` | `0.6` |

### Manual Weight Override

If `distance_weight` and `score_weight` are provided, they override the selected `route_mode`.

Example:

```json
{
  "categories": ["nature", "museum", "history"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "recommended",
  "distance_weight": 2.0,
  "score_weight": 0.05
}
```

In this case, the route mode is still shown as `recommended`, but the custom weight values are used.

### Example Response

```json
{
  "message": "Full route generated successfully.",
  "summary": {
    "generated_days": 3,
    "number_of_places": 9,
    "total_distance_km": 48.6,
    "total_travel_time_minutes": 98,
    "total_visit_duration_minutes": 720,
    "return_to_hotel_distance_km": 12.4,
    "return_to_hotel_minutes": 25,
    "total_plan_duration_minutes": 843,
    "unplanned_place_count": 4,
    "unplanned_places": [
      "Example Unplanned Place"
    ],
    "hotel_used_as_start": "Hotel Example",
    "selected_start_place": "Kotor Old Town",
    "start_place_source": "hotel_nearest_place",
    "route_algorithm": "score_based_nearest_neighbor",
    "route_mode": "balanced",
    "route_quality_note": "This route balances travel distance and recommendation score.",
    "distance_weight": 1.0,
    "score_weight": 0.3
  },
  "day_plans": [
    {
      "plan_id": 1,
      "day_number": 1,
      "date": "2026-04-10",
      "daily_summary": {
        "day_number": 1,
        "number_of_places": 3,
        "total_distance_km": 15.2,
        "total_travel_time_minutes": 31,
        "total_visit_duration_minutes": 240
      },
      "route_items": [
        {
          "route_id": 1,
          "visit_order": 1,
          "place_name": "Kotor Old Town",
          "category": "History",
          "source": "manual",
          "recommendation_score": 100,
          "arrival_time": "09:10:00",
          "departure_time": "11:10:00"
        }
      ]
    }
  ]
}
```

### Notes

- Existing day plans and route items for the trip are deleted before generating a new full route.
- If the trip has a hotel and `start_place` is not provided, the optimizer starts from the nearest suitable place to the hotel.
- If there is not enough time in a day, remaining places are moved to following days.
- Places that cannot fit into the trip duration are returned in `unplanned_places`.
- The route algorithm is currently `score_based_nearest_neighbor`.

---

# Geoapify External Service Endpoints

## Get City Coordinates

Returns latitude and longitude information for a city using Geoapify Geocoding API.

### Endpoint

```http
GET /api/external/geoapify/city/?name=Kotor, Montenegro
```

### Authentication

Required.

### Query Parameters

| Parameter | Type | Required | Description |
|---|---:|---:|---|
| `name` | string | Yes | City name to geocode. |

### Example Response

```json
{
  "city": "Kotor, Montenegro",
  "formatted": "Kotor, Montenegro",
  "latitude": 42.425,
  "longitude": 18.771
}
```

---

## Search Places from Geoapify

Searches places from Geoapify without importing them into the local database.

### Endpoint

```http
GET /api/external/geoapify/places/?city=Kotor, Montenegro&categories=nature,history
```

### Authentication

Required.

### Query Parameters

| Parameter | Type | Required | Description |
|---|---:|---:|---|
| `city` | string | Yes | City name. |
| `categories` | string | No | Comma-separated internal categories. Example: `nature,history`. |
| `radius` | integer | No | Search radius in meters. |
| `limit` | integer | No | Maximum number of places requested from Geoapify. |

### Example Response

```json
{
  "city": {
    "city": "Kotor, Montenegro",
    "formatted": "Kotor, Montenegro",
    "latitude": 42.425,
    "longitude": 18.771
  },
  "requested_categories": ["nature", "history"],
  "geoapify_categories": ["natural", "leisure.park", "heritage", "tourism.sights"],
  "raw_place_count": 30,
  "normalized_place_count": 22,
  "filtered_out_count": 8,
  "places": [
    {
      "place_name": "Example Nature Place",
      "latitude": 42.43,
      "longitude": 18.78,
      "category": "Nature",
      "rating": null,
      "estimated_visit_duration": 180,
      "source": "geoapify",
      "source_place_id": "example-source-place-id",
      "formatted_address": "Example Address",
      "raw_categories": [
        "natural"
      ]
    }
  ],
  "filtered_out_places": [
    {
      "place_name": "Savo Ilić",
      "category": "Tourism",
      "reason": "excluded_category: memorial",
      "raw_categories": [
        "tourism",
        "tourism.sights",
        "tourism.sights.memorial"
      ],
      "source": "geoapify",
      "source_place_id": "example-source-place-id"
    }
  ]
}
```

---

## Import Places from Geoapify

Imports places from Geoapify into the local `place` table.

The import process includes:

- city geocoding
- category mapping
- place normalization
- quality filtering
- duplicate detection
- source tracking

### Endpoint

```http
POST /api/external/geoapify/import-places/
```

### Authentication

Required.

### Request Body

```json
{
  "city": "Kotor, Montenegro",
  "categories": ["nature", "history"],
  "radius": 30000,
  "limit": 30
}
```

### Request Body Fields

| Field | Type | Required | Description |
|---|---:|---:|---|
| `city` | string | Yes | City name used for Geoapify search. |
| `categories` | list[string] | No | Internal categories mapped to Geoapify categories. |
| `radius` | integer | No | Search radius in meters. |
| `limit` | integer | No | Maximum number of places requested from Geoapify. |

### Example Response

```json
{
  "message": "Places imported successfully.",
  "city": {
    "city": "Kotor, Montenegro",
    "formatted": "Kotor, Montenegro",
    "latitude": 42.425,
    "longitude": 18.771
  },
  "requested_categories": ["nature", "history"],
  "geoapify_categories": ["natural", "leisure.park", "heritage", "tourism.sights"],
  "raw_place_count": 30,
  "normalized_place_count": 22,
  "filtered_out_count": 8,
  "imported_count": 20,
  "skipped_count": 2,
  "imported_places": [
    {
      "place_id": 15,
      "place_name": "Example Nature Place",
      "category": "Nature",
      "source": "geoapify",
      "source_place_id": "example-source-place-id"
    }
  ],
  "skipped_places": [
    {
      "place_name": "Existing Place",
      "reason": "duplicate",
      "existing_place_id": 3
    }
  ],
  "filtered_out_places": [
    {
      "place_name": "Savo Ilić",
      "category": "Tourism",
      "reason": "excluded_category: memorial",
      "raw_categories": [
        "tourism",
        "tourism.sights",
        "tourism.sights.memorial"
      ],
      "source": "geoapify",
      "source_place_id": "example-source-place-id"
    }
  ]
}
```

### Notes

- `source` is stored as `geoapify`.
- `source_place_id` is used for duplicate detection.
- Places can also be skipped if a nearby place with the same name already exists.
- Weak POIs such as memorials, military objects, cemeteries, and similar records can be filtered out.
- Imported Geoapify places usually have `rating: null`, because Geoapify does not provide a reliable Google-like rating field for all POIs.
- Visit duration is estimated according to internal category.

---

# Route Optimizer Concepts

## Recommendation Score

Each place receives a temporary recommendation score during route generation.

The score is calculated using:

- preferred categories
- base category value
- rating, if available
- place source
- estimated visit duration sanity

Example scoring logic:

| Factor | Example |
|---|---|
| Preferred category match | Higher score |
| Nature / History / Museum | Higher base score |
| Manual source | Small bonus |
| Geoapify source | Small bonus |
| Very long visit duration | Possible penalty |

The score is not stored permanently in the database. It is calculated during request processing and returned in the route response.

---

## Score-Based Nearest Neighbor

The current route algorithm is:

```text
score_based_nearest_neighbor
```

It uses both distance and recommendation score.

Simplified formula:

```text
route_cost = distance_weight * distance - score_weight * recommendation_score
```

Lower cost is better.

This means:

- shorter distance is preferred
- higher recommendation score is preferred

The selected `route_mode` controls how much distance and score affect the final route.

---

# Common Test Queries

## Check Imported Place Distribution

```sql
SELECT category, source, COUNT(*) AS count
FROM place
GROUP BY category, source
ORDER BY source, category;
```

## Check Generated Route Items

```sql
SELECT 
    dp.day_number,
    dp.date,
    ri.visit_order,
    p.place_name,
    p.category,
    p.source,
    ri.arrival_time,
    ri.departure_time
FROM route_item ri
JOIN day_plan dp ON ri.day_plan_id = dp.plan_id
JOIN place p ON ri.place_id = p.place_id
ORDER BY dp.day_number, ri.visit_order;
```

## Clear Generated Routes

```sql
DELETE FROM route_item;
DELETE FROM day_plan;
```

## Clear Geoapify Places Only

```sql
DELETE FROM place
WHERE source = 'geoapify';
```

---

# Current Route Optimizer Features

- Hotel-based route starting point
- Return-to-hotel time calculation
- Multi-day route generation
- Geoapify place import
- Place quality filtering
- Recommendation score calculation
- Score-aware nearest neighbor route algorithm
- Route modes:
  - `balanced`
  - `shortest`
  - `recommended`
- Route quality explanation in API response