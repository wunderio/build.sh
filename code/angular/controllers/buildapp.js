

var buildApp = angular.module('buildApp', ['angular-drupal']).run(function($rootScope, drupal) {
	console.log($rootScope);
	drupal.node_load(1).then(function(node) {
		$rootScope.nodes = [{'title': node.title}];
	});

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

});
