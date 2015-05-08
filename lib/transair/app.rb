require 'sinatra/base'
require 'sinatra/json'

$repo = StringRepository.new

module Transair
  class App < Sinatra::Base
    get '/strings/:key/:version' do
      string = $repo.find(key: params[:key], version: params[:version])
    end

    put '/strings/:key/:version' do
    end

    put '/strings/:key/:version/translations/:locale' do
    end
  end
end
