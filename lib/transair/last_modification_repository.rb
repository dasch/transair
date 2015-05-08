module Transair
  class LastModificationRepository
    def initialize
      clear
    end

    def clear
      @timestamps = Hash.new {|h, k| h[k] = {} }
    end

    def find(key:, version:)
      @timestamps[key][version]
    end

    def update(key:, version:)
      @timestamps[key][version] = Time.now
    end
  end
end
