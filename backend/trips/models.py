from django.db import models
from django.contrib.auth.models import User
from places.models import Place
import uuid

class Trip(models.Model):
    trip_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(
        User,
        on_delete = models.CASCADE,
        db_column="user_id",
        related_name="trips"
    )
    destination = models.CharField(max_length=255)
    start_date = models.DateField()
    end_date = models.DateField()
    is_pinned = models.BooleanField(default=False)
    collaborators = models.ManyToManyField(User, through='TripCollaborator', related_name="shared_trips", blank=True)
    invite_code = models.UUIDField(default=uuid.uuid4, editable=False)
    viewer_invite_code = models.UUIDField(default=uuid.uuid4, editable=False)

    class Meta:
        managed = False
        db_table = "trip"

    def __str__(self):
        return f"{self.destination} ({self.start_date} - {self.end_date})"
    
class TripPreference(models.Model):
    preference_id = models.AutoField(primary_key=True)
    trip = models.ForeignKey(
        Trip,
        on_delete=models.CASCADE,
        db_column="trip_id",
        related_name="preferences"
    )
    preference = models.CharField(max_length=100)

    class Meta:
        managed = False
        db_table = "trip_preference"

    def __str__(self):
        return self.preference
    
class DayPlan(models.Model):
    plan_id = models.AutoField(primary_key=True)
    trip = models.ForeignKey(
        Trip,
        on_delete=models.CASCADE,
        db_column="trip_id",
        related_name="day_plans"
    )
    day_number = models.IntegerField()
    date = models.DateField()
    weather_note = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        managed = False
        db_table = "day_plan"

    def __str__(self):
        return f"Day {self.day_number} - {self.trip.destination}"
    
class RouteItem(models.Model):
    route_id = models.AutoField(primary_key=True)
    day_plan = models.ForeignKey(
        DayPlan,
        on_delete=models.CASCADE,
        db_column="day_plan_id",
        related_name="route_items"
    )
    place = models.ForeignKey(
        Place,
        on_delete=models.CASCADE,
        db_column="place_id",
        related_name="route_items"
    )
    visit_order = models.IntegerField()
    arrival_time = models.TimeField(blank=True, null=True)
    departure_time = models.TimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = "route_item"

    def __str__(self):
        return f"{self.visit_order}. {self.place.place_name}"
    
class Hotel(models.Model):
    hotel_id = models.AutoField(primary_key=True)
    trip = models.ForeignKey(
        Trip,
        on_delete=models.CASCADE,
        db_column="trip_id",
        related_name="hotels"
    )
    name = models.CharField(max_length=255)
    latitude = models.FloatField()
    longitude = models.FloatField()
    rating = models.FloatField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = "hotel"

    def __str__(self):
        return self.name
    
class TripCollaborator(models.Model):
    trip = models.ForeignKey("Trip", on_delete=models.CASCADE, db_column="trip_id")
    user = models.ForeignKey(User, on_delete=models.CASCADE, db_column="user_id")
    role = models.CharField(max_length=10, default="editor")

    class Meta:
        managed = False
        db_table = "trip_collaborators"
        unique_together = (('trip', 'user'),)