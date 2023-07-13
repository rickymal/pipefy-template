# spec/activity/container_test.rb
require 'pry'
require "minitest/autorun"
require 'minitest/reporters'
require 'async'
require 'rufus-scheduler'

require_relative '../utils/active_job'
require_relative '../utils/job'
require './lib/utils/global.rb'
require './lib/davinci'
require 'async/semaphore'
require 'async/barrier'


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

App = Lotus::Container.new()
App.pipefy(HelloWorld, Lotus::Method::Flow)


describe 'DAG' do 
  active_jobs = Hash.new

  it 'capaz de criar DAGS e listar as tarefas que estão disponíveis para serem utilizadas' do 
    Use do 
      dag = Lotus::Job::Dag.new(App, Rufus::Scheduler.new(), SecureRandom.hex(10))
      active_jobs[dag] = Array.new()
      dag.name = 'uma dag para teste'
      dag.description = 'Uma descrição qualquer para a DAG'
      content = dag.describe().merge({dag: dag})  

      assert_hashes_equal({
        name: "uma dag para teste",
        description: "Uma descrição qualquer para a DAG"
      }, content, partial_match: true)
    end
  end

  it 'Clicar em uma tarefa e aparecer detalhes dela para ser executada, permitindo passar parametros' do 
    Use do |tsk|
      dag = Lotus::Job::Dag.new(App, Rufus::Scheduler.new(), SecureRandom.hex(10))
      active_jobs[dag] = Array.new()
      dag.name = 'uma dag para teste'
      dag.description = 'Uma descrição qualquer para a DAG'
      content = dag.describe().merge({dag: dag})  

      id_selected = content[:id]
      
      parameters = dag.job.get_activities().map do |activity|
        activity.report()
      end

      assert_hashes_equal({
        data: String
      }, parameters.first, partial_match: true)
    end
  end

  it 'Checando jobs (active_jobs) em execução' do 
    Use do |tsk|
      dag = Lotus::Job::Dag.new(App, Rufus::Scheduler.new(), SecureRandom.hex(10))
      dag.name = 'uma dag para teste'
      dag.description = 'Uma descrição qualquer para a DAG'

      # [mock] simulando um parametro enviado à aplicação
      params = Array.new()
      
      barrier = Async::Barrier.new

      tsk.async { barrier.async { dag.run(params, '* * * * * /1', 3) } }
      tsk.async { barrier.async { dag.run(params, '* * * * * /2', 3) } }
      tsk.async { barrier.async { dag.run(params, '* * * * * /2', 1) } }

      barrier.wait()
      
      ctx = dag.scheduled_jobs().map do |it|
        {
          dag_status: it.status,
          pipeline_status: it.application.tasks.map do |it|
            it.method_status()
          end
        }
      end
      
      tsk.stop()
      expected = [{:dag_status=>"running", :pipeline_status=>[{:status=>"running", :msg=>nil}]},
      {:dag_status=>"running", :pipeline_status=>[{:status=>"running", :msg=>nil}]},
      {:dag_status=>"timeout", :pipeline_status=>[{:status=>"running", :msg=>nil}]}]
    
      ctx.zip(expected) do |real, expected|
        assert_hashes_equal(expected,real)
      end
    end
  end
end

