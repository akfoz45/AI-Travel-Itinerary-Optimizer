# Postman Test Checklist

This checklist is used to verify the main backend API flows of the AI-Powered Travel Planner project.

Base URL for local development:

```http
http://127.0.0.1:8000
```

Protected endpoints require JWT authentication:

```http
Authorization: Bearer <access_token>
```

---

# 1. Authentication Tests

## 1.1 Register User

### Endpoint

```http
POST /api/auth/register/
```

### Body

```json
{
  "username": "akif",
  "email": "akif@example.com",
  "password": "StrongPassword123"
}
```

### Expected Result

```text
[ ] User is created successfully
[ ] Response includes user id, username, and email
[ ] Password is not returned in the response
[ ] Duplicate username is rejected
```

---

## 1.2 Get JWT Token

### Endpoint

```http
POST /api/auth/token/
```

### Body

```json
{
  "username": "akif",
  "password": "StrongPassword123"
}
```

### Expected Result

```text
[ ] Response includes access token
[ ] Response includes refresh token
[ ] Invalid credentials return an error
```

---

## 1.3 Refresh JWT Token

### Endpoint

```http
POST /api/auth/token/refresh/
```

### Body

```json
{
  "refresh": "refresh_token_here"
}
```

### Expected Result

```text
[ ] New access token is returned
[ ] Invalid refresh token is rejected
```

---

# 2. Places Tests

## 2.1 List Places

### Endpoint

```http
GET /api/places/
```

### Expected Result

```text
[ ] Places are returned successfully
[ ] Each place includes place_id
[ ] Each place includes place_name
[ ] Each place includes latitude and longitude
[ ] Each place includes category
[ ] Each place includes source
[ ] Each place includes source_place_id
```

---

## 2.2 Filter Places by Category

### Endpoint

```http
GET /api/places/?category=Nature
```

### Expected Result

```text
[ ] Only Nature places are returned
[ ] Category filtering is case-insensitive
```

Test also:

```http
GET /api/places/?category=nature
GET /api/places/?category=NATURE
```

---

## 2.3 Filter Places by Minimum Rating

### Endpoint

```http
GET /api/places/?min_rating=4
```

### Expected Result

```text
[ ] Only places with rating >= 4 are returned
[ ] Places with rating = null are not returned for min_rating filter
```

---

# 3. Trip Tests

## 3.1 Create Trip

### Endpoint

```http
POST /api/trips/
```

### Body

```json
{
  "destination": "Kotor, Montenegro",
  "start_date": "2026-07-01",
  "end_date": "2026-07-03",
  "preferences": ["nature", "history", "museum"]
}
```

### Expected Result

```text
[ ] Trip is created successfully
[ ] Trip is linked to the authenticated user
[ ] Preferences are created successfully
[ ] Response includes trip_id
[ ] Response includes destination
[ ] Response includes start_date and end_date
```

---

## 3.2 List User Trips

### Endpoint

```http
GET /api/trips/
```

### Expected Result

```text
[ ] Only authenticated user's trips are returned
[ ] Other users' trips are not visible
```

---

## 3.3 Retrieve Trip Detail

### Endpoint

```http
GET /api/trips/{trip_id}/
```

### Expected Result

```text
[ ] Trip detail is returned successfully
[ ] Preferences are included
[ ] Hotels are included if available
[ ] Day plans are included if available
[ ] Route items are included if available
```

---

## 3.4 Delete Trip

### Endpoint

```http
DELETE /api/trips/{trip_id}/
```

### Expected Result

```text
[ ] Trip is deleted successfully
[ ] Related trip preferences are deleted
[ ] Related day plans are deleted
[ ] Related route items are deleted
[ ] Other users cannot delete this trip
```

---

# 4. Geoapify City Test

## 4.1 Get City Coordinates

### Endpoint

```http
GET /api/external/geoapify/city/?name=Kotor, Montenegro
```

### Expected Result

```text
[ ] City coordinates are returned
[ ] Response includes latitude
[ ] Response includes longitude
[ ] Response includes formatted city name
```

### Example Expected Fields

