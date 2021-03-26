class NamePriceDescription

  attr_accessor :name, :price, :description

  def initialize(parameters)
    @name = parameters[:name]
    @price = parameters[:price]
    @description = parameters[:description]
  end

  def to_json(*a)
  	{
	  name: @name,
	  price: @price,
	  description: @description
  	}.to_json(*a)
  end
end