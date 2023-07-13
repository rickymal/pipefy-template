require './ariel/examples/etl_with_error.rb'
require './ariel/examples/etl.rb'

class App
	def endpoint=(val)
		binding.pry
	end
end

App.new.