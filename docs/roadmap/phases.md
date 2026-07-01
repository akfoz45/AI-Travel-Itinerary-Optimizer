# Project Roadmap

This document defines the development phases of the AI-Powered Travel Planner project.

The roadmap is designed to build the project step by step, starting from documentation and backend foundation, then moving toward route optimization, external API integration, weather-aware routing, AI-based recommendation, mobile application development, and deployment.

---

# Phase 1: Planning and Documentation

## Status

Completed

## Goal

Define the project scope, system architecture, database structure, API design, and development roadmap before implementation.

## Completed Work

- Project idea defined
- Core features identified
- Test scenario selected
- Architecture diagrams created
- Database schema designed
- API endpoint documentation created
- Algorithm documentation created
- Postman test checklist created
- Project roadmap created

## Documents Created

```text
README.md
docs/architecture/context_diagram.md
docs/architecture/container_diagram.md
docs/architecture/component_diagram.md
docs/architecture/sequence_diagram.md
docs/architecture/route_optimization_flow.md
docs/database/schema.md
docs/algorithms/graph_model.md
docs/algorithms/route_optimization.md
docs/api/endpoints.md
docs/api/postman-test-checklist.md
docs/roadmap/phases.md
```

## Notes

This phase established the foundation of the project and made the implementation process more structured.

---

# Phase 2: Backend Foundation

## Status

Completed

## Goal

Create the Django backend structure and configure the core backend environment.

## Completed Work

- Django project created
- Backend folder structure organized
- Django REST Framework added
- MySQL database connection configured
- Environment variables added
- `.env` file configured
- `SECRET_KEY` moved to `.env`
- Main Django apps created
- JWT authentication configured
- Basic URL structure created

## Django Apps Created

```text
api
trips
places
route_optimizer
external_services
weather
```

## Backend Technologies

```text
Python
Django
Django REST Framework
MySQL
JWT Authentication
python-dotenv
```

## Notes

The backend now has a modular structure and is ready for API-based development.

---

# Phase 3: Database Design and Integration

## Status

Completed

## Goal

Create the relational database schema and connect it with Django models.

## Completed Work

- MySQL database created
- Core project tables created manually
- Django built-in `auth_user` table used for authentication
- Project tables connected to Django models
- `managed = False` used for manually created tables
- Foreign key relationships defined
- Place source tracking added
- Geoapify source fields added to `place` table

## Main Tables

```text
auth_user
trip
trip_preference
day_plan
route_item
place
hotel
```

## Important Decision

The project uses Django’s built-in `auth_user` table instead of creating a custom user table manually.

Project-specific tables are created manually in MySQL and mapped with Django models.

## Place Table Extensions

```sql
ALTER TABLE place
ADD COLUMN source VARCHAR(50) DEFAULT 'manual',
ADD COLUMN source_place_id VARCHAR(255) NULL;
```

## Notes

The database is ready for trip management, place storage, route generation, hotel-based routing, and external place import.

---

# Phase 4: REST API Development

## Status

Completed

## Goal

Create the main REST API endpoints required by the backend.

## Completed Work

- User registration endpoint created
- JWT token endpoint configured
- JWT refresh endpoint configured
- Places list endpoint created
- Place filtering added
- Trip create endpoint added
- Trip list endpoint added
- Trip detail endpoint added
- Trip delete endpoint added
- Single-day route generation endpoint added
- Full-route generation endpoint added
- Request serializers added
- Response serializers added
- Ownership checks added for user trips

## Main API Groups

```text
Authentication APIs
Trip APIs
Place APIs
Route Generation APIs
External Service APIs
Weather APIs
```

## Notes

The backend now supports the main API flow required by the mobile client and testing environment.

---

# Phase 5: External Services Integration

## Status

Completed

## Goal

Integrate external place data into the project.

## Initial Plan

The original external place provider considered for the project was OpenTripMap.

## Final Decision

Geoapify Places API was selected because it was easier to access and integrate during development.

## Completed Work

- Geoapify API key configured
- Geoapify city geocoding added
- Geoapify places search added
- Internal category to Geoapify category mapping added
- Geoapify category to internal project category mapping added
- Place normalization added
- Place quality filtering added
- Weak POI filtering added
- Duplicate detection added
- Geoapify place import endpoint added
- Imported places stored with `source = geoapify`
- Imported places stored with `source_place_id`

## Geoapify Endpoints

```http
GET /api/external/geoapify/city/?name=Kotor, Montenegro
GET /api/external/geoapify/places/?city=Kotor, Montenegro&categories=nature,history
POST /api/external/geoapify/import-places/
```

