module Transair
  class StringRepository
    def initialize
      @masters = Hash.new {|h, k| h[k] = {} }
      @translations = Hash.new {|ts, k| ts[k] = Hash.new {|vs, v| vs[v] = {} } }
    end

    def find_master(key:, version:)
      @masters[key][version]
    end

    def add_master(key:, version:, value:)
      @masters[key][version] = value
    end

    def add_translation(key:, version:, locale:, value:)
      @translations[key][version][locale] = value
    end
  end
end
