# нулевой уровень - общий каталог товаров ( список, что на главной) ul class="box-category
# уровень с подкатегориями товаров div class="category-modlist 
# уровень 1 --  предпоследний - где список товаров данного типа -  div class="product-list' или div class: 'product-grid'
# в зависимости от вида отображения товаров
# уровень 2 -- нижний уровень, где описание товара в   div class="product-info"  название и цена( тут же собрал и х-ки)

require 'json'
require 'watir'
require 'nokogiri'
require 'open-uri'
require_relative 'lib/product.rb'

class Smadshop
  attr_accessor :browser

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
 
  def goto_page
    browser.goto('https://smadshop.md/')
    browser.window.maximize
  end

  def get_links   
    html =  browser.ul(class: 'box-category').html
    links_info = Nokogiri::HTML.parse(html)  
    #  беру ссылки только где  style, они ведут на общую категорию
    links = links_info.css('a[style]').map do |link|
      link.attribute('href').to_s
      end
    # убираю икею и услуги
    links.shift
    links.pop
    # круговая(поуровневая) проверка до того момента, когда масссив необработанных полностью ссылок будет пустым
    # структурно это так: главная категория(корневая) - нулевой уровень. получаем все ссылки, в которых могут быть и конечные ссылки,
    # и ссылки, где есть подкатегории. Конечные ссылки записываем в отдельный массив и потом в файл, что бы часами опять не ждать
    # их получение.
    # И прогоняем это по кругу , пока массив подкатегорий не будет  пустым, то есть
    # обработаем все подкатегории и получим из всех ссылки на категорию товара (пример - велосипеды, они сразу на нужномм уровне
    # (без подкатегорий) и можно сразу их заносить в массив ссылок, готовых к обработке).
    # максимальный уровень 4, но я сделал с запасом, на всякий случай, все равно выйдет из цикла раньше)
    #  код оставил, что бы более понятно было каков механизм, а сделал через рекурсию в итоге
    # loop do
    #   step0 = links
    #   break if step0.size == 0
    #   step1 = checking(step0)
    #   break if step1.size == 0
    #   step2 = checking(step1)
    #   break if step2.size == 0
    #   step3 = checking(step2)
    #   break if step3.size == 0
    #   step4 = checking(step3)
    #   break if step4.size == 0
    #   step5 = checking(step4)
    #   break if step5.size == 0
    #   step6 = checking(step5)
    #  break if step5.size == 0
    # end
    checking(links)
  end

  
  # получаем ссылки из файла
  def get_links_from_file
    file = File.read('/home/iuri/Ruby/Smadshop/Smadshop/Smadshop_sub_links.txt') 
    sublinks = JSON.parse(file)
  end
  # парсим количество страниц каждой категории товара и создаем ссылки на каждую из них
  def parse_pagination
    links = get_links_from_file
    links.map do |sublink|
      browser.goto(sublink)
      #  делаю отображение товара "Картинки"
      browser.element(id: 'a_view_grid').wait_until(&:present?).click
      html =  browser.div(class: 'pagination').html
      pagination_info = Nokogiri::HTML.parse(html)
      #  количество страниц берем отсюда <div class="results">Показано с 1 по 21 из 364 (всего 18 страниц)</div>
      number_of_pages = pagination_info.css("[class= 'results']").text.split(' ')[-2].to_i
      # устанавливаю  1,чтобы не крутил  все страницы каждого товара,хаватит и первой для наглядности
      # но проверил, все  ссылки отлично создаются и работают
      number_of_pages = 3
      pagination_links = Array.new(number_of_pages) {|i| sublink + '?page=' + (i+1).to_s}

      parse_products_same_category__info(pagination_links,categorys_name)
 
      params = {"Smadshop": @final_info} 
      File.open("/home/iuri/Ruby/Smadshop/Smadshop/data/Smadshop_rezult.txt", "w") do |info|
        info.write(JSON.pretty_generate(params))
        end
      end
  end

  def parse_products_same_category__info(pagination,categorys_name)
    @all_products_category = []   
    #   sublinks_last_level - последний уровень ссылок, по которым уже хранится вся инфа о товаре (описание ,название и цена)
    sublinks_last_level = pagination.map do |page|
      # browser.link(href: /#{page}/).wait_until(&:present?).click
      browser.goto(page)
      html =  browser.div(class: 'product-grid').html
      sublinks_last_level_info = Nokogiri::HTML.parse(html)     
      sublinks_last_level_info.css('a[href]').map do |element|
        element['href']
        end
      end
    sublinks_last_level.flatten!.uniq!  
    sublinks_last_level.map do |info_page|
      browser.goto(info_page)
      html =  browser.div(class: 'product-info').html
      product_info = Nokogiri::HTML.parse(html)
      #  собираем в массив все запарсенные товары категории( к примеру, все товары типа 'велосипеды')
      @all_products_category << parse_name_price_description(product_info) 
      end
      parameters = {"#{categorys_name}": @all_products_category}
      # params = {'Smadshop': parameters}
      @final_info << parameters
      # тут могу выводить в разные файлы по категориям товара, если это надо
      # File.open("#{categorys_name}.txt", "w") do |info|
      #  info.write(JSON.pretty_generate(parameters))
      #  end
  end
   
  def parse_name_price_description(product_info) 
    name = product_info.css('h1').text
    # проверяем есть ли товар или он закончился. Если закончился- ставим цену 0, к примеру, или можем написать , что товара нет
    check_product = product_info.css("[class='soldout_ttl']").text.match?(/Товар закончился/)
    if check_product == false
      price = product_info.css("[class = 'price-new']").text.to_f
    else
      price = 0
    end 
    # есть 4 типа описания товара(данные специально записаны по разному)
    # поэтому делаю проверку по размеру массива данных   и по наличию класса product_specs_info
    des = {}
    check_class = (browser.div class: 'product_specs_info').exists?
    description = product_info.css("[class = 'row'], [class = 'row odd']").map do |info|
      #  удаляю и разбиваю , данные в таком формате   "\n" + "Тип:  \n" + "двухколесный "
      info.text.tr("\n", "").strip.split(': ')
      end
    #  пример https://smadshop.md/telefony/panasonic-kx-ts2382uaw-white-telefon.html
    if description.size != 0
      des = Hash[description]
    #  пример https://smadshop.md/telefony/telefon-panasonic-kx-ts2350uaw.html
    elsif 
      if check_class == true
        html = browser.div(class: 'product_specs_info').html
        doc = Nokogiri::HTML(html)
        string = doc.css('div').text
        description = string.slice(string.index("\n")..-1).strip.split("\n").map do |element| 
          element.split(": ")
          end
        des = Hash[description]
      elsif
        html = browser.div(itemprop: "description").html
        check = Nokogiri::HTML(html)
        description = check.css('div').map do |info|
          info.text.strip.split(': ')
          end
        # пример https://smadshop.md/telefony/telefon-panasonic-kx-ts2388uab.html
        if description.size != 1  
          description.shift
          des = Hash[description]
        # пример https://smadshop.md/telefony/telefon-panasonic-kx-ts2350uaj.html
        else
          html = browser.div(itemprop: "description").html
          check = Nokogiri::HTML(html)
          string = check.css('p').text
          description = string.strip.split("\n").map do |element| 
            element.split(": ")
            end
          des = Hash[description]
        end
      end
    end
      
    description = Array[des]
    parameters = {
      name:   name,
      price:  price,
      description: description
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
    html =  browser.div(id: 'content').html
    categorys_name_info = Nokogiri::HTML.parse(html)
    categorys_name = categorys_name_info.css('h1').text
  end

def checking(value)
    @sub_links_not_ready = []
    sublinks = value.map do |sublink|
      browser.goto(sublink)
      #  прверяем на нужном ли мы уровне
      check_level = (browser.div id: 'listing_options').exists?
      #  проверяем, есть ли такой товар в наличии,  если его нет - есть строка class='content' В этой категории нет товаров.
      html_check_empty =  browser.div(id: 'content').html
      check = Nokogiri::HTML.parse(html_check_empty)
      check_empty = check.css("[class='content']").text.match?(/В этой категории нет товаров./)
       #  проверка на наличие такого товара . пример - https://smadshop.md/klimaticheskaya-tehnika/kaminnye-topki/
       # его мы просто пропускаем и идем на следующую ссылку
        if check_empty == true
          next
        elsif check_level == false
          # продолжаем получать линки субкатегорий'
          html =  browser.div(class: 'category-modlist').html
          sublinks_info = Nokogiri::HTML.parse(html)
          # для каждой категории получаем список субкатегорий 
          sublinks = sublinks_info.css('a[href]').map do |element|             
            element['href']
            end  
          @sub_links_not_ready << sublinks
          # sublinks.flatten
        elsif check_level == true
          @sub_links << sublink          
        end
    end    
    s = @sub_links.flatten.compact
    File.open("/home/iuri/Ruby/Smadshop/Smadshop/data/Smadshop_sub_links.txt", "w") do |info|
      info.write(JSON.pretty_generate(s))
      end
    #  рекурсия
    checking(@sub_links_not_ready.flatten.compact) if @sub_links_not_ready.flatten.compact.size != 0
  end

end

Smadshop.new.start
