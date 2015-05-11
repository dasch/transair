require 'sinatra/base'
require 'json'
require 'sinatra/json'

require 'transair/string_repository'
require 'transair/translation_repository'
require 'transair/last_modification_repository'

module Transair
  class App < Sinatra::Base
    configure do
      enable :logging

      set :string_repo, Transair::StringRepository.new
      set :translation_repo, Transair::TranslationRepository.new
      set :last_modification_repo, Transair::LastModificationRepository.new
    end

    def self.clear
      settings.string_repo.clear
      settings.translation_repo.clear
      settings.last_modification_repo.clear
    end

    get '/strings/:key/:version' do
      key, version = params.values_at(:key, :version)

      master = settings.string_repo.find(key: key, version: version)

      if master
        master
      else
        status 404
      end
    end

    put '/strings/:key/:version' do
      key, version = params.values_at(:key, :version)
      master = request.body.read

      begin
        settings.string_repo.add(key: key, master: master, version: version)
        settings.last_modification_repo.update(key: key, version: version)
        master
      rescue StringRepository::InvalidVersion
        status 400
      end
    end

    get '/strings/:key' do
      versions = settings.string_repo.find_all(key: params[:key])
      json(versions)
    end

    get '/strings/:key/:version/translations' do
      key, version = params.values_at(:key, :version)

      unless settings.string_repo.exist?(key: key, version: version)
        halt 404
      end

      last_modified settings.last_modification_repo.find(key: key, version: version)

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

      settings.last_modification_repo.update(key: key, version: version)
    end
  end
end
