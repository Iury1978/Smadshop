class Product

  attr_accessor :name, :price

  def initialize(parameters)
    @name = parameters[:name]
    @price = parameters[:price]
  end

  def to_json(*a)
  	{
	  name: @name,
	  price: @price
  	}.to_json(*a)
  end
end