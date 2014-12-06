build.sh
=================================================

By the Wunderful People at Wunderkraut

--

build.sh is a tool for making, updating and managing Drupal installations from the development phase up to production.


It is built to:
 - Eliminate the need to have 3rd part code in your repository.
 - Make core and module updates fast and easy.
 - Enhance security of your Drupal installation.
 - Make your life just a little bit easier and worry free.

Installation:

No installation is required, build.sh is the only required file apart from the necessary configuration files.

Dependencies:

Drush capable of running make commands (latest version should work out of the box).

python + various libraries are required, running ./build.sh should print the help text if everything is OK.
The only extra library you may have to install is the python yaml library. This should be installable with:

$ pip install ...

Basic usage:

Running build.sh without any parameters will give you a simple help on what you can do.

	$ build.sh [options] [command] [site]

Options:

  -h --help
 	Prints help
  -c --config
	Configuration file to use, defaults to conf/site.yml'
  -v --version
  	Print version information

Configuration file:

The configuration file is a yaml based file which contains both the site information and commands.
The site information consists of definitions for temporary build dir, old builds and final builds dir, the used Drupal installation profile name, linking and copying information, etc. See conf/site.yml for examples and more information.

Commands:

A command is a set of steps defined in the configuration file (see the bottom of conf/site.yml) therefore commands can vary from configuration to another.

The only hard coded command is test:
$ ./build.sh test
Would do a simple test on your drush make file to check projects/libraries that are not referencing any direct versions (for example drupal.org module dev versions or github master versions).

The example configuration file in conf/site.yml defines the following commands:

 - new
 - update
 - package
 - backup

The provided steps are:

 - make
 	Create a temporary Drupal installation based on the drush make file (drush make).
 - backup
 	Backup the current final installation if such exists under the previous builds directory.
 - purge
 	Simply purges the current final installation (drops database).
 - finalize
 	Deletes the final installation (if such exists) and replaces it with the temporary one.
 - install
 	Run Drupal site installation via drush (drops database)
 - update
 	Run drush updatedb for the final installation.
 - cleanup
 	Clean up any old builds under previous builds directory.
 - append
 	Simply append the given file to the end of another file
 	Example:
 		- append: conf/our_htaccess_additions > current/.htaccess
 - link
 	Process link and copy directives. This step is not required as it is run by the finalize step if not yet ran.
 - test
 	Tests make file for possible volatile module/library references, in essence this is the same as running ./build.sh test
 - shell
 	Run a shell command. NOTE: currently piping does not work, this means you cannot do things like 'echo "hello" >> world.txt'

Example of usage:

At the beginning you will always run:
$ ./build.sh new
This should produces a new fresh Drupal installation. Usually you should use the installation profile as well as Drupal features to enable your sites modules and to configure it.

(Add a new modules to conf/site.make, add update hooks to enable modules to your installation profiles install file, etc).

$ ./build.sh update
This will rebuild the site accordingly from scratch without dropping any databases and finally Drupal update is ran.




About files and directories (-> denotes copying/symlinking):

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



