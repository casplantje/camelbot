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

my $loopTimeOut = 1000; # Todo: find a proper loop timeout that fits irc response times
my $timeOutSeconds = 120;
my $timeOutThreshold = 0.25;	# Threshold where to start pinging

# my $debug = *STDOUT;
open (my $debug, ">", "/dev/null")
	or die "Cannot open debug sink!\n";

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
	# todo: move all settings to xml file
	# todo: add possibility for ssl
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
	# Todo: break out(last) when the connection is lost
	my $timeOutCounterReset = $timeOutSeconds/($loopTimeOut/1000000);
	my $timeOutCounter = $timeOutCounterReset;
	print "TimeoutCounter: $timeOutCounter\n";
	while ($timeOutCounter > 0) {
		$sockSemaphore->down();
		print $debug "downed semaphore in readText\n";
		my $input;
		print $debug "start can_read\n";
		my @ready = $sockSelect->can_read(0);
		if ($#ready >= 0)
		{
			print $debug "start read\n";
			$sock->recv($input, 1024);
			print $debug "end read\n";
			print $debug "end can_read\n";

			chop $input;
			if ($input)
			{
				if ($input =~ /^PING(.*)$/i) {
					# We must respond to PINGs to avoid being disconnected.
					print $sock "PONG $1\r\n";
					print "PONG\n";
				}
				elsif ($input =~ /^PONG(.*)$/i) {
					print "Received Pong!\n";
					$timeOutCounter = $timeOutCounterReset;
				}
				else {
					handleMessage($input);
				}
			}
		}
		
		# Ping counter
		$timeOutCounter--;
		if ($timeOutCounter == ($timeOutThreshold * $timeOutCounterReset))
		{
			print "pinging...\n";
			print $sock "PING\r\n";
		}
		
		$sockSemaphore->up();
		usleep($loopTimeOut);
		print $debug "upped semaphore in readText\n";
		
	}
	
	# Connection lost; close connection and call connect function again.
	print "Connection lost, trying to reconnect...\n";
	if ($sock)
	{
		close ($sock);
	}
	connection::irc::connect();
}

# Central function to call whenever a message is received
# This function is also supposed to be used as fallback in other
# functions that read from the socket
sub handleMessage
{
		my ($message) = @_;
		# This will be replaced by a function in the core
		# handling input
		# Todo: parse a line to a hash
		# Todo2: Make a struct to parse the line into
		# Todo3: Move the actual handling outside the semaphore
		#		locks
		print "$message\n";	
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

sub sendCommand
{
	my ($text) = @_;
	print $debug "Going to send...\n";
	$sockSemaphore->down();
	print $debug "Socket rights acquired\n";
	# will send a message to irc
		print "$text";
	print $sock "$text\r\n";
	$sockSemaphore->up();	
}

1;
