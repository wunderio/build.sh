#!/usr/bin/env python
# *****************************************************************************
# build.sh by the Wunderful People at Wunderkraut
#
# https://github.com/wunderkraut/build.sh
# *****************************************************************************

import getopt
import sys
import yaml
import os
import subprocess
import shutil
import hashlib
import datetime
import stat
import re
import tarfile
import time

# Build scripts version string.
build_sh_version_string = "build.sh 1.0"

build_sh_skip_backup = False
build_sh_disable_cache = False

# Site.make item (either a project/library from the site.make)
class MakeItem:

	def __init__(self, type, name):
		self.type = type
		self.name = name
		self.version = 'UNDEFINED'
		if self.type == 'libraries':
			self.project_type = 'library'
		else:
			self.project_type = 'module'

		self.download_args = {}

	# Parse a line from site.make for this project/lib
	def parse(self, line):

		# Download related items
		type = re.compile("^[^\[]*\[[^\]]*\]\[download\]\[([^\]]*)\]\s*=\s*(.*)$")
		t = type.match(line)
		if t:
			self.download_args[t.group(1)] = t.group(2)

		# Version number
		version = re.compile("^.*\[version\]\s*=\s*(.*)$")
		v = version.match(line)
		if v:
			self.version = v.group(1)

		# Project type
		type = re.compile("^[^\[]*\[[^\]]*\]\[type\]\s*=\s*(.*)$")
		t = type.match(line)
		if t:
			self.project_type = t.group(1)

	# Validate site.make item, returns a string describing the issue or False if no issues
	def validate(self):
		if 'type' in self.download_args:
			version = re.compile(".*[0-9]+\.[0-9]+.*")
			if self.download_args['type'] == 'git':
				if 'tag' not in self.download_args and 'revision' not in self.download_args:
					return "No revision or tag defined for a git download"
			elif self.download_args['type'] == 'file' and 'url' in self.download_args and not version.match(self.download_args['url']):
				return "URL does not seem to have a version number in it (" + self.download_args['url'] + ")"
		elif 'dev' in self.version:
			return "Development version in use (" + self.version + ")"
		return False

# BuildError exception class.
class BuildError(Exception):

	def __init__(self, value):
		self.value = value

	def __str__(self):
		return repr(self.value)

