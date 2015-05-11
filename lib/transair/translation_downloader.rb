module Transair
  class TranslationDownloader
    def initialize(queue:, connection:, upload_queue:, logger:, timestamps:, locales:)
      @queue, @connection = queue, connection
      @logger = logger
      @upload_queue = upload_queue
      @timestamps = timestamps
      @locales = locales
    end

    def start!
      @thread = Thread.new do
        while slice = @queue.deq
          download!(slice)
        end
      end
    end

    def wait
      @thread.join
    end

    private

    def download!(strings)
      requests = strings.map do |key, master|
        @logger.info "Syncing key #{key}..."

        version = version_for(master)
        path = "/strings/#{key}/#{version}/translations"
        headers = {}

        if last_modified = get_last_modification(key)
          headers["If-Modified-Since"] = last_modified.httpdate
        end

        {
          method: :get,
          path: path,
          headers: headers
        }
      end

      missing_strings = []
      responses = @connection.requests(requests)

      responses.zip(strings).each do |response, (key, master)|
        if response.status == 404
          @logger.info "Key #{key} not found, uploading..."
          missing_strings << [key, master]
        elsif response.status == 304
          @logger.info "Key #{key} still fresh."
        elsif response.status == 200
          translations = JSON.parse(response.body)

          @logger.info "Key #{key} found, storing #{translations.size} translations..."

          translations.each do |locale, translation|
            @locales[locale][key] = translation
          end

          update_last_modification(key, response.headers["Last-Modified"])
        else
          @logger.warn "Failed to download translations for key #{key} -- " \
            "response status #{response.status}"
        end
      end

      @upload_queue.enq(missing_strings)
      @connection.reset
    end

    def version_for(master)
      Digest::SHA1.hexdigest(master)[0, 12]
    end

    def get_last_modification(key)
      @timestamps[key]
    end

    def update_last_modification(key, timestamp)
      @timestamps[key] = Time.httpdate(timestamp) if timestamp
    end
  end
end