```json
{
  "city": "Kotor, Montenegro",
  "formatted": "Kotor, Montenegro",
  "latitude": 42.425,
  "longitude": 18.771
}
```

---

# 5. Geoapify Places Search Tests

## 5.1 Search Tourism Places

### Endpoint

```http
GET /api/external/geoapify/places/?city=Kotor, Montenegro&categories=tourism&radius=10000&limit=30
```

### Expected Result

```text
[ ] Geoapify request succeeds
[ ] raw_place_count is returned
[ ] normalized_place_count is returned
[ ] filtered_out_count is returned
[ ] places list is returned
[ ] filtered_out_places list is returned
```

---

## 5.2 Search History Places

### Endpoint

```http
GET /api/external/geoapify/places/?city=Kotor, Montenegro&categories=history&radius=10000&limit=30
```

### Expected Result

```text
[ ] Geoapify request succeeds
[ ] Returned places are mapped to internal categories
[ ] History, Museum, Religious, or Tourism categories may appear
[ ] Weak POIs can be filtered out
```

---

## 5.3 Search Nature Places

### Endpoint

```http
GET /api/external/geoapify/places/?city=Kotor, Montenegro&categories=nature&radius=30000&limit=30
```

### Expected Result

```text
[ ] Geoapify request succeeds
[ ] Nature places are returned if available
[ ] Search radius is large enough for natural areas outside city center
[ ] No 400 Bad Request error occurs
```

---

# 6. Geoapify Import Tests

## 6.1 Import Tourism Places

### Endpoint

```http
POST /api/external/geoapify/import-places/
```

### Body

```json
{
  "city": "Kotor, Montenegro",
  "categories": ["tourism"],
  "radius": 10000,
  "limit": 30
}
```

### Expected Result

```text
[ ] Import request succeeds
[ ] raw_place_count is returned
[ ] normalized_place_count is returned
[ ] imported_count is returned
[ ] skipped_count is returned
[ ] filtered_out_count is returned
[ ] Imported places have source = geoapify
[ ] Imported places have source_place_id
```

---

## 6.2 Import History Places

### Endpoint

```http
POST /api/external/geoapify/import-places/
```

### Body

```json
{
  "city": "Kotor, Montenegro",
  "categories": ["history"],
  "radius": 10000,
  "limit": 30
}
```

### Expected Result

```text
[ ] Import request succeeds
[ ] Geoapify categories are mapped correctly
[ ] Weak memorial-like records are filtered out
[ ] Duplicate records are skipped
```

---

## 6.3 Import Nature Places

### Endpoint

```http
POST /api/external/geoapify/import-places/
```

### Body

```json
{
  "city": "Kotor, Montenegro",
  "categories": ["nature"],
  "radius": 30000,
  "limit": 30
}
```

### Expected Result

```text
[ ] Import request succeeds
[ ] Nature places are imported if available
[ ] Imported places are stored with category = Nature
[ ] source = geoapify
```

---

## 6.4 Check Filtered Out Places

### Expected Result

```text
[ ] filtered_out_places is returned
[ ] Each filtered place includes place_name
[ ] Each filtered place includes category
[ ] Each filtered place includes reason
[ ] Each filtered place includes raw_categories
[ ] Each filtered place includes source
[ ] Each filtered place includes source_place_id
```

### Example

```json
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
```

---

## 6.5 Duplicate Import Test

Run the same import request twice.

### Expected Result

```text
[ ] First request imports new places
[ ] Second request skips existing places
[ ] skipped_count increases
[ ] skipped_places includes duplicate reason
[ ] Database does not contain duplicate Geoapify records
```

---

# 7. SQL Verification for Imported Places

## 7.1 Check Category and Source Distribution

```sql
SELECT category, source, COUNT(*) AS count
FROM place
GROUP BY category, source
ORDER BY source, category;
```

### Expected Result

```text
[ ] manual places are preserved
[ ] geoapify places are visible
[ ] Nature records exist if nature import succeeded
[ ] Museum / Tourism / Religious / History records may exist depending on import result
```

---

