# spec/activity/container_test.rb
require 'pry'

require "minitest/autorun"
require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
require 'async'

require_relative '../lib.rb'


def assert_hashes_equal(expected, actual, path = [], msg = nil)
  differences = []

  expected.each_key do |key|
    current_path = path + [key]
    if !actual.key?(key)
      differences << "Chave ausente no hash atual: #{current_path.join('.')}"
    elsif expected[key].is_a?(Hash) && actual[key].is_a?(Hash)
      sub_differences = assert_hashes_equal(expected[key], actual[key], current_path, nil)
      differences.concat(sub_differences) unless sub_differences.empty?
    elsif expected[key] != actual[key]
      differences << "Diferença no valor da chave\n #{current_path.join('.')}: esperado #{expected[key].inspect}, obtido #{actual[key].inspect}\n"
    end
  end

  actual.each_key do |key|
    current_path = path + [key]
    if !expected.key?(key)
      differences << "Chave extra no hash atual: #{current_path.join('.')}"
    end
  end

  if path.empty?
    assert differences.empty?, (msg || "Diferenças entre os hashes: \n\n") + differences.join("\n")
  else
    differences
  end
end




describe "testando o miniteste" do  
  it "verificando se simplesmente funciona" do 
    assert true
  end
end

# Classe que será usada para definir como a aplicação/pipeline será construida
class App < Lotus::Application

  def reactor()
    return Async::Task.current
  end

end

describe "testes básicos em ambientes diferente" do
  it "Devo conseguir fazer o 'hello world' apenas com método 'flow' (task)" do 
    Async do |task|


      lotus = Lotus::Container.new()
      lotus.name = 'hello world'
      lotus.pipefy HelloWorld, Lotus::Method::Flow

      @resp = nil
      app = lotus.new do |it|
        @resp = it
        
      end

      task.sleep 1
      app.call()
      task.sleep 1

      assert_equal "Hello, world!", @resp 
      app.call END_APP

      task.stop()
    end
  end

  it "Conseguir criar um sistema ETL simples" do
    Async do |task|
      lotus = Lotus::Container.new()
      lotus.name = 'ETL'
      lotus.pipefy Extract, Lotus::Method::Stream
      lotus.pipefy Transform, Lotus::Method::Actor
      lotus.pipefy Load, Lotus::Method::Flow

      @resp = []

      app = lotus.new do |resp|
        @resp << resp
      end

      app.call(10)
      task.sleep 1
      
      
      assert_equal ["data: transforming: 0",
          "data: transforming: 1",
          "data: transforming: 2",
            "data: transforming: 3",
            "data: transforming: 4",
              "data: transforming: 5",
              "data: transforming: 6",
                "data: transforming: 7",
                "data: transforming: 8",
                  "data: transforming: 9"], @resp 

      
      task.stop()
    end
  end
end





describe "testes básicos com serviços" do 

  it "ser capaz de carregar um serviço simples e usa uma variável dele" do
    Async do |task|
      print_service = PrintService.new('henrique')
      @resp = nil
      lotus = Lotus::Container.new App
      lotus.name = 'hello world with service test'
      lotus.pipefy HelloWithServiceArgs, Lotus::Method::Flow, print_service: print_service  

      app = lotus.new do |resp|
        @resp = resp
      end
      
      app.call()

      task.sleep 1
      

      assert_equal "Hello, henrique", @resp
      task.stop()

    end 
  end

  it "ser capaz de carregar um serviço simples e usa uma variável dele (com delegação)" do
    Async do |task|
      print_service = PrintService.new('henrique')
      
      lotus = Lotus::Container.new App
      lotus.name = 'hello world with service'
      lotus.pipefy HelloWithServiceArgs, Lotus::Method::Flow, print_service: print_service  

      app = lotus.new do |resp|
        @resp = resp
      end
      
      app.call()

      task.sleep 1
      

      assert_equal "Hello, henrique", @resp
      task.stop()

    end 
  end

  describe 'gerenciamento de processos' do 

    it 'capaz de iniciar uma tarefa mata-la' do 
      Async do |task|
        lotus = Lotus::Container.new App
        lotus.name = 'hello world with big delay'
        lotus.pipefy HelloWithBigDelay, Lotus::Method::Flow

        @r1 = nil
        @r2 = nil
        @r3 = nil
        
        app1 = lotus.new do |resp|
          @r1 = resp
        end

        app1.stop()

        task.stop()
      end 


    end

    require 'stringio'

    it 'capaz de iniciar três tarefas e pegar um relatório do estado de execução dos mesmo (funcionando)' do 
      Async do |task|
        Lotus::Container.clear_application_info()
        original_stdout = $stdout
        app_name = 'hello world with big delay'

        # Redireciona a saída padrão para um objeto StringIO
        fake_stdout = StringIO.new
        $stdout = fake_stdout

        
        lotus = Lotus::Container.new App
        lotus.name = app_name
        lotus.pipefy HelloWithBigDelay, Lotus::Method::Flow

        @r1 = nil
        @r2 = nil
        @r3 = nil
        
        app1 = lotus.new do |resp|
          @r1 = resp
        end

        app2 = lotus.new do |resp|
          @r2 = resp
        end

        app_with_error = 'hello world with big delay and error'
        lotus = Lotus::Container.new App
        lotus.name = app_with_error
        lotus.pipefy HelloWithBigDelayAndError, Lotus::Method::Flow

        app3 = lotus.new do |resp|
          @r3 = resp
        end



        expected = {
          'hello world with big delay' => {
            'applications' => {
              'hello world with big delay <#1>' => 'running',
              'hello world with big delay <#2>' => 'running',
            }
          },
          'hello world with big delay and error' => {
            'applications' => {
              'hello world with big delay and error <#1>' => 'running',
            }
          }
        }

        task.sleep 1
        
        assert_hashes_equal(expected[app_name], Lotus::Container.info('applications')[app_name])
        # assert_equal expected, Lotus::Activity::Container.info('applications')

        app1.stop()
        task.sleep 1


        expected = {
          app_name => {
            'applications' => {
              "#{app_name} <#1>" => 'stopped',
              "#{app_name} <#2>" => 'running',
            }
          },
          'hello world with big delay and error' => {
            'applications' => {
              "#{app_with_error} <#1>" => 'running',
            }
          }
        }

        # assert_equal expected, Lotus::Activity::Container.info('applications')
        assert_hashes_equal(expected[app_name], Lotus::Container.info('applications')[app_name])
        app3.call 10
        task.sleep 5

        expected = {
          'hello world with big delay' => {
            'applications' => {
              'hello world with big delay <#1>' => 'stopped',
              'hello world with big delay <#2>' => 'running',
            }
          },
          'hello world with big delay and error' => {
            'applications' => {
              'hello world with big delay and error <#1>' => 'error',
            }
          }
        }


        assert_hashes_equal(expected[app_with_error], Lotus::Container.info('applications')[app_with_error])

        # assert_equal expected, Lotus::Activity::Container.info('applications')

        $stdout = original_stdout

        task.stop()
      end


    end

  
  end
end

