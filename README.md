## Description
ActorKit provides an Objective-C implementation of asynchronous inter-thread message passing.

The purpose of ActorKit is to facilitate the implementation of concurrent software on both the desktop (Mac OS X) and embedded devices (iPhone OS). On the iPhone, thread-based concurrency is a critical tool in achieving high interface responsiveness while implementing long-running and potentially computationally expensive background processing. On Mac OS X, thread-based concurrency opens the door to leveraging the power of increasingly prevalent multi-core desktop computers.

To this end, ActorKit endeavours to provide easily understandable invariants for concurrent software:

- All threads are actors.
- Any actor may create additional actors.
- Any actor may asynchronously deliver a message to another actor.
- An actor may synchronously wait for message delivery from another actor.
- As an actor may only synchronously receive messages, no additional concurrency primitives are required, such as mutexes or condition variables.

Building on this base concurrency model, ActorKit provides facilities for proxying Objective-C method invocations between threads, providing direct, transparent, synchronous and asynchronous execution of Objective-C methods on actor threads.

Plausible ActorKit is provided free of charge under the MIT license, and may be freely integrated with any application.

You may wish to start by reading the more comprehensive [Introduction](http://plactorkit.googlecode.com/svn/tags/plactorkit-1.0/docs/index.html).

# Building
To build an embeddable framework:

`user@max:~/actorkit-trunk> ./bin/release-build.sh -c Release`

This will create a release directory in the current working directory, named 'ActorKit-<date\>-snap'. The release directory contains Mac OS X and iPhone frameworks that may be copied directly to your project (including your iPhone project -- a static framework is used).

