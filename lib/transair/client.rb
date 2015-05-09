require 'yaml'
require 'digest/sha1'
require 'logger'
require 'json'
require 'faraday'

module Transair
  class Client
    def self.build(url:, locales:)
      connection = Faraday.new(url: url) do |faraday|
        faraday.adapter :net_http_persistent
      end

      logger = Logger.new($stderr)
      logger.formatter = proc {|severity, datetime, progname, msg| msg + "\n" }

      new(
        master_path: "masters.yml",
        translations_path: "translations",
        locales: locales,
        connection: connection,
        logger: logger
      )
    end

    def initialize(master_path:, translations_path:, locales:, connection:, logger:)
      @master_file_path = master_path
      @translations_path = translations_path
      @connection = connection
      @locales = locales
      @logger = logger
      @translations = {}

      @locales.each do |locale|
        path = File.join(@translations_path, "#{locale}.yml")

        if File.exist?(path)
          @translations[locale] = YAML.load_file(path)
        else
          @translations[locale] = Hash.new
        end
      end
    end

    def sync!
      master_strings.each do |key, master|
        @logger.info "Syncing key #{key}..."
        sync_key(key, master)
      end

      FileUtils.mkdir_p(@translations_path)

      @translations.each do |locale, entries|
        File.open(File.join(@translations_path, "#{locale}.yml"), "w") do |file|
          file << YAML.dump(entries)
        end
      end
    end

    private

    def sync_key(key, master)
      version = Digest::SHA1.hexdigest(master)[0, 12]

      @locales.each do |locale|
        url = "/strings/#{key}/#{version}/translations/#{locale}"
        existing_translation = @translations[locale][key]

        response = @connection.get(url) do |req|
          if existing_translation
            etag = Digest::SHA1.hexdigest(existing_translation)
            req.headers["If-None-Match"] = etag
          end
        end

        if response.status == 404
          @logger.info "Key #{key} not found, uploading..."
          upload_key(key, version, master)
          break
        elsif response.status == 200
          @logger.info "Translation for #{key} found in #{locale}..."

          @translations[locale][key] = response.body
        else
          @logger.warn "Failed to download #{locale} translation for key #{key} -- " \
            "response status #{response.status}"
        end
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
