require 'sinatra/base'
require 'json'
require 'sinatra/json'

require 'transair/string_repository'
require 'transair/translation_repository'

$string_repo = Transair::StringRepository.new
$translation_repo = Transair::TranslationRepository.new

module Transair
  class App < Sinatra::Base
    get '/strings/:key/:version' do
      key, version = params.values_at(:key, :version)
      string = $string_repo.find(key: key, version: version)

      if string
        json(string)
      else
        status 404
      end
    end

    put '/strings/:key/:version' do
      key, version = params.values_at(:key, :version)
      master = request.body.read
      string = $string_repo.add(key: key, master: master, version: version)

      json(string)
    end

    get '/strings/:key/:version/translations' do
      key, version = params.values_at(:key, :version)

      unless $string_repo.exist?(key: key, version: version)
        halt 404
      end

      translations = $translation_repo.find_all(key: key, version: version)

      json(translations)
    end

    put '/strings/:key/:version/translations/:locale' do
      key, version, locale = params.values_at(:key, :version, :locale)
      translation = request.body.read

      unless $string_repo.exist?(key: key, version: version)
        halt 404
      end

      $translation_repo.add(
        key: key,
        version: version,
        locale: locale,
        translation: translation
      )
    end
  end
end
