module Lotus
    module Reflections
        def self.find_files_by_path(path)
            return Dir.entries(path).reject {|it| ['.','..'].include?(it)}
        end

        def self.load_arguments_by_file(file)
            extension = file.split('.')[-1]
            if extension == 'yml' || extension == 'yaml'
                return YAML.load_file(file)
            elsif extension == 'json'
                return JSON.load(File.read(file))
            else
                raise Exception, "algo de errado não está certo"
            end
        end
    end
end