from django.db import models

class Place(models.Model):
    place_id = models.AutoField(primary_key=True)
    place_name = models.CharField(max_length=255)
    latitude = models.FloatField()
    longitude = models.FloatField()
    category = models.CharField(max_length=100, blank=True, null=True)
    rating = models.FloatField(blank=True, null=True)
    estimated_visit_duration = models.IntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = "place"

    def __str__(self):
        return self.place_name