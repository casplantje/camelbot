package plugins::testplugin;

use core::pluginmanager;
use strict; use warnings;

sub regexAction1
{
	print "regexAction1 match!\n";
}

sub loadPlugin
{
	my %regex1 = (
		regex => ".*Botface.*",
		handler => \&regexAction1
	);

	core::pluginmanager::registerRegex(\%regex1);
	print "Loaded testplugin!\n";
}

sub unloadPlugin
{
	print "Unloaded testplugin!\n";
}

print "Loaded testplugin module!\n";
1;
