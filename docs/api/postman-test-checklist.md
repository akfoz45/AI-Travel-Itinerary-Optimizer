# Postman API Test Checklist

This checklist is used to verify the REST API endpoints of the **AI-Powered Travel Planner** backend.

## Base URL

```http
http://127.0.0.1:8000
```

---

# 1. Authentication Tests

## 1.1 Register User

### Endpoint

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

### Expected Response

```json
{
  "message": "User registered successfully."
}
```

### Checklist

```text
[ ] User can register successfully
[ ] Duplicate username gives validation error
[ ] Password is not returned in response
```

---

## 1.2 Obtain JWT Token

### Endpoint

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

### Expected Response

```json
{
  "refresh": "...",
  "access": "..."
}
```

### Checklist

```text
[ ] Valid username/password returns access token
[ ] Valid username/password returns refresh token
[ ] Wrong password returns 401 Unauthorized
```

---

## 1.3 Refresh JWT Token

### Endpoint

```http
POST /api/auth/token/refresh/
```

### Request Body

```json
{
  "refresh": "refresh_token_here"
}
```

### Checklist

```text
[ ] Valid refresh token returns new access token
[ ] Invalid refresh token returns error
```

---

# 2. Places Tests

## 2.1 List Places

### Endpoint

```http
GET /api/places/
```

### Checklist

```text
[ ] Places endpoint returns 200 OK
[ ] Response is a list
[ ] Each place has place_id, place_name, latitude, longitude, category, rating, estimated_visit_duration
```

---

## 2.2 Filter Places by Category

### Endpoint

```http
GET /api/places/?category=History
```

### Checklist

```text
[ ] Only History places are returned
[ ] Empty result does not crash the API
```

---

## 2.3 Filter Places by Minimum Rating

### Endpoint

```http
GET /api/places/?min_rating=4
```

### Checklist

```text
[ ] Only places with rating >= 4 are returned
[ ] Invalid rating value is handled properly
```

---

# 3. Trip Tests

All trip endpoints require JWT authentication.

## Authorization Header

```http
Authorization: Bearer <access_token>
```

---

## 3.1 Create Trip

### Endpoint

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

### Checklist

```text
[ ] Trip is created successfully
[ ] Trip is linked to authenticated user
[ ] Preferences are created
[ ] Hotel is created
[ ] User field is not required in request body
```

---

## 3.2 List User Trips

### Endpoint

```http
GET /api/trips/
```

### Checklist

```text
[ ] Only authenticated user's trips are returned
[ ] Other users' trips are not visible
[ ] Response contains preferences, day_plans, hotels
```

---

## 3.3 Get Trip Detail

### Endpoint

```http
GET /api/trips/{trip_id}/
```

### Checklist

```text
[ ] User can view own trip
[ ] User cannot view another user's trip
[ ] Invalid trip_id returns 404
```

---

## 3.4 Delete Trip

### Endpoint

```http
DELETE /api/trips/{trip_id}/
```

### Checklist

```text
[ ] User can delete own trip
[ ] User cannot delete another user's trip
[ ] Deleted trip disappears from trip list
[ ] Related day plans, route items, preferences and hotels are deleted by cascade
```

---

# 4. Manual Day Plan Tests

## 4.1 Create Day Plan

### Endpoint

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

### Checklist

```text
[ ] Day plan is created successfully
[ ] Day plan belongs to selected trip
[ ] User cannot create day plan for another user's trip
```

---

## 4.2 Add Route Item

### Endpoint

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

### Checklist

```text
[ ] Route item is created successfully
[ ] Route item belongs to selected day plan
[ ] User cannot add route item to another user's day plan
[ ] Invalid place_id returns error
```

---

# 5. Route Optimization Tests

## 5.1 Generate Single-Day Route

### Endpoint

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

### Checklist

```text
[ ] Route is generated successfully
[ ] Existing day plan for the same day is replaced
[ ] Route items are created
[ ] arrival_time and departure_time are not null
[ ] Summary is returned
[ ] Hotel is used as starting point if start_place is omitted
[ ] selected_start_place is returned
[ ] return_to_hotel_minutes is returned
[ ] unplanned_places is returned
```

