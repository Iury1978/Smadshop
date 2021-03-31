require 'json'

class PriceComparison
# attr_accessor :smadshop, :rozetka
#   def initialize
#     smadshop = {}
#     rozetka = {}
#   end

  def start
  	smadshop_data
  	rozetka_data
  end

  def smadshop_data
    file = File.read('./results/Smadshop_rezult_simple.txt') 
    smadshop = JSON.parse(file)
    a = smadshop.values.flatten.map do |name|
       name.keys
    end
    pp a
  end

  def rozetka_data
    file = File.read('./results/Rozetka_rezult_simple.txt') 
    rozetka = JSON.parse(file)
    pp rozetka.keys
  end


end

PriceComparison.new.start