# Maker class.
class Maker:

	def __init__(self, settings):

		self.composer = settings.get('composer', 'composer')
		self.drush = settings.get('drush', 'drush')
		self.type = settings.get('type', 'drush make')
		self.drupal_subpath = settings.get('drupal_subpath', '')
		self.temp_build_dir_name = settings['temporary']
		self.temp_build_dir = os.path.abspath(self.temp_build_dir_name)
		self.final_build_dir_name = settings['final']
		self.final_build_dir = os.path.abspath(self.final_build_dir_name)
		self.final_build_dir_bak = self.final_build_dir + "_bak_" + str(time.time())
		self.old_build_dir = os.path.abspath(settings.get('previous', 'previous'))
		self.profile_name = settings.get('profile', 'standard')
		self.site_name = settings.get('site', 'A drupal site')
		self.make_cache_dir = settings.get('make_cache', '.make_cache')
		self.settings = settings
		self.store_old_buids = True
		self.linked = False

		if self.type == 'drush make':
			self.makefile = os.path.abspath(settings.get('makefile', 'conf/site.make'))
			self.makefile_hash = hashlib.md5(open(self.makefile, 'rb').read()).hexdigest()

		# See if drush is installed
		if not self._which('drush'):
			raise BuildError('Drush missing!?')

	def test(self):
		self._validate_makefile()

	# Check if given program exists
	# http://stackoverflow.com/questions/377017/test-if-executable-exists-in-python
	def _which(self, program):
		import os
		def is_exe(fpath):
			return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

		fpath, fname = os.path.split(program)
		if fpath:
			if is_exe(program):
				return program
		else:
			for path in os.environ["PATH"].split(os.pathsep):
				path = path.strip('"')
				exe_file = os.path.join(path, program)
				if is_exe(exe_file):
					return exe_file

		return None

	# Quickly validate the drush make file
	def _validate_makefile(self):
		f = open(self.makefile)
		if f:
			content = f.readlines()
			projects = {}
			prog = re.compile("^([^\[]*)\[([^\]]*)\]\[([^\]]*)\].*$")
			for line in content:
				m = prog.match(line)
				if m:
					name = m.group(2)
					if name not in projects:
						projects[name] = MakeItem(m.group(1), name)
					projects[name].parse(line)

			errors = False
			for item in projects:
				error = projects[item].validate()
				if error:
					errors = True
					self.warning(projects[item].name + ': ' + error)
			if errors:
				raise BuildError("The make file is volatile - it is not ready for production use")
			else:
				self.notice("Everything looks good!")

	# Run make
	def make(self):
		if self.type == 'drush make':
			self._drush_make()
		elif self.type == 'composer':
			self._composer_make()

	def _composer_make(self):
		self._precheck()
		self.link()
		self._composer([
			'-d=' + self.temp_build_dir,
			'install'
		]);

	def _drush_make(self):
		global build_sh_disable_cache
		self._precheck()
		self.notice("Building")

		packaged_build = self.make_cache_dir + '/' + self.makefile_hash + '.tgz';

		if not build_sh_disable_cache and os.path.exists(packaged_build):
			# Existing build
			self.notice("Make file unchanged - unpacking previous make")
			tar = tarfile.open(packaged_build)
			tar.extractall()
			tar.close()

		else:

			if not self._drush(self._collect_make_args()):
				raise BuildError("Make failed - check your makefile")

			os.remove(self.temp_build_dir + "/sites/default/default.settings.php")

			if not os.path.isdir(self.make_cache_dir):
				os.makedirs(self.make_cache_dir)

			tar = tarfile.open(packaged_build, "w:gz")
			tar.add(self.temp_build_dir, arcname=self.temp_build_dir_name)
			tar.close()

		# f = open(self.temp_build_dir + "/buildhash", "w")
		# f.write(self.makefile_hash)
		# f.close()
		# Remove default.settings.php

	# Existing final build?
	def hasExistingBuild(self):
		return os.path.isdir(self.final_build_dir)

	# Backup current final build
	def backup(self, params):
		global build_sh_skip_backup
		if build_sh_skip_backup:
			self.notice("Skipping backup!")
			return
		if not params:
			params = {}
		self.notice("Backing up current build")
		if self.hasExistingBuild():
			self._backup(params)

	def cleanup(self):
		compare = time.time() - (60*60*24)
		for f in os.listdir(self.old_build_dir):
			fullpath = os.path.join(self.old_build_dir, f)
			if os.stat(fullpath).st_mtime < compare:
				if os.path.isdir(fullpath):
					self.notice("Removing old build " + f)
					shutil.rmtree(fullpath)
				elif os.path.isfile(fullpath):
					self.notice("Removing old build archive " + f)
					os.remove(fullpath)

	# Purge current final build
	def purge(self):
		self.notice("Purging current build")
		if self.hasExistingBuild():
			self._wipe()

	# Link
	def link(self):
		# Link and copy required files
		self._link()
		self._copy()
		self.linked = True

	# Finalize new build to be the final build
	def finalize(self):
		self.notice("Finalizing new build")
		if os.path.isdir(self.final_build_dir):
			self._unlink()
			self._ensure_writable(self.final_build_dir)
			os.rename(self.final_build_dir, self.final_build_dir_bak)
		# Make sure linking has happened
		if not self.linked:
			self.link()
		os.rename(self.temp_build_dir, self.final_build_dir)
		if os.path.isdir(self.final_build_dir_bak):
			shutil.rmtree(self.final_build_dir_bak, True)

	# Print notice
	def notice(self, *args):
		print "\033[92m** BUILD NOTICE: \033[0m" + ' '.join(str(a) for a in args)

	# Print errror
	def error(self, *args):
		print "\033[91m** BUILD ERROR: \033[0m" + ' '.join(str(a) for a in args)

	# Print warning
	def warning(self, *args):
		print "\033[93m** BUILD WARNING: \033[0m" + ' '.join(str(a) for a in args)

	# Run install
	def install(self):
		if not self._drush([
			"--root=" + format(self.final_build_dir + self.drupal_subpath),
			"site-install",
			self.profile_name,
			"install_configure_form.update_status_module='array(FALSE,FALSE)'"
			"--account-name=admin",
			"--account-pass=admin",
			"--site-name=" + self.site_name,
			"-y"
		]):
			raise BuildError("Install failed.");

	# Update existing final build
	def update(self):
		if self._drush([
			"--root=" + format(self.final_build_dir + self.drupal_subpath),
			'updatedb',
			'--y'
		]):
			self.notice("Update process completed")
		else:
			self.warning("Unable to update")

	# Ask user for verification
	def verify(self, text):
		if text:
			response = raw_input(text)
		else:
			response = raw_input("Type yes to verify that you know what you are doing: ")
		if response.lower() != "yes":
			raise BuildError("Cancelled by user")

	# Execute a shell command
	def shell(self, command):
		if isinstance(command, list):
			for step in command:
				value = os.system(command) == 0
				if not value:
					return False
			return True
		else:
			return os.system(command) == 0

	def append(self, command):
		files = command.split(">")
		if len(files) > 1:
			with open(files[1].strip(), "a") as target:
				target.write(open(files[0].strip(), "rb").read())
		else:
			raise BuildError("Append commands syntax is: source > target")

	# Execute given step
	def execute(self, step):

		command = False
		if isinstance(step, dict):
			step, command = step.popitem()

		if step == 'make':
			self.make()
		elif step == 'backup':
			self.backup(command)
		elif step == 'purge':
			self.purge()
		elif step == 'finalize':
			self.finalize()
		elif step == 'install':
			self.install()
		elif step == 'update':
			self.update()
		elif step == 'cleanup':
			self.cleanup()
		elif step == 'append':
			self.append(command)
		elif step == 'verify':
			self.verify(command)
		elif step == 'shell':
			self.shell(command)
		elif step == 'link':
			self.link()
		elif step == 'test':
			self.test()
		else:
			print "Unknown step " + step


	# Collect make args
	def _collect_make_args(self):
		return [
			"--strict=0",
			"--concurrency=20",
			"-y",
			"make",
			self.makefile,
			self.temp_build_dir
		]


	# Handle link
	def _link(self):
		if not "link" in self.settings:
			return
		for tuple in self.settings['link']:
			source, target = tuple.items()[0]
			target = self.temp_build_dir + "/" + target
			if source.endswith('*'):
				path = source[:-1]
				paths = [path + name for name in os.listdir(path) if os.path.isdir(path + name)]
				for source in paths:
					self._link_files(source, target + "/" + os.path.basename(source))
			else:
				self._link_files(source, target)

	# Handle unlink
	def _unlink(self):
		if not "link" in self.settings:
			return
		for tuple in self.settings['link']:
			source, target = tuple.items()[0]
			target = self.final_build_dir + "/" + target
			if source.endswith('*'):
				path = source[:-1]
				paths = [path + name for name in os.listdir(path) if os.path.isdir(path + name)]
				for source in paths:
					self._unlink_files(target + "/" + os.path.basename(source))
			else:
				self._unlink_files(target)


	# Handle copy
	def _copy(self):
		if not "copy" in self.settings:
			return
		for tuple in self.settings['copy']:
			source, target = tuple.popitem()
			target = self.temp_build_dir + "/" + target
			self._copy_files(source, target)

	# Execute a composer command
	def _composer(self, args, quiet = False):
		if quiet:
			FNULL = open(os.devnull, 'w')
			return subprocess.call([self.composer] + args, stdout=FNULL, stderr=FNULL) == 0
		return subprocess.call([self.composer] + args) == 0

	# Execute a drush command
	def _drush(self, args, quiet = False):
		if quiet:
			FNULL = open(os.devnull, 'w')
			return subprocess.call([self.drush] + args, stdout=FNULL, stderr=FNULL) == 0
		return subprocess.call([self.drush] + args) == 0

	# Ensure directories exist
	def _precheck(self):
		# Remove old build it if exists
		if os.path.isdir(self.temp_build_dir):
			shutil.rmtree(self.temp_build_dir)
		if not os.path.isdir(self.old_build_dir):
			os.mkdir(self.old_build_dir)

	# TarFile exclude callback for _backup function
	def _backup_exlude(self, file):
		for exclude in self._build_exclude_files:
			if file.endswith(exclude):
				return True
		return False

	# Backup existing final build
	def _backup(self, params):

		if 'skip-database' in params:
			self.notice("Database dump skipped as requested")
		else:

			dump_file = self.final_build_dir + '/db.sql'

			if self._drush([
				"--root=" + format(self.final_build_dir + self.drupal_subpath),
				'sql-dump',
				'--result-file=' + dump_file
			], True):

				self.notice("Database dump taken")

			else:

				self.warning("No database dump taken")

		name = datetime.datetime.now()
		name = name.isoformat()

		backup_file = self.old_build_dir + "/" + name + ".tgz"

		if 'ignore' in params:
			self._build_exclude_files = params['ignore']
		else:
			self._build_exclude_files = {}

		tar = tarfile.open(backup_file, "w:gz", dereference=True)
		tar.add(self.final_build_dir, arcname=self.final_build_dir_name, exclude=self._backup_exlude)
		tar.close()


	# Wipe existing final build
	def _wipe(self):
		if self._drush([
			'--root=' + format(self.final_build_dir + self.drupal_subpath),
			'sql-drop',
			'--y'
		], True):
			self.notice("Tables dropped")
		else:
			self.notice("No tables dropped")
		if os.path.isdir(self.final_build_dir):
 			self._unlink()
 			self._ensure_writable(self.final_build_dir)
 			os.rename(self.final_build_dir, self.final_build_dir_bak)
 		if os.path.isdir(self.final_build_dir_bak):
 			shutil.rmtree(self.final_build_dir_bak, True)

	# Ensure we have write access to the given dir
	def _ensure_writable(self, path):
		for root, dirs, files in os.walk(path):
			for momo in dirs:
				file = os.path.join(root, momo)
				mode = os.stat(file).st_mode
				os.chmod(file, mode|stat.S_IWRITE)
			for momo in files:
				file = os.path.join(root, momo)
				mode = os.stat(file).st_mode
				os.chmod(file, mode|stat.S_IWRITE)

	def _ensure_container(self, filepath):
		# Ensure target directory exists
		target_container = os.path.dirname(filepath)
		if not os.path.exists(target_container):
			self.notice("Created directory " + target_container)
			os.makedirs(target_container)

	# Symlink file from source to target
	def _link_files(self, source, target):
		self._ensure_container(target)
		if os.path.exists(source) and not os.path.exists(target):
			source = os.path.relpath(source, os.path.dirname(target))
			os.symlink(source, target)
		else:
			raise BuildError("Can't link " + source + " to " + target + ". Make sure that the source exists.")

	# Unlink file from target
	def _unlink_files(self, target):
		self._ensure_container(target)
		if os.path.exists(target):
			os.unlink(target)


	# Copy file from source to target
	def _copy_files(self, source, target):
		self._ensure_container(target)
		if os.path.exists(source) and not os.path.exists(target):
			if os.path.isdir(source):
				shutil.copytree(source, target)
			else:
				shutil.copyfile(source, target)
		else:
			raise BuildError("Can't copy " + source + " to " + target + ". Make sure that the source exists.")


