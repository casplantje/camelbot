package connection::irc;

use strict;
use IO::Socket;

my $server = "irc.twitch.tv";
my $port = 6667;
my $nick = "botface";
my $login = "oauth:n40n3ly8rrnkapa3ofysx9kpd21yk0";
my $channel = "#casplantje";

my $sock;
my $listenEvent;
                                    
print "loaded irc module!\n";

sub connect()
{
	$sock = new IO::Socket::INET->new(PeerAddr => $server,
                                PeerPort => $port,
                                Proto => 'tcp') or
                                    die "Can't connect\n";
                                    
    print $sock "PASS $login\r\nNICK $nick\r\n";

	# Read lines from the server until it tells us we have connected.
	while (my $input = <$sock>) {
		# Check the numerical responses from the server.
		if ($input =~ /004/) {
			# We are now logged in.
			last;
		}
		elsif ($input =~ /433/) {
			die "Nickname is already in use.";
		}
		print "$input\n";
	}
	
	#$listenEvent = 
	
	print $sock "JOIN $channel\r\n";
	print "connected!\n";
}

sub readText()
{
	print "Reading irc chat\n";
	# Keep reading lines from the server.
	while (my $input = <$sock>) {
		chop $input;
		if ($input =~ /^PING(.*)$/i) {
			# We must respond to PINGs to avoid being disconnected.
			print $sock "PONG $1\r\n";
		}
		else {
			# Print the raw line received by the bot.
			print "$input\n";
		}
	}
}

1;
