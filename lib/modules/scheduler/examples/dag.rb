#!/usr/bin/env ruby
require 'securerandom'
require 'pry'
require 'async'
require 'async/http/server'
require 'async/http/client'
require 'async/http/endpoint'
require 'async/http/protocol/response'
require './lib/modules/scheduler/utils/job'
require './lib/modules/scheduler/utils/active_job'
require 'rufus-scheduler'
require 'async/container'
require 'async'
require 'rufus-scheduler'


Async do 
  container = Async::Container.new
  container.async(name: "tarefa1") do |tsk|
    dag = Lotus::Job::Dag.new(Etl)
    dag.run(30, '* * * * * /1', 10)
	puts "O Processo já terminou hermano"
	tsk.stop()
  end
  container.async(name: "tarefa2") do |tsk|
    dag = Lotus::Job::Dag.new(Etl)
    dag.run(70, '* * * * * /3', 10)
	tsk.stop()
  end
  container.wait # Espera até que todos os filhos terminem
end

Async do 
	dag = Lotus::Job::Dag.new(Etl, Rufus::Scheduler.new())
	Async { dag.run(30, '* * * * * /1', 10) }
	Async { dag.run(70, '* * * * * /3', 10) }
end

Async do |tsk|


	# 1. Listar todas as tarefas que estão disponíveis para ser utilizada
	active_jobs_in_execution = Hash.new
	dag1 = Lotus::Job::Dag.new(Etl, Rufus::Scheduler.new(), SecureRandom.hex(10))
	active_jobs_in_execution[dag1] = Array.new() 
	dag2 = Lotus::Job::Dag.new(Etl, Rufus::Scheduler.new(), SecureRandom.hex(10))
	active_jobs_in_execution[dag2] = Array.new()
	dag1.name = "Etl1"
	dag1.description = "Uma descição qualquer do Etl1"
	dag2.name = "Etl2"
	dag2.description = "Uma descição qualquer do Etl2"
	# lof = list of
	lof_dags = [dag1, dag2]
	content = lof_dags.map do |dag|
		dag.describe().merge({dag: dag})
	end


	# 2. Clicar em uma tarefa e aparecer detalhes dela para ser executada, permitindo passar parametros
	# [mock]
	id_selected = content[0][:id]
	dag_selected = content.find { |it| it[:id] == id_selected }.fetch(:dag)
	binding.pry
	parameters = dag_selected.job.get_activities().map do |activity|
		activity.report()
	end
	# Manda para o front-end
	parameters = 100
	# Iniciar uma DAG que rodará a cada um segundo por 10 minutos
	tsk.async { dag_selected.run(parameters, '* * * * * /1', 10.min) }
	# Iniciar uma DAG que rodará a cada dois segundos por 1 minuto
	tsk.async { dag_selected.run(parameters, '* * * * * /2', 1.min) }
	# Pausa na fibra para inicializar a execução
	tsk.sleep 0.5


	# 3. Checando jobs (active_jobs) em execução
	started_jobs = dag_selected.scheduled_jobs()
	# Me trará o status de cada pipeline
	status = started_jobs.map do |it|
		{
			dag_status: it.status,
			pipeline_status: it.application.tasks.map do |it|
				it.method_status()
			end
		}
	end
	# Pausa na fibra para inicializar a execução
	tsk.sleep 0.5
	puts status
end
