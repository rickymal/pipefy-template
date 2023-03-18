class Service
    attr_reader :esdev
    attr_reader :esprod
    def on_load()
        @esdev = Client::Elasticsearch.new
    end
end