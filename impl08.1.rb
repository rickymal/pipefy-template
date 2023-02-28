require 'async'
require 'async/queue'

# Objeto que representa uma operação.
# contém a casca (metodo) de execução, e o operator que determina como o método será usado
class PipeOperator
    attr_accessor :method, :operator, :type
    attr_accessor :input, :output

    def initialize(type, method, &blk)
        @method = method
        @operator = blk
        @type = type
    end

    # Vai iniciar a thread para leitura
    def init(it)
        if !@input.nil?
            it.async do
                while resp = @input.dequeue

                    # verificar o fluxo de pipelines posteriormente
                    puts "RESPONDIDO #{resp}"
                    binding.pry
                    # Pensar depois o que fazer quando chegar no final
                    if @output.nil?
                        binding.pry
                    end
                    @operator.call resp, @method, @output 
                end
            end
        end
    end

    def call(data)
        binding.pry 
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
    def inject_operators()
        operators = self
        queues = (self.size() - 1).times.map do 
            Async::LimitedQueue.new 20
        end

        queues.insert(0, nil)
        queues.insert(-1, nil)

        operators.zip(queues.each_cons(2)) do |opt, (qinput, qoutput)|
  
            # Onde os dados serão puxados para serem inseridos no pipeline
            opt.input_enqueue qinput

            # Onde os dados serão registrados para ir para o próximo pipe
            opt.output_enqueue qoutput
        end


        it = Async::Task.current
        operators.each {|ot| ot.init(it)}
    end

    def self.from_array arr
        self.new arr
    end
end

require 'pry'
# Classe que será responsável por buildar um array de pipeoperators
class Template
    def initialize()
        @pipeline = []
    end

    def yielded(method)

        # O objeto pipeoperator recebe o alias, o método a ser executado e um bloco
        # que determina como esse método será chamado
        # o bloco irá receber três parâmetros:
        # input (informação inputada no método pelo pipeline)
        # method (o method em si para operação)
        # qeueue (uma fila assíncrona para permitir a passagem para o próximo pipe)
        @pipeline << PipeOperator.new('yielded', method) do |input, method, queue|
            method.call do |result|
                queue.enqueue result
            end 
        end
    end

    def flow(method)
        @pipeline << PipeOperator.new('flow', method) do |input, method, queue|
            queue.enqueue method.call(input) 
        end
    end

    def raw(method, &blk)
        @pipeline << PipeOperator.new('raw', method, &blk)
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
        @@aggregators = Class.new.include decentralized_implementations[0] 
    end

    def initialize()
        pipebuider = Template.new()
        draw(pipebuider)
        
        @pipeline = pipebuider.build_pipeline()
        @pipeline.inject_operators
        @head = @pipeline.first()
    end

    def run(initial_value)
        binding.pry
        @head.call initial_value
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