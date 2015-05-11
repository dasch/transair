module Transair
  class EnumeratedQueue
    include Enumerable

    def initialize(queue)
      @queue = queue
    end

    def each
      until @queue.empty?
        value = @queue.deq
        break if value.nil?
        yield value
      end
    end
  end
end