## 7.2 Check Geoapify Source Fields

```sql
SELECT place_id, place_name, category, source, source_place_id
FROM place
WHERE source = 'geoapify'
ORDER BY place_id DESC;
```

### Expected Result

```text
[ ] source is geoapify
[ ] source_place_id is not empty for imported Geoapify places
[ ] place_name is readable
[ ] category is mapped to internal project category
```

---

# 8. Weather API Tests

## 8.1 Get Current Weather by Coordinates

### Endpoint

```http
GET /api/weather/current/?latitude=42.425&longitude=18.771
```

### Authentication

Required.

```http
Authorization: Bearer <access_token>
```

### Expected Result

```text
[ ] Request succeeds with valid JWT token
[ ] Response includes latitude
[ ] Response includes longitude
[ ] Response includes timezone
[ ] Response includes time
[ ] Response includes temperature
[ ] Response includes apparent_temperature
[ ] Response includes humidity
[ ] Response includes precipitation
[ ] Response includes rain
[ ] Response includes wind_speed
[ ] Response includes weather_code
[ ] Response includes weather_description
[ ] Response includes is_rainy
[ ] Response includes is_good_for_outdoor
```

### Example Expected Response

```json
{
  "latitude": 42.42,
  "longitude": 18.78,
  "timezone": "Europe/Podgorica",
  "time": "2026-06-30T14:15",
  "temperature": 26.1,
  "apparent_temperature": 27.3,
  "humidity": 52,
  "precipitation": 0,
  "rain": 0,
  "wind_speed": 10.4,
  "weather_code": 1,
  "weather_description": "Mainly clear",
  "is_rainy": false,
  "is_good_for_outdoor": true
}
```

---

## 8.2 Missing Current Weather Coordinates

### Endpoint

```http
GET /api/weather/current/
```

### Expected Result

```text
[ ] API returns validation error
[ ] Response says latitude and longitude are required
```

### Expected Response

```json
{
  "error": "latitude and longitude query parameters are required."
}
```

---

## 8.3 Invalid Current Weather Coordinates

### Endpoint

```http
GET /api/weather/current/?latitude=abc&longitude=test
```

### Expected Result

```text
[ ] API returns validation error
[ ] Response says latitude and longitude must be valid numbers
```

### Expected Response

```json
{
  "error": "latitude and longitude must be valid numbers."
}
```

---

## 8.4 Current Weather Endpoint Without Token

### Endpoint

```http
GET /api/weather/current/?latitude=42.425&longitude=18.771
```

### Expected Result

```text
[ ] API returns authentication error
[ ] Weather data is not returned
```

---

## 8.5 Get Daily Forecast by Coordinates

### Endpoint

```http
GET /api/weather/forecast/?latitude=42.425&longitude=18.771&start_date=2026-07-01&end_date=2026-07-03
```

### Authentication

Required.

```http
Authorization: Bearer <access_token>
```

### Expected Result

```text
[ ] Request succeeds with valid JWT token
[ ] Response includes latitude
[ ] Response includes longitude
[ ] Response includes timezone
[ ] Response includes daily_forecast
[ ] Each daily forecast item includes date
[ ] Each daily forecast item includes weather_code
[ ] Each daily forecast item includes weather_description
[ ] Each daily forecast item includes temperature_max
[ ] Each daily forecast item includes temperature_min
[ ] Each daily forecast item includes precipitation_sum
[ ] Each daily forecast item includes rain_sum
[ ] Each daily forecast item includes wind_speed_max
[ ] Each daily forecast item includes is_rainy
[ ] Each daily forecast item includes is_good_for_outdoor
```

---

## 8.6 Missing Forecast Date Range

### Endpoint

```http
GET /api/weather/forecast/?latitude=42.425&longitude=18.771
```

### Expected Result

```text
[ ] API returns validation error
[ ] Response says start_date and end_date are required
```

### Expected Response

```json
{
  "error": "start_date and end_date query parameters are required."
}
```

---

## 8.7 Invalid Forecast Coordinates

### Endpoint

