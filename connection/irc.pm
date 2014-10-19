package connection::irc;

use strict;
use IO::Socket;
use IO::Select;
 use threads ('yield',
'stack_size' => 64*4096,
'exit' => 'threads_only',
'stringify');
use Thread::Semaphore;
use Time::HiRes qw(usleep nanosleep);

my $server = "irc.twitch.tv";
my $port = 6667;
my $nick = "botface";
my $login = "oauth:n40n3ly8rrnkapa3ofysx9kpd21yk0";
my $channel = "#casplantje";
open (my $debug, ">", "/dev/null")
	or die "Cannot open debug sink!\n";
my $loopTimeOut = 1000;
# my $debug = *STDOUT;

# Multithreaded communication stuff
# The sock can accessed by different threads; the receiving thread
# accesses it regularly and the core can call the sending function
# in order to safely send messages through the socket.
my $sock;
my $receiveThread;
my $sockSemaphore =  Thread::Semaphore->new();
my $sockSelect;
                                    
print "loaded irc module!\n";

sub connect
{
	$sock = new IO::Socket::INET->new(PeerAddr => $server,
                                PeerPort => $port,
                                Proto => 'tcp') or
                                    die "Can't connect\n";
                                    
    $sockSelect = new IO::Select ($sock);
                                    
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
	
	
	print $sock "JOIN $channel\r\n";
	print "connected!\n";
	
	# Create thread; from here on the socket is accessed from multiple
	# threads
	$receiveThread = threads->create(\&readText);
}

sub readText
{
	print "Reading irc chat\n";
	# Keep reading lines from the server.
	while (1) {
		$sockSemaphore->down();
		print $debug "downed semaphore in readText\n";
		my $input;
		print $debug "start can_read\n";
		#if ($sockSelect->can_read(10))
		my @ready = $sockSelect->can_read(0);
		my $st;
		foreach $st(@ready)
		{
			print $debug "start read\n";
		#	$input = <$sock>;
		$st->recv($input, 1024);
			print $debug "end read\n";
		}
		print $debug "end can_read\n";

		chop $input;
		if ($input =~ /^PING(.*)$/i) {
			# We must respond to PINGs to avoid being disconnected.
			print $sock "PONG $1\r\n";
			print "PONG\n";
		}
		else {
			# Print the raw line received by the bot.
			if ($input)
			{
				# This will be replaced by a function in the core
				# handling input
				# Todo: parse a line to a struct
				# Todo2: Make a struct to parse the line into
				# Todo3: Move the actual handling outside the semaphore
				#		locks
				print "$input\n";
			}
		}
		
		$sockSemaphore->up();
		usleep($loopTimeOut);
		print $debug "upped semaphore in readText\n";
	}
	# Todo: add handling for lost connections
}

sub sendText
{
	my ($text) = @_;
	print $debug "Going to send...\n";
	$sockSemaphore->down();
	print $debug "Socket rights acquired\n";
	# will send a message to irc
		print "PRIVMSG $channel :$text";
	print $sock "PRIVMSG $channel :$text\r\n";
	$sockSemaphore->up();
}

1;
