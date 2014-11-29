package core::pluginmanager;

# The pluginmanager can load and unload plugins.
# There are "events", like a regex match, which plugins can
# subscribe to so the pluginmanager can call them when necessary.
# Todo: add polling list (with settable time)

use strict; use warnings;
use Module::Load;
use Symbol 'delete_package';

# add include directories
push ( @INC,"../plugins");

my $plugindir = "plugins";
my @plugins;
my @pluginfiles;
my @regexes;

sub registerRegex
{
	my ($regex) = @_;
	push @regexes, $regex;
}

sub unregisterRegex
{
	my ($regex) = @_;
	my $i = 0;
	
	foreach my $currentRegex (@regexes)
	{
		if ($currentRegex == $regex)
		{
			splice @regexes, $i, 1;
		}
		$i++;
	}
}

sub listRegexes
{
	foreach my $regex (@regexes)
	{
		print $regex->{name} . "\n";
	}
}

sub handleMessageRegex
{
	my ($message) = @_;
		
	foreach my $regex (@regexes)
	{
		if (defined($message->{message}))
		{
			my $matchMessage = $message->{message};
			my @regexResults = ( $matchMessage =~ $regex->{regex});
			
			if (@regexResults)
			{
				print "Match: $matchMessage\n";
				if (defined($regex->{handler}))
				{
					print "executing handler\n";
					$regex->{handler}($message, \@regexResults);
				}
			}
		}
	}
}

sub loadPlugins
{
	opendir (DIR, "./$plugindir") or die $!;
	
	while (my $file = readdir(DIR))
	{
		if ($file =~ "(.*)\.pm")
		{
				print "Loading $file\n";
				my $module = "$plugindir::$1";
				my $modulepath = "$plugindir/$1.pm";
				load $module;
				# Call load function
				$module->loadPlugin;
				# add plugin to list
				push @plugins, $module;
				push @pluginfiles, $modulepath;
		}
	}
	
	closedir (DIR) or die $1;
}

sub unloadPlugins
{
	foreach my $module (@plugins)
	{
		$module->unloadPlugin;
		# remove declarations
		delete_package $module;
	}
	foreach my $modulefile (@pluginfiles)
	{
		# unload module file
		delete $INC{$modulefile};
	}
	
	# Check and if necessary empty the regex array
	# This is only to tidy up if plugins don't unregister
	# their regexes properly
	foreach my $regex (@regexes)
	{
		print "Warning! Regex " . $regex->{name} . " wasn't unloaded properly. Check the unloadPlugin of its module!\n";
	}
	@regexes = ();
}

print "loaded plugin manager module!\n";

1;