```http
GET /api/weather/forecast/?latitude=abc&longitude=test&start_date=2026-07-01&end_date=2026-07-03
```

### Expected Result

```text
[ ] API returns validation error
[ ] Response says latitude and longitude must be valid numbers
```

### Expected Response

```json
{
  "error": "latitude and longitude must be valid numbers."
}
```

---

## 8.8 Forecast Endpoint Without Token

### Endpoint

```http
GET /api/weather/forecast/?latitude=42.425&longitude=18.771&start_date=2026-07-01&end_date=2026-07-03
```

### Expected Result

```text
[ ] API returns authentication error
[ ] Forecast data is not returned
```

---

# 9. Recommendation Score Tests

## 9.1 Generate Route and Check Scores

### Endpoint

```http
POST /api/trips/{trip_id}/generate-full-route/
```

### Body

```json
{
  "categories": ["nature", "museum", "history"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "balanced"
}
```

### Expected Result

```text
[ ] route_items include recommendation_score
[ ] recommendation_score is not null
[ ] Nature places receive high score when nature is preferred
[ ] Museum places receive high score when museum is preferred
[ ] History places receive high score when history is preferred
[ ] Manual places receive source bonus
[ ] Geoapify places receive source score
```

---

## 9.2 Compare Scores by Category

Test with:

```json
{
  "categories": ["nature"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "balanced"
}
```

### Expected Result

```text
[ ] Nature places have higher recommendation_score than unrelated categories
[ ] Tourism places have lower score than selected preferred category
```

---

# 10. Route Mode Tests

## 10.1 Balanced Route

### Body

```json
{
  "categories": ["nature", "museum", "history"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "balanced"
}
```

### Expected Result

```text
[ ] Route is generated successfully
[ ] summary.route_mode = balanced
[ ] summary.distance_weight = 1.0
[ ] summary.score_weight = 0.3
[ ] summary.route_quality_note explains balanced mode
```

---

## 10.2 Shortest Route

### Body

```json
{
  "categories": ["nature", "museum", "history"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "shortest"
}
```

### Expected Result

```text
[ ] Route is generated successfully
[ ] summary.route_mode = shortest
[ ] summary.distance_weight = 1.5
[ ] summary.score_weight = 0.1
[ ] summary.route_quality_note explains shortest mode
```

---

## 10.3 Recommended Route

### Body

```json
{
  "categories": ["nature", "museum", "history"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "recommended"
}
```

### Expected Result

```text
[ ] Route is generated successfully
[ ] summary.route_mode = recommended
[ ] summary.distance_weight = 0.8
[ ] summary.score_weight = 0.6
[ ] summary.route_quality_note explains recommended mode
```

---

## 10.4 Invalid Route Mode

### Body

```json
{
  "categories": ["nature", "history"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "fastest"
}
```

### Expected Result

```text
[ ] API returns validation error
[ ] Route is not generated
[ ] Invalid route_mode is rejected
```

---

# 11. Manual Weight Override Tests

## 11.1 Override Recommended Mode

### Body

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

### Expected Result

```text
[ ] Route is generated successfully
[ ] summary.route_mode = recommended
[ ] summary.distance_weight = 2.0
[ ] summary.score_weight = 0.05
[ ] Manual values override route mode defaults
```

---

## 11.2 Negative Distance Weight

### Body

```json
{
  "categories": ["nature"],
  "start_time": "09:00",
  "end_time": "18:00",
  "distance_weight": -1,
  "score_weight": 0.3
}
```

### Expected Result

```text
[ ] API returns validation error
[ ] Route is not generated
```

---

## 11.3 Negative Score Weight

### Body

```json
{
  "categories": ["nature"],
  "start_time": "09:00",
  "end_time": "18:00",
  "distance_weight": 1.0,
  "score_weight": -0.5
}
```

### Expected Result

```text
[ ] API returns validation error
[ ] Route is not generated
```

---

# 12. Forecast-Aware Route Tests

## 12.1 Full Route Uses Forecast Context

### Endpoint

```http
POST /api/trips/{trip_id}/generate-full-route/
```

### Body

