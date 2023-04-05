# spec/apps/add_exclamation_test.rb
require 'spec_helper'

class AddExclamationTest < Minitest::Test
    
    def test_pause_and_resume_app
        # Inicializando o aplicativo e adicionando uma atividade simples
        app = Lotus::App.new
        app.add_activity do |data|
        sleep(1)
        data * 2
        end
    
        # Iniciando o aplicativo
        app.start
    
        # Pausando o aplicativo após um curto período
        sleep(0.5)
        app.pause
    
        # Verificando se o aplicativo está realmente pausado
        assert app.paused?
    
        # Retomando a execução do aplicativo
        app.resume
    
        # Verificando se o aplicativo não está mais pausado
        refute app.paused?
    
        # Aguardando a conclusão da atividade
        sleep(1.5)
    
        # Verificando se a atividade foi concluída
        assert app.finished?
    end

    def test_app_communication_across_tree_levels
        # Criando aplicativos pai e filho
        parent_app = Lotus::App.new
        child_app = Lotus::App.new
      
        # Adicionando atividades aos aplicativos
        parent_app.add_activity do |data|
          data.merge(child_app_output: child_app.start)
        end
      
        child_app.add_activity do |data|
          "Child App Output"
        end
      
        # Conectando o aplicativo filho ao pai
        parent_app.add_child_app(child_app)
      
        # Iniciando o aplicativo pai
        parent_app.start
      
        # Aguardando a conclusão do aplicativo pai
        sleep(1)
      
        # Verificando se os aplicativos concluíram a execução
        assert parent_app.finished?
        assert child_app.finished?
      
        # Verificando se a comunicação entre os aplicativos ocorreu corretamente
        assert_equal "Child App Output", parent_app.output[:child_app_output]
    end

    def test_pause_and_resume_app
        # Criando um aplicativo com duas atividades
        app = Lotus::App.new
        app.add_activity { |data| sleep(1); "Activity 1" }
        app.add_activity { |data| sleep(1); "Activity 2" }
      
        # Iniciando o aplicativo em uma thread separada
        app_thread = Thread.new { app.start }
      
        # Aguardando a primeira atividade concluir
        sleep(1.5)
      
        # Verificando se a primeira atividade foi concluída
        assert_equal "Activity 1", app.current_output
      
        # Pausando o aplicativo
        app.pause
      
        # Verificando se o aplicativo está pausado
        assert app.paused?
      
        # Aguardando um tempo para garantir que a segunda atividade não seja executada enquanto o aplicativo estiver pausado
        sleep(1.5)
      
        # Verificando se a segunda atividade ainda não foi executada
        assert_equal "Activity 1", app.current_output
      
        # Retomando o aplicativo
        app.resume
      
        # Aguardando a conclusão da segunda atividade
        sleep(1.5)
      
        # Verificando se a segunda atividade foi concluída após retomar o aplicativo
        assert_equal "Activity 2", app.current_output
      
        # Verificando se o aplicativo concluiu a execução
        assert app.finished?
      
        # Finalizando a thread do aplicativo
        app_thread.join
    end
    
      
end

