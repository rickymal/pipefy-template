
# Example
module App
	class Extract
		def self.report()
			return {}
		end

		def call(data = nil, task = Async::Task.current)
			10.times do |yld|
				task.sleep data
				yield "yld(#{data})"
			end
		end
	end
	
	class Transform
		def self.report()
			return {}
		end

		def call(data = nil)
			raise Exception, 'disparando um erro qualquer'
			return "#{data} - transformed"
		end
	end
	
	class Load
		def self.report()
			return {}
		end

		def call(data = nil)
			return data
		end
	end
end

Errortl ||= Lotus::Container.new()
Errortl.pipefy(App::Extract, Lotus::Method::Stream)
Errortl.pipefy(App::Transform, Lotus::Method::Flow)
Errortl.pipefy(App::Load, Lotus::Method::Flow)