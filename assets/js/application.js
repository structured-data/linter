/*global $, _, angular*/

var testApp = angular.module('linterApp', ['ngRoute', 'ngSanitize'])
  .config(['$routeProvider', '$locationProvider', '$logProvider',
    function($routeProvider, $locationProvider, $logProvider) {

      $locationProvider.html5Mode(true);
      $logProvider.debugEnabled(true);
      $routeProvider.
        when('/', {
          controller: 'LinterCtrl'
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
  .controller('LinterCtrl', ['$scope',
    function ($scope) {
      // Which fieldset to display
      $scope.fieldset = 'url';
    }
  ]);
