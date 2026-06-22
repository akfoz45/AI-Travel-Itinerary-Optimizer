# Container Diagram

## Purpose

This diagram describes the main containers of the system.

```mermaid
graph TB

User["User"]

Mobile["Flutter Mobile Application"]

Backend["Django REST API"]

Database["MySQL Database"]

ExternalAPIs["External APIs"]

RouteEngine["Route Optimization Engine"]

User --> Mobile

Mobile --> Backend

Backend --> Database

Backend --> ExternalAPIs

Backend --> RouteEngine
```

## Description

The Flutter application communicates with the Django REST backend.

The backend:

* Stores data in MySQL.
* Requests information from external APIs.
* Sends place data to the Route Optimization Engine.
* Returns JSON responses to the mobile application.
