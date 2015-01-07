api_app = angular.module 'migrants.api', ['ngResource']
app = angular.module 'migrants.main', ['migrants.api']

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

resetScope = ($scope) -> 
    '''
    Ensure the state is cleaned every time
    '''
    $scope.countries = {}
    $scope.categories = new Set([])
    $scope.category_by_year = defaultDict([])
    $scope.years = new Set([])
    $scope.destinations = defaultDict(-1)
    $scope.origins = defaultDict(-1)
    $scope.current_country = null;
    $scope.is_loading = false

defaultDict = (type) ->
    dict = {}
    return {
        get: (key) ->
            if (!dict[key])
                dict[key] = type.constructor()
            return dict[key]
        dict: dict
    }

screenSize = () ->
    # http://stackoverflow.com/questions/3437786
    docElm = document.documentElement
    body = document.getElementsByTagName('body')[0]
    x = window.innerWidth || docElm.clientWidth || body.clientWidth
    y = window.innerHeight|| docElm.clientHeight|| body.clientHeight
    return [x, y]

[width, height] = (Math.round(item - item * 10 / 100) for item in screenSize())


lineTransition =  (path) ->
    path.transition()
        .duration(5500)
        .each("end", (d,i) -> return 1)

class WorldMap
    @COUNTRY_COLOR = "#6d7988"

    constructor: ($scope) ->
        @scope = $scope
        @tooltip = d3.select("#container").append("div").attr("class", "tooltip hidden")
        @offsetL = document.getElementById('container').offsetLeft + 20
        @offsetT = document.getElementById('container').offsetTop + 10

        @zoom = d3.behavior.zoom()
            .scaleExtent([0.72, 10])
            .on("zoom", @move)

        @container = document.getElementById('container')
        @setup width, height
        @draw()

        # async black magic
        # Need 3 Api calls + a json to be downloaded for the data to be initialized
        # Then the data is picked from the scope, might be a better way of doing this
        @async_load_data = _.after(4, @_load_data)

    load_data: () ->
        '''
        the load_data functions are a hack to work with async calls on load
        Mostly temporary code until the color maps are fixed.
        '''

        links = []
        link_origin = @scope.countries[@scope.current_country]
        [min, max] = [Infinity, -Infinity]
        people = []

        _.map(@scope.destinations, (value, key) => 
            destination = @scope.countries[value.alpha2]
            if destination == undefined
                return -1

            links.push({coordinates: [link_origin, destination]})
            people.push(value.people)
            if value.people > max
                max = value.people
        )

        # TODO clean up this mess
        median = d3.mean(people)
        low = people.filter (x) -> x < median
        high = people.filter (x) -> x > median

        [lowMedian, highMedian] = [d3.median(low), d3.median(high)]
        [lowDomain, highDomain] = [[], []]
        [lowMax, highMax] = [d3.max(low), d3.max(high)]

        _.map(_.range(
            0, Math.round(lowMax / lowMedian)),
            (i) -> lowDomain.push(i * lowMedian))
        _.map(_.range(
            0, Math.round(highMax / highMedian)),
            (i) -> highDomain.push(i * highMedian))

        lowColorMap = d3.scale.linear()
            .domain(lowDomain)
            .range(["#FF0000", "#FF3700", "#FF6600", "#FF8000", "#FFAE00"])

        highColorMap = d3.scale.linear()
            .domain(highDomain)
            .range(["#FFD900", "#FFFF00", "#FFFF91", "#FFFFC4", "#FCFCD9", "#FCFCEB"])

        @g.selectAll(".country")
            .attr('fill', (d, i) =>
                result = @scope.destinations[d.properties.ISO_A2]
                if result == -1 || !result
                    return 'not-colored'
                else
                    if result.people < median
                        colorMap = lowColorMap
                    else
                        colorMap = highColorMap

                    val = d3.rgb(colorMap(result.people))
                    [r, g, b] = [val.r, val.g, val.b]
                    val = "rgba(#{r},#{g},#{b}, 0.6)" 
                    return val
            )
        # @addLines links

    _load_data: () ->
        @load_data()

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
                .style("fill", @COUNTRY_COLOR)

            country.on("mousemove", @mousemove)
            country.on("mouseout",  @mouseout)
            @async_load_data()
        )

    addLines: (links) =>
        '''
        Links example
        [route = { coordinates: [[54.0000, -2.0000], [42.8333, 12.8333]]}]
        '''
        c20 = d3.scale.category10()
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
            .style("stroke", (d, i) => c20(i))

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


app.controller 'MainCtrl', 
    ['$scope', '$http', 'Origin', 'Destination', 'Categories', 'Countries'
     ($scope, $http, Origin, Destination, Categories, Countries) ->
        resetScope($scope)
        $scope.worldMap = new WorldMap($scope)

        result = Origin.query({code: 'gb', category_id: 1})
        $scope.current_country = 'GB'
        result.$promise.then (results) ->
            angular.forEach results, (result) ->
                data = result.destination
                data['people'] = result.people
                $scope.destinations[data.alpha2] = data
            $scope.worldMap.async_load_data()

        countries = Countries.query()
        countries.$promise.then (results) ->
            angular.forEach results, (result) ->
                $scope.countries[result.alpha2] = [
                    result.center_lat, result.center_long
                ]
            $scope.worldMap.async_load_data()

        categories = Categories.query()
        categories.$promise.then (results) ->
            angular.forEach results, (result) ->
                $scope.categories.add(result.title)
                $scope.years.add(result.year)
                $scope.category_by_year.get(result.year).push(result.title)
            $scope.worldMap.async_load_data()
]

    # projection = d3.geo.equirectangular()
    #     .center([23, -3])
    #     .rotate([4.4, 0])
    #     .scale(225)
    #     .translate([x / 2, y / 2])
