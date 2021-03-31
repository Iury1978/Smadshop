require 'json'
require 'date'

class PriceComparison

  attr_accessor :date_array

  def initialize
  	@date_array = []
  end

  def smadshop
    file = File.read('./data/Smadshop_rezult_simple.txt') 
    smadshop = JSON.parse(file)
    get_data(smadshop)  
  end

  def rozetka
    file = File.read('./data/Rozetka_rezult_simple.txt') 
    rozetka = JSON.parse(file)
    get_data(rozetka) 
  end   
  
  def comparison
    smadshop.map do |smadshop_element|
      rozetka.map do |rozetka_element|
    	if smadshop_element['name'] == rozetka_element['name']
    	  date_array << "#{smadshop_element['name']}"
    	  difference = smadshop_element['price'] - rozetka_element['price']
    	  if difference > 0
    	  	date_array << 'В Розетке стоит ' + "#{rozetka_element['price']}" + ', что дешевле, чем в Смадшопе на ' + "#{difference}" " л." + "\n\r"
    	  elsif difference < 0
    	  	date_array << 'В Смадшопе стоит ' + "#{smadshop_element['price']}" + ', что дешевле, чем в Розетке на ' + "#{difference}" " л." + "\n\r"
    	  else
    	  	date_array << 'Цена одинаковая'
    	  end
        end
      end
    end
    save_to_file(date_array)
  end

  def get_data(data)
  	data_array = data.values.flatten.map do |element|
     element.values if element.keys.join == 'Мобильные телефоны'    	
    end
    data_array.compact.flatten
  end

  def save_to_file(date_array)
  	todays_date = ("По состоянию на "  + Time.now.strftime("%d %B %Y") + "\n\r")
    file = File.open("./data/price_comparison.txt", "w")
    file.puts(todays_date)
	for items in date_array do 
	  file.puts(items)
	  end
	file.close  
  end 

end

PriceComparison.new.comparison
