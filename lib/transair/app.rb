require 'sinatra/base'
require 'json'
require 'sinatra/json'

require 'transair/string_repository'
require 'transair/translation_repository'

module Transair
  class App < Sinatra::Base
    configure do
      enable :logging

      set :string_repo, Transair::StringRepository.new
      set :translation_repo, Transair::TranslationRepository.new
    end

    def self.clear
      settings.string_repo.clear
      settings.translation_repo.clear
    end

    get '/strings/:key/:version' do
      key, version = params.values_at(:key, :version)
      string = settings.string_repo.find(key: key, version: version)

      if string
        json(string)
      else
        status 404
      end
    end

    put '/strings/:key/:version' do
      key, version = params.values_at(:key, :version)
      master = request.body.read

      begin
        string = settings.string_repo.add(key: key, master: master, version: version)
        json(string)
      rescue StringRepository::InvalidVersion
        status 400
      end
    end

    get '/strings/:key/:version/translations' do
      key, version = params.values_at(:key, :version)

      unless settings.string_repo.exist?(key: key, version: version)
        halt 404
      end

      translations = settings.translation_repo.find_all(key: key, version: version)

      json(translations)
    end

    put '/strings/:key/:version/translations/:locale' do
      key, version, locale = params.values_at(:key, :version, :locale)
      translation = request.body.read

      unless settings.string_repo.exist?(key: key, version: version)
        halt 404
      end

      settings.translation_repo.add(
        key: key,
        version: version,
        locale: locale,
        translation: translation
      )
    end
  end
end
