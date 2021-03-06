require 'fakefs/spec_helpers'
require 'yaml'
require 'webmock/rspec'

require 'transair/client'
require 'transair/app'

describe Transair::Client do
  include FakeFS::SpecHelpers

  let(:master_file_path) { "masters.yml" }
  let(:translations_path) { "translations" }
  let(:logger) { Logger.new(StringIO.new) }
  let(:backend) { Transair::App }
  let(:connection) { Excon.new("http://example.com") }

  def client
    Transair::Client.new(
      master_path: master_file_path,
      translations_path: translations_path,
      url: "http://example.com",
      logger: logger
    )
  end

  before do
    stub_request(:any, %r(http://example.com/.*)).to_rack(backend)
    write_master_file Hash.new
    backend.clear
  end

  it "uploads new strings" do
    add_master_string "x.y.greeting", "Hello, World!"

    client.sync!

    response = connection.get(path: "/strings/x.y.greeting/0a0a9f2a6772")
    expect(response.status).to eq 200

    expect(response.body).to eq("Hello, World!")
  end

  it "downloads translations for existing keys" do
    add_master_string "x.y.greeting", "Hello, World!"
    
    client.sync!

    response = connection.put(
      path: "/strings/x.y.greeting/0a0a9f2a6772/translations/fr",
      body: "Bonjour, Monde!"
    )

    expect(response.status).to eq 200

    client.sync!

    expect(translations_for("fr")).to eq(
      "x.y.greeting" => "Bonjour, Monde!"
    )
  end

  it "can re-download translations" do
    add_master_string "x.y.greeting", "Hello, World!"
    
    client.sync!

    response = connection.put(
      path: "/strings/x.y.greeting/0a0a9f2a6772/translations/fr",
      body: "Bonjour, Monde!"
    )

    expect(response.status).to eq 200

    client.sync!
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
