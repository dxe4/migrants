from django.db import models


class DataCategory(models.Model):
    id = models.IntegerField(primary_key=True)
    title = models.CharField(max_length=150)
    year = models.IntegerField()

    def __unicode__(self):
        # Ideadlly would be title but its too big
        return u"{} - {}".format(self.year, self.id)


class Country(models.Model):
    id = models.IntegerField(primary_key=True)
    alpha2 = models.CharField(max_length=2, unique=True, index=True)
    area = models.CharField(max_length=200)
    alt_name = models.CharField(max_length=200)
    name = models.CharField(max_length=200)
    order = models.IntegerField(unique=True)
    region = models.CharField(max_length=100)

    def __unicode__(self):
        return u"{} - {}".format(self.name, self.alpha2)


class MigrationInfo(models.Model):
    destination = models.ForeignKey(Country, related_name='destination')
    origin = models.ForeignKey(Country, related_name='origin')
    category = models.ForeignKey(DataCategory)
    people = models.IntegerField()

    class Meta:
        unique_together = ('destination', 'origin', 'category')

    def __unicode__(self):
        fields = [self.origin, " -> ", self.destination, self.category]
        return u" ".join(map(repr, fields))
