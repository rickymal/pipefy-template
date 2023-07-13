def assert_hashes_equal(expected, actual, path = [], msg = nil, partial_match: false)
  differences = []

  expected.each_key do |key|
    current_path = path + [key]
    if !actual.key?(key)
      differences << "Chave ausente no hash atual: #{current_path.join('.')}"
    elsif expected[key].is_a?(Hash) && actual[key].is_a?(Hash)
      sub_differences = assert_hashes_equal(expected[key], actual[key], current_path, nil, partial_match: partial_match)
      differences.concat(sub_differences) unless sub_differences.empty?
    elsif expected[key] != actual[key]
      differences << "Diferença no valor da chave\n #{current_path.join('.')}: esperado #{expected[key].inspect}, obtido #{actual[key].inspect}\n"
    end
  end

  if !partial_match
    actual.each_key do |key|
      current_path = path + [key]
      if !expected.key?(key)
        differences << "Chave extra no hash atual: #{current_path.join('.')}"
      end
    end
  end

  if path.empty?
    assert differences.empty?, (msg || "Diferenças entre os hashes: \n\n") + differences.join("\n")
  else
    differences
  end
end

def catch_io()
  @original_stdout = $stdout
  return $stdout = StringIO.new
end

def Use(&blk)
  @stdout = catch_io()
  Async(&blk).wait()
  $stdout = @original_stdout
end

