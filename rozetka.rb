# нулевой уровень - общий каталог товаров ( список, что на главной) ul class="box-category
# уровень с подкатегориями товаров div class="category-modlist 
# уровень 1 --  предпоследний - где список товаров данного типа -  div class="product-list' или div class: 'product-grid'
# в зависимости от вида отображения товаров
# уровень 2 -- нижний уровень, где описание товара в   div class="product-info"  название и цена( тут же собрал и х-ки)

require 'json'
require 'watir'
require 'nokogiri'
require 'open-uri'
# require_relative 'category'
require_relative 'check_module'
require_relative 'product'

class Rozetka
  include Check_module
  attr_reader :browser

  def initialize
    @browser = Watir::Browser.new :chrome
    # массив всех ссылок последнего уровня, заполняется в модуле
    @sub_links = []
    # все конечные ссылки будут храниться в этом массиве
    @final_info = []
  end

  def start
    # отключил goto_page и get_links только записывают инфу в файл.
    # что бы не ждать  весь цикл получения ссылок их можно отключить и сразу обрабатывать записаныне
    #  в файле Smadshop_sub_links.txt наугад оставил пару ссылок для демонстрации работы
    # goto_page
    # get_links
    parse_pagination
  end


  # парсим количество страниц каждой каSmadshopтегории товара и создаем ссылки на каждую из них
  def parse_pagination
    link = 'https://rozetka.md/mobile-phones/c80003/'
   
      browser.goto(link)
      #  делаю отображение товара "Картинки"
      # browser.element(id: 'a_view_grid').wait_until(&:present?).click
      html =  browser.nav(id: 'navigation_block').html
      pagination_info = Nokogiri::HTML.parse(html)

      #  количество страниц берем отсюда <div class="results">Показано с 1 по 21 из 364 (всего 18 страниц)</div>
      number_of_pages = pagination_info.css("a").text[-1].to_i
      # puts number_of_pages
      # устанавливаю  1,чтобы не крутил  все страницы каждого товара,хаватит и первой для наглядности
      # но проверил, все  ссылки отлично создаются и работают
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
      # puts sublinks_last_level_info  
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
        # puts string
        end
      sublinks_last_level =  a.compact
      # puts sublinks_last_level
      # abort
    sublinks_last_level.map do |info_page|
      browser.goto(info_page)
      html_price =  browser.span(id: 'price_label').html
      html_name = browser.div(class: "detail-title-wrap").html
      product_info_name = Nokogiri::HTML.parse(html_name)
      product_info_price = Nokogiri::HTML.parse(html_price)
    #   puts product_info_price.css("[id='price_label']").text.delete(" ")
    #   puts product_info_name.css("h1").text.strip
    # abort

      #  собираем в массив все запарсенные товары категории( к примеру, все товары типа 'велосипеды')
      @all_products_category << parse_name_price_description(product_info_name, product_info_price) 
      end
      parameters = {"#{categorys_name}": @all_products_category}
      # params = {'Smadshop': parameters}
      @final_info << parameters
      # тут могу выводить в разные файлы по категориям товара, если это надо
      # File.open("#{categorys_name}.txt", "w") do |info|
      #  info.write(JSON.pretty_generate(parameters))
      #  end
  end
   
  def parse_name_price_description(product_info_name, product_info_price)  
    name = product_info_name.css('h1').text.strip
    puts name
    # проверяем есть ли товар или он закончился. Если закончился- ставим цену 0, к примеру, или можем написать , что товара нет
    price = product_info_price.css("[id='price_label']").text.delete(" ")
    puts price
    # есть 4 типа описания товара(данные специально записаны по разному)
    # поэтому делаю проверку по размеру массива данных   и по наличию класса product_specs_info
  
    parameters = {
      name:   name,
      price:  price      
    }
    Product.new(parameters)
    # w = NamePrice.new(parameters)
    # puts JSON.pretty_generate(w)
    # puts '-----------'
     #  непонятный неуловимый пробел во втором элементе
     # description.map do |element|
     #  puts element[1].start_with?(" ") 
     # end
  end
  #  метод, создающий общее имя категории
  def categorys_name
    html =  browser.div(id: 'catalog_title_block').html
    categorys_name_info = Nokogiri::HTML.parse(html)
    categorys_name = categorys_name_info.css('h1').text.strip
  end

end

Rozetka.new.start
