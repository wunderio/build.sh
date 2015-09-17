
// Hacky stuff herein
var D;

var buildApp = angular.module('buildApp', ['angular-drupal', 'ngSanitize']).run(function($rootScope, drupal) {
	D = drupal;
});

buildApp.$inject = ["$rootScope", "drupal"];

angular.module('angular-drupal').config(function($provide) {
  $provide.value('drupalSettings', {
    sitePath: 'http://127.0.0.1:8888/',
    endpoint: 'api'
  });

});


function s(h) {
	return h;
}

buildApp.controller('BuildAppCtrl', function ($scope) {
	$scope.node = {'title': 'node title', 'body': 'node body'};

	D.node_load(1).then(function(node) {
		$scope.node = {'title': node.title, 'body': node.body.und[0].safe_value};
	});

});
