class RequestDispatching
	def call(method, request, headers, query)
		if self.respond_to? method
			self.send(method, request, headers, query)
		else
			self.default_request(method, request, headers, query)
		end
	end
end

class Test < RequestDispatching
	def default_request(method, request, headers, query)
		Protocol::HTTP::Response[200, {}, ["Hello World"]]
	end
end