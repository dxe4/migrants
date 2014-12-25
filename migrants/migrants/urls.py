from django.conf.urls import patterns, include, url
from rest_framework import routers
from migrants.base.views import OriginView, DestinationView

# router = routers.DefaultRouter()
from rest_framework.urlpatterns import format_suffix_patterns

urlpatterns = patterns(
    '',
    # url(r'^', include(router.urls)),
    url(r'^origin/(?P<alpha2>[a-z]{2})$', OriginView.as_view()),
    url(r'^destination/(?P<alpha2>[a-z]{2})$', DestinationView.as_view()),
)
urlpatterns = format_suffix_patterns(urlpatterns)
