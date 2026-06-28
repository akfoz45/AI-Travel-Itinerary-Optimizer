# Project Roadmap

This document describes the development phases of the **AI-Powered Travel Planner** project.

---

# Phase 1: Project Planning and Documentation

## Status

Completed

## Completed Tasks

* Project idea defined
* Main system objectives documented
* Target user scenario defined
* Test scenario selected: 3-night Montenegro trip
* System architecture documented
* Context diagram created
* Container diagram created
* Component diagram created
* Sequence diagram created
* Route optimization flow documented
* Database schema documented
* API endpoint documentation created
* Postman API test checklist prepared

## Main Outputs

* `README.md`
* `docs/architecture/context_diagram.md`
* `docs/architecture/container_diagram.md`
* `docs/architecture/component_diagram.md`
* `docs/architecture/sequence_diagram.md`
* `docs/architecture/route_optimization_flow.md`
* `docs/database/schema.md`
* `docs/algorithms/graph_model.md`
* `docs/algorithms/route_optimization.md`
* `docs/api/endpoints.md`
* `docs/api/postman-test-checklist.md`

---

# Phase 2: Backend Foundation

## Status

Completed

## Completed Tasks

* Django backend project created
* Backend folder structure organized
* Django apps created:

  * `api`
  * `trips`
  * `places`
  * `route_optimizer`
  * `external_services`
* Django REST Framework installed and configured
* MySQL database connection configured
* Environment variables configured with `.env`
* Django authentication system integrated
* JWT authentication configured
* Project dependencies saved in `requirements.txt`

## Main Outputs

* `backend/config/settings.py`
* `backend/config/urls.py`
* `backend/requirements.txt`
* `.env` configuration
* Django app structure

---

# Phase 3: Database Implementation

## Status

Completed

## Completed Tasks

* MySQL database created
* Django system tables created with migrations
* Project-specific tables manually created in MySQL
* Django models mapped to existing MySQL tables
* `managed = False` used for manually created tables
* Django `auth_user` table used for user management
* Project tables connected through foreign keys
* Django admin panel configured
* Test data added through Django admin

## Implemented Tables

* `auth_user`
* `trip`
* `trip_preference`
* `day_plan`
* `place`
* `route_item`
* `hotel`

## Main Outputs

* `trips/models.py`
* `places/models.py`
* `trips/admin.py`
* `places/admin.py`
* `docs/database/schema.md`

---

# Phase 4: REST API Development

## Status

Completed

## Completed Tasks

* User registration endpoint implemented
* JWT token obtain endpoint implemented
* JWT token refresh endpoint implemented
* Places listing endpoint implemented
* Place filtering by category implemented
* Place filtering by minimum rating implemented
* Trip creation endpoint implemented
* Trip list endpoint implemented
* Trip detail endpoint implemented
* Trip delete endpoint implemented
* Manual day plan creation endpoint implemented
* Manual route item creation endpoint implemented
* Single-day route generation endpoint implemented
* Full multi-day route generation endpoint implemented
* Case-insensitive category filtering implemented
* Case-insensitive start place matching implemented
* Service layer created for route generation logic
* Hotel-based route start implemented
* Automatic nearest-place selection from hotel implemented
* Return-to-hotel travel time control implemented
* Time window validation implemented
* Transaction handling added for route generation
* Route summary data added
* Daily summary data added
* Unplanned places returned in response
* API endpoint documentation completed
* Postman API test checklist prepared

## Implemented API Groups

### Authentication

* `POST /api/auth/register/`
* `POST /api/auth/token/`
* `POST /api/auth/token/refresh/`

### Places

* `GET /api/places/`

### Trips

* `GET /api/trips/`
* `POST /api/trips/`
* `GET /api/trips/{trip_id}/`
* `DELETE /api/trips/{trip_id}/`

### Manual Day Plan Management

* `POST /api/trips/{trip_id}/day-plans/`
* `POST /api/trips/day-plans/{plan_id}/route-items/`

### Route Optimization

* `POST /api/trips/{trip_id}/generate-route/`
* `POST /api/trips/{trip_id}/generate-full-route/`

## Main Outputs

* `api/views.py`
* `api/serializers.py`
* `api/urls.py`
* `places/views.py`
* `places/serializers.py`
* `places/urls.py`
* `trips/views.py`
* `trips/serializers.py`
* `trips/urls.py`
* `route_optimizer/services.py`
* `route_optimizer/utils.py`
* `route_optimizer/graph_builder.py`
* `route_optimizer/nearest_neighbor.py`
* `route_optimizer/time_estimator.py`
* `docs/api/endpoints.md`
* `docs/api/postman-test-checklist.md`

---

# Phase 5: External Services Integration

## Status

Next

## Goal

Replace or enrich manually entered place data with external data sources.

## Planned Tasks

