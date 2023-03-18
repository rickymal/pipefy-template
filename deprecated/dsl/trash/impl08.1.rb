require 'async'
require 'async/queue'

# Objeto que representa uma operação.
# contém a casca (metodo) de execução, e o operator que determina como o método será usado
class PipeOperator
    attr_accessor :method, :operator, :type
    attr_accessor :input, :output

    def initialize(type, method, instance_constructor = nil, template = nil, &blk)
        @method = method
        @operator = blk
        @type = type
        @instance_constructor = instance_constructor
        @template = template

        
        if @template
            @template.instance_exec(@output, &instance_constructor)
        end
    end

    # Vai iniciar a thread para leitura
    def init(it, &blk)
        if !@input.nil?
            it.async do
                while resp = @input.dequeue
                    
                    # verificar o fluxo de pipelines posteriormente
                    puts "RESPONDIDO #{resp}"

                    # Pensar depois o que fazer quando chegar no final
                    if @output.nil?
                        blk.call resp
                        next
                    end

                    # if @operator || block_given?
                    if @operator
                        @operator.call resp, @method, @output, :using
                    end
                end
                
                @operator.call resp, @method, @output, :ending
                @output.enqueue nil
            end
        end
    end

    def call(data)

        @output.enqueue data
    end

    def input_enqueue(queue)
        @input = queue
    end

    def output_enqueue(queue)
        @output = queue
    end
end


# Responsável por definir o fluxo de comportamento entre os operators
class OperatorsArray < Array
    def inject_operators(&callback)
        operators = self
        queues = self.size().times.map do 
            Async::LimitedQueue.new 20
        end

        queues.insert(-1, nil)
    
        operators.zip(queues.each_cons(2)) do |opt, (qinput, qoutput)|
            # Onde os dados serão puxados para serem inseridos no pipeline
            opt.input_enqueue qinput

            # Onde os dados serão registrados para ir para o próximo pipe
            opt.output_enqueue qoutput
        end

        it = Async::Task.current
        operators.each {|ot| ot.init(it, &callback)}

        return queues.first()
    end

    def self.from_array arr
        self.new arr
    end
end

require 'pry'
# Classe que será responsável por buildar um array de pipeoperators
class Template
    
    def initialize(klass_template)
        @pipeline = []
        @template = klass_template
        @instance = klass_template.new()
    end

    def yielded(method)
        
        @pipeline << PipeOperator.new('yielded', @instance.method(method)) do |input, method, queue|
            method.call do |result|
                queue.enqueue result
            end 
        end
    end

    def batch(method)
        @hfb = Array.new()
        @pipeline << PipeOperator.new('yielded', @instance.method(method)) do |input, method, queue, status|
            if status == :ending
                queue.enqueue @hfb
                queue.enqueue nil
                break
            end

            method.call input do |result|
                if @hfb.size() > 3
                    queue.enqueue @hfb.dup()
                    @hfb.clear()
                end
                @hfb << result
            end 
        end
    end

    def flow(method)
        @pipeline << PipeOperator.new('flow', @instance.method(method)) do |input, method, queue|
            queue.enqueue method.call(input) 
        end
    end

    
    def build_pipeline()
        return OperatorsArray.from_array @pipeline
    end
end

# 1. os métodos 'yielded' e 'flow' podem ficar dentro de alguma extenção. não?


# Classe responsável por realizar a construção da classe que deverá ser instanciada.
class Dashboard
    def initialize(klass_or_modules, &blk)
        @klass_or_modules = klass_or_modules
        @blk = blk
    end


    def self.plug(decentralized_implementations)
        klass = Class.new
        klass.include decentralized_implementations[0] 

        @@aggregators = klass 
    end

    def initialize()

        pipebuider = Template.new(@@aggregators)
        draw(pipebuider)
        
        @pipeline = pipebuider.build_pipeline()
        @head = @pipeline.inject_operators do |response|
            binding.pry
        end
    end

    def run(initial_value)
        @head.enqueue initial_value
    end
end



require 'async'

class Promise
  def initialize(async_task)
    @async_task = async_task
  end

  def then(&block)
    Promise.new(Async do |task|
      result = @async_task.wait
      block.call(result)
    end)
  end

  def wait
    @async_task.wait
  end

  def result
    @async_task.result
  end
end

def some_async_operation
  Promise.new(Async do |task|
    # perform some asynchronous operation
    task.sleep(1) # wait for 1 second
    "async operation completed"
  end)
end

promise = some_async_operation
  .then { |result| "The result is: #{result}" }
  .then { |result| puts result }

promise.wait # wait for the promise chain to complete