build.sh
=================================================

By the Wunderful People at Wunderkraut

build.sh is a tool for making, updating and managing Drupal installations from the development phase to production. 

It is built to:
 - Eliminate the need to have 3rd part code in your repository.
 - Make core and module updates fast and easy.
 - Enhance security of your Drupal installation.
 - Make your life just a little bit easier and worry free.



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



