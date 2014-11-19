package core::pluginmanager;

use strict; use warnings;
use Module::Load;

# add include directories
push ( @INC,"../plugins");

my $plugindir = "plugins";

opendir (DIR, "./$plugindir") or die $!;

while (my $file = readdir(DIR))
{
	if ($file =~ "(.*)\.pm")
	{
			print "Loading $file\n";
			my $module = "$plugindir::$1";
			load $module;
			# Call load function
			$module->loadPlugin;
			# todo: register plugin in a list
	}
}

print "loaded plugin manager module!\n";

1;