```json
{
  "categories": ["nature", "museum", "history"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "recommended"
}
```

### Expected Result

```text
[ ] Route is generated successfully
[ ] summary.route_algorithm = daily_weather_aware_score_based_nearest_neighbor
[ ] summary.weather_source = forecast
[ ] summary includes weather_forecast_available
[ ] summary includes weather_forecast_dates
[ ] summary includes weather_used_for_scoring
[ ] summary includes weather_context
[ ] summary includes weather_note
[ ] Each day_plan.daily_summary includes weather_context
[ ] Each day_plan.daily_summary uses its own date's weather context
[ ] If trip has a hotel, forecast is fetched using hotel coordinates
[ ] If forecast API fails, route generation still succeeds
```

---

## 12.2 Single Day Route Uses Forecast Context

### Endpoint

```http
POST /api/trips/{trip_id}/generate-route/
```

### Body

```json
{
  "day_number": 1,
  "date": "2026-07-02",
  "categories": ["nature", "history"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "recommended"
}
```

### Expected Result

```text
[ ] Single day route is generated successfully
[ ] summary.route_algorithm = forecast_aware_score_based_nearest_neighbor
[ ] summary.weather_source = forecast
[ ] summary includes weather_forecast_available
[ ] summary includes weather_forecast_dates
[ ] summary includes weather_context
[ ] summary.weather_context.date matches selected date if forecast is available
[ ] summary includes weather_note
[ ] recommendation_score reflects weather adjustment
```

---

## 12.3 Route Generation Without Hotel

Generate a route for a trip that has no hotel record.

### Body

```json
{
  "start_place": "Kotor Old Town",
  "categories": ["nature", "history"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "recommended"
}
```

### Expected Result

```text
[ ] Route generation still works if start_place is provided
[ ] weather_forecast_available is false
[ ] weather_used_for_scoring is false
[ ] weather_context is null
[ ] weather_note says weather data was not available
```

---

## 12.4 Forecast-Aware Score Check: Good Weather

When `is_good_for_outdoor = true`:

```text
[ ] Nature places receive weather bonus
[ ] Tourism places receive smaller weather bonus
[ ] Museum places are not strongly boosted by good outdoor weather
```

Expected behavior:

```text
Nature score > Tourism score > unrelated category score
```

---

## 12.5 Forecast-Aware Score Check: Rainy Weather

When `is_rainy = true`:

```text
[ ] Nature places receive weather penalty
[ ] Tourism places receive weather penalty
[ ] Museum places receive weather bonus
[ ] Religious places receive weather bonus
[ ] Food places receive weather bonus
```

Expected behavior:

```text
Indoor-friendly places should become more competitive in the route.
```

---

## 12.6 Daily Forecast Context Check

Generate a full route for a multi-day trip.

### Expected Result

```text
[ ] Day 1 daily_summary weather_context date matches day 1 date
[ ] Day 2 daily_summary weather_context date matches day 2 date
[ ] Day 3 daily_summary weather_context date matches day 3 date
[ ] Different days can have different weather_context values
[ ] Same place is not repeated across different days
```

---

# 13. Full Route Generation Tests

## 13.1 Generate Full Route

### Endpoint

```http
POST /api/trips/{trip_id}/generate-full-route/
```

### Body

```json
{
  "categories": ["nature", "museum", "history"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "balanced"
}
```

### Expected Result

```text
[ ] Full route is generated successfully
[ ] Response includes summary
[ ] Response includes day_plans
[ ] Each day_plan includes route_items
[ ] Each route_item includes arrival_time
[ ] Each route_item includes departure_time
[ ] Each route_item includes recommendation_score
[ ] summary.route_algorithm = daily_weather_aware_score_based_nearest_neighbor
[ ] summary.route_mode is returned
[ ] summary.route_quality_note is returned
[ ] summary.weather_source = forecast
[ ] summary includes weather_forecast_available
[ ] summary includes weather_forecast_dates
[ ] summary includes weather_used_for_scoring
[ ] summary includes weather_context
[ ] summary includes weather_note
[ ] Each day_plan.daily_summary includes daily weather_context
[ ] Same place is not repeated across different days
```

