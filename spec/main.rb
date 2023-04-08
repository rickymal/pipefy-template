# spec/activity/container_test.rb

require "minitest/autorun"
require 'pry'
require 'minitest/reporters'
require_relative '../lib/lib.rb'
require 'async'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new


Async do 


  describe 'testando miniteste' do
    it 'simplesmente deve funcionar' do 
      assert true
    end
  end
  
  describe 'testes básico com diferentes ambientes' do 
    class SayHello < Lotus::Activity::Pipe
      def call(name:)
        return "#{name}: Hello, "
      end
    end

    class SayWorld < Lotus::Activity::Pipe
      def call(phrase)
        pp "#{phrase} world!"
      end
    end

    class CounterUntil10 < Lotus::Activity::Pipe
      def call()
        10.times do |it|
          yield it
        end
      end
    end

    class SayHelloCount < Lotus::Activity::Pipe
      def call(content)
        pp "Contendo #{content}"
      end
    end


  
    it 'deve ser capaz de criar um hello world utilizando o método \'flow\' que utilize a gem async' do 
      lotus = Lotus::Activity::Container.new()

      lotus.pipe(SayHello, Lotus::Method::Flow)
      lotus.pipe(SayWorld, Lotus::Method::Flow)
      
      app = lotus.compile()
      app.run name: "Henrique" do |resp|
        assert_equal resp, "Hello, world! Henrique"
      end.await()
    end

    it 'deve ser capaz de criar um hello world utilizando o método \'stream\' que utilize a gem async' do 
      # Responsável por gerenciar os processos 
      lotus = Lotus::Activity::Container.new()

      lotus.pipe(CounterUntil10, Lotus::Method::Stream)
      lotus.pipe(SayHelloCount, Lotus::Method::Flow)

    end

    it 'deve ser capaz de criar um simples ETL utilizando os três métodos principais' do 
      lotus = Lotus::Activity::Container.new()
      lotus.pipe(ExtractData, Lotus::Method::Stream)
      lotus.pipe(TransformData, Lotus::Method::Actor)
      lotus.pipe(LoadData, Lotus::Method::Flow)

      app = lotus.compile 

      app.run 10 do |resp|
        pp resp
      end.await()
    end

  end

  describe 'testes basicos com serviços' do 
    class SayHello < Lotus::Activity::Pipe
      def call()
        return "#{self.yml.name}: Hello, "
      end
    end

    class SayWorld < Lotus::Activity::Pipe
      def call(phrase)
        pp "#{phrase} world!"
      end
    end

    class SayWorldWithCallback < Lotus::Activity::Pipe

      def 
      def call(phrase)
        pp "#{phrase} world!"
      end
    end

    class NameService < Lotus::Activity::Service
      def self.on_klass_load(container)
        container.app('say_world').set_dependencies yml: self
      end

      def name()
        return 'henrique'
      end

      def self.on_instance_load(container)
      end
    end

    class PrintCallback < Lotus::Activity::Service
      def on_pipe_init(pipe)
        Async do 

        end
      end

      def on_container_init(container)
      end

    end


    it 'deve criar um serviço e ser capaz de utiliza-lo' do 
      lotus = Lotus::Activity::Container.new()

      lotus.pipe(SayHello, Lotus::Method::Flow)

      name_service = NameService.new()
      name_service.name = 'henrique'
      
      lotus.pipe(SayWorld, Lotus::Method::Flow, services: [name_service])
      
      app = lotus.compile Lotus::Enviroment::Task
      app.run name: "Henrique" do |resp|
        assert_equal resp, "Hello, world! Henrique"
      end.await()
    end

    it 'deve criar um serviço que puxa dados de outro serviço' do 
      lotus = Lotus::Activity::Container.new()
    
      lotus.pipe(SayHello, Lotus::Method::Flow)

      yaml_service = YamlLoader.new()

      name_service = NameService.new(yaml_service)
      name_service.name = 'henrique'
      
      lotus.pipe(SayWorld, Lotus::Method::Flow, services: [name_service])


    end

    class N9N::Client < Lotus::Activity::Service

      def initialize()
        @lotus = []
      end

      def on_lotus_load(lotus)
        @lotus << lotus.build()
      end


      def on_request_received(request, response)
        request.headers 
        request.body
        request.query
        

        return N9N::Response
          .status(200)
          .body({teste: 200})
          .headers(request.headers)
         


      end
    end





    it 'deve criar um serviço que tenha a capacidade de chamar métodos do pipe' do 
      lotus = Lotus::Activity::Container.new()
      print_callback = PrintCallback.new()
      lotus.pipe(SayHelloWithCallback, Lotus::Method::Flow, services: print_callback)
    end

    it 'deve ser capaz de criar um que é executado em um período de tempo' do 

    end

    it 'deve criar um serviço especial que me permite por meio de http buildar (compilar) e também executar e receber parametros de execução, ou seja, o serviço terá uma inversão de controle' do 
      n9n = N9n.new 'localhost://3000'
      
      lotus1 = Lotus::Activity::Container.new
      lotus1.name 'app1'
      lotus1.service n9n
      lotus1.pipe SayHello, Lotus::Method::Flow
      
      lotus2 = Lotus::Activity::Container.new
      lotus1.name 'app2'
      lotus2.service n9n
      lotus2.pipe SayHello, Lotus::Method::Flow
      

      Async do 
        n9n.init()
      end

      options = make_request()
      assert_equal options, {
          options: ['app1', 'app2']
      }

    end
  end
end
