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
  "start_date": "2026-04-10",
  "end_date": "2026-04-12",
  "preferences": ["nature", "history"]
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

# 8. Recommendation Score Tests

## 8.1 Generate Route and Check Scores

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

## 8.2 Compare Scores by Category

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

# 9. Route Mode Tests

## 9.1 Balanced Route

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

## 9.2 Shortest Route

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

## 9.3 Recommended Route

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

## 9.4 Invalid Route Mode

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

# 10. Manual Weight Override Tests

## 10.1 Override Recommended Mode

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

## 10.2 Negative Distance Weight

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

## 10.3 Negative Score Weight

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

# 11. Full Route Generation Tests

## 11.1 Generate Full Route

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
[ ] summary includes route_algorithm
[ ] summary includes route_mode
[ ] summary includes route_quality_note
```

---

## 11.2 Existing Day Plans Are Replaced

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

## 11.3 Hotel-Based Start

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
```

---

## 11.4 User-Provided Start Place

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

## 11.5 Return to Hotel Calculation

### Expected Result

```text
[ ] summary.return_to_hotel_distance_km is returned
[ ] summary.return_to_hotel_minutes is returned
[ ] total_plan_duration_minutes includes return-to-hotel time
[ ] Route does not add a place if there is not enough time to return to hotel
```

---

## 11.6 Unplanned Places

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

# 12. Single Day Route Generation Tests

## 12.1 Generate Single Day Route

### Endpoint

```http
POST /api/trips/{trip_id}/generate-route/
```

### Body

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

### Expected Result

```text
[ ] Single day route is generated successfully
[ ] Response includes summary
[ ] Response includes day_plan
[ ] Route items are created
[ ] recommendation_score is returned
[ ] route_mode is returned
[ ] route_quality_note is returned
```

---

## 12.2 Short Single Day Time Window

### Body

```json
{
  "day_number": 1,
  "date": "2026-04-10",
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

# 13. Authorization and Ownership Tests

## 13.1 Access Trip Owned by Another User

### Expected Result

```text
[ ] User A cannot retrieve User B's trip
[ ] User A cannot generate route for User B's trip
[ ] User A cannot delete User B's trip
```

---

## 13.2 Missing Token

Call protected endpoint without Authorization header.

### Expected Result

```text
[ ] API returns authentication error
[ ] Protected data is not returned
```

---

## 13.3 Invalid Token

Call protected endpoint with invalid token.

### Expected Result

```text
[ ] API returns authentication error
[ ] Protected data is not returned
```

---

# 14. SQL Verification for Generated Routes

## 14.1 Check Route Items

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
```

---

## 14.2 Check Number of Day Plans

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

## 14.3 Check Route Item Count by Source

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

# 15. Cleanup Queries

## 15.1 Clear Generated Routes

```sql
DELETE FROM route_item;
DELETE FROM day_plan;
```

---

## 15.2 Clear Geoapify Places Only

```sql
DELETE FROM place
WHERE source = 'geoapify';
```

---

## 15.3 Full Cleanup for Route Testing

```sql
DELETE FROM route_item;
DELETE FROM day_plan;
DELETE FROM place
WHERE source = 'geoapify';
```

---

# 16. API Completion Criteria

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
[ ] Full route generation works
[ ] Single day route generation works
[ ] Hotel-based start works
[ ] Return-to-hotel calculation works
[ ] Recommendation score is returned
[ ] route_mode works
[ ] route_quality_note is returned
[ ] Manual weight override works
[ ] Invalid route_mode is rejected
[ ] Invalid negative weights are rejected
[ ] Authorization and ownership checks work
[ ] SQL verification confirms correct database records
```

---

# 17. Recommended Test Order

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
10. Generate full route with balanced mode
11. Generate full route with shortest mode
12. Generate full route with recommended mode
13. Test manual weight override
14. Test single day route generation
15. Test short time window
16. Test duplicate Geoapify import
17. Test authorization with another user
18. Verify database state with SQL
```