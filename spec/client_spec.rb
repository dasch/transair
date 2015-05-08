require 'fakefs/spec_helpers'
require 'yaml'
require 'faraday'

require 'transair/client'
require 'transair/app'

describe Transair::Client do
  include FakeFS::SpecHelpers

  let(:master_file_path) { "masters.yml" }
  let(:translations_path) { "translations" }
  let(:logger) { Logger.new(StringIO.new) }
  let(:backend) { Transair::App.new }
  let(:connection) { Faraday.new {|f| f.adapter :rack, backend } }

  let(:client) do
    Transair::Client.new(
      master_path: master_file_path,
      translations_path: translations_path,
      connection: connection,
      logger: logger
    )
  end

  before do
    write_master_file Hash.new
  end

  it "uploads new strings" do
    add_master_string "x.y.greeting", "Hello, World!"

    client.sync!

    response = connection.get("/strings/x.y.greeting/0a0a9f2a6772")
    expect(response.status).to eq 200

    expect(JSON.parse(response.body)).to eq(
      "key" => "x.y.greeting",
      "master" => "Hello, World!",
      "version" => "0a0a9f2a6772"
    )
  end

  it "downloads translations for existing keys" do
    add_master_string "x.y.greeting", "Hello, World!"
    
    client.sync!

    response = connection.put("/strings/x.y.greeting/0a0a9f2a6772/translations/fr", "Bonjour, Monde!")
    expect(response.status).to eq 200

    client.sync!

    expect(translations_for("fr")).to eq(
      "x.y.greeting" => "Bonjour, Monde!"
    )
  end

  def add_master_string(key, master)
    data = YAML.load_file(master_file_path)
    data[key] = master

    write_master_file(data)
  end

  def write_master_file(object)
    File.open(master_file_path, "w") do |file|
      file << YAML.dump(object)
    end
  end

  def translations_for(locale)
    path = File.join(translations_path, "#{locale}.yml")
    YAML.load_file(path)
  end
end
