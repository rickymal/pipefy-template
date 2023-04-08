# lotus.gemspec

Gem::Specification.new do |s|
    s.name        = 'lotus'
    s.version     = '0.1.0'
    s.date        = '2023-03-28'
    s.summary     = "Seu Projeto - Um framework de gerenciamento e orquestração de aplicativos"
    s.description = "Seu Projeto é um framework que facilita a criação, gerenciamento e orquestração de aplicativos e serviços. Ele oferece uma arquitetura modular e escalável, permitindo a criação de soluções personalizadas e flexíveis."
    s.authors     = ["henrique mauler"]
    s.email       = 'henriquemauler@gmail.com'
    s.files       = Dir['lib/**/*.rb']
    s.homepage    = 'https://github.com/seu_nome/lotus'
    s.license     = 'GPL'
  
    # Adicione suas dependências aqui, por exemplo:
    s.add_dependency 'json', '~> 2.0'
    s.add_dependency 'httparty', '~> 0.18.0'
  
    s.add_development_dependency 'rake', '~> 13.0'
    s.add_development_dependency 'rspec', '~> 3.0'
  end
  