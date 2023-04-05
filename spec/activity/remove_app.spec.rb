require 'minitest/autorun'
require_relative '../lib/lotus/container'

class TestContainer < Minitest::Test
  def setup
    @container = Lotus::Activity::Container.new
    @app = Lotus::App.new
    @http_service = Lotus::HttpService.new
  end

  def test_remove_service_or_app_from_container
    # Adicionando um aplicativo e um serviço ao container
    @container.add(:app, @app)
    @container.add(:http_service, @http_service)

    # Removendo o aplicativo e o serviço do container
    @container.remove(:app)
    @container.remove(:http_service)

    # Verificando se o aplicativo e o serviço foram removidos com sucesso
    assert_nil @container.get(:app)
    assert_nil @container.get(:http_service)
  end

  def test_pause_and_resume_app_execution
    # Inicializando o aplicativo
    @app.start
  
    # Verificando se o aplicativo está em execução
    assert @app.running?
  
    # Pausando o aplicativo
    @app.pause
  
    # Verificando se o aplicativo está pausado
    assert @app.paused?
  
    # Retomando a execução do aplicativo
    @app.resume
  
    # Verificando se o aplicativo retomou a execução
    assert @app.running?
  end

  def test_app_communication_using_services
    # Inicializando os aplicativos e serviços
    app1 = Lotus::App.new
    app2 = Lotus::App.new
    http_service = Lotus::HttpService.new
  
    # Adicionando o serviço ao aplicativo 1
    app1.add_service(http_service)
  
    # Configurando a comunicação entre os aplicativos
    http_service.on(:request_received) do |request|
      app2.process_request(request)
    end
  
    # Enviando uma solicitação para o aplicativo 1
    app1.receive_request("Sample request")
  
    # Verificando se o aplicativo 2 recebeu e processou a solicitação
    assert_equal "Sample request", app2.request_data
  end
  
  
end
