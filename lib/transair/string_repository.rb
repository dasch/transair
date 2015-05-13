require 'digest/sha1'

module Transair
  class StringRepository
    InvalidVersion = Class.new(StandardError)

    def initialize
      clear
    end

    def find(key:, version:)
      @masters[key][version]
    end

    def all
      @masters
    end

    def find_all(key:)
      @masters[key]
    end

    def exist?(key:, version:)
      !find(key: key, version: version).nil?
    end

    def add(key:, master:, version: nil)
      version ||= version_for(master)

      if version != version_for(master)
        raise InvalidVersion, "invalid string version"
      end

      @masters[key][version] = master
    end

    def clear
      @masters = Hash.new {|h, k| h[k] = {} }
    end

    private
    
    def version_for(master)
      Digest::SHA1.hexdigest(master)[0, 12]
    end
  end
end
