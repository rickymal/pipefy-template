class MicroServer
	def initialize(endpoint)
		@server = Async::HTTP::Server.new(self, endpoint)
		@objects = Hash.new
	end

	def serve(endpoint, manager = nil, &block)
		@objects[endpoint] = manager || block
	end

	def call(request)
		
		endpoint, raw_query_params = request.path.split("?")
		
		if !raw_query_params.nil? && raw_query_params.include?("\\&")
			raise Exception, "encontrado formato especial de query params!"
		end

		if raw_query_params
			query_params = raw_query_params.split("&").map do |it|
				it.split('=')
			end.to_h
		else
			query_params = nil
		end

		if app = @objects[endpoint]
			return app.call(request.method, request, request.headers, query_params)
		else
			raise Exception, "tentando acessar um endpoint ainda não registrado!"
		end

	end

	def up(task)
		task.async { @server.run }
	end
end