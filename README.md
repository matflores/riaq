# Riaq

Experimental attempt of providing Riak based queues and workers,
heavily inspired by [Ost](https://github.com/soveran/ost).

Due to Riak's distributed capabilities and lack of atomic operations,
as soon as you launch more than one worker there's no guarantee that
each item added to the queue will be processed just once. If you can't
live with this limitation, then this tool is not for you.

## Description

*Riaq* makes it easy to enqueue object ids and process them with
workers.

Say you want to process video uploads. In your application you will
have something like this:

```ruby
Riaq[:videos_to_process].push(@video.id)
```

Then, you will have a worker that will look like this:

```ruby
require "riaq"

Riaq[:videos_to_process].each do |id|
  # Do something with it!
end
```

## Usage

*Riaq* connects to Riak automatically with the default options.

You can customize the connection by calling `connect`.

Then you only need to refer to a queue for it to pop into existence:

```ruby
Riaq[:rss_feeds] << @feed.id
```

A worker is a Ruby file with this basic code:

```ruby
require "riaq"

Riaq[:rss_feeds].each do |id|
  # ...
end
```

It will pop items from the queue as soon as they become available.

Note that in these examples we are pushing numbers to the queue. As
we have unlimited queues, each queue should be specialized and the
workers must be smart enough to know what to do with the numbers they
pop.

### Available methods

`Riaq.connect`: configure the connection to Riak. It accepts
the same options as [the Riak Ruby client](https://github.com/basho/riak-ruby-client).

`Riaq.stop`: halt processing for all queues.

`Riaq[:example].push item`, `Riaq[:some_queue] << item`: add `item` to
the `:example` queue.

`Riaq[:example].each { |item| ... }`: consume `item` from the `:example` queue.

`Riaq[:example].stop`: halt processing for the `example` queue.

## Priorities

There's no concept of priorities, as each queue is specialized and you
can create as many as you want. For example, nothing prevents the
creation of the `:example_high_priority` or the
`:example_low_priority` queues.

## Installation

    $ gem install riaq

## License

Distributed under the terms of the MIT license.
See bundled [LICENSE](https://github.com/matflores/riaq/blob/master/LICENSE)
file for more info.