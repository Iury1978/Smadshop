# нулевой уровень - общий каталог товаров ( список, что на главной) ul class="box-category
# уровень с подкатегориями товаров div class="category-modlist 
# уровень 1 --  предпоследний - где список товаров данного типа -  div class="product-list' или div class: 'product-grid'
# в зависимости от вида отображения товаров
# уровень 2 -- нижний уровень, где описание товара в   div class="product-info"  название и цена( тут же собрал и х-ки)

require 'json'
require 'watir'
require 'nokogiri'
require 'open-uri'
require_relative '../lib/product.rb'
require "sqlite3"

class Smadshop

  def initialize
    @browser = Watir::Browser.new :chrome
    @db = SQLite3::Database.new "../data/smadshop.db"
  end

  def start
    # отключил goto_page и get_links только записывают инфу в файл.
    # что бы не ждать  весь цикл получения ссылок их можно отключить и сразу обрабатывать записаныне
    #  в файле  БД smadshop.bd 
    # goto_page
    # get_links
    parse_pagination  def parse_accounts
    get_accounts_id.map do |acc_id|
      @browser.li(data_semantic_account_number: "#{acc_id}").wait_until(&:present?).click
      html = @browser.div(data_semantic: "account").html
      account_info = Nokogiri::HTML.parse(html)

      @accounts << parse_account(account_info, acc_id)
      end
    full_accounts_information = { accounts: @accounts }
    puts JSON.pretty_generate(full_accounts_information)
    # File.new("bendigobank_result.txt", "w")
    File.open("../data/bendigobank_result.txt", "w") do |info|
      info.write(JSON.pretty_generate(full_accounts_information))
    end
  end
  end

  def create_db
    @db = SQLite3::Database.new "../data/smadshop.db"
    # сначала создаем только таблицу links, потом из нее будем читать данные и создавать другие таблицы
    @db.execute "CREATE TABLE IF NOT EXISTS main.Links (Link_name TEXT)"
  end
 
  def goto_page
    @browser.goto('https://smadshop.md/')
    @browser.window.maximize
  end

  def get_links   
    html =  @browser.ul(class: 'box-category').html
    links_info = Nokogiri::HTML.parse(html)  
    #  беру ссылки только где  style, они ведут на общую категорию
    links = links_info.css('a[style]').map do |link|
      link.attribute('href').to_s
      end
    # убираю икею и услуги
    links.shift
    links.pop
    checking(links)
  end
  
  # получаем ссылки из базы данных
  def get_links_from_db
  links = @db.execute "SELECT * FROM main.Links"
  links.flatten
  end
  # парсим количество страниц каждой категории товара и создаем ссылки на каждую из них
  def parse_pagination
    #  создаем таблицу Shops, пока с одим магазином
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS Shops (
      shop_id INTEGER PRIMARY KEY AUTOINCREMENT,
      shop_name TEXT,
      UNIQUE(shop_name)
      );
      SQL
    @db.execute <<-SQL
      INSERT OR IGNORE INTO Shops (shop_name)  VALUES ("smadshop") ;
      SQL
      
    links = get_links_from_db
    links.map do |sublink|
      @browser.goto(sublink)
      #  делаю отображение товара "Картинки"
      @browser.element(id: 'a_view_grid').wait_until(&:present?).click
      html =  @browser.div(class: 'pagination').html
      pagination_info = Nokogiri::HTML.parse(html)
      #  количество страниц берем отсюда <div class="results">Показано с 1 по 21 из 364 (всего 18 страниц)</div>
      number_of_pages = pagination_info.css("[class= 'results']").text.split(' ')[-2].to_i
      # устанавливаю  1,чтобы не крутил  все страницы каждого товара,хаватит и первой для наглядности
      # но проверил, все  ссылки отлично создаются и работают
      number_of_pages = 1
      pagination_links = Array.new(number_of_pages) {|i| sublink + '?page=' + (i+1).to_s}

      parse_products_same_category__info(pagination_links,categorys_name)
      end
  end

  def parse_products_same_category__info(pagination,categorys_name)
    # массив всех товаров определенной категории
    @all_products_category = []   
    #   sublinks_last_level - последний уровень ссылок, по которым уже хранится вся инфа о товаре (описание ,название и цена)
    sublinks_last_level = pagination.map do |page|
      # @browser.link(href: /#{page}/).wait_until(&:present?).click
      @browser.goto(page)
      html =  @browser.div(class: 'product-grid').html
      sublinks_last_level_info = Nokogiri::HTML.parse(html)     
      sublinks_last_level_info.css('a[href]').map do |element|
        element['href']
        end
      end
    sublinks_last_level.flatten!.uniq!  
    sublinks_last_level.map do |info_page|
      @browser.goto(info_page)
      html =  @browser.div(class: 'product-info').html
      product_info = Nokogiri::HTML.parse(html)
      #  собираем в массив все запарсенные товары категории( к примеру, все товары типа 'велосипеды')
      @all_products_category << parse_name_price(product_info) 
      end
    
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS Category (
      category_id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_name TEXT,
      shop_id
      UNIQUE(shop_name)
      );
      SQL
    @db.execute <<-SQL
      INSERT OR IGNORE INTO Shops (shop_name)  VALUES ("smadshop") ;
      SQL

    # @db.execute <<-SQL
    #   CREATE TABLE IF NOT EXISTS main.Category(
    #   category_id INTEGER PRIMARY KEY   AUTOINCREMENT,
    #   category_name TEXT,
    #   shop_id INTEGER
    #   );
    #   SQL
    #   # @db.execute "CREATE TABLE IF NOT EXISTS main.VVV (Name TEXT, Price REAL)"
    #   @db.execute "INSERT OR IGNORE INTO Category ( category_name ) VALUES (?)", [categorys_name]
      

    # @all_products_category.map do |a|
    #   @db.execute <<-SQL
    #   CREATE TABLE IF NOT EXISTS main.Чехлы_для_мебели(
    #   Name TEXT,
    #   Price REAL,
    #   UNIQUE(Name)
    #   );
    #   SQL
    #   # @db.execute "CREATE TABLE IF NOT EXISTS main.VVV (Name TEXT, Price REAL)"
    #   @db.execute "INSERT OR IGNORE INTO Чехлы_для_мебели ( Name, Price ) VALUES (?, ?)", [a.name, a.price]
    #   end


    #    abort
  end
   
  def parse_name_price(product_info) 
    name = product_info.css('h1').text
    # проверяем есть ли товар или он закончился. Если закончился- ставим цену 0, к примеру, или можем написать , что товара нет
    check_product = product_info.css("[class='soldout_ttl']").text.match?(/Товар закончился/)
    if check_product == false
      price = product_info.css("[class = 'price-new']").text.to_f
    else
      price = 0
    end 

    parameters = {
      name:   name,
      price:  price
    }
    Product.new(parameters)

  end
  #  метод, создающий общее имя категории
  def categorys_name
    html =  @browser.div(id: 'content').html
    categorys_name_info = Nokogiri::HTML.parse(html)
    categorys_name = categorys_name_info.css('h1').text
  end

