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

[width, height] = (Math.round(item * 97 / 100) for item in screenSize())

lineTransition =  (path) ->
    path.transition()
        .duration(5500)
        .each("end", (d,i) -> return 1)

makeTable = (tableData) =>
    columns = ["country", "people"]
    current_table = d3.selectAll('#table-left table');
    current_table = current_table.remove()

    table = d3.select("#table-left").append("table")
    thead = table.append("thead")
    tbody = table.append("tbody")

    thead.append("tr")
        .selectAll("th")
        .data(columns)
        .enter()
        .append("th")
        .text((column) -> column)
        .style("color", "white")
        .style("font-size", "20px")

    rows = tbody.selectAll("tr")
        .data(tableData)
        .enter()
        .append("tr")
        .style("color", "white")
        .style("font-size", "15px")

    cells = rows.selectAll("td")
        .data((row) =>
            columns.map((column) =>
                return {column: column, value: row[column]}
            )
        )
        .enter()
          .append("td")
          .text((d) => d.value)

class WorldMap
    @TABLE_LENGTH = 10
    @NULL_COUNTRY_COLOR = "#6d7988"
    @COUNTRY_COLOR = 'rgb(255, 255, 255)'
    @COLOR_MAP = ['rgba(255,255,204, 0.6)', 'rgba(255,237,160, 0.6)', 'rgba(254,217,118, 0.6)',
                  'rgba(254,178,76, 0.6)', 'rgba(253,141,60, 0.6)', 'rgba(252,78,42, 0.6)',
                  'rgba(227,26,28, 0.6)','rgba(189,0,38, 0.6)','rgba(128,0,38, 0.6)']

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

        # links = [] This is to be a "visual overload", may need later on.
        link_origin = @scope.countries[@scope.current_country]
        people = []
        tableData = []

        dict_name = @scope.currentMode.dict

        current_dict = @scope[dict_name]
        console.log dict_name, current_dict

        _.map(current_dict, (value, key) => 
            destination = @scope.countries[value.alpha2]

            if destination == undefined
                return -1

            if tableData.length < WorldMap.TABLE_LENGTH
                tableData.push({"country": value.alt_name, "people":value.people})

            # links.push({coordinates: [link_origin, destination]})
            people.push(value.people)
        )
        console.log people

        people = (Math.log(i ** 3) for i in people)
        median = d3.median(people)
        [min, max] = [d3.min(people), d3.max(people)]

        domain = []
        _.map(_.range(0, Math.round(max / median)), (i) -> domain.push(i))

        colorMap = d3.scale.quantize()
            .domain([min, max])
            # colorbrower_schemes.js
            .range(WorldMap.COLOR_MAP)

        @g.selectAll(".country")
            .attr('fill', (d, i) =>
                result = current_dict[d.properties.ISO_A2]
                if result == -1 || !result
                    if d.properties.ISO_A2 == @scope.current_country
                        return WorldMap.COUNTRY_COLOR
                    else
                        return WorldMap.NULL_COUNTRY_COLOR
                else 
                    # That will cuase (crazy / 3) cpu on zoom
                    # need to add the right values to avoid re-calc
                    return colorMap(Math.log(result.people ** 3))
            )
        makeTable(tableData)
        # @addLines links

    _load_data: () ->
        @load_data()
        # Async black magic, after the json is loaded 3 times is enough
        # Might be the easiest way to solve this
        @async_load_data = @load_data

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
                .on("dblclick", @dblclick)

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


loadCountry = ($scope, countryCode, categoryId) =>
    resetScope($scope)
    result = $scope.currentMode.Query.query({
        code: countryCode.toLowerCase(), category_id: categoryId
    })

    console.log $scope.currentMode
    $scope.current_country = countryCode.toUpperCase()
    mode = $scope.currentMode.result
    dict_name = $scope.currentMode.dict
    current_dict = $scope[dict_name]

    result.$promise.then (results) =>
        angular.forEach results, (result) =>
            data = result[mode]
            data['people'] = result.people
            current_dict[data.alpha2] = data

        $scope.worldMap.async_load_data()


loadInitialData = ($scope, Countries, Categories) =>
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


app.controller 'MainCtrl', 
    ['$scope', '$http', 'Origin', 'Destination', 'Categories', 'Countries'
     ($scope, $http, Origin, Destination, Categories, Countries) ->
        $scope.modes = [
            {
                name: "Destination",
                Query: Destination,
                dict: "origins",
                result: "origin"
            },
            {
                name: "Origin",
                Query: Origin,
                dict: "destinations",
                result: "destination"
            }
        ]

        $scope.countries = {}
        $scope.categories = new Set([])
        $scope.category_by_year = defaultDict([])

        $scope.currentMode = $scope.modes[0]
        $scope.$watch('currentMode', () -> return loadCountry($scope, "gb", 10))

        $scope.worldMap = new WorldMap($scope)

        loadInitialData($scope, Countries, Categories)

]

# docFrag = document.createDocumentFragment()
# table = d3.select(docFrag).append("table").attr("class", "graph-key")
# thead = table.append("thead")
# tbody = table.append("tbody")


    # projection = d3.geo.equirectangular()
    #     .center([23, -3])
    #     .rotate([4.4, 0])
    #     .scale(225)
    #     .translate([x / 2, y / 2])


    # val = d3.rgb()
    # [r, g, b] = [val.r, val.g, val.b]
    # val = "rgba(#{r},#{g},#{b}, 0.6)"
