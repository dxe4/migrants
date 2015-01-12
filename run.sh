export DJANGO_SETTINGS_MODULE=migrants.settings.live
gunicorn migrants.wsgi -b 0.0.0.0:9000 -c /etc/gunicorn.d/gunicorn.py
