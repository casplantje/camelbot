package core::pluginmanager;

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

sub handleMessageRegex
{
	my ($message) = @_;
	print "handling messages\n";
		
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
					$regex->{handler}();
					print "executing handler\n";
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
	# Todo: add regex unloading
	
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
}

print "loaded plugin manager module!\n";

1;
