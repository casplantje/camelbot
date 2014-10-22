package connection::irc;

use strict;
use Switch;
use IO::Socket;
use IO::Select;
use connection::credentials;

 use threads ('yield',
'stack_size' => 64*4096,
'exit' => 'threads_only',
'stringify');
use Thread::Semaphore;
use Time::HiRes qw(usleep nanosleep);

my $loopTimeOut = 1000; # Todo: find a proper loop timeout that fits irc response times
my $timeOutSeconds = 120;
my $timeOutThreshold = 0.05;	# Threshold where to start pinging

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
	# todo: add nickserv support
	
	$sock = new IO::Socket::INET->new(PeerAddr => $connection::credentials::server,
                                PeerPort => $connection::credentials::port,
                                Proto => 'tcp') or
                                    die "Can't connect\n";
                                    
    $sockSelect = new IO::Select ($sock);
                                    
    print $sock "PASS $connection::credentials::login\r\nNICK $connection::credentials::nick\r\n";

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
	
	
	print $sock "JOIN $connection::credentials::channel\r\n";
	print "connected!\n";
	
	# Create thread; from here on the socket is accessed from multiple
	# threads
	$receiveThread = threads->create(\&readText);
}

sub readText
{
	print "Reading irc chat\n";
	# Keep reading lines from the server.
	# Timeout counter; every $timeOutSeconds a ping is done
	# if the pong is not responded within the threshold the connection
	# is deemed broken and it will try to reconnect
	my $timeOutCounterReset = $timeOutSeconds/($loopTimeOut/1000000);
	my $timeOutCounter = $timeOutCounterReset;
	print "TimeoutCounter: $timeOutCounter\n";
	while ($timeOutCounter > (-1 * ($timeOutCounterReset * $timeOutThreshold)))
	{
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
		}
		
		# Ping counter
		$timeOutCounter--;
		if ($timeOutCounter == 0)
		{
			print "pinging...\n";
			print $sock "PING\r\n";
		}
		
		$sockSemaphore->up();
		
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
		if ($message =~ ":(.*)!(.*)@(.*) PRIVMSG (.*) :(.*)")
		{
			#print "Nick: $1 $2 Channel: $4 message: $5\n";
			my %message = (
				type => "message",
				nick => $1,
				fullname => $2,
				hostname => $3,
				target => $4,
				message => $5
			);
		}
		
		if ($message =~ ".*MODE (.*) ([+-])([aiwroOs]) (.*)")
		{
			# First convert the mode code
			# the add/remove sign
			my $change;
			switch ($2)
			{
				case "+" { $change = "add"; }
				case "-" { $change = "remove"; }
				else { last; }
			}
			
			# the privileges; not all of them are necessary for this
			# bot framework for now
			my $privilege;
			switch ($3)
			{
				case "o" { $privilege = "operator"; }
				case "O" { $privilege = "localOperator"; }
				else { last; }
			}
			
			my %message = (
				type => "privilege",
				chat => $1,
				change => $change,
				privilege => $privilege,
				nick => $4,
			);
#			while (my ($k,$v)=each %message){print "$k $v\n"}
		}
		
		# quick and dirty command parsing for testing and fun 
		if ($message =~ ":(.*)!(.*)@(.*) JOIN (.*)")
		{
			print "JOIN: $1\n";
		}
		print "$message\n";	
		if ($message =~ ":casplantje!casplantje.*Botface.*")
		{
			sendText("What issit, mate?");
		}
		if ($message =~ ":casplantje!casplantje(.*)!salty(.*)")
		{
			sendText("Enjoy your complementary salt, $2 PJSalt");
		}
}

sub sendText
{
	my ($text) = @_;
	print $debug "Going to send...\n";
	$sockSemaphore->down();
	print $debug "Socket rights acquired\n";
	# will send a message to irc
		print "PRIVMSG $connection::credentials::channel :$text";
	print $sock "PRIVMSG $connection::credentials::channel :$text\r\n";
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
