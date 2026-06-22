# Context Diagram

## Purpose

This diagram describes the external actors and systems interacting with the AI-Powered Travel Planner.

```mermaid
graph TB

User["User"]

System["AI-Powered Travel Planner"]

PlacesAPI["Google Places API"]

WeatherAPI["Weather API"]

RoutingAPI["OpenRouteService API"]

User --> System

System --> PlacesAPI
System --> WeatherAPI
System --> RoutingAPI
```

## Description

The user interacts with the AI-Powered Travel Planner.

The application communicates with external services:

* Google Places API
* Weather API
* OpenRouteService API

These services provide location, weather, and routing information used to generate optimized travel plans.
