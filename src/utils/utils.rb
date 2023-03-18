def find_ruby_files_by_path(path, nested = false, ignore: [], &blk)
    ruby_files = []
    Dir.foreach(path) do |filename|
      next if filename == '.' || filename == '..'
      file_path = File.join(path, filename)
      if File.directory?(file_path) && nested
        ruby_files += find_ruby_files_by_path(file_path)
      elsif filename.end_with?('.rb')
        ruby_files << file_path
      end
    end

    ruby_files.each(&blk) if blk
    return ruby_files
rescue Exception => error 
  binding.pry
end

def find_ruby_files_by_path(path, nested = false, ignore: [], &blk)
    ruby_files = []
    Dir.foreach(path) do |filename|
      next if filename == '.' || filename == '..' || ignore.include?(filename)
  
      file_path = File.join(path, filename)
  
      if File.directory?(file_path) && nested
        ruby_files += find_ruby_files_by_path(file_path, nested: true, ignore: ignore, &blk)
      elsif filename.end_with?('.rb')
        absolute_path = File.expand_path(file_path)
        ruby_files << absolute_path
        yield absolute_path if blk
      end
    end
  
    ruby_files
  rescue Exception => error 
    binding.pry
  end
  

def get_constants_by_path(path, &blk)
    constants = []
    File.readlines(path).each do |line|
      line.strip!
      next if line.empty? || line.start_with?('#')
  
      if line.start_with?('module ') || line.start_with?('class ')
        constant_name = line.split(' ')[1]
        constants << constant_name
      end
    rescue Exception => error 
        binding.pry
    end
    binding.pry
    load path
    consts = constants.map {|it| Object.const_get(it)}.compact()


    consts.each {|it| blk.call(path.split('/').last.split('.').first(), it)}

    load path, true

    return consts
  rescue Exception => error 
    binding.pry
end


def load_application(path)
  require path 
end