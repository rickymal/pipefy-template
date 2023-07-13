# spec/activity/container_test.rb
require 'pry'
require "minitest/autorun"
require 'minitest/reporters'
require 'async'
require 'async/http'
require 'rufus-scheduler'

require './lib/modules/scheduler/utils/active_job'
require './lib/modules/scheduler/utils/job'
require './lib/utils/global.rb'
require './lib/davinci'
require 'async/semaphore'
require 'async/barrier'
require 'rufus-scheduler'

require_relative '../utils/micro_server.rb'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class HelloWorld

    def self.report()
      return {
        data: String
      }
    end

    def call(data = nil)
      puts "Hello, world with #{data}"
    end
end

Hello = Lotus::Container.new()
Hello.pipefy(HelloWorld, Lotus::Method::Flow)

class Pipeline
    def self.report()
        return {
            data: String 
        }
    end

    def extract(data = nil)
        return {extract: data}
    end

    def transform(data = nil)
        return data[:extract] = "#{data}:transformed"
    end

    def load(data = nil)
        return data.merge({status: 'lodaded'})
    end
end

Etl = Lotus::Container.new()
Etl.pipefy({obj: Pipeline, pipe_method: 'extract'}, Lotus::Method::Flow)
Etl.pipefy({obj: Pipeline, pipe_method: 'transform'}, Lotus::Method::Flow)
Etl.pipefy({obj: Pipeline, pipe_method: 'load'}, Lotus::Method::Flow)

describe 'WEBSERVER' do 
  created_dags = Array.new()
  it 'capaz de inicializar o servidor' do 
    Use do |tsk|
      endpoint = Async::HTTP::Endpoint.parse('http://127.0.0.1:9294')
      server_manager = MicroServer.new(endpoint)
      client = Async::HTTP::Client.new(endpoint)
      task = server_manager.up(tsk)
      created_dags = Array.new()
      hello_dag = Lotus::Job::Dag.new(Hello, Rufus::Scheduler.new(), SecureRandom.hex(10))
      hello_dag.name = 'Hello World'
      hello_dag.description = 'Executa um simples Hello World!'
      etl_dag = Lotus::Job::Dag.new(Etl, Rufus::Scheduler.new(), SecureRandom.hex(10))
      etl_dag.name = 'ETL'
      etl_dag.description = 'Executar um simples ETL'

      created_dags << {
        dag: hello_dag,
        description: hello_dag.describe(),
        tips: {
          params: {},
          cron: "* * * * * /1",
          timeout: '60'
        }
      }

      created_dags << {
        dag: etl_dag,
        description: etl_dag.describe(),
        tips: {
          params: {
            data: {
              default: {},
              description: "qualquer informação, literalmente"
            }
          },
          cron: "* * * * * /1",
          timeout: '60'
        }
      }

      assert_equal created_dags, created_dags
    end
  end

  # it '' do 
  #   server_manager.serve '/' do |method, request, headers, query|
	# 		next Protocol::HTTP::Response[200, {}, ["Hello World"]]
	# 	end	
	
	# 	# 1.Uma requisição para puxar todas as dags disponíveis para uso
	# 	resp = client.get('/app?p1=10&p2=300')
	# 	headers = resp.headers
	# 	status = resp.status
	# 	body = JSON.load resp.read
	
	# 	# 3.Ter a capacidade de específicar os parametros que serão executados
	# 	# Puxando uma dag qualquer para trabalhar
	# 	dag_id = body.dig(0,'dag_description','id')
	
	# 	data = {
	# 		id: dag_id,
	# 		cron: "* * * * * /1",
	# 		timeout: "30",
	# 		params: {
	# 			delay: 2,
	# 			times: 10
	# 		}
	# 	}.to_json
	
	# 	headers = {'content-type' => 'application/json', 'Content-Length' => data.length.to_s}
	# 	resp = client.post("/dag?id=#{dag_id}", headers, data)
	
	# 	headers = resp.headers
	# 	status = resp.status
	# 	body = JSON.load resp.read
	
	# 	puts "headers: #{headers}"
	# 	puts "status: #{status}"
	# 	puts "body: #{body}"
		
	# 	# 5. Puxar todas as DAGS disponíveis e inclusive as que já foram executadas para observe os status das mesmas
		
	# 	task.sleep 1
	# 	headers = {'content-type' => 'application/json', 'Content-Length' => data.length.to_s}
	# 	resp = client.get("/scheduled_dag?id=#{dag_id}", headers, data)
	
	# 	headers = resp.headers
	# 	status = resp.status
	# 	body = JSON.load resp.read
	
	# 	puts "headers: #{headers}"
	# 	puts "status: #{status}"
	# 	puts "body: #{body}"
  # end
end

