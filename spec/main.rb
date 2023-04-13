# spec/activity/container_test.rb

require "minitest/autorun"
require 'pry'
require 'minitest/reporters'
require_relative '../lib/lib.rb'
require 'async'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# spec/activity/container_test.rb

require "minitest/autorun"
require 'pry'
require 'minitest/reporters'
require_relative '../lib/lib.rb'
require 'async'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new


describe "testando o miniteste" do  
  it "verificando se simplesmente funciona" do 
    assert true
  end
end

describe "testes básicos em ambientes diferente" do
  it "Devo conseguir fazer o 'hello world' apenas com método 'flow' (task)" do 
    Async do |task|


      lotus = Lotus::Activity::Container.new()
      lotus.name = 'hello world'
      lotus.pipefy HelloWorld

      @resp = nil
      app = lotus.new do |it|
        @resp = it
        
      end

      sleep 1
      app.call()
      sleep 2

      assert_equal "Hello, world!", @resp 
      app.call END_APP

      task.stop()
    end
  end

  it "Conseguir criar um sistema ETL simples" do
    Async do |task|
      lotus = Lotus::Activity::Container.new()
      lotus.name = 'ETL'
      lotus.pipefy Extract
      lotus.pipefy Transform
      lotus.pipefy Load

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

class Activity < Lotus::Activity::Container

  def new()

  end

end


describe "testes básicos com serviços" do 

  it "ser capaz de carregar um serviço simples e usa uma variável dele" do
    Async do |task|
      print_service = PrintService.new('henrique')
      
      lotus = Lotus::Activity::Container.new()
      lotus.name = 'hello world with service'
      lotus.pipefy HelloWithServiceArgs, print_service: print_service  

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
      
      lotus = Lotus::Activity::Container.new()
      lotus.name = 'hello world with service'
      lotus.pipefy HelloWithServiceArgs, print_service: print_service  

      app = lotus.new do |resp|
        @resp = resp
      end
      
      app.call()

      task.sleep 1
      

      assert_equal "Hello, henrique", @resp
      task.stop()

    end 
  end

  # it "Fazendo uma inversão de controle com o serviço (n1n)" do 
  #   service = LastResult.new()
  #   lotus = Lotus::Activity::Container.new()
  #   lotus.name = 'inversão de controle'
  #   lotus.pipe FeedBack

  #   app = lotus.new()
  #   app.call 10
  #   app.call 20
  #   app.call 30

  #   service.make_call 500

  #   service.get_last_result()

  # end

  # it 'deve ser capaz de criar varios serviços e a gerencia-los' do 
  #   n1n = N1n.new()
  #   lotus = lotus = Lotus::Activity::Container.new(n1n)
  #   lotus.app = 'many apps'
  #   lotus.pipe HelloWorld

  #   ap1 = lotus.new()
  #   ap2 = lotus.new()
  #   ap3 = lotus.new()

  #   assert_equal lotus.apps, [
  #     "many apps <#1>",
  #     "many apps <#2>",
  #     "many apps <#3>",
  #   ]

  # end
end

