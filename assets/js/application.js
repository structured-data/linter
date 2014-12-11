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
      $scope.verifySSL = true;  // verifySSL parameter
      $scope.loading = null;      // show page loading symbol
      $scope.fieldset = 'url';    // Which fieldset to display

      // Which form field to show
      $scope.getClass = function(fieldset) {
        return $scope.fieldset === fieldset ? "active" : "";
      };

      $scope.lintUrl = function(path) {
        $scope.loading = true;
        $scope.result = null;
        $scope.url = path;
        $location.url($location.path()); // Clear parameters
        $location.search('url', path);  // Add url parameter
        if (!$scope.verifySSL) {
          $location.search('verify_ssl', 'false'); // Add only if false
        }
        $http.get("/", {params: {url: path, verify_ssl: $scope.verifySSL}})
          .success(function(data) {
            $scope.result = data;
            $scope.loading = false;
          })
          .error(function(data) {
            $scope.result = {messages: [data]};
            $scope.loading = false;
          });
      };

      $scope.lintInput = function(input) {
        $scope.loading = true;
        $scope.result = null;
        $location.url($location.path()); // Clear parameters
        $http.post("/", {content: input, verify_ssl: $scope.verifySSL})
          .success(function(data) {
            $scope.result = data;
            $scope.loading = false;
          })
          .error(function(data) {
            $scope.result = {messages: [data]};
            $scope.loading = false;
          });
      };

      // If there are routeParams, use them to initialize the controller
      if ($location.search().url) {$scope.lintUrl($location.search().url);}
    }
  ]);
