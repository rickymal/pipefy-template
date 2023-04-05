# spec/activity/container_test.rb
require 'spec_helper'

class ContainerTest < Minitest::Test
  def setup
    @container = Activity::Container.new
  end

  def test_can_add_service
    http_service = HttpService.new
    @container.add_service(:http, http_service)

    assert_equal http_service, @container.services[:http], "O serviço deve ser adicionado ao container"
  end

  def test_can_add_app
    app = App.new
    @container.add_app(:main_app, app)

    assert_equal app, @container.apps[:main_app], "O aplicativo deve ser adicionado ao container"
  end

  def test_can_run_app
    app = Minitest::Mock.new
    app.expect(:call, nil)

    @container.add_app(:main_app, app)
    @container.run_app(:main_app)

    app.verify
  end

  def test_add_and_replace_service_or_app_in_container
    # Adicionando um aplicativo e um serviço ao container
    @container.add(:app, @app)
    @container.add(:http_service, @http_service)
  
    # Substituindo o aplicativo e o serviço no container
    new_app = Lotus::App.new
    new_http_service = Lotus::HttpService.new
    @container.add(:app, new_app)
    @container.add(:http_service, new_http_service)
  
    # Verificando se o aplicativo e o serviço foram substituídos com sucesso
    assert_equal new_app, @container.get(:app)
    assert_equal new_http_service, @container.get(:http_service)
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
  
  
end