## Quality Filtering

The system can filter out weak or less useful POIs such as:

```text
memorials
military objects
cemeteries
graves
war-related objects
low-value monuments
```

## Notes

Geoapify provides useful place data, but it does not provide a reliable Google-like rating field for every POI. Therefore, imported Geoapify places usually have `rating = null`.

The project uses an internal `recommendation_score` instead of relying only on external ratings.

---

# Phase 6: Route Optimization Improvements

## Status

Completed

## Goal

Improve route generation using graph-based route modeling, recommendation scores, hotel-based starting points, and route modes.

## Completed Work

- Distance calculation added
- Weighted graph builder added
- Score-based nearest neighbor algorithm added
- Recommendation score calculation added
- Hotel-based start logic added
- Nearest place to hotel logic added
- Return-to-hotel calculation added
- Multi-day route generation added
- Single-day route generation added
- Time-window validation added
- Unplanned places tracking added
- Route modes added
- Manual weight override added
- Route quality explanation added

## Route Modes

| Mode | Description | Distance Weight | Score Weight |
|---|---|---:|---:|
| `balanced` | Balances travel distance and recommendation score. | `1.0` | `0.3` |
| `shortest` | Prioritizes shorter travel distance. | `1.5` | `0.1` |
| `recommended` | Prioritizes places with higher recommendation scores. | `0.8` | `0.6` |

## Main Route Formula

```text
route_cost = distance_weight * distance - score_weight * recommendation_score
```

Lower route cost is better.

## Main Algorithm

```text
score_based_nearest_neighbor
```

## Notes

This phase made the route optimizer more realistic by considering both distance and place value.

---

# Phase 7: Testing and Validation

## Status

In Progress

## Goal

Test all backend API flows using Postman and SQL verification.

## Completed Work

- Postman checklist created
- Authentication tests documented
- Trip API tests documented
- Place API tests documented
- Geoapify tests documented
- Weather API tests documented
- Route generation tests documented
- SQL verification queries added
- Completion criteria added

## Testing Areas

```text
Authentication
JWT authorization
Trip ownership
Place listing and filtering
Geoapify search
Geoapify import
Weather current endpoint
Weather forecast endpoint
Route generation
Route modes
Manual weight override
Forecast-aware scoring
Database verification
```

## Main Test Checklist

```text
docs/api/postman-test-checklist.md
```

## Notes

This phase should be completed before moving to frontend or deployment work.

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
- Daily forecast endpoint created
- Weather data normalized for internal use
- Weather context added to route generation
- Forecast-aware recommendation score adjustment added
- Rainy weather detection added
- Outdoor suitability detection added
- Weather note added to route response
- Full route generation connected to daily forecast data
- Single-day route generation connected to selected date forecast data
- Daily summaries can include day-specific weather context
- API documentation updated
- Postman test checklist updated

## Main Endpoints

```http
GET /api/weather/current/?latitude=42.425&longitude=18.771
GET /api/weather/forecast/?latitude=42.425&longitude=18.771&start_date=2026-07-01&end_date=2026-07-03
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
temperature_max
temperature_min
precipitation_sum
rain_sum
wind_speed_max
is_rainy
is_good_for_outdoor
```

## Forecast-Aware Route Behavior

| Weather Condition | Route Effect |
|---|---|
| Rainy weather | Outdoor categories such as `Nature` and `Tourism` receive a score penalty. |
| Rainy weather | Indoor-friendly categories such as `Museum`, `Religious`, and `Food` receive a score bonus. |
| Good outdoor weather | `Nature` places receive a score bonus. |
| Good outdoor weather | `Tourism` places receive a smaller score bonus. |
| Weather unavailable | Route is generated without weather adjustment. |

## Route Algorithms Added

```text
forecast_aware_score_based_nearest_neighbor
daily_weather_aware_score_based_nearest_neighbor
```

## Response Fields Added to Route Summary

```json
{
  "weather_source": "forecast",
  "weather_forecast_available": true,
  "weather_forecast_dates": [
    "2026-07-01",
    "2026-07-02",
    "2026-07-03"
  ],
  "weather_used_for_scoring": true,
  "weather_context": {
    "date": "2026-07-01",
    "weather_description": "Mainly clear",
    "is_rainy": false,
    "is_good_for_outdoor": true
  },
  "weather_note": "Good outdoor weather detected. Nature and tourism places received a score bonus."
}
```

## Remaining / Future Improvements

