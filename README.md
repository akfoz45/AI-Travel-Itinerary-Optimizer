# AI-Powered Travel Planner

## Overview

AI-Powered Travel Planner is an end-to-end travel planning application that generates personalized itineraries using external APIs, graph algorithms, and recommendation techniques.

The system helps users create optimized multi-day travel plans based on their preferences, destination, season, and available time.

The initial test scenario for the project is:

> A 3-night trip to Montenegro during spring.

---

## Objectives

* Build a complete client-server application.
* Learn REST API design and integration.
* Apply graph theory and optimization algorithms.
* Understand system architecture and data flow.
* Develop a scalable and maintainable software system.

---

## Features

### User Management

* User registration and authentication
* Profile management

### Trip Planning

* Destination selection
* Travel dates
* User preferences
* Budget constraints

### External API Integration

* Places API
* Weather API
* Routing API

### Route Optimization

* Distance matrix generation
* Weighted graph construction
* Shortest path algorithms
* Daily itinerary generation

### Recommendation Engine

* Place ranking
* Preference matching
* Weather-aware recommendations

### Mobile Application

* Trip creation
* Daily itinerary visualization
* Interactive maps

---

## Tech Stack

### Mobile

* Flutter

### Backend

* Django
* Django REST Framework

### Database

* PostgreSQL

### External Services

* Google Places API
* OpenWeather API
* OpenRouteService API

### Algorithms

* Graph Theory
* Dijkstra Algorithm
* A* Algorithm
* Traveling Salesman Problem (Approximation)

### AI and Recommendation

* Scikit-Learn
* Rule-based Recommendation Engine

---

## Architecture

The system consists of:

* Flutter Mobile Application
* Django REST API
* MySQL Database
* External APIs
* Route Optimization Engine
* Recommendation Engine

---

## Project Structure

```
AI-Travel-Planner
│
├── backend
├── mobile
├── ml_engine
├── docs
│
├── README.md
```

---

## Development Roadmap

### Phase 1

Project Setup and Architecture

### Phase 2

Database Design

### Phase 3

REST API Development

### Phase 4

External API Integration

### Phase 5

Route Optimization Engine

### Phase 6

Recommendation Engine

### Phase 7

Flutter Mobile Application

### Phase 8

Testing and Deployment

---

## Test Scenario

Destination: Montenegro

Season: Spring

Duration: 3 Nights

Preferences:

* Nature
* History

Expected Output:

* Optimized multi-day itinerary
* Weather-aware recommendations
* Efficient route planning

---

## Future Improvements

* Hotel recommendations
* Restaurant suggestions
* AI chatbot assistant
* Collaborative trip planning
* Real-time traffic information
* Multi-user shared itineraries
