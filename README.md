build.sh
=================================================

By the Wunderful People at Wunderkraut

--

Apologies for the incomplete documentation! We're working on it.

build.sh is a tool for making, updating and managing Drupal installations from the development phase to production. 

It is built to:
 - Eliminate the need to have 3rd part code in your repository.
 - Make core and module updates fast and easy.
 - Enhance security of your Drupal installation.
 - Make your life just a little bit easier and worry free.

Usage:

@TODO

Running build.sh without any parameters will give you a simple help on what you can do.

	$ build.sh [options] [command] [site]

Commands:

@TODO

build.sh commands can vary from a configuration file to another. A command consists of a number of steps which are executed in the order in which they are defined.

There are a few hard coded commands:

./build.sh test
Would run a simple test on your drush make file to check for problematic projects/libraries

The example configuration file in conf/site.yml defines the following commands:
 - new
 - update
 - package
 - backup

Provided steps:

@TODO

About files and directories:

	File/directory				Explanation

	code/						Custom modules, themes, features, etc.

		profiles/wk				Generic site install profile -> profiles/wk
		modules					Custom modules directory ->  sites/all/modules/custom
		themes					Custom themes directory -> sites/all/themes/custom

	conf/						Configuration files

		site.yml				build.sh configuration
		site.make				drush make file
		local.settings.php		Drupal settings.php file -> sites/default/settings.php		

	files/						Drupal files folder -> sites/default/files



