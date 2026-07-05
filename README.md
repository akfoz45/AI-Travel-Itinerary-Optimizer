# AI Travel Itinerary Optimizer

AI Travel Itinerary Optimizer is a full-stack travel planning application that helps users create personalized multi-day travel routes based on destination, travel dates, hotel location, user preferences, weather conditions, and route optimization logic.

The project consists of a Django REST backend and a Flutter mobile application.

---

## Project Overview

This application allows users to:

- Register and log in
- Create trips
- Select travel preferences
- Add hotel information
- Generate optimized daily travel routes
- View route results day by day
- Edit or delete trips
- Regenerate routes when trip details change

The route generation system uses place data, weather data, scoring logic, and graph-based route optimization to generate daily itineraries.

---

## Main Features

### Authentication

- User registration
- User login
- JWT-based authentication
- Token storage on mobile
- Splash screen authentication check
- Logout

### Trip Management

- Create trip
- Edit trip
- Delete trip
- List user trips
- View trip detail
- Add destination
- Select start and end dates
- Select travel preferences with chips
- Add hotel information

### Route Generation

- Generate full multi-day route
- Use trip preferences as default route categories
- Allow category customization before route generation
- Select start place
- Select start and end time with time picker
- Select route mode:
  - Balanced
  - Shortest
  - Recommended
- Regenerate existing routes
- Automatically clear old route data before generating a new route

### Route Result

- Route summary
- Daily route plans
- Place order
- Arrival and departure times
- Recommendation score
- Weather note
- One-click return to Trip Detail

### Weather-Aware Recommendation

- Weather forecast integration
- Weather-aware scoring
- Route generation fallback when weather data is unavailable

---

## Tech Stack

### Backend

- Python
- Django
- Django REST Framework
- Simple JWT
- MySQL
- django-cors-headers
- python-dotenv

### Mobile

- Flutter
- Dart
- HTTP package
- Flutter Secure Storage
- Intl

### External APIs

- Geoapify Places API
- Open-Meteo Weather API

### Core Concepts

- REST API design
- JWT authentication
- Graph-based route optimization
- Recommendation scoring
- Weather-aware itinerary planning
- Mobile/backend integration

---

## Project Structure

```text
Travel_App
│
├── backend
│   ├── accounts
│   ├── trips
│   ├── places
│   ├── route_optimizer
│   ├── core
│   ├── manage.py
│   └── requirements.txt
│
├── mobile
│   └── travel_planner_app
│       ├── lib
│       │   ├── core
│       │   ├── features
│       │   │   ├── auth
│       │   │   ├── trips
│       │   │   └── routes
│       │   └── main.dart
│       └── pubspec.yaml
│
├── docs
│   ├── api
│   └── roadmap
│
└── README.md
```

---

## Backend Setup

### 1. Create and activate virtual environment

```bash
python -m venv .venv
```

Windows PowerShell:

```bash
.venv\Scripts\activate
```

### 2. Install dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 3. Create `.env` file

Create a `.env` file inside the backend directory.

Example:

```env
SECRET_KEY=your-django-secret-key
DEBUG=True

DB_NAME=ai_travel_planner
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_HOST=localhost
DB_PORT=3306

GEOAPIFY_API_KEY=your_geoapify_api_key
```

### 4. Run migrations

```bash
python manage.py makemigrations
python manage.py migrate
```

### 5. Start backend server

```bash
python manage.py runserver
```

Backend runs on:

```text
http://127.0.0.1:8000
```

---

## Flutter Mobile Setup

### 1. Go to Flutter app directory

```bash
cd mobile/travel_planner_app
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure API base URL

Open:

```text
lib/core/constants/api_constants.dart
```

For Flutter Web / Chrome:

```dart
static const String baseUrl = 'http://127.0.0.1:8000';
```

For Android Emulator:

```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

### 4. Run Flutter app

```bash
flutter run
```

### 5. Analyze project

```bash
flutter analyze
```

Expected result:

```text
No issues found!
```

---

## API Endpoints

### Authentication

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/auth/register/` | Register user |
| POST | `/api/auth/token/` | Login and get JWT tokens |
| POST | `/api/auth/token/refresh/` | Refresh access token |

### Trips

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/trips/` | List user trips |
| POST | `/api/trips/` | Create trip |
| GET | `/api/trips/{trip_id}/` | Get trip detail |
| PUT | `/api/trips/{trip_id}/` | Update trip |
| DELETE | `/api/trips/{trip_id}/` | Delete trip |

### Route Generation

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/trips/{trip_id}/generate-route/` | Generate route for one day |
| POST | `/api/trips/{trip_id}/generate-full-route/` | Generate full multi-day route |

---

## Example Trip Creation Request

```json
{
  "destination": "Kotor, Montenegro",
  "start_date": "2026-07-01",
  "end_date": "2026-07-03",
  "preferences": ["nature", "history", "museum"],
  "hotel": {
    "name": "Hotel Kotor Example",
    "latitude": 42.425,
    "longitude": 18.771,
    "rating": 4.5
  }
}
```

---

## Example Route Generation Request

```json
{
  "categories": ["nature", "history", "museum"],
  "start_time": "09:00",
  "end_time": "18:00",
  "route_mode": "recommended",
  "start_place": "Kotor Old Town"
}
```

---

## Current Mobile Screens

- Splash Screen
- Login Screen
- Register Screen
- My Trips Screen
- Create Trip Screen
- Edit Trip Screen
- Trip Detail Screen
- Generate Route Screen
- Route Result Screen

---

## Route Generation Logic

The route generation flow:

1. User creates a trip.
2. User selects preferences.
3. User adds hotel information.
4. User opens Trip Detail.
5. User generates route.
6. Backend fetches relevant places.
7. Backend applies recommendation scoring.
8. Backend uses weather context when available.
9. Backend builds a weighted graph.
10. Backend generates daily route plans.
11. Flutter displays route summary and daily itinerary.

If a trip already has a route, regenerating a route replaces the existing route.

---

## Known Limitations

- Hotel recommendation is not automatic yet.
- Map visualization is not implemented yet.
- Route generation depends on available place data.
- Weather forecast may be unavailable for some cases.
- Current recommendation logic is rule-based.
- Offline support is not implemented.

---

## Future Improvements

- Interactive map view
- Automatic hotel search
- Restaurant recommendation
- More advanced AI-based itinerary generation
- Budget-aware trip planning
- Real-time traffic support
- Collaborative trip planning
- Saved favorite places
- Push notifications
- Deployment to cloud
- Mobile app release build

---

## Test Scenario

Initial test scenario:

```text
Destination: Kotor, Montenegro
Duration: 3 days
Preferences: nature, history, museum
Hotel: Hotel Kotor Example
Start place: Kotor Old Town
Route mode: recommended
```

Expected output:

- Multi-day route plan
- Daily itinerary
- Ordered places
- Arrival and departure times
- Recommendation scores
- Weather-aware notes

---

## Author

Akif Özdemir

GitHub: `akfoz45`