# spec/spec_helper.rb

require 'bundler/setup'
Bundler.require(:default, :test)

require_relative '../lib/seu_projeto'

RSpec.configure do |config|
  # Algumas configurações básicas do RSpec podem ser adicionadas aqui
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!

  # Habilitar a exibição de cores no terminal
  config.color = true

  # Definir a ordem de execução dos testes como aleatória
  config.order = :random
  Kernel.srand config.seed
end
