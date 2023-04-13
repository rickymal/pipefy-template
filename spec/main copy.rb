# spec/activity/container_test.rb

require "minitest/autorun"
require 'pry'
require 'minitest/reporters'
require_relative '../lib/lib.rb'
require 'async'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class SayHelloWorld 
  def call 
    return 'Hello, world!'
  end
end

class Extract
  def call
    3.times do |yld|
      yield yld
    end
  end
end

class Transform
  def call(data)
    return "#{data}s"
  end
end

class Load
  def call(data)
    pp "resultado final: #{data}"
  end
end


Async do 
  describe "testando o miniteste" do  
    it "verificando se simplesmente funciona" do 
    end
  end

  describe "testes básicos em ambientes diferente" do
    it "Devo conseguir fazer o 'hello world' apenas com método 'flow' (task)" do 

      lotus = Lotus::Activity::Container.new()
      lotus.name = 'hello world'
      lotus.pipe SayHelloWorld, Lotus::Method::Flow, {}

      app = lotus.compile
      counter = nil
      resp = app.run() do |it|
        counter = it 
      end 

      # Este await irá segurar até que todos os queues estejam vazios, quanto um 'nil' é enviado
      resp.await()
      assert_equal counter, "Hello, world!"
    end

    it "Conseguir criar um sistema ETL simples" do
      
      lotus = Lotus::Activity::Container.new()
      lotus.name = 'ETL'
      
      lotus.pipe Extract, Lotus::Method::Stream, {}
      lotus.pipe Tranform, Lotus::Method::Actor, {}
      lotus.pipe Load, Lotus::Method::Flow, {}

      app = lotus.compile
      counter = []
      resp = app.run do |it|
        counter << it
      end
      resp.await()

      assert_equal container, [
        "resultado final: 1s",
        "resultado final: 2s",
        "resultado final: 3s",
      ]

    end
  end

  describe "testes básicos com serviços" do 
    class BaseService
      attr_reader :x

      def on_load(pipe)
        @x = 100
      end

    end

    class LoadWithService
      def call(data)
        return "resultado final: #{data} + #{self.base_service.x}"
      end
    end
    it "ser capaz de carregar um serviço simples e usa uma variável dele" do
            
      lotus = Lotus::Activity::Container.new()
      lotus.name = 'Base + service'
      
      lotus.pipe Extract, Lotus::Method::Stream, {}
      lotus.pipe Tranform, Lotus::Method::Actor, {}
      lotus.pipe LoadWithService, Lotus::Method::Flow, {base_service: BaseService.new()}


      app = lotus.compile
      counter = []
      resp = app.run do |it|
        counter << it
      end
      resp.await()

      assert_equal container, [
        "resultado final: 1s",
        "resultado final: 2s",
        "resultado final: 3s",
      ]

    end

    class Scheduler
      def on_load(container)
      end
    end

    it "Criando um serviço que puxa outro serviço (scheduler)" do  
      scheduler = Scheduler.new()
      lotus = Lotus::Activity::Container.new({scheduler:})

      scheduler.sched every: 1.day, gte: 23.hour, lte: 7.hour
      

      lotus.name = 'scheduler'

      lotus.pipe SayHelloWorld, Lotus::Method::Flow
    end

    it "Criando um serviço que chama um método do pipe em que foi injetado" do 
      class PrintPipeData < Lotus::Acitivity::Service
        def on_load(pipe)
          @pipe = pipe 
        end

        def print()
          # E se o serviço injetado estiver dentro de um ator, como poderei chama-lo?
          # Simples, não haverá mais Lotus::Methods, eles serão integrados ao pipe
          # a pergunta é, eu faço com que seja um método chamado call que trabalhe?
          # ou personalizo?
          pp "pipe: #{@pipe.content}"
        end
      end

      class SaveSomething < Lotus::Activity::Pipe 
        attr_reader :content
        include Lotus::Method::Flow

        def call(data)
          @content = data
        end
      end

      print_pipe_data = PrintPipeData.new()
      lotus = Lotus::Activity::Container.new()
      lotus.name = 'callback'

      # Cada objeto em questão é uma atividade em potencial, porém também é um serviço
      print_pipe_data = PrintPipeData.new
      lotus.pipe SaveSomething, print_pipe_data

      app = lotus.compile()
      app.run(100)
      sleep 1
      assert_equal print_pipe_data.print(), 100
      app.await()


    

    end


    # n1n é um serviço para gerenciar a execução de processos 
    # Permite observar e chamar métodos internos de um pipe
    it "Fazendo uma inversão de controle com o serviço (n1n)" do 
      class RaiseError
        def call()
          puts "Working!!!"
          sleep 5
          puts "OOps"
          raise Exception, "simulating an error"
        end
      end

      module N1N
        class Client < Lotus::Activity::Service
        end
      end

      n9n = N1N::Client.new()
      lotus = Lotus::Activity::Container.new(n9n, policy: "no-rules")
      lotus.name = 'n9n'
      lotus.pipe RaiseError
      
      task = n9n.start('n9n')
      assert_equal task.status, 'initialized'
      n9n.call()
      assert_equal task.status, 'running'
      sleep 7
      assert_equal task.status, 'failed'
      assert_equal task.error.type, Exception
      assert_equal task.error.message, "simulating an error"

      task = n9n.start('n9n')
      assert_equal task.status, 'initialized'
      n9n.call()
      assert_equal task.status, 'running'
      n9n.kill('n9n')
      assert_equal task.status, 'killed'

    end

    it 'deve ser capaz de cirar um objeto remoto para ser acessado, uma classe movida para um ractor' do 
    end
  end

end