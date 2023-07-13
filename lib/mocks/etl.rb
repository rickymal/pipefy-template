
# Example
module App
	class Extract
		def self.report()
			return {}
		end

		def call(data = nil, task = Async::Task.current)
			delay, times = data.fetch_values('delay', 'times')
			times.times do |yld|
				task.sleep delay
				puts "running #{yld}"
				yield "yld(#{data})"
			end
		rescue Exception => error 
			binding.pry
		end
	end
	
	class Transform
		def self.report()
			return {}
		end

		def call(data = nil)
			return "#{data} - transformed"
		end
	end
	
	class Load
		def self.report()
			return {}
		end

		def call(data = nil)
			puts "Loaded: #{data}"
		end
	end
end

Etl ||= Lotus::Container.new()
Etl.pipefy(App::Extract, Lotus::Method::Stream)
Etl.pipefy(App::Transform, Lotus::Method::Flow)
Etl.pipefy(App::Load, Lotus::Method::Flow)


