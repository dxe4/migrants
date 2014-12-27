app = angular.module 'migrants.main', []

app.controller 'MainCtrl', ['$scope', '$http', ($scope, $http) ->
    $scope.spam = ["spam", "eggs"]
    map = new Datamap({element: document.getElementById('container')})
]