---

## 5.2 Generate Single-Day Route With Manual Start Place

### Endpoint

```http
POST /api/trips/{trip_id}/generate-route/
```

### Request Body

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

### Checklist

```text
[ ] Lowercase start_place works
[ ] start_place_source is user_input
[ ] Invalid start_place returns error
```

---

## 5.3 Generate Full Route

### Endpoint

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

### Checklist

```text
[ ] Full route is generated successfully
[ ] Multiple day plans are created
[ ] Existing day plans are replaced
[ ] Daily summaries are returned
[ ] General summary is returned
[ ] generated_days is correct
[ ] total_days is calculated from trip start_date and end_date
[ ] unplanned_place_count is returned
[ ] unplanned_places list is returned
[ ] Hotel-to-first-place travel time is included
[ ] Return-to-hotel travel time is included
```

---

## 5.4 Case-Insensitive Category Test

### Endpoint

```http
POST /api/trips/{trip_id}/generate-full-route/
```

### Request Body

```json
{
  "categories": ["HISTORY", "nature"],
  "start_time": "09:00",
  "end_time": "18:00"
}
```

### Checklist

```text
[ ] HISTORY matches History
[ ] nature matches Nature
[ ] Mixed case categories work correctly
```

---

## 5.5 Short Time Window Test

### Endpoint

```http
POST /api/trips/{trip_id}/generate-full-route/
```

### Request Body

```json
{
  "categories": ["history", "nature"],
  "start_time": "09:00",
  "end_time": "09:30"
}
```

### Checklist

```text
[ ] API returns meaningful error if no place fits
[ ] No empty DayPlan remains in database
[ ] Transaction rollback works correctly
```

---

## 5.6 Missing Hotel and Missing Start Place Test

Use a trip that has no hotel.

### Endpoint

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

### Expected Response

```json
{
  "error": "Start place is required when trip has no hotel."
}
```

### Checklist

```text
[ ] API returns error when both hotel and start_place are missing
[ ] API works if start_place is provided manually
```

---

# 6. Authorization and Ownership Tests

## 6.1 No Token

### Request

```http
GET /api/trips/
```

Send the request without an Authorization header.

### Checklist

```text
[ ] API returns 401 Unauthorized
```

---

## 6.2 Invalid Token

### Header

```http
Authorization: Bearer invalid_token
```

### Checklist

```text
[ ] API returns 401 Unauthorized
```

---

## 6.3 Access Another User's Trip

### Steps

```text
1. Register user A
2. Register user B
3. Create trip with user A
4. Login as user B
5. Try GET /api/trips/{user_a_trip_id}/
```

### Checklist

```text
[ ] User B cannot access User A's trip
[ ] API returns 404 or permission-safe error
```

---

# 7. Database Validation Checks

Run these queries in MySQL after route generation.

## Check Trips

```sql
SELECT * FROM trip;
```

## Check Day Plans

```sql
SELECT * FROM day_plan;
```

## Check Route Items

```sql
SELECT * FROM route_item;
```

## Check Hotels

```sql
SELECT * FROM hotel;
```

### Checklist

```text
[ ] Route generation creates expected day_plan records
[ ] Route generation creates expected route_item records
[ ] Failed route generation does not leave empty day_plan records
[ ] Deleting a trip deletes related records
```

---

# 8. API Completion Criteria

The API part can be considered complete when:

```text
[ ] Authentication works
[ ] JWT-protected endpoints reject unauthenticated requests
[ ] Trip CRUD works
[ ] Places listing and filtering work
[ ] Manual day plan creation works
[ ] Manual route item creation works
[ ] Single-day route generation works
[ ] Full-route generation works
[ ] Hotel-based start works
[ ] Return-to-hotel control works
[ ] Daily summaries are returned
[ ] Error responses are meaningful
[ ] User ownership checks work
[ ] Database remains consistent after errors
```
