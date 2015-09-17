
// Hacky stuff herein
var D;

var buildApp = angular.module('buildApp', ['angular-drupal']).run(function($rootScope, drupal) {
	D = drupal;
});

buildApp.$inject = ["$rootScope", "drupal"];

angular.module('angular-drupal').config(function($provide) {
  $provide.value('drupalSettings', {
    sitePath: 'http://127.0.0.1:8888/',
    endpoint: 'api'
  });

});


buildApp.controller('BuildAppCtrl', function ($scope) {
	$scope.nodes = [
		{'title': 'node title'},
	];

	D.node_load(1).then(function(node) {
		$scope.nodes = [{'title': node.title}];
	});

});