def checking(value)
    @sub_links_not_ready = []
    sublinks = value.map do |sublink|
      @browser.goto(sublink)
      #  прверяем на нужном ли мы уровне
      check_level = (@browser.div id: 'listing_options').exists?
      #  проверяем, есть ли такой товар в наличии,  если его нет - есть строка class='content' В этой категории нет товаров.
      html_check_empty =  @browser.div(id: 'content').html
      check = Nokogiri::HTML.parse(html_check_empty)
      check_empty = check.css("[class='content']").text.match?(/В этой категории нет товаров./)
        #  проверка на наличие такого товара . пример - https://smadshop.md/klimaticheskaya-tehnika/kaminnye-topki/
        # его мы просто пропускаем и идем на следующую ссылку
        if check_empty == true
          next
        elsif check_level == false
          # продолжаем получать линки субкатегорий'
          html =  @browser.div(class: 'category-modlist').html
          sublinks_info = Nokogiri::HTML.parse(html)
          # для каждой категории получаем список субкатегорий 
          sublinks = sublinks_info.css('a[href]').map do |element|             
            element['href']
            end  
          @sub_links_not_ready << sublinks
          # sublinks.flatten
        elsif check_level == true
          @sub_links << sublink  
          # записываем каждую полученную ссылку непосредственно в БД smadshop.db в таблицу links
          save_link_to_db(sublink)
        end
    end    
    checking(@sub_links_not_ready.flatten.compact) if @sub_links_not_ready.flatten.compact.size != 0
  end
  # метод записи всех конечных ссылок на категории товаров в БД
  def save_link_to_db(sublink)
    # в таком виде выдает синтаксическую ошибку near "UNIQUE": syntax error (SQLite3::SQLException)
    # так и не понял, что ему не нравится и написал по другому..
    # @db.execute "CREATE TABLE IF NOT EXISTS main.Links (Link_name TEXT) UNIQUE(Link_name)"    
    @db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS main.Links(
    Link_name TEXT,
    UNIQUE(Link_name)
    );
    SQL
    @db.execute "INSERT OR IGNORE INTO Links ( Link_name ) VALUES ( '#{sublink}' )"
  end


end

# Smadshop.new.start
