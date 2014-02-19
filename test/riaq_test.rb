require "protest"
require_relative "../lib/riaq"

Protest.context "Riaq" do
  setup do
    Riaq[:test].flush
  end

  test "access queued items" do
    push "1"

    assert_equal ["1"], Riaq[:test].items
  end

  test "query the number of queued items" do
    push "1"

    assert_equal 1, Riaq[:test].size
  end

  test "check queue emptiness" do
    assert Riaq[:test].empty?

    push "1"

    assert !Riaq[:test].empty?
  end

  test "process items from the queue in order" do |redis|
    %w(1 2 3).each { |i| push i }

    results = []

    process do |item|
      results << item
    end

    assert Riaq[:test].empty?
    assert_equal ["1", "2", "3"], results
  end

  test "halt processing a queue" do
    Thread.new do
      sleep 0.5
      Riaq[:always_empty].stop
    end

    Riaq[:always_empty].each { }

    assert true
  end

  test "halt processing all queues" do
    Thread.new do
      sleep 0.5
      Riaq.stop
    end

    t1 = Thread.new { Riaq[:always_empty].each { } }
    t2 = Thread.new { Riaq[:always_empty_too].each { } }

    t1.join
    t2.join

    assert true
  end

  def push(id)
    Riaq[:test].push(id)
  end

  def process(&job)
    thread = Thread.new do
      Riaq[:test].each do |item|
        begin
          yield(item)
        ensure
          thread.kill if Riaq[:test].empty?
        end
      end
    end

    thread.join
  end
end
