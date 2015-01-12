migrants
========

Hosted here:
http://migrants.python.coffee/


The data used is provided by un and can be found 
[here](http://www.un.org/en/development/desa/population/migration/data/estimates2/estimatesorigin.shtml) and [here](http://www.migrationpolicy.org/programs/data-hub/charts/international-migrants-country-destination-1960-2013?width=1000&height=850&iframe=true)



Creating topojson files.
get the shx file from here `https://github.com/nvkelso/natural-earth-vector`
`ogr2ogr -f "GeoJSON" spam.json file_name.shp -select "iso_a2,name"`
`topojson -o topo.json spam.json --id-property iso_a3`
Then you can use http://www.mapshaper.org/ to shrink the file
