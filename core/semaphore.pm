#** @file semaphore.pm
# @brief Global semaphore for making the threads work together properly.
#
#*
package core::semaphore;

# TODO: test and review the semaphore structure to see whether deadlocks are possible

use Thread::Semaphore;

our $coreSemaphore =  Thread::Semaphore->new();

1;
