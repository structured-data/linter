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
  .controller('LinterController', ['$scope', '$http', '$location',
    function ($scope, $http, $location) {
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
        $location.url($location.path()); // Clear parameters
        $location.search('url', path);  // Add url parameter
        if (!$scope.validateSSL) {
          $location.search('validate_ssl', 'false'); // Add only if false
        }
        $scope.result = {messages: ["Loading..."]};
        $http.get("/", {params: {url: path, validate_ssl: $scope.validateSSL}})
          .success(function(data) {
            $scope.result = data;
          })
          .error(function(data) {
            $scope.result = {messages: [data]};
          });
      };

      $scope.lintInput = function(input) {
        $scope.result = {messages: ["Loading..."]};
        $location.url($location.path()); // Clear parameters
        $http.post("/", {content: input, validate_ssl: $scope.validateSSL})
          .success(function(data) {
            $scope.result = data;
          })
          .error(function(data) {
            $scope.result = {messages: [data]};
          });
      };

      // If there are routeParams, use them to initialize the controller
      if ($location.search().url) {$scope.lintUrl($location.search().url);}
    }
  ]);
