# spec/services/http_service_test.rb
require 'spec_helper'
require 'rack/test'

class HttpServiceTest < Minitest::Test
  include Rack::Test::Methods

  def app
    HttpService.new
  end

  def test_responds_with_success_on_get_request
    get '/'
    assert last_response.ok?, "O serviço deve responder com sucesso a uma requisição GET"
    assert_equal 'Hello from HttpService!', last_response.body
  end

  def test_responds_with_error_on_invalid_route
    get '/invalid-route'
    refute last_response.ok?, "O serviço deve responder com erro em uma rota inválida"
  end
end
