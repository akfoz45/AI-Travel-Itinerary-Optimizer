# Project Roadmap and Development Phases

This document describes the development phases of the AI-Powered Travel Planner project.

The roadmap is designed to keep the project structured, testable, and extendable.

---

# Phase 1: Planning and Documentation

## Status

Completed

## Goal

Define the project scope, system architecture, database structure, route optimization logic, API design, and development roadmap.

## Completed Work

- Project idea defined
- Main features identified
- Test scenario selected: 3-night Montenegro trip
- System architecture documented
- Context diagram created
- Container diagram created
- Component diagram created
- Sequence diagram created
- Route optimization flow documented
- Database schema documented
- API endpoint documentation created
- Postman test checklist created

## Related Documents

```text
docs/architecture/context_diagram.md
docs/architecture/container_diagram.md
docs/architecture/component_diagram.md
docs/architecture/sequence_diagram.md
docs/architecture/route_optimization_flow.md
docs/database/schema.md
docs/api/endpoints.md
docs/api/postman-test-checklist.md
```

---

# Phase 2: Backend Foundation

## Status

Completed

## Goal

Create the Django backend project structure and prepare the basic backend foundation.

## Completed Work

- Django project created
- Django REST Framework added
- JWT authentication configured
- MySQL connection configured
- Environment variables added with `.env`
- Backend apps created:
  - `trips`
  - `places`
  - `route_optimizer`
  - `external_services`
  - `api`
- Basic project settings configured
- Requirements file created

## Main Technologies

```text
Python
Django
Django REST Framework
Simple JWT
MySQL
python-dotenv
```

---

# Phase 3: Database Design and Integration

## Status

Completed

## Goal

Create the database structure for trips, preferences, places, day plans, route items, and hotels.

## Completed Work

- MySQL database created
- Django built-in `auth_user` table used for users
- Project tables created manually in MySQL
- Django models connected to existing MySQL tables using `managed = False`
- Foreign key relationships added
- Place source tracking added:
  - `source`
  - `source_place_id`

## Main Tables

```text
auth_user
trip
trip_preference
place
day_plan
route_item
hotel
```

## Notes

The project uses Django's built-in user table instead of creating a custom user table manually.

Project-specific tables are managed manually in MySQL, while Django models are used to interact with them.

---

# Phase 4: REST API Development

## Status

Completed

## Goal

Develop the main REST API endpoints required for authentication, trips, places, day plans, and route generation.

## Completed Work

- User registration endpoint created
- JWT token endpoint configured
- JWT refresh endpoint configured
- Places listing endpoint created
- Place category filtering added
- Minimum rating filtering added
- Trip creation endpoint created
- Trip listing endpoint created
- Trip detail endpoint created
- Trip deletion endpoint created
- Single-day route generation endpoint created
- Full multi-day route generation endpoint created
- Ownership checks implemented for authenticated trip operations

## Main Endpoints

```http
POST /api/auth/register/
POST /api/auth/token/
POST /api/auth/token/refresh/

GET /api/places/

GET /api/trips/
POST /api/trips/
GET /api/trips/{trip_id}/
DELETE /api/trips/{trip_id}/

POST /api/trips/{trip_id}/generate-route/
POST /api/trips/{trip_id}/generate-full-route/
```

---

# Phase 5: External Services Integration

## Status

Completed

## Goal

Integrate an external places API to fetch real-world POI data and import it into the local database.

## Completed Work

- Geoapify API integration added
- City geocoding implemented
- Places search by city implemented
- Internal category to Geoapify category mapping added
- Geoapify category to internal category mapping added
- Place normalization implemented
- Geoapify import endpoint created
- Duplicate detection added
- `source = geoapify` tracking added
- `source_place_id` tracking added
- Weak POI quality filtering added
- Filtered-out places returned with reasons

## Main Endpoints

```http
GET /api/external/geoapify/city/
GET /api/external/geoapify/places/
POST /api/external/geoapify/import-places/
```

## Current External Provider

```text
Geoapify
```

## Notes

OpenTripMap was considered earlier, but Geoapify is currently used because it was easier to access and integrate during development.

---

# Phase 6: Route Optimization Improvements

## Status

Completed

## Goal

Improve the route generation system so it considers not only distance but also user preferences and place quality.

## Completed Work

- Distance calculation added
- Weighted graph construction added
- Nearest neighbor route generation added
- Hotel-based route starting point added
- Return-to-hotel calculation added
- Multi-day route splitting added
- Time-window based route planning added
- Estimated visit duration support added
- Unplanned places tracking added
- Recommendation score calculation added
- Score-aware nearest neighbor algorithm added
- Route modes added:
  - `balanced`
  - `shortest`
  - `recommended`
- Manual weight override added:
  - `distance_weight`
  - `score_weight`
- Route quality explanation added with `route_quality_note`

## Current Algorithm

```text
score_based_nearest_neighbor
```

## Simplified Formula

```text
route_cost = distance_weight * distance - score_weight * recommendation_score
```

## Supported Route Modes

| Mode | Purpose |
|---|---|
| `balanced` | Balances distance and recommendation score |
| `shortest` | Prioritizes shorter travel distance |
| `recommended` | Prioritizes higher recommendation scores |

---

# Phase 7: Testing and Validation

## Status

In Progress

## Goal

Systematically test backend functionality using Postman and SQL verification queries.

## Completed Work

- Postman test checklist created
- Authentication tests documented
- Trip tests documented
- Places tests documented
- Geoapify tests documented
- Import tests documented
- Recommendation score tests documented
- Route mode tests documented
- Full route generation tests documented
- Single-day route generation tests documented
- SQL verification queries documented

## Remaining Work