---

## 13.2 Existing Day Plans Are Replaced

Run the same full route request twice.

### Expected Result

```text
[ ] Old route_item records are deleted
[ ] Old day_plan records are deleted
[ ] New day_plan records are created
[ ] New route_item records are created
[ ] Duplicate day plans are not created for the same generation
```

---

## 13.3 Hotel-Based Start

Generate route without `start_place`.

### Body

```json
{
  "categories": ["nature", "history"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "balanced"
}
```

### Expected Result

```text
[ ] If trip has a hotel, hotel is used as start reference
[ ] summary.hotel_used_as_start is not null
[ ] summary.start_place_source = hotel_nearest_place
[ ] selected_start_place is the nearest suitable place to hotel
[ ] forecast is fetched using hotel coordinates
```

---

## 13.4 User-Provided Start Place

### Body

```json
{
  "start_place": "Kotor Old Town",
  "categories": ["nature", "history"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "balanced"
}
```

### Expected Result

```text
[ ] Route starts from the provided start place
[ ] summary.selected_start_place = Kotor Old Town
[ ] summary.start_place_source = user_input
```

---

## 13.5 Return to Hotel Calculation

### Expected Result

```text
[ ] summary.return_to_hotel_distance_km is returned
[ ] summary.return_to_hotel_minutes is returned
[ ] total_plan_duration_minutes includes return-to-hotel time
[ ] Route does not add a place if there is not enough time to return to hotel
```

---

## 13.6 Unplanned Places

Use a short time window.

### Body

```json
{
  "categories": ["nature", "museum", "history"],
  "start_time": "09:00",
  "end_time": "11:00",
  "route_mode": "balanced"
}
```

### Expected Result

```text
[ ] Some places may be left unplanned
[ ] summary.unplanned_place_count is returned
[ ] summary.unplanned_places is returned
[ ] API does not crash
```

---

# 14. Single Day Route Generation Tests

## 14.1 Generate Single Day Route

### Endpoint

```http
POST /api/trips/{trip_id}/generate-route/
```

### Body

```json
{
  "day_number": 1,
  "date": "2026-07-02",
  "categories": ["nature", "history"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "recommended"
}
```

### Expected Result

```text
[ ] Single day route is generated successfully
[ ] Response includes summary
[ ] Response includes day_plan
[ ] Route items are created
[ ] recommendation_score is returned
[ ] route_mode is returned
[ ] route_quality_note is returned
[ ] summary.route_algorithm = forecast_aware_score_based_nearest_neighbor
[ ] summary.weather_source = forecast
[ ] summary.weather_forecast_available is returned
[ ] summary.weather_forecast_dates is returned
[ ] summary.weather_context is returned
[ ] summary.weather_note is returned
```

---

## 14.2 Short Single Day Time Window

### Body

```json
{
  "day_number": 1,
  "date": "2026-07-02",
  "categories": ["nature", "history"],
  "start_time": "09:00",
  "end_time": "10:00",
  "route_mode": "balanced"
}
```

### Expected Result

```text
[ ] API handles short time window safely
[ ] Route may contain zero or few places
[ ] Unplanned places are returned
[ ] API does not crash
```

---

# 15. Authorization and Ownership Tests

## 15.1 Access Trip Owned by Another User

### Expected Result

```text
[ ] User A cannot retrieve User B's trip
[ ] User A cannot generate route for User B's trip
[ ] User A cannot delete User B's trip
```

---

## 15.2 Missing Token

Call protected endpoint without Authorization header.

### Expected Result

```text
[ ] API returns authentication error
[ ] Protected data is not returned
```

---

## 15.3 Invalid Token

Call protected endpoint with invalid token.

### Expected Result

```text
[ ] API returns authentication error
[ ] Protected data is not returned
```

---

# 16. SQL Verification for Generated Routes

## 16.1 Check Route Items

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

### Expected Result

```text
[ ] Route items are ordered by day_number and visit_order
[ ] arrival_time is not null
[ ] departure_time is not null
[ ] source includes manual and/or geoapify places
[ ] categories match request preferences where possible
[ ] Same place is not repeated across multiple days
```

