module Transair
  class TranslationRepository
    def initialize
      clear
    end

    def find_all(key:, version:)
      @translations[key][version]
    end

    def add(key:, version:, locale:, translation:)
      @translations[key][version][locale] = translation
    end

    def clear
      @translations = Hash.new {|ts, k| ts[k] = Hash.new {|vs, v| vs[v] = {} } }
    end
  end
end
