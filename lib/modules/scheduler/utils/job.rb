
module Lotus
	module Job 
		class Dag
			attr_writer :name
			attr_writer :cron
			attr_writer :description
			attr_reader :job
			
			def initialize(job, scheduler = Rufus::Scheduler.new(), id = SecureRandom.hex(10), task = Async::Task.current())
				@job  = job 
				@scheduler = scheduler
				@task = task
				@id = id 
				@started_jobs = Array.new()
			end
		
			def describe()
				return {
					id: @id,
					name: @name,
					description: @description,
				}
			end
		
			def scheduled_jobs()
				return @started_jobs
			end
		
			def run(parameter, cron, timeout)
				main = @task
				scheduler = @scheduler
				job = @job.new()
				running_job = Lotus::Job::ActiveJob.new main, scheduler, job, cron, timeout, parameter
				@started_jobs << running_job
				running_job.run("Job<#{SecureRandom.hex(5)}>")
				return running_job
			end
		end
	end
end
