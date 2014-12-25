# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models, migrations


class Migration(migrations.Migration):

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Country',
            fields=[
                ('id', models.IntegerField(primary_key=True, serialize=False)),
                ('alpha2', models.CharField(db_index=True, unique=True, max_length=2)),
                ('area', models.CharField(max_length=200)),
                ('alt_name', models.CharField(max_length=200)),
                ('name', models.CharField(max_length=200)),
                ('order', models.IntegerField(unique=True)),
                ('region', models.CharField(max_length=100)),
            ],
            options={
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='DataCategory',
            fields=[
                ('id', models.IntegerField(primary_key=True, serialize=False)),
                ('title', models.CharField(max_length=150)),
                ('year', models.IntegerField()),
            ],
            options={
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='MigrationInfo',
            fields=[
                ('id', models.AutoField(auto_created=True, verbose_name='ID', serialize=False, primary_key=True)),
                ('people', models.IntegerField()),
                ('category', models.ForeignKey(to='base.DataCategory')),
                ('destination', models.ForeignKey(to='base.Country', related_name='destination')),
                ('origin', models.ForeignKey(to='base.Country', related_name='origin')),
            ],
            options={
            },
            bases=(models.Model,),
        ),
        migrations.AlterUniqueTogether(
            name='migrationinfo',
            unique_together=set([('destination', 'origin', 'category')]),
        ),
    ]
