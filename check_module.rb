module Check_module
  
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
    File.open("./results/Smadshop_sub_links.txt", "w") do |info|
      info.write(JSON.pretty_generate(s))
      end
    #  рекурсия
    checking(@sub_links_not_ready.flatten.compact) if @sub_links_not_ready.flatten.compact.size != 0

  end
end