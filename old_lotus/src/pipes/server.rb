
class ServelessAsync
    def initialize()
        @GETS = Hash.new()
        @tokens = {}
    end

    def call(request)
        puts "OOOOPPA"
        binding.pry
       
    end
end
require 'async'
require 'async/http'
require 'pry'
serveless = ServelessAsync.new()
endpoint = Async::HTTP::Endpoint.parse('http://127.0.0.1:3010')
server = Async::HTTP::Server.new(
    serveless, 
    endpoint
)

Async do 
    server.run()
end