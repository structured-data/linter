/*global $, _, angular*/

var testApp = angular.module('LinterApp', ['ngRoute', 'ngSanitize'])
  .config(['$routeProvider', '$locationProvider', '$logProvider',
    function($routeProvider, $locationProvider, $logProvider) {

      $locationProvider.html5Mode(true);
      $logProvider.debugEnabled(true);
      $routeProvider.
        when('/', {
          controller: 'LinterController'
        }).
        otherwise({
          controller: function() {
              window.location.replace('/');
          }, 
          template: "<div></div>"
          //redirectTo: '/tests'
        });
    }
  ])
  .controller('LinterController', ['$scope', '$http',
    function ($scope, $http) {
      $scope.url = null;          // URL parameter
      $scope.upload = null;       // upload parameter FIXME
      $scope.input = null;        // input parameter
      $scope.validateSSL = true;  // validateSSL parameter
      // Which fieldset to display
      $scope.fieldset = 'url';

      // Which form field to show
      $scope.getClass = function(fieldset) {
        return $scope.fieldset === fieldset ? "active" : "";
      };

      $scope.lintUrl = function(path) {
        $scope.url = path;
        $http.get("/", {params: {url: path, validate_ssl: $scope.validateSSL}})
          .success(function(data, status, headers, config) {
            $scope.result = data;
          })
          .error(function(data, status, headers, config) {
            $scope.result = {messages: data};
          });
      };
    }
  ]);
