require 'transair/app'
require 'rack/test'

describe Transair do
  include Rack::Test::Methods

  def app
    Transair::App
  end

  before do
    app.clear
  end

  it "allows adding new strings" do
    put "/strings/x.y.greeting/0a0a9f2a6772", "Hello, World!"
    expect(last_response.status).to eq 200

    get "/strings/x.y.greeting/0a0a9f2a6772"

    expect(last_response.body).to eq "Hello, World!"
  end

  it "responds with 400 Bad Request if the version is not correct" do
    put "/strings/x.y.greeting/xoxo", "Hello, World!"
    expect(last_response.status).to eq 400
  end

  it "allows adding translations to a string" do
    put "/strings/x.y.greeting/0a0a9f2a6772", "Hello, World!"
    expect(last_response.status).to eq 200

    put "/strings/x.y.greeting/0a0a9f2a6772/translations/fr", "Bonjour, Monde!"
    expect(last_response.status).to eq 200

    get "/strings/x.y.greeting/0a0a9f2a6772/translations"
    translations = JSON.parse(last_response.body)

    expect(translations).to eq("fr" => "Bonjour, Monde!")
  end

  it "returns 404 when getting a non-existent string" do
    get "/strings/x.y.greeting/0a0a9f2a6772"
    expect(last_response.status).to eq 404

    get "/strings/x.y.greeting/0a0a9f2a6772/translations"
    expect(last_response.status).to eq 404
  end
end
