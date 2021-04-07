# Smadshop

Эта программа создана исключительно в учебных целях. Цель ее - изучение сбора и обработки данных с интернет-магазина на примере smadshop.md

## Требования

- Ruby 2.6.3
- JSON
- watir
- nokogiri
- open-uri

## Запуск

Запуск программы происходит Smadshop/bin ./smadshop

В данный момент в программе отключены 2 метода  goto_page и get_links, собирающие информацию о  адресах всех страниц с товаром для ускорения обработки конечных данных
При их включении будет происходить обход всего ресурса и сбор конечных адресов в файл /data/Smadshop_rezult.txt.

В данный момент мы считаем, гто адреса уже были собраны в /data/Smadshop_sublinks.txt. и  подгружаем их из этого файла для дальнейшей обработки.

Так же в папке бин находятся 2 файла
- rozetka - для сбора данных только по телефонам (тольк 3 страницы, просто для демонстрации)
- price_comparsion - дл сравнения цен на товары в этих 2 магазинах.

price_comparsion исползует упрощенные данные из файлов /data/Smadshop_rezult_simple.txt /data/Rozetka_rezult_simple.txt .
В них ключи имеют одинаковые знвчения для обоих магазинов  и результат сравнения цен записывается в файл /data/price_comparsion.txt.

## Вспомогательные файлы

`/data/html/`
хранятся примеры кода страниц на определенных этапах парсинга для наглядности и чтения информации
