/*global $, _, angular*/

var testApp = angular.module('linterApp', ['ngRoute', 'ngSanitize', 'angularFileUpload'])
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
  .controller('LinterController', ['$scope', '$http', '$location', 'FileUploader',
    function ($scope, $http, $location, FileUploader) {
      var uploader = $scope.uploader = new FileUploader({url: "/"});
      $scope.url = null;          // URL parameter
      $scope.upload = null;       // upload parameter FIXME
      $scope.input = null;        // input parameter
      $scope.verifySSL = true;    // verifySSL parameter
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
          .then(function(response) {
            $scope.result = response.data;
            $scope.loading = false;
          })
          .catch(function(response) {
            $scope.result = response.data;
            $scope.loading = false;
          });
      };

      $scope.lintInput = function(input) {
        $scope.loading = true;
        $scope.result = null;
        $location.url($location.path()); // Clear parameters
        $http.post("/", {content: input, verify_ssl: $scope.verifySSL})
          .then(function(response) {
            $scope.result = response.data;
            $scope.loading = false;
          })
          .catch(function(response) {
            $scope.result = response.data;
            $scope.loading = false;
          });
      };

      uploader.onAfterAddingFile = function() {
        $scope.result = null;
        $location.url($location.path()); // Clear parameters
      };
      uploader.onBeforeUploadItem = function() {
        $scope.loading = true;
        $scope.result = null;
        $location.url($location.path()); // Clear parameters
      };
      uploader.onCompleteItem = function(fileItem, data) {
        $scope.result = data;
        $scope.loading = false;
      };

      // If there are routeParams, use them to initialize the controller
      if ($location.search().url) {
        // Set verify_ssl, if it's in the params
        if ($location.search().verify_ssl === "false") $scope.verifySSL = false;
        $scope.lintUrl($location.search().url);
      }
    }
  ]);