* Research external place data providers
* Select a place data provider
* Create service files inside `external_services`
* Add external API key configuration to `.env`
* Implement external place search
* Fetch tourist attractions by destination
* Fetch place coordinates, ratings, categories and metadata
* Store or cache external place results
* Integrate external place data with route generation
* Add error handling for failed external API requests
* Document external service usage

## Candidate APIs

* OpenTripMap API
* Google Places API
* Foursquare Places API

## Suggested First Provider

OpenTripMap API

## Reason

OpenTripMap is suitable for tourist attraction data and is practical for a travel itinerary demo project.

## Expected Outputs

* `external_services/place_service.py`
* `external_services/urls.py`
* `external_services/views.py`
* External place data endpoint
* Updated API documentation
* Updated `.env.example`

---

# Phase 6: Weather Integration

## Status

Planned

## Goal

Use weather data to improve route and place recommendations.

## Planned Tasks

* Research weather API providers
* Add weather API key to `.env`
* Fetch weather data by destination and date
* Add weather-aware recommendation rules
* Penalize outdoor places during bad weather
* Prefer indoor places during rain or extreme weather
* Add weather information to generated route response
* Document weather integration

## Candidate APIs

* OpenWeather API
* WeatherAPI
* Meteostat

## Expected Outputs

* `external_services/weather_service.py`
* Weather-aware route scoring
* Weather data in route response
* Updated documentation

---

# Phase 7: Route Optimization Improvements

## Status

Planned

## Goal

Improve route quality beyond basic nearest neighbor ordering.

## Planned Tasks

* Improve route scoring logic
* Add preference-based place ranking
* Add category weighting
* Add rating-based scoring
* Add estimated visit duration scoring
* Add opening-hours logic if data is available
* Improve travel time estimation
* Replace simple distance-based travel time with real travel duration if possible
* Compare nearest neighbor with alternative route strategies
* Add route quality metrics

## Possible Improvements

* Preference score
* Rating score
* Distance score
* Weather score
* Time window score
* Category diversity score

## Expected Outputs

* Improved `route_optimizer/services.py`
* New route scoring helper functions
* Better route summary metrics
* Updated algorithm documentation

---

# Phase 8: Recommendation Engine

## Status

Planned

## Goal

Recommend places based on user preferences and trip context.

## Planned Tasks

* Build rule-based recommendation logic
* Score places by user preferences
* Add category weight system
* Add destination-specific recommendation logic
* Add trip duration awareness
* Add budget-aware recommendation logic if budget is used
* Prepare future ML-based recommendation module
* Document recommendation logic

## Initial Approach

Rule-based recommendation system.

## Future Approach

Machine learning-based recommendation system.

## Expected Outputs

* `ml_engine/`
* Recommendation scoring functions
* Preference-based route generation
* Updated algorithm documentation

---

# Phase 9: Mobile Application

## Status

Planned

## Goal

Create a Flutter mobile application that consumes the Django REST API.

## Planned Tasks

* Create Flutter project
* Design authentication screens
* Implement register screen
* Implement login screen
* Store JWT token securely
* Create trip creation screen
* Create trip list screen
* Create trip detail screen
* Display generated full route
* Display daily route plans
* Display daily summaries
* Display unplanned places
* Connect Flutter app to Django REST API
* Add loading and error states
* Improve mobile UI design

## Expected Screens

* Register screen
* Login screen
* Home screen
* Trip creation screen
* Trip list screen
* Trip detail screen
* Generated route screen
* Daily plan detail screen

## Expected Outputs

* `mobile/`
* Flutter API service layer
* Flutter models
* Mobile UI screens

---

# Phase 10: Testing and Validation

## Status

Planned

## Goal

Validate backend, database, route generation and mobile integration.

## Planned Tasks

* Run Postman API test checklist
* Test authentication flow
* Test trip ownership rules
* Test database consistency
* Test route generation with normal inputs
* Test route generation with edge cases
* Test short time window behavior
* Test missing hotel and missing start place behavior
* Test invalid category behavior
* Test external API failure cases
* Test Flutter API integration
* Document test results

## Expected Outputs

* Completed Postman checklist
* Test result notes
* Bug fix commits
* Updated documentation

---

# Phase 11: Deployment

## Status

Planned

## Goal

Prepare the project for deployment or demonstration.

## Planned Tasks

* Prepare production settings
* Move sensitive values to environment variables
* Configure allowed hosts
* Configure static files
* Prepare production database settings
* Create `.env.example`
* Add deployment instructions
* Deploy backend if required
* Prepare demo data
* Prepare project presentation

## Possible Deployment Platforms

* Render
* Railway
* PythonAnywhere
* VPS
* Local demo environment

## Expected Outputs

* Deployment-ready backend configuration
* `.env.example`
* Deployment documentation
* Demo-ready project

---

# Current Overall Status

The core backend API has been completed.

The project is ready to move into the next major phase:

```text
External Services Integration
```

The next development focus is to integrate an external place data provider, such as OpenTripMap, so that the system can fetch real tourist attraction data instead of relying only on manually inserted sample places.
