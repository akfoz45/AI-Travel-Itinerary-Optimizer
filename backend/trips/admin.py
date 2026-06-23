from django.contrib import admin
from .models import Trip, TripPreference, DayPlan, RouteItem, Hotel

@admin.register(Trip)
class TripAdmin(admin.ModelAdmin):
    list_display = (
        "trip_id",
        "user",
        "destination",
        "start_date",
        "end_date",
    )
    search_fields = ("destination", "user_username")
    list_filter = ("destination",)

@admin.register(TripPreference)
class TripPreferenceAdmin(admin.ModelAdmin):
    list_display = (
        "preference_id",
        "trip",
        "preference",
    )
    search_fields = ("preference",)

@admin.register(DayPlan)
class DayPlanAdmin(admin.ModelAdmin):
    list_display = (
        "plan_id",
        "trip",
        "day_number",
        "date",
    )
    list_filter = ("day_number", "date")

@admin.register(RouteItem)
class RouteItemAdmin(admin.ModelAdmin):
    list_display = (
        "route_id",
        "day_plan",
        "place",
        "visit_order",
        "arrival_time",
        "departure_time",
    )
    list_filter = ("visit_order",)

@admin.register(Hotel)
class HotelAdmin(admin.ModelAdmin):
    list_display = (
        "hotel_id",
        "trip",
        "name",
        "rating",
    )
    search_fields = ("name",)