# Print help function
def help():
	print 'build.sh [options] [command] [site]'
	print '[command] is one of the commands defined in the configuration file'
	print '[site] defines the site to build, defaults to default'
	print 'Options:'
	print ' -h --help'
	print '			Print this help'
	print ' -c --config'
	print '			Configuration file to use, defaults to conf/site.yml'
	print ' -o --commands'
	print '			Configuration file to use, defaults to conf/commands.yml'
	print ' -s --skip-backup'
	print '			Do not take backups, ever'
	print ' -d --disable-cache'
	print '			Do not use caches'
	print ' -v --version'
	print '			Print version information'


# Print version function.
def version():
	print build_sh_version_string

# Program main:
def main(argv):

	# Default configuration file to use:
	config_file = 'conf/site.yml'
	commands_file = 'conf/commands.yml'
	do_build = True

	# Parse options:
	try:
		opts, args = getopt.getopt(argv, "hdc:o:vst", ["help", "config=", "commands=", "version", "test", "skip-backup", "disable-cache"])
	except getopt.GetoptError:
		help()
		return

	for opt, arg in opts:
		if opt in ('-h', "--help"):
			help()
			return
		elif opt in ("-c", "--config"):
			config_file = arg
		elif opt in ("-o", "--commands"):
			commands_file = arg
		elif opt in ("-s", "--skip-backup"):
			global build_sh_skip_backup
			build_sh_skip_backup = True
		elif opt in ("-d", "--disable-cache"):
			global build_sh_disable_cache
			build_sh_disable_cache = True
		elif opt in ("-v", "--version"):
			version()
			return

	try:

		# Get the settings file YAML contents.
		f = open(config_file)
		settings = yaml.safe_load(f)
		f.close()

		try:
			command = args[0]
		except IndexError:
			help()
			return

		# Default site is "default"
		site = 'default'
		try:
			site = args[1]
		except IndexError:
			if 'WKV_SITE_ENV' in os.environ:
				site = os.environ['WKV_SITE_ENV']
			else:
				site = 'default'

		sites = []
		sites.append(site)

		for site in sites:

			# Copy defaults.
			site_settings = settings["default"].copy()

			if not site in settings:
				new_site = False
				for site_name in settings:
					if 'aliases' in settings[site_name]:
						if isinstance(settings[site_name]['aliases'], basestring):
							site_aliases = [ settings[site_name]['aliases'] ]
						else:
							site_aliases = settings[site_name]['aliases']
						if site in site_aliases:
							new_site = site_name
							break
				if not new_site:
					raise BuildError("The site " + site + " is not defined")
				site = new_site

			# If not the default site, update it with defaults.
			if site != "default":
				site_settings.update(settings[site])

			# Create the site maker based on the settings
			maker = Maker(site_settings)

			maker.notice("Using configuration " + site)

			commands = {}

			if 'commands' in settings:
				commands = settings['commands']
				maker.warning("There are commands defined in site.yml - please move them to commands.yml.")

			# Read in the commands file
			if os.path.isfile(commands_file):
				if 'commands' in settings:
					maker.warning("Commands defined in commands.yml override the commands defined in site.yml")
				f = open(commands_file)
				commands = yaml.safe_load(f)
				f.close()

			commands['test'] = {"test": "test"}

			# Add and overwrite commands with local_commands
			if 'local_commands' in settings[site]:
				commands.update(settings[site]['local_commands'])

			if do_build:
				# Execute the command(s).
				if command in commands:
					command_set = commands[command]
					for step in command_set:
						maker.execute(step)
				else:
					maker.notice("No such command defined as '" + command + "'")


	except Exception, errtxt:
		print "\033[91m** BUILD ERROR: \033[0m%s" % (errtxt)
		exit(1)

# Entry point.
if __name__ == "__main__":
	main(sys.argv[1:])
