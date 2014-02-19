require "riak"

module Riaq
  PENDING = 0
  PROCESSING = 1

  class Queue
    attr :bucket

    def initialize(name)
      @bucket = riak.bucket("riaq:#{name}")
    end

    def push(value)
      item = @bucket.new(Time.now.to_f)
      item.content_type = "text/plain"
      item.data = value
      item.indexes = { status_int: PENDING }
      item.store
    end

    def each(&block)
      @stopping = false

      loop do
        break if @stopping

        key = bucket.get_index("status_int", PENDING, max_results: 1).first

        next unless key

        item = @bucket.get(key)
        item.indexes = { status_int: PROCESSING }
        item.store

        block.call(item.data)

        item.delete
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
      Riak::MapReduce.new(riak).index(@bucket.name, "status_int", PENDING).map("Riak.mapValues", keep: true).run
    end

    def size
      bucket.get_index("status_int", PENDING).size
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
