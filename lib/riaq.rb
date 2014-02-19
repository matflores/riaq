require "riak"

module Riaq
  class Queue
    attr :bucket

    def initialize(name)
      @bucket = riak.bucket("riaq:#{name}")
    end

    def push(value)
      item = @bucket.new(Time.now.to_f)
      item.content_type = "text/plain"
      item.data = value
      item.store
    end

    def each(&block)
      @stopping = false

      loop do
        break if @stopping

        key = bucket.get_index("$bucket", @bucket.name, max_results: 1).first

        # FIXME cycling when a non-existing key is returned is slow
        #       but 2i index doesn't seem to get immediately updated
        #       when the item gets deleted from the queue.
        next unless key && bucket.exists?(key)

        item = @bucket.get(key).data

        @bucket.delete(key)

        block.call(item)
      end
    end

    def flush
      bucket.get_index("$bucket", @bucket.name).each do |key|
        @bucket.delete(key)
      end
    end

    def stop
      @stopping = true
    end

    def items
      # FIXME items should always be returned in the same order
      Riak::MapReduce.new(riak).index(@bucket.name, "$bucket", @bucket.name).map("Riak.mapValues", keep: true).run
    end

    def size
      # FIXME optimize filter
      bucket.get_index("$bucket", @bucket.name).select { |key| key && bucket.exists?(key) }.size
    end

    def empty?
      size == 0
    end

    alias << push

    def riak
      @riak ||= Riak::Client.new(Riaq.options)
    end
  end

  @queues = Hash.new do |hash, key|
    hash[key] = Queue.new(key)
  end

  def self.[](queue)
    @queues[queue]
  end

  def self.stop
    @queues.each { |_, queue| queue.stop }
  end

  @options = nil

  def self.connect(options = {})
    @options = options
  end

  def self.options
    @options || {}
  end
end
