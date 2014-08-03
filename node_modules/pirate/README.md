# Argh! What's This?

Pirate provides a simple key-value storage interface with adapters for different storage systems. Pirate currently supports MongoDB, Elasticsearch, Redis and in-memory storage.

## Benefits

The benefits of this approach are:

* **Simplify your code.** The Pareto Principle often applies to storage systems, where you only need 20% of the features 80% of the time. Pirate optimizes that 80% while still allowing you to extend adapters to handle the other 20%, specific to your requirements.

* **Eliminate the impedance mismatch between HTTP and storage.** Pirate follows a similar interface to that supported by HTTP: `get`, `put`, `patch`, and `delete`. There's no equivalent to `post` and there are a few additional  methods, but semantically, they're very close.

* **Easily switch between storage implementations.** Pirate's adapters not only hide the complexity of the underlying storage implementation, they make it much easier to change it. You can prototype using an in-memory solution, then use a database and later partition your data across servers.

* **Make use of powerful event-based interfaces.** Node-style callbacks provide a reasonable least-common-denominator, but for more sophisticated applications, they can be tedious. Pirate uses a library called [Mutual][0] to provide a simple event-based interface. Each method returns an `events` object to which event handlers can be attached. Events "bubble up" (think DOM) so that error-handling no longer needs to be done local to the call.

[0]:http://github.com/dyoder/mutual

## Example

Here's a simple program to `put` and `get` and object from MongoDB.

```coffee
{log} = console
{Mongo} = require "pirate"
{EventChannel} = require "mutual"

# Create the top-level events object
events = new EventChannel

# Default error handler just logs the error
events.on "error", (error) -> log error

# Create an adapter, passing in the events object
Mongo.Adapter.make
  events: events
  port: 27018
  host: "127.0.0.1"
  database: "foo"
  options:
    auto_reconnect: true

# When the adapter is ready, we can do stuff
events.on "ready", (adapter) ->

  # First, let's add a second event handler to 
  # close the connection and exit
  events.on "error", ->
    adapter.close
    process.exit -1

  # Okay, let's get the collection we're going to use
  (adapter.collection "bar")

  # Once we have the collection, let's put something
  .on "success", (collection) ->
    (collection.put "baz", baz: "hello")

    # If the put works, try getting the same thing back out
    .on "success", (object) ->
      (collection.get "baz")

      # If the get works, show the result and close the 
      # adapter because we're done!
      .on "success", (object) ->
        log object
        adapter.close()
```

# Adapter API

The elements of the interface are:

* `get key` Returns the object associated with the key or null.

* `put key, object` Overwrites the object associated with `key` with `object`. Returns the updated object.

* `delete key` Deletes the object associated with `key`. Returns nothing.

* `patch key, patch` Updates the object associated with `key` by overlaying `patch`. Returns the updated object.

* `all` Returns all the objects in the collection.

* `count` Returns a count of all the objects in the collection.

All API methods actually return an `EventChannel` object. The `success` event is how a value is ultimately returned, if necessary.



          

