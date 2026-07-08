from django.db import models
from django.conf import settings

class Place(models.Model):
    place_id = models.AutoField(primary_key=True)
    place_name = models.CharField(max_length=255)
    latitude = models.FloatField()
    longitude = models.FloatField()
    category = models.CharField(max_length=100, blank=True, null=True)
    rating = models.FloatField(blank=True, null=True)
    estimated_visit_duration = models.IntegerField(blank=True, null=True)
    source = models.CharField(max_length=50, default="manual")
    source_place_id = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        managed = False
        db_table = "place"

    def __str__(self):
        return self.place_name
    
class FavoritePlace(models.Model):
    favorite_id = models.AutoField(primary_key=True)

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="favorite_places"
    )

    place = models.ForeignKey(
        Place,
        on_delete=models.CASCADE,
        related_name="favorited_by"
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "favorite_place"
        unique_together = ("user", "place")

    def __str__(self):
        return f"{self.user} - {self.place.place_name}"