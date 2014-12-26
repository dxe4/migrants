from django.shortcuts import get_object_or_404
from django.views.generic.base import TemplateView

from rest_framework.views import APIView
from rest_framework.response import Response

from migrants.base.models import Country
from migrants.base.serializers import (
    OriginCountrySerializer, DestinationCountrySerializer
)


class BaseCountryView(APIView):

    def get(self, request, alpha2):
        alpha2 = alpha2.upper()
        result = get_object_or_404(
            Country.objects.select_related(self.join_fields),
            alpha2=alpha2
        )
        serializer = self.serializer(result)
        return Response(serializer.data)


class OriginView(BaseCountryView):
    join_fields = 'origin'
    serializer = OriginCountrySerializer


class DestinationView(BaseCountryView):
    join_fields = 'destination'
    serializer = DestinationCountrySerializer


class Index(TemplateView):
    template_name = 'index.html'
    http_method_names = ['get']