---

## 16.2 Check Number of Day Plans

```sql
SELECT trip_id, COUNT(*) AS day_plan_count
FROM day_plan
GROUP BY trip_id;
```

### Expected Result

```text
[ ] Number of day plans matches trip duration when route generation succeeds
[ ] Duplicate day plans are not created after regenerating full route
```

---

## 16.3 Check Route Item Count by Source

```sql
SELECT 
    p.source,
    COUNT(*) AS route_item_count
FROM route_item ri
JOIN place p ON ri.place_id = p.place_id
GROUP BY p.source;
```

### Expected Result

```text
[ ] Geoapify places can be used in generated routes
[ ] Manual places can be used in generated routes
```

---

## 16.4 Check Duplicate Places Across Days

```sql
SELECT 
    p.place_name,
    COUNT(*) AS used_count
FROM route_item ri
JOIN place p ON ri.place_id = p.place_id
GROUP BY p.place_name
HAVING COUNT(*) > 1;
```

### Expected Result

```text
[ ] Query should return no rows
[ ] A place should not be repeated across different days in the same full route
```

---

# 17. Cleanup Queries

## 17.1 Clear Generated Routes

```sql
DELETE FROM route_item;
DELETE FROM day_plan;
```

---

## 17.2 Clear Geoapify Places Only

```sql
DELETE FROM place
WHERE source = 'geoapify';
```

---

## 17.3 Full Cleanup for Route Testing

```sql
DELETE FROM route_item;
DELETE FROM day_plan;
DELETE FROM place
WHERE source = 'geoapify';
```

---

# 18. API Completion Criteria

The backend API can be considered feature-complete for the current phase if all of the following are true:

```text
[ ] User registration works
[ ] JWT login works
[ ] Trips can be created, listed, retrieved, and deleted
[ ] Places can be listed and filtered
[ ] Geoapify city search works
[ ] Geoapify place search works
[ ] Geoapify import works
[ ] Imported places store source and source_place_id
[ ] Weak POIs are filtered out
[ ] Duplicate imports are skipped
[ ] Weather current endpoint works
[ ] Weather current endpoint validates missing coordinates
[ ] Weather current endpoint validates invalid coordinates
[ ] Weather forecast endpoint works
[ ] Forecast endpoint validates missing date range
[ ] Forecast endpoint validates invalid coordinates
[ ] Weather endpoints require authentication
[ ] Full route generation works
[ ] Single day route generation works
[ ] Hotel-based start works
[ ] Return-to-hotel calculation works
[ ] Recommendation score is returned
[ ] Forecast-aware recommendation score works
[ ] Full route generation uses forecast-aware weather scoring
[ ] Single day route generation uses forecast-aware weather scoring
[ ] Daily summaries include day-specific weather context
[ ] Same place is not repeated across full route days
[ ] route_mode works
[ ] route_quality_note is returned
[ ] weather_context is returned
[ ] weather_note is returned
[ ] Manual weight override works
[ ] Invalid route_mode is rejected
[ ] Invalid negative weights are rejected
[ ] Authorization and ownership checks work
[ ] SQL verification confirms correct database records
```

---

# 19. Recommended Test Order

Use this order when testing from a clean database state:

```text
1. Register user
2. Get JWT token
3. Create trip
4. Add hotel manually or through admin/database
5. Check existing manual places
6. Import Geoapify tourism places
7. Import Geoapify history places
8. Import Geoapify nature places
9. Check place category/source distribution with SQL
10. Test weather current endpoint
11. Test weather forecast endpoint
12. Generate full route with balanced mode
13. Generate full route with shortest mode
14. Generate full route with recommended mode
15. Check forecast weather_context and weather_note in route summary
16. Check each day_plan daily_summary weather_context
17. Test forecast-aware route scoring
18. Test manual weight override
19. Test single day route generation
20. Test short time window
21. Test duplicate Geoapify import
22. Test authorization with another user
23. Verify database state with SQL
```