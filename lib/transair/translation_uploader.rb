require 'transair/enumerated_queue'

module Transair
  class TranslationUploader
    def initialize(queue:, logger:, connection:)
      @queue = queue
      @logger = logger
      @connection = connection
    end

    def upload!
      queue = EnumeratedQueue.new(@queue)

      queue.each_slice(10) do |strings|
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

    private

    def version_for(master)
      Digest::SHA1.hexdigest(master)[0, 12]
    end
  end
end
