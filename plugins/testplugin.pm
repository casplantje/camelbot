package plugins::testplugin;

use strict; use warnings;

sub loadPlugin
{
	print "Loaded testplugin!\n";
}

sub unloadPlugin
{
	print "Unloaded testplugin!\n";
}

sub regexAction1
{
	print "regexAction1 match!\n";
}
print "Loaded testplugin module!\n";
1;
