package connection::credentials;
use strict;
use XML::LibXML '1.70';
use Switch;

# reads all credentials for irc
# global variables for settings
our $server;
our $port;
our $nick;
our $login;
our $channel;
our $ssl;
our $nickservlogin;

my $parser = XML::LibXML->new();
my $settings = $parser->parse_file("credentials.xml");

for my $property ($settings->findnodes('/ircsettings/*')) {
	switch ($property->nodeName())
			{
				case "server" { $server = $property->textContent(); }
				case "port" { $port = $property->textContent(); }
				case "nick" { $nick = $property->textContent(); }
				case "login" { $login = $property->textContent(); }
				case "nickservlogin" { $nickservlogin = $property->textContent(); }
				case "channel" { $channel = $property->textContent(); }
				case "ssl" { $ssl = $property->textContent(); }
			}
}

1;
