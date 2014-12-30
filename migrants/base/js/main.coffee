api_app = angular.module 'migrants.api', ['ngResource']
app = angular.module 'migrants.main', ['migrants.api']

screenSize = () ->
    # http://stackoverflow.com/questions/3437786
    docElm = document.documentElement
    body = document.getElementsByTagName('body')[0]
    x = window.innerWidth || docElm.clientWidth || body.clientWidth
    y = window.innerHeight|| docElm.clientHeight|| body.clientHeight
    return [x, y]

[width, height] = (Math.round(item - item * 10 / 100)for item in screenSize())


lineTransition =  (path) ->
    path.transition()
        .duration(5500)
        .each("end", (d,i) -> return 1)
        

class WorldMap
    constructor: ->
        @tooltip = d3.select("#container").append("div").attr("class", "tooltip hidden")
        @offsetL = document.getElementById('container').offsetLeft + 20
        @offsetT = document.getElementById('container').offsetTop + 10

        @zoom = d3.behavior.zoom()
            .scaleExtent([0.72, 10])
            .on("zoom", @move)

        @container = document.getElementById('container')
        @setup width, height
        @draw()

    setup: (x, y) ->
        @projection = d3.geo.mercator()
            .translate([( x / 2), (y / 1.5)])
            .scale( x / 2 / Math.PI)

        @path = d3.geo.path().projection(@projection)

    draw: () =>
        d3.json("static/countries.topo.json", (error, world) =>
            countries = topojson.feature(world, world.objects.countries).features

            @svg = d3.select("#container").append("svg")
                .attr("width", width)
                .attr("height", height)
                .call(@zoom)
                .on("dblclick", @click)
                .append("g")

            @g = @svg.append("g")

            country = @g.selectAll(".country").data(countries)

            country.enter().insert("path")
                .attr("class", "country")
                .attr("d", @path)
                .attr("id", (d,i) ->  return d.properties.ISO_A2)
                .attr("title", (d,i) ->  return d.properties.NAME)
                .style("fill", "#6d7988")

            country.on("mousemove", @mousemove)
            country.on("mouseout",  @mouseout)
        )

    addLines: (links) =>
        '''
        Links example
        [route = { coordinates: [[54.0000, -2.0000], [42.8333, 12.8333]]}]
        '''
        @g.selectAll("line")
            .data(links)
            .enter()
            .append("line")
            .attr("x1", (d) =>
                @projection([d.coordinates[0][1], d.coordinates[0][0]])[0])
            .attr("y1", (d) =>
                @projection([d.coordinates[0][1], d.coordinates[0][0]])[1])
            .attr("x2", (d) =>
                @projection([d.coordinates[1][1], d.coordinates[1][0]])[0])
            .attr("y2", (d) =>
                @projection([d.coordinates[1][1], d.coordinates[1][0]])[1])
            .style("stroke", "yellow")

    redraw: () ->
        x = @container.offsetWidth
        y = x / 2
        d3.select('svg').remove()
        @setup(x, y)
        @draw(topo)


    throttle: () =>
        window.clearTimeout(throttleTimer)
        throttleTimer = window.setTimeout(() =>
            return @redraw()
            200
        )

    dblclick: () =>
        latlon = @projection.invert(d3.mouse(@container))
        console.log latlon

    mousemove: (d, i) =>
        mouse = d3.mouse(@svg.node()).map( (d) -> return parseInt(d))
        style = "left:" + (mouse[0] + @offsetL) + "px;top:" + (mouse[1] + @offsetT) + "px"
        @tooltip.classed("hidden", false)
            .attr("style", style)
            .html(d.properties.NAME)

    mouseout: (d, i) =>
        @tooltip.classed("hidden", true)

    move: () =>
        t = d3.event.translate;
        s = d3.event.scale;
        zscale = s;
        h = height / 4;


        t[0] = Math.min(
            (width / height)  * (s - 1),
            Math.max(width * (1 - s), t[0] )
        )

        t[1] = Math.min(
            h * (s - 1) + h * s,
            Math.max(height  * (1 - s) - h * s, t[1])
        )

        @zoom.translate(t);
        @g.attr("transform", "translate(" + t + ")scale(" + s + ")")


api_app.factory 'Origin', ['$resource', ($resource) ->
    $resource 'category/:category_id/origin/:code'
]

api_app.factory 'Destination', ['$resource', ($resource) ->
    $resource 'category/:category_id/destination/:code'
]

api_app.factory 'Categories', ['$resource', ($resource) ->
    $resource 'category/all'
]

api_app.factory 'Countries', ['$resource', ($resource) ->
    $resource 'country/all'
]

defaultDict = (type) ->
    dict = {}
    return {
        get: (key) ->
            if (!dict[key])
                dict[key] = type.constructor()
            return dict[key]
        dict: dict
    }

app.controller 'MainCtrl', 
    ['$scope', '$http', 'Origin', 'Destination', 'Categories', 'Countries'
     ($scope, $http, Origin, Destination, Categories, Countries) ->
        $scope.countries = {}
        $scope.categories = new Set([])
        $scope.category_by_year = defaultDict([])
        $scope.years = new Set([])
        $scope.current_result = defaultDict([])
        $scope.is_loading = false

        result = Origin.query({code: 'gb', category_id: 1})
        result.$promise.then (results) ->
            angular.forEach results, (result) ->
                data = result.destination
                data['people'] = result.people
                $scope.current_result.get('destination').push(data)

        countries = Countries.query()
        countries.$promise.then (results) ->
            angular.forEach results, (result) ->
                $scope.countries[result.alpha2] = [
                    result.center_lat, result.center_long
                ]

        categories = Categories.query()
        categories.$promise.then (results) ->
            angular.forEach results, (result) ->
                $scope.categories.add(result.title)
                $scope.years.add(result.year)
                $scope.category_by_year.get(result.year).push(result.title)

        worldMap = new WorldMap()
]

    # projection = d3.geo.equirectangular()
    #     .center([23, -3])
    #     .rotate([4.4, 0])
    #     .scale(225)
    #     .translate([x / 2, y / 2])
