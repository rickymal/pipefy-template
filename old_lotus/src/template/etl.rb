module ETL
    def extract(data = nil)
        10.times do |yld|
            yield yld
        end
    end

    def transform(data)
        data + 1
    end

    def load(data)
        puts "Carregando dados de #{data}"
    end
end