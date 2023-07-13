require 'async/queue'
require_relative 'core/utils/promise'
require 'pry'

class Integer
	def hour()
		return self * 60 * 60
	end

	def min()
		return self * 60
	end
end

module Lotus
	class Scheduler
	end
end



module COMMAND
	RUN ||= :_run_lotus_service_ahorad
	STOP ||= :_stop_lotus_service_ahorad
end

END_APP = :_enum_end_app

require 'pry'
require_relative 'core/utils/actor'
require_relative 'core/utils/thread'
require_relative 'core/utils/application'
require_relative 'core/utils/chainable'
require_relative 'core/utils/container'
require_relative 'core/utils/context_mapping'
require_relative 'core/utils/reflections'

require_relative 'core/utils/flow'
require_relative 'core/utils/_pipe.rb'
require_relative 'core/utils/queue_path_builder'
require_relative 'core/utils/stream'
require_relative 'core/utils/task'

require_relative 'core/utils/default_initializer'
require_relative 'core/examples/custom_exception'
require_relative 'core/examples/extract'
require_relative 'core/examples/feedback'
require_relative 'core/examples/hello_world_big_delay_error'
require_relative 'core/examples/hello_world_big_delay'
require_relative 'core/examples/hello_world_service_args'
require_relative 'core/examples/hello_world'
require_relative 'core/examples/load'
require_relative 'core/examples/print_service'
require_relative 'core/examples/transform'