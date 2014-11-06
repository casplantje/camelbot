package connection::credentials;
use strict;
use XML::LibXML::Simple   qw(XMLin);
use Switch;
use Data::Dumper;

# reads all credentials for irc
my $ircsettings = XMLin("credentials.xml");

sub ircSetting
{
	my ($setting) = @_;
	
	# check whether the call is from connection::irc
	my ($package) = caller;
	if ($package == "connection::irc")
	{
		return ($ircsettings)[0]{$setting};
	} else
	{
		die "Settings not retrieved by connection::irc!";
	}
}

1;
