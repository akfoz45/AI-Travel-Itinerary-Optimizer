# Component Diagram

## Purpose

This diagram describes the internal components of the backend.

```mermaid
graph TD

TripView["TripView"]

TripService["TripService"]

PlacesService["PlacesService"]

WeatherService["WeatherService"]

RouteService["RouteService"]

TripRepository["TripRepository"]

TripView --> TripService

TripService --> PlacesService

TripService --> WeatherService

TripService --> RouteService

TripService --> TripRepository
```

## Description

The View layer receives requests.

The Service layer contains business logic.

Repositories communicate with database models.

Dedicated services interact with external APIs and optimization algorithms.
