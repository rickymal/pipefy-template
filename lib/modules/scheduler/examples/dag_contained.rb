# Rodando os jobs em processos separados
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
    dags_in_execution = Hash.new
    dag1 = Lotus::Job::Dag.new(Etl, Rufus::Scheduler.new(), SecureRandom.hex(10))
    dags_in_execution[dag1] = Array.new() 
    dag2 = Lotus::Job::Dag.new(Etl, Rufus::Scheduler.new(), SecureRandom.hex(10))
    dags_in_execution[dag2] = Array.new()
    dag1.name = "Etl1"
    dag1.description = "Uma descição qualquer do Etl1"
    dag2.name = "Etl2"
    dag2.description = "Uma descição qualquer do Etl2"
    lof_dags = [dag1, dag2]
    content = lof_dags.map do |dag|
        dag.describe().merge({dag: dag})
    end

    # 2. Clicar em uma tarefa e aparecer detalhes dela para ser executada, permitindo passar parametros
    # [mock]
    id_selected = content[0][:id]
    # dag_selected = content.select {|it| it[:id] == id_selected}
    dag_selected = content.find { |it| it[:id] == id_selected }.fetch(:dag)
    parameters = dag_selected.job.get_activities().map do |activity|
      activity.report()
    end
    parameter s = 100
    tsk.async { dag_selected.run(parameters, '* * * * * /1', 10.min) }
    tsk.async { dag_selected.run(parameters, '* * * * * /2', 1.min) }
    tsk.sleep 0.5
    # 3. Checando dags em execução
    started_jobs = dag_selected.scheduled_jobs()
    binding.pry
    # Me trará o status de cada pipeline, mas não me diz que a execução do job em si está 'ok'
    status = started_jobs.map do |it|
        {
            dag_status: it.status,
            pipeline_status: it.application.tasks.map do |it|
                it.method_status()
            end
        }
    end
    tsk.sleep 0.5
    puts status
  end
