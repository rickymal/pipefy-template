#!/usr/bin/env ruby
#!template

require 'securerandom'
require 'pry'
require 'async'
require 'async/http/server'
require 'async/http/client'
require 'async/http/endpoint'
require 'async/http/protocol/response'
require 'rufus-scheduler'
require 'async/container'
require 'rufus-scheduler'
require_relative '../../davinci'
require_relative '../scheduler/utils/active_job'
require_relative '../scheduler/utils/job'
require_relative '../../mocks/etl_with_error.rb'
require_relative '../../mocks/etl.rb'

# Classe Core que guarda informações sobre o servidor que será criado
class MicroServer
	def initialize(endpoint)
		@server = Async::HTTP::Server.new(self, endpoint)
		@objects = Hash.new
	end

	def serve(endpoint, manager = nil, &block)
		@objects[endpoint] = manager || block
	end

	def call(request)
		
		endpoint, raw_query_params = request.path.split("?")
		
		if !raw_query_params.nil? && raw_query_params.include?("\\&")
			raise Exception, "encontrado formato especial de query params!"
		end

		if raw_query_params
			query_params = raw_query_params.split("&").map do |it|
				it.split('=')
			end.to_h
		else
			query_params = nil
		end

		if app = @objects[endpoint]
			return app.call(request.method, request, request.headers, query_params)
		else
			raise Exception, "tentando acessar um endpoint ainda não registrado!"
		end

	end

	def up(task)
		task.async { @server.run }
	end
end


Async do |task|
	endpoint = Async::HTTP::Endpoint.parse('http://127.0.0.1:9294')
	server_manager = MicroServer.new(endpoint)	
	client = Async::HTTP::Client.new(endpoint)
	task = server_manager.up(task)
	created_dags = Array.new
	dag1 = Lotus::Job::Dag.new(Etl, Rufus::Scheduler.new(), SecureRandom.hex(10))
	
	dag1.name = "ETL1"
	dag1.description = "Executa um simples ETL"
	# Define um exemplo para ser inputado pelo usuário!
	
	created_dags << {
		dag: dag1,
		tips: {
			params: {
				delay: {
					default: 1,
					description: "Define o tempo (em segundos) de execução de transformação",
					type: "Integer"
				},
				times: {
					default: 10,
					description: "Define quantos dados o sistema ETL irá gerar",
					type: "Integer"
				},
			},
			cron: "* * * * * /1",
			timeout: '60'
		}
	}
	dag2 = Lotus::Job::Dag.new(Errortl, Rufus::Scheduler.new(), SecureRandom.hex(10))
	dag2.name = "ETL2"
	dag2.description = "Executa um simples ETL"
	created_dags << {
		dag: dag2,
		tips: {
			params: {
				delay: {
					default: 1,
					description: "Define o tempo (em segundos) de execução de transformação",
					type: "Integer"
				},
				times: {
					default: 10,
					description: "Define quantos dados o sistema ETL irá gerar",
					type: "Integer"
				},
			},
			cron: "* * * * * /1",
			timeout: '60'
		}
	}


	dags_info = created_dags.map do |it|
		it[:dag_description] = it[:dag].describe
		next it
	end

	server_manager.serve '/app' do |method, request, headers, query|
		next Protocol::HTTP::Response[200, {}, [dags_info.to_json()]]
	end

	server_manager.serve '/dag' do |method, request, headers, query|
		body = JSON.load request.read
		selected_dag = created_dags.find { |it| it.dig(:dag_description, :id) == body['id'] }.fetch(:dag)
		puts 'running'
		task.async { selected_dag.run(body['params'], body['cron'], body['timeout'].to_i()) }
		task.sleep 0.5
		next Protocol::HTTP::Response[200, {}, []]
	end

	server_manager.serve '/scheduled_dag' do |method, request, headers, query|
		dag_id = query['id']
		selected_dag = created_dags.find { |it| it.dig(:dag_description, :id) == dag_id }.fetch(:dag)
				
		status = selected_dag.scheduled_jobs.map do |it|
			{
				dag_status: it.status,
				pipeline_status: it.application.tasks.map do |it|
					it.method_status()
				end
			}
		end
		
		next Protocol::HTTP::Response[200, {}, status.to_json()]
	end
end