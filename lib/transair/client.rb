require 'yaml'
require 'digest/sha1'
require 'logger'
require 'json'
require 'faraday'

module Transair
  class Client
    def self.build(url:)
      connection = Faraday.new(url: url) do |faraday|
        faraday.adapter :net_http_persistent
      end

      logger = Logger.new($stderr)
      logger.formatter = proc {|severity, datetime, progname, msg| msg + "\n" }

      new(
        master_path: "masters.yml",
        translations_path: "translations",
        connection: connection,
        logger: logger
      )
    end

    def initialize(master_path:, translations_path:, connection:, logger: Logger.new($stderr))
      @master_file_path = master_path
      @translations_path = translations_path
      @connection = connection
      @logger = logger
      @locales = Hash.new {|h, k| h[k] = {} }
    end

    def sync!
      master_strings.each do |key, master|
        @logger.info "Syncing key #{key}..."
        sync_key(key, master)
      end

      FileUtils.mkdir_p(@translations_path)

      @locales.each do |locale, translations|
        File.open(File.join(@translations_path, "#{locale}.yml"), "w") do |file|
          file << YAML.dump(translations)
        end
      end
    end

    private

    def sync_key(key, master)
      version = Digest::SHA1.hexdigest(master)[0, 12]
      url = "/strings/#{key}/#{version}/translations"

      response = @connection.get(url)

      if response.status == 404
        @logger.info "Key #{key} not found, uploading..."
        upload_key(key, version, master)
      elsif response.status == 200
        translations = JSON.parse(response.body)

        @logger.info "Key #{key} found, storing #{translations.size} translations..."

        translations.each do |locale, translation|
          @locales[locale][key] = translation
        end
      else
        @logger.warn "Failed to download translations for key #{key} -- " \
          "response status #{response.status}"
      end
    end

    def upload_key(key, version, master)
      url = "/strings/#{key}/#{version}"
      response = @connection.put(url, master)

      if response.status == 200
        @logger.info "Uploaded key #{key}"
      else
        @logger.warn "Failed to upload key #{key} -- response status: #{response.status}"
      end
    end

    def master_strings
      @master_strings ||= load_master_strings
    end

    def load_master_strings
      YAML.load_file(@master_file_path)
    end
  end
end