- Execute all checklist tests from a clean database state
- Test invalid request bodies
- Test authorization with multiple users
- Test short time windows
- Test duplicate imports
- Test route regeneration behavior
- Verify SQL records after route generation
- Fix any bugs found during testing

## Related Document

```text
docs/api/postman-test-checklist.md
```

---

# Phase 8: Weather Integration

## Status

Completed for current backend phase

## Goal

Integrate weather data into the travel planning process and use weather conditions to adjust route recommendation scores.

## Completed Work

- Weather app created
- Open-Meteo selected as the weather provider
- API-key-free weather integration added
- Current weather endpoint created
- Weather data normalized for internal use
- Weather context added to route generation
- Weather-aware recommendation score adjustment added
- Rainy weather detection added
- Outdoor suitability detection added
- Weather note added to route response
- API documentation updated
- Postman test checklist updated

## Main Endpoint

```http
GET /api/weather/current/?latitude=42.425&longitude=18.771
```

## Current Weather Provider

```text
Open-Meteo
```

## Weather Data Used

```text
temperature
apparent_temperature
humidity
precipitation
rain
wind_speed
weather_code
weather_description
is_rainy
is_good_for_outdoor
```

## Weather-Aware Route Behavior

| Weather Condition | Route Effect |
|---|---|
| Rainy weather | Outdoor categories such as `Nature` and `Tourism` receive a score penalty. |
| Rainy weather | Indoor-friendly categories such as `Museum`, `Religious`, and `Food` receive a score bonus. |
| Good outdoor weather | `Nature` places receive a score bonus. |
| Good outdoor weather | `Tourism` places receive a smaller score bonus. |
| Weather unavailable | Route is generated without weather adjustment. |

## Response Fields Added to Route Summary

```json
{
  "weather_used_for_scoring": true,
  "weather_context": {
    "temperature": 26.1,
    "weather_description": "Mainly clear",
    "is_rainy": false,
    "is_good_for_outdoor": true
  },
  "weather_note": "Good outdoor weather detected (Mainly clear, 26.1°C). Nature and tourism places received a score bonus."
}
```

## Remaining / Future Improvements

- Use forecast data instead of only current weather
- Match weather forecast to each trip day
- Add date-based weather scoring
- Add indoor/outdoor metadata to places
- Cache weather responses to reduce repeated API calls
- Add weather fallback behavior for unavailable APIs
- Add weather-based explanations per day plan

## Notes

The current implementation uses current weather data from Open-Meteo and applies it during route generation.

This is enough for the current backend phase, but future versions should use forecast data for multi-day trips.

---

# Phase 9: Recommendation Engine / AI Layer

## Status

Partially Completed

## Goal

Create a recommendation layer that ranks places according to user preferences, place category, source, rating, visit duration, and context.

## Completed Work

- Rule-based recommendation score implemented
- Category preference scoring added
- Base category scoring added
- Source-based scoring added
- Rating-based scoring added when rating exists
- Visit duration sanity check added
- Recommendation score returned in route response
- Recommendation score used in route algorithm

## Remaining Work

- Improve scoring formula with more real-world signals
- Add weather-aware scoring
- Add user preference history
- Add popularity score if available
- Add collaborative or ML-based recommendation later
- Evaluate recommendation quality with test trips
- Add explanation fields for why a place was recommended

## Current Approach

```text
Rule-based recommendation scoring
```

## Future Approach

```text
Hybrid recommendation system
Rule-based + ML-based scoring
```

---

# Phase 10: Mobile Application

## Status

Planned

## Goal

Develop the mobile frontend for users to create trips, select preferences, import places, and generate optimized travel routes.

## Planned Work

- Flutter project setup
- Authentication screens
- Login/register flow
- Trip creation screen
- Trip list screen
- Trip detail screen
- Preference selection UI
- Route mode selection UI
- Route generation screen
- Daily itinerary display
- Place detail cards
- Map view
- API integration with Django backend
- JWT token storage
- Error handling and loading states

## Planned Route Mode UI

```text
Balanced
Shortest
Recommended
```

## Possible Screens

```text
Login Screen
Register Screen
Home Screen
Create Trip Screen
Trip Detail Screen
Route Result Screen
Map Screen
Profile Screen
```

---

# Phase 11: Deployment

## Status

Planned

## Goal

Prepare the project for deployment and public/demo access.

## Planned Work

- Backend production settings
- Environment variable management
- MySQL production database setup
- Static file handling
- CORS configuration
- API deployment
- Mobile app build
- Domain configuration
- HTTPS setup
- README deployment section
- Basic monitoring and error logging

## Possible Deployment Options

```text
Render
Railway
PythonAnywhere
DigitalOcean
AWS
Azure
```

---

# Current Project Status Summary

The backend currently supports:

```text
[✓] User registration
[✓] JWT authentication
[✓] MySQL database integration
[✓] Trip creation and listing
[✓] Place listing and filtering
[✓] Geoapify city search
[✓] Geoapify place search
[✓] Geoapify place import
[✓] Place quality filtering
[✓] Duplicate import detection
[✓] Source tracking for imported places
[✓] Full multi-day route generation
[✓] Single-day route generation
[✓] Hotel-based route starting point
[✓] Return-to-hotel calculation
[✓] Recommendation score calculation
[✓] Score-aware route algorithm
[✓] Route modes
[✓] Route quality notes
[✓] API documentation
[✓] Postman test checklist
[✓] Weather API integration with Open-Meteo
[✓] Current weather endpoint
[✓] Weather-aware recommendation scoring
[✓] Weather context in route summary
[✓] Weather note in route response
```

---

# Next Immediate Tasks

The next recommended tasks are:

```text
1. Run the full Postman test checklist
2. Fix bugs found during testing
3. Commit stable backend changes
4. Improve weather integration with forecast-based scoring
5. Start mobile app planning
```