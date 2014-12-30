from django.views.generic.base import TemplateView

from rest_framework.generics import ListAPIView
from migrants.base.models import MigrationInfo, DataCategory, Country
from migrants.base.serializers import (
    OriginMigrantInfoSerializer, DestinationMigrantInfoSerializer,
    DataCategorySerializer, CountryCenterSerializer
)


class BaseCountryView(ListAPIView):

    def get_queryset(self):
        alpha2 = self.kwargs['alpha2'].upper()
        category_id = self.kwargs['category_id']

        kwargs = {
            "{}__alpha2".format(self.join_field): alpha2,
            'people__gte': 1000,
            'category__id': category_id
        }
        result = MigrationInfo.objects.filter(
            **kwargs
        ).order_by('-people')[0:30]
        return result


class OriginView(BaseCountryView):
    join_field = 'origin'
    serializer_class = OriginMigrantInfoSerializer


class DestinationView(BaseCountryView):
    join_field = 'destination'
    serializer_class = DestinationMigrantInfoSerializer


class ListCategoriesView(ListAPIView):
    serializer_class = DataCategorySerializer

    def get_queryset(self):
        return DataCategory.objects.all()


class ListCountryCenterView(ListAPIView):
    serializer_class = CountryCenterSerializer

    def get_queryset(self):
        return Country.objects.all()


class Index(TemplateView):
    template_name = 'index.html'
    http_method_names = ['get']
