from django.conf.urls import patterns, include, url
# from rest_framework import routers
from migrants.base.views import (
    OriginView, DestinationView, Index, ListCategoriesView
)

# router = routers.DefaultRouter()
from rest_framework.urlpatterns import format_suffix_patterns

urlpatterns = patterns(
    '',
    # url(r'^', include(router.urls)),
    url(r'^$', Index.as_view()),
    url(r'^category/(?P<category_id>[0-9]+)/origin/(?P<alpha2>[a-z]{2})$',
        OriginView.as_view()),
    url(r'^category/(?P<category_id>[0-9]+)/destination/(?P<alpha2>[a-z]{2})$',
        DestinationView.as_view()),
    url(r'^category/list$', ListCategoriesView.as_view()),
)
urlpatterns = format_suffix_patterns(urlpatterns)
