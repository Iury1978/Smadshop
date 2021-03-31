require 'json'
require 'watir'
require 'nokogiri'
require 'open-uri'
require_relative 'product'

class Rozetka
  attr_reader :browser

  def initialize
    @browser = Watir::Browser.new :chrome
    # все конечные ссылки будут храниться в этом массиве
    @final_info = []
  end

  def parse_pagination
    link = 'https://rozetka.md/mobile-phones/c80003/'
   
      browser.goto(link)
      html =  browser.nav(id: 'navigation_block').html
      pagination_info = Nokogiri::HTML.parse(html)
      number_of_pages = pagination_info.css("a").text[-1].to_i
      number_of_pages = 3
      pagination_links = Array.new(number_of_pages) {|i| link + 'page='  + (i+1).to_s + '/'}
      parse_products_same_category__info(pagination_links,categorys_name) 
      params = {"Rozetka": @final_info} 
      File.open("./results/Rozetka_rezult.txt", "w") do |info|
        info.write(JSON.pretty_generate(params))
        end      
  end

  def parse_products_same_category__info(pagination,categorys_name)
    @all_products_category = []   
    #   sublinks_last_level - последний уровень ссылок, по которым уже хранится вся инфа о товаре (описание ,название и цена)
    sublinks_last_level = pagination.map do |page|
      browser.goto(page)
      html =  browser.div(name: "goods_list").html
      sublinks_last_level_info = Nokogiri::HTML.parse(html)   
      sublinks_last_level_info.css('a').map do |element|
        element['href']
        end
      end
    sublinks_last_level.flatten!.uniq!  
    a = sublinks_last_level.map do |string|
        if string.include?  "comments"
          string = nil 
        elsif string.include? "#"
          string = nil 
        else
          string
        end
        end
      sublinks_last_level =  a.compact
      sublinks_last_level.map do |info_page|
        browser.goto(info_page)
        html_price =  browser.span(id: 'price_label').html
        html_name = browser.div(class: "detail-title-wrap").html
        product_info_name = Nokogiri::HTML.parse(html_name)
        product_info_price = Nokogiri::HTML.parse(html_price)
        @all_products_category << parse_name_price_description(product_info_name, product_info_price) 
        end
    parameters = {"#{categorys_name}": @all_products_category}
    @final_info << parameters
  end
   
  def parse_name_price_description(product_info_name, product_info_price)  
    name = product_info_name.css('h1').text.strip
    puts name
    price = product_info_price.css("[id='price_label']").text.delete(" ")
    puts price
    parameters = {
      name:   name,
      price:  price      
    }
    Product.new(parameters)
  end
  #  метод, создающий общее имя категории
  def categorys_name
    html =  browser.div(id: 'catalog_title_block').html
    categorys_name_info = Nokogiri::HTML.parse(html)
    categorys_name = categorys_name_info.css('h1').text.strip
  end

end

Rozetka.new.parse_pagination
