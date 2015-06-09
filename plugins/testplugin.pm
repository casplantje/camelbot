package plugins::testplugin;

use core::pluginmanager;
use strict; use warnings;
use connection::chatconnection;

#** @var private %regex1 Regex handler 1
# @brief Simple hashlist containing the information for handling a regex event.
#*
my %regex1 = (
	name => "RegexHandler1",
	regex => "![bB]otface.*",
	handler => \&regexAction1,
	cooldown => 10
);

#** @method public regexAction1 (%message, @regexMatches)
# @brief Regex event handler
#
# @param message A message hashlist as defined in irc.pm
# @param regexMatches an array of all regex matches
#*
sub regexAction1
{
	my ($message, @regexMatches) = @_;
	print "regexAction1 match!\n";
	connection::chatconnection::sendMessage("What issit, mate?");
}

#** @var private %regex2 Regex handler 2
# @brief Simple hashlist containing the information for handling a regex event.
#*
my %regex2 = (
	name => "RegexHandler2",
	regex => "!salty\ (.*)",
	handler => \&regexAction2
);

#** @method public regexAction2 (%message, @regexMatches)
# @brief Alternative regex event handler
#
# @param message A message hashlist as defined in irc.pm
# @param regexMatches an array of all regex matches
#*
sub regexAction2
{
	my $message = shift;
	my $regexMatches = shift;
	my $name = $$regexMatches[0];
	$name =~ s/^\s+|\s+$//g; # Regex matches can contain rather strange whitespaces. Don't know why
	
	print "\nEnjoy your complementary salt, " . $name . " PJSalt\n";
	connection::chatconnection::sendMessage("Enjoy your complementary salt, " . $name . " PJSalt");
}

#** @var private %regex2 Regex handler 2
# @brief Simple hashlist containing the information for handling a regex event.
#*
my %regexPyramid = (
	name => "RegexPyramidHandler",
	regex => "!pyramid\ (.*)",
	handler => \&regexPyramidAction,
	cooldown => 60
);


#** @method public regexPyramid (%message, @regexMatches)
# @brief Pyramid function
#
# @param message A message hashlist as defined in irc.pm
# @param regexMatches an array of all regex matches
#*
sub regexPyramidAction
{
	my $message = shift;
	my $regexMatches = shift;
	my $element = $$regexMatches[0];
	$element =~ s/^\s+|\s+$//g; # Regex matches can contain rather strange whitespaces. Don't know why
	
	connection::chatconnection::sendMessage("$element");
	connection::chatconnection::sendMessage("$element $element");
	connection::chatconnection::sendMessage("$element $element $element");
	connection::chatconnection::sendMessage("$element $element");
	connection::chatconnection::sendMessage("$element");
}

#** @var private %poll1 Poll handler 1
# @brief Simple hashlist containing the information for handling a poll event.
# interval = 1 second
#*
my %poll1 = (
	name => "PollHandler1",
	interval => 1,
	handler => \&pollAction1
);

#** @method public pollAction1 ()
# @brief Poll event handler
#*
sub pollAction1
{
	#print "Polling something...\n";
}

#** @method public loadPlugin ()
# @brief function called when the plugin is loaded
#*
sub loadPlugin
{
	core::pluginmanager::registerRegex(\%regex1);
	core::pluginmanager::registerRegex(\%regex2);
	core::pluginmanager::registerRegex(\%regexPyramid);
	core::pluginmanager::registerPoll(\%poll1);
	print "Loaded testplugin!\n";
}

#** @method public unloadPlugin ()
# @brief function called when the plugin is unloaded
#*
sub unloadPlugin
{
	core::pluginmanager::unregisterRegex(\%regex1);
	core::pluginmanager::unregisterRegex(\%regex2);
	core::pluginmanager::unregisterRegex(\%regexPyramid);
	core::pluginmanager::unregisterPoll(\%poll1);
	print "Unloaded testplugin!\n";
}

print "Loaded testplugin module!\n";
1;
