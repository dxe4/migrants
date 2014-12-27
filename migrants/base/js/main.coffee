app = angular.module 'migrants.main', []

screenSize = () ->
    # http://stackoverflow.com/questions/3437786
    docElm = document.documentElement
    body = document.getElementsByTagName('body')[0]
    x = window.innerWidth || docElm.clientWidth || body.clientWidth
    y = window.innerHeight|| docElm.clientHeight|| body.clientHeight
    return [x, y]


app.controller 'MainCtrl', ['$scope', '$http', ($scope, $http) ->
    container = document.getElementById('container')

    [$scope.x, $scope.y] = (
        Math.round(item - item * 10 / 100)for item in screenSize())

    defaultProjection = (element) -> 
        projection = d3.geo.equirectangular()
            .center([23, -3])
            .rotate([4.4, 0])
            .scale(225)
            .translate([$scope.x / 2, $scope.y / 2])

        path = d3.geo.path().projection(projection)
        return {path: path, projection: projection}

    initMap = () ->
        $scope.dataMap = new Datamap({
            element: container
            scome: "world"
            setProjection: defaultProjection
        })

    angular.element(document).ready(initMap)

]
