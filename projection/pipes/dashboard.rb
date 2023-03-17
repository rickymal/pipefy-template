require './utils/utils.rb'

Davinci::App name: "Dashboard", route: "/root" do |it|

    find_ruby_files_by_path './extensions' do |path|
        get_constants_by_path(path) do |file, mdl|
            it.plug mdl
        end
    end

    find_ruby_files_by_path './template' do |path|
        get_constants_by_path(path) do |file, mdl|
            it.plug mdl
        end
    end

    find_ruby_files_by_path './services' do |path|
        get_constants_by_path(path) do |file, srv|
            it.use file => srv
        end
    end

    # Carrega todo conteudo da pasta pipes excluindo-se
    find_ruby_files_by_path './pipes' do |path|
        load(path)
    end
end