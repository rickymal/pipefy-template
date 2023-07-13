

module Lotus
	module Job 
		class ActiveJob
			attr_reader :status
			attr_reader :error
		
			def stop()
				@task.stop()
				@scheduled_job.unschedule()
				@status = 'stopped'
				return nil
			end
		
			def run(name)
				
				main = @main
				scheduler = @scheduler
				application = @application
				cron = @cron
				timeout = @timeout
				parameter = @parameter
				queues = application.get_pipeline_queues()
		
				
				queue = Queue.new()
				job_running = false
				@status = 'initializating'
				job_id = scheduler.cron cron do
					if !job_running
						queue << [COMMAND::RUN, parameter]
					end
				end
				@scheduled_job = scheduler.job(job_id)
		
				@task = main.with_timeout(2) do |tsk|
					@status = 'online'
					while resp = queue.pop
						if resp[0] == COMMAND::RUN && !job_running
							@status = 'running'
							job_running = true
		
							# Por alguma razão que ainda preciso investigar
							# está chegando muito 'nil' quando passo a atividade para um processo async-container
							if resp[1].nil?
								next
							end
							application.call resp[1]
		
						elsif resp[0] == COMMAND::STOP
							@status = 'finished'
							break
						end
					end	  
					@status = 'finished'			
				end
			
				@task.wait()

				# @task.sleep timeout
				# @task.stop()
				# @scheduled_job.unschedule()

				has_data_flowing = queues.any? {|it| !it.empty?}
				if has_data_flowing && @status == 'running'
					@status = 'timeout'
				else
					@status = 'finished'
				end
				
				return @status
			rescue Async::TimeoutError => error 
				@status = 'itimeout'
				# nothing
			rescue Async::Stop => error 
				@status = 'stopped'
				# Caso algum sistema externo queira interromper o código, pode deixar
			rescue Exception => error 
				binding.pry
			ensure
				@task&.stop()
				@scheduled_job&.unschedule()
				return @status
			end
		
			def initialize(main, scheduler, application, cron, timeout, parameter, name: "JOB")
				@main = main
				@scheduler = scheduler
				@application = application
				@cron = cron
				@timeout = timeout
				@parameter = parameter
			end
		
			def application()
				return @application
			end
		
			def on_error()
		
			end
		end
	end
end

