from django.contrib import admin
from .models import Place

@admin.register(Place)
class PlaceAdmin(admin.ModelAdmin):
    list_display = (
        "place_id",
        "place_name",
        "category",
        "rating",
        "estimated_visit_duration",
    )
    search_fields = ("place_name", "category")
    list_filter = ("category",)