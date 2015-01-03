package plugins::testplugin;

use Data::Dumper;
use core::pluginmanager;
use strict; use warnings;
use connection::chatconnection;

# Regex handler 1
my %regex1 = (
	name => "RegexHandler1",
	regex => ".*[bB]otface.*",
	handler => \&regexAction1
);

sub regexAction1
{
	my ($message, @regexMatches) = @_;
	print "regexAction1 match!\n";
	connection::chatconnection::sendMessage("What issit, mate?");
}

# Regex handler 2
my %regex2 = (
	name => "RegexHandler2",
	regex => "!salty\ (.*)",
	handler => \&regexAction2
);

sub regexAction2
{
	my $message = shift;
	my $regexMatches = shift;
	my $name = $$regexMatches[0];
	$name =~ s/^\s+|\s+$//g; # Regex matches can contain rather strange whitespaces. Don't know why
	
	print "\nEnjoy your complementary salt, " . $name . " PJSalt\n";
	connection::chatconnection::sendMessage("Enjoy your complementary salt, " . $name . " PJSalt");
}

# Poll handler 1
my %poll1 = (
	name => "PollHandler2",
	interval => 1,
	handler => \&pollAction1
);

sub pollAction1
{
	#print "Polling something...\n";
}

sub loadPlugin
{
	core::pluginmanager::registerRegex(\%regex1);
	core::pluginmanager::registerRegex(\%regex2);
	core::pluginmanager::registerPoll(\%poll1);
	print "Loaded testplugin!\n";
}

sub unloadPlugin
{
	core::pluginmanager::unregisterRegex(\%regex1);
	core::pluginmanager::unregisterRegex(\%regex2);
	core::pluginmanager::unregisterPoll(\%poll1);
	print "Unloaded testplugin!\n";
}

print "Loaded testplugin module!\n";
1;
