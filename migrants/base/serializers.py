from rest_framework import serializers

from migrants.base.models import DataCategory, Country, MigrationInfo


class _CountrySerializer(serializers.ModelSerializer):

    class Meta:
        model = Country
        fields = ('alpha2', 'area', 'alt_name', 'name', 'region')


class CountryCenterSerializer(serializers.ModelSerializer):

    class Meta:
        model = Country
        fields = ('alpha2', 'center_lat', 'center_long')


class DataCategorySerializer(serializers.ModelSerializer):

    class Meta:
        model = DataCategory
        fields = ('title', 'year', 'id')


class OriginMigrantInfoSerializer(serializers.ModelSerializer):
    destination = _CountrySerializer(many=False, read_only=True)

    class Meta:
        model = MigrationInfo
        fields = ('destination', 'people')


class DestinationMigrantInfoSerializer(serializers.ModelSerializer):
    origin = _CountrySerializer(many=False, read_only=True)

    class Meta:
        model = MigrationInfo
        fields = ('origin', 'people')


# Bad design, keep for now..:
# class OriginCountrySerializer(serializers.ModelSerializer):
#     origin = OriginMigrantInfoSerializer(many=True, read_only=True)

#     class Meta:
#         model = Country
#         fields = ('alpha2', 'area', 'alt_name', 'name', 'region', 'origin')


# class DestinationCountrySerializer(serializers.ModelSerializer):
#     destination = DestinationMigrantInfoSerializer(many=True, read_only=True)

#     class Meta:
#         model = Country
#         fields = (
#             'alpha2', 'area', 'alt_name', 'name', 'region', 'destination')
