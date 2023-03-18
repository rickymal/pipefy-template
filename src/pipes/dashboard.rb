require 'pry-stack_explorer'
binding.pry
require './src/utils/utils.rb'
require './src/utils/davinci.rb'

require 'pathname'

def relative_path_from_project(file_path)
  project_dir = Pathname.new(File.expand_path('.'))
  file_pathname = Pathname.new(file_path)
  file_pathname.relative_path_from(project_dir).to_s
end


# Kai.App
Davinci.App name: "Dashboard", route: "/root" do |it|

    # # Define que as aplicações filhas serão Tasks Async
    # it.define_child_app_as Async::Container::Threaded


    find_ruby_files_by_path './src/extensions' do |path|
        
        get_constants_by_path(path) do |_, mdl|
            it.plug mdl
        end
    end

    find_ruby_files_by_path './src/template' do |path|
        get_constants_by_path(path) do |_, mdl|
            it.template mdl
        end
    end

    find_ruby_files_by_path './src/services' do |path|
        get_constants_by_path(path) do |file, srv|

            it.use file => srv
        end
    end

    # Carrega todo conteudo da pasta pipes excluindo-se
    var = find_ruby_files_by_path './src/pipes', ignore: [__FILE__] do |path|
        binding.pry
        load_application(path)
        binding.pry
    end
rescue Exception => error 
    binding.pry

end