require 'digest/sha1'

module Transair
  class I18nString
    attr_reader :key, :master

    def initialize(key:, master:)
      @key, @master = key, master
    end

    def version
      @version ||= Digest::SHA1.hexdigest(master)[0, 12]
    end

    def serializable_hash
      {
        "key" => key,
        "master" => master,
        "version" => version,
      }
    end

    def to_json(*)
      serializable_hash.to_json
    end
  end

  class StringRepository
    InvalidVersion = Class.new(StandardError)

    def initialize
      clear
    end

    def find(key:, version:)
      master = @masters[key][version]

      if master
        I18nString.new(key: key, master: master)
      else
        nil
      end
    end

    def exist?(key:, version:)
      !find(key: key, version: version).nil?
    end

    def add(key:, master:, version: nil)
      string = I18nString.new(key: key, master: master)

      if version && version != string.version
        raise InvalidVersion, "invalid string version"
      end

      @masters[key][string.version] = master

      string
    end

    def clear
      @masters = Hash.new {|h, k| h[k] = {} }
    end
  end
end