- Add indoor/outdoor metadata to places
- Cache weather responses to reduce repeated API calls
- Add weather fallback behavior for unavailable APIs
- Add weather-based explanations per day plan
- Improve daily route generation so each day can dynamically choose different category priorities
- Add user-facing weather badges in the mobile app
- Add weather-aware route comparison in frontend

## Notes

The current implementation uses Open-Meteo current weather and daily forecast data.

Current weather is available as a standalone endpoint, but route generation primarily uses forecast data.

Full route generation uses forecast data for the trip date range.

Single-day route generation uses the forecast context matching the selected route date.

---

# Phase 9: Recommendation Engine / AI Layer

## Status

Partially Completed

## Goal

Add an intelligent recommendation layer that helps rank places according to user preferences, place category, source, estimated visit duration, and weather conditions.

## Completed Work

- Rule-based recommendation score added
- Preferred category scoring added
- Category base score added
- Rating-based scoring added
- Source-based scoring added
- Visit duration scoring added
- Weather-aware score adjustment added
- Forecast-aware score adjustment added
- Recommendation score returned in route response

## Current Recommendation Factors

```text
preferred categories
place category
rating
place source
estimated visit duration
weather context
forecast context
```

## Current Status

The project currently uses a rule-based recommendation system.

This is suitable for the current backend phase because it is transparent, easy to explain, and stable for testing.

## Future Improvements

- Add machine learning-based recommendation
- Learn user preferences from past trips
- Add user feedback after visiting places
- Add popularity score
- Add place type embeddings
- Add collaborative filtering
- Add personalized recommendation ranking

## Notes

This phase is partially completed because the current system has intelligent scoring, but it is not yet a trained ML model.

---

# Phase 10: Mobile Application

## Status

Planned

## Goal

Create a mobile client that communicates with the Django REST API.

## Planned Technology

```text
Flutter
Dart
REST API
JWT Authentication
```

## Planned Screens

```text
Login screen
Register screen
Home screen
Trip list screen
Create trip screen
Trip detail screen
Place list screen
Route result screen
Day plan detail screen
Weather information display
Profile screen
```

## Planned Features

- User login
- User registration
- Create trip
- List trips
- View trip detail
- Generate full route
- Generate single-day route
- Show route items by day
- Show arrival and departure times
- Show place categories
- Show recommendation scores
- Show weather context
- Show weather note
- Show unplanned places
- Display route quality note

## Notes

Mobile development should start after backend API testing is stable.

---

# Phase 11: Deployment

## Status

Planned

## Goal

Deploy the backend API and prepare the project for real-world demonstration.

## Planned Work

- Prepare production settings
- Configure environment variables
- Configure database credentials
- Set `DEBUG=False`
- Configure allowed hosts
- Configure static files
- Deploy backend
- Deploy database
- Test API in production
- Update README with deployment instructions

## Possible Deployment Options

```text
Render
Railway
PythonAnywhere
DigitalOcean
AWS
```

## Notes

Deployment should be done after backend testing and before final project presentation.

---

# Current Project Status Summary

```text
[✓] Project idea defined
[✓] Documentation-first structure created
[✓] Architecture diagrams created
[✓] MySQL database selected
[✓] Django backend created
[✓] JWT authentication added
[✓] Main database tables created
[✓] Django models connected to manual MySQL tables
[✓] Places API created
[✓] Trips API created
[✓] Route generation API created
[✓] Geoapify integration added
[✓] Geoapify import added
[✓] Place quality filtering added
[✓] Recommendation scoring added
[✓] Hotel-based route start added
[✓] Return-to-hotel calculation added
[✓] Route modes added
[✓] Manual route weight override added
[✓] Weather API integration with Open-Meteo
[✓] Current weather endpoint
[✓] Daily weather forecast endpoint
[✓] Forecast-aware recommendation scoring
[✓] Forecast context in route summary
[✓] Day-specific weather context in daily summaries
[✓] Weather note in route response
[✓] Daily weather-aware full route generation
[✓] API documentation updated
[✓] Postman test checklist updated
[ ] Full Postman testing completed
[ ] Mobile app started
[ ] Deployment completed
```

---

# Next Immediate Tasks

The next recommended tasks are:

```text
1. Run the full Postman test checklist
2. Fix bugs found during testing
3. Commit stable backend changes
4. Improve daily-weather-aware route quality if needed
5. Start mobile app planning
```

---

# Suggested Git Commit

After updating this roadmap file:

```bash
git add docs/roadmap/phases.md
git commit -m "docs: update roadmap for forecast-aware routing"
```