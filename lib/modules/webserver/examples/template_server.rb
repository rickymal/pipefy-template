require 'async'
require 'async/http/server'
require 'async/http/client'
require 'async/http/endpoint'
require 'async/http/protocol/response'

endpoint = Async::HTTP::Endpoint.parse('http://127.0.0.1:9294')

app = lambda do |request|
	Protocol::HTTP::Response[200, {}, ["Hello World"]]
end

server = Async::HTTP::Server.new(app, endpoint)
client = Async::HTTP::Client.new(endpoint)
	
Async do |task|
	server_task = task.async do
		server.run
	end
	
	response = client.get("/")
	puts response.status
	puts response.read
	server_task.stop
end