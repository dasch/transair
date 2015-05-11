require 'yaml'
require 'digest/sha1'
require 'logger'
require 'json'
require 'time'
require 'excon'

require 'transair/translation_downloader'

module Transair
  class Client
    SYNC_CHUNK_SIZE = 85

    def self.build(url:)
      logger = Logger.new($stderr)
      logger.formatter = proc {|severity, datetime, progname, msg| msg + "\n" }

      new(
        master_path: "masters.yml",
        translations_path: "translations",
        url: url,
        logger: logger
      )
    end

    def initialize(master_path:, translations_path:, url:, logger: Logger.new($stderr))
      @master_file_path = master_path
      @translations_path = translations_path
      @connection = Excon.new(url, persistent: true)
      @logger = logger
      @locales = Hash.new {|h, k| h[k] = {} }
      @upload_queue = Queue.new
      @timestamp_file_path = File.join(translations_path, ".timestamps.yml")
      @timestamps = load_timestamps(@timestamp_file_path)
    end

    def sync!
      queue = Queue.new

      master_strings.each_slice(SYNC_CHUNK_SIZE) do |slice|
        queue << slice
      end

      downloaders = 4.times.map do
        queue << nil
        TranslationDownloader.new(
          queue: queue,
          connection: @connection,
          upload_queue: @upload_queue,
          logger: @logger,
          locales: @locales,
          timestamps: @timestamps
        )
      end

      downloaders.each(&:start!)
      downloaders.each(&:wait)

      upload_missing_strings!

      FileUtils.mkdir_p(@translations_path)

      @locales.each do |locale, translations|
        save_translations(locale, translations)
      end

      File.open(@timestamp_file_path, "w") do |f|
        f << YAML.dump(@timestamps)
      end
    end

    private

    def load_timestamps(path)
      if File.exist?(path)
        YAML.load_file(path)
      else
        Hash.new
      end
    end

    def upload_missing_strings!
      until @upload_queue.empty?
        strings = @upload_queue.deq
        next if strings.empty?

        requests = strings.map do |(key, master)|
          version = version_for(master)
          path = "/strings/#{key}/#{version}"

          { path: path, method: :put, body: master }
        end

        responses = @connection.requests(requests)

        responses.zip(strings).each do |response, (key, master)|
          if response.status == 200
            @logger.info "Uploaded key #{key}"
          else
            @logger.warn "Failed to upload key #{key} -- response status: #{response.status}"
          end
        end
      end
    end

    def master_strings
      @master_strings ||= load_master_strings
    end

    def load_master_strings
      YAML.load_file(@master_file_path)
    end

    def save_translations(locale, translations)
      file_path = File.join(@translations_path, "#{locale}.yml")

      if File.exist?(file_path)
        existing_translations = YAML.load_file(file_path)
      else
        existing_translations = Hash.new
      end

      translations.each do |key, value|
        existing_translations[key] = value
      end

      File.open(file_path, "w") do |file|
        file << YAML.dump(existing_translations)
      end
    end

    def version_for(master)
      Digest::SHA1.hexdigest(master)[0, 12]
    end
  end
end
