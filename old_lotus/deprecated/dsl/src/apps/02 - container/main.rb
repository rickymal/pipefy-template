
require 'async'
require 'async/container'
require 'async/io/stream'

# class MessageReceiver
#   def initialize
#     @queue = Async::Queue.new
#   end

#   def call
#     while message = @queue.dequeue
#       puts "Received message: #{message}"
#     end
#   end

#   def receive(message)
#     @queue.enqueue(message)
#   end
# end

# # Create a new controller to manage the processes.
# controller = Async::Container::Controller.new

# # Spawn a process and add it to the controller.
# receiver = controller.add do
#   MessageReceiver.new.call
# end

# # Spawn another process and add it to the controller.
# sender = controller.add do
#   stream = Async::IO::Stream.new(IO.pipe[0])
#   stream = Async::IO::Stream.new(IO.pipe[1])

#   # Send a message to the receiver process.
#   stream.write("Hello from the sender process!")

#   # Close the write end of the pipe.
#   stream.close_write
# end

# # Monitor the receiver process.
# monitor = controller.monitor(receiver)

# # Wait for the receiver process to finish.
# controller.wait(receiver)

# # Remove the receiver process from the controller.
# controller.remove(receiver)

# # Send a message to the receiver process.
# monitor.send(:receive, "Hello from the sender process!")

# # Wait for the message to be received.
# sleep(1)


Console.logger.debug!


# # T1
# require 'async'
# require 'async/container'


# class Controller < Async::Container::Controller
# 	def create_container
# 		Async::Container::Forked.new
# 		# Async::Container::Threaded.new
# 		# Async::Container::Hybrid.new
# 	end
	 
# 	def setup(container)
# 		# container.run count: 10, restart: true do |instance|
# 		# 	while true
# 		# 		Console.logger.debug(instance, "Sleeping...")
# 		# 		sleep(1)
# 		# 	end
# 		# end
# 		container.run count: 1, restart: false do |instance|
#             Console.logger.debug(instance, "Sleeping...")
# 			# while true
# 			# 	sleep(1)
# 			# end
# 		end
# 	end
# end

# Async do 
    
#     controller = Controller.new
#     controller.run
#     sleep 10
#     controller.run
#     sleep 10

# end


# # sleep 60 * 60
# # T2
# Async do 
    
#     id = 0
#     # create new object with idx parameter using async container
#     container = Async::Container::Hybrid.new
    
#     container.spawn name: 'oioioi' do |task|
#         Console.logger.debug task, "Aguardando receber algum dado ... ID #{id}  "
#         sleep(5)
#         # resp = queue.dequeue
#         Console.logger.debug task, "Oooopa!"
#     end
 
#     id = 1
#     container.spawn do |task|
#         Console.logger.debug task, "Aguardando receber algum dado ... ID #{id}  "
#         sleep(5)
#         # resp = queue.dequeue
#         Console.logger.debug task, "Oooopa!"
#     end
    
    
#     id = 2
#     container.spawn do |task|
#         Console.logger.debug task, "Aguardando receber algum dado ... ID #{id}  "
#         sleep(5)
#         # resp = queue.dequeue
#         Console.logger.debug task, "Oooopa!"
#     end

#     sleep 10
#     container.run() do 
#         puts "OOOOOOOOIIIIIII"
#     end
#     sleep 10
#     
 
#     container.wait()
# end

# # T3
# # Async do |it|

# #     ctxi, ctxo = pipe.build_pipeline()
# #     ctxi.enqueue 100
# #     sleep 1
# #     puts ctxo.dequeue
# # end
  

# T4
Async do 
    container = Async::Container.new
    input, output = Async::IO.pipe
    
    container.spawn do |instance|
        stream = Async::IO::Stream.new(input)
        output.close
        
        while message = stream.gets
            puts "Hello World from #{instance}: #{Marshal.load(message)}"
        end
        
        puts "exiting"
    end
    
    stream = Async::IO::Stream.new(output)
    
    5.times do |i|
        stream.puts(Marshal.dump({a: 30}))
    end
    
    stream.close
    
    container.wait
end