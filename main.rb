# frozen_string_literal: true
require_relative 'classes/csv'
require_relative 'classes/fetcher'
require 'thread'
require 'csv'
require 'set'

##
# Klasa Main jest odpowiedzialna za pobieranie, przetwarzanie i zapisywanie
# danych dotyczących samochodów z pliku XML i CSV.
class Main
  ##
  # Inicjalizuje nową instancję klasy Main.
  def initialize
    @xml_url = 'https://www.autocentrum.pl/sitemap/daneTechniczne.xml'
    @params = ''
    @csv_filename = 'dane.csv'
    @licznik = 0
    @max_semicolons = 0
    @max_semicolons_params = ''
    @mutex = Mutex.new
    @max_threads = 300
    @existing_links = Set.new
  end

  ##
  # Wczytuje istniejące linki z pliku CSV do zbioru @existing_links.
  def load_existing_links
    if File.exist?(@csv_filename)
      CSV.foreach(@csv_filename, headers: true, encoding: 'UTF-8') do |row|
        @existing_links.add(row['link'])  # Zakładam, że w pliku CSV jest kolumna o nazwie 'Link'
      end
    end
  end

  ##
  # Znajduje parametr z największą liczbą średników i aktualizuje zmienne instancyjne.
  #
  # [parameters] Parametr do sprawdzenia.
  # [link] Link związany z parametrem.
  def check_semicolons(parameters, link, brand, model, fullname)
    semicolons = parameters.count(';')
    @mutex.synchronize do
      if semicolons > @max_semicolons
        @max_semicolons = semicolons
        @max_semicolons_params = "link: #{link};marka: #{brand};model: #{model};nazwa: #{fullname};#{parameters}"
      end
    end
  end
  # Wyłuskuje markę, model oraz pełną nazwę z URL-a, zakładając, że URL zaczyna się od określonego base_url
  #
  # @param [String] link URL, z którego ma zostać wydobyta marka i model.
  # @return [Array<String, String, String>] Tablica zawierająca:
  #   - Markę wydobyta z URL-a (lub nil, jeśli URL nie pasuje do oczekiwanego wzorca).
  #   - Model wydobyty z URL-a (lub nil, jeśli URL nie pasuje do oczekiwanego wzorca).
  #   - Pozostałą część ścieżki URL-a po usunięciu base_url (lub nil, jeśli URL nie pasuje do oczekiwanego wzorca).
  def extract_brand_and_model(link)
    # Zakładamy, że link jest poprawny i ma odpowiednią strukturę
    base_url = "https://www.autocentrum.pl/dane-techniczne/"
    if link.start_with?(base_url)
      # Usuń część base_url
      path = link.sub(base_url, "")
      # Rozdziel ścieżkę na części
      parts = path.split("/")
      # Zakładamy, że marka i model są na pierwszej i drugiej pozycji
      brand = parts[0]
      model = parts[1]
      return [brand, model, path]
    else
      return [nil, nil, nil]
    end
  end
  ##
  # Pobiera parametry ze strony pod danym linkiem i przetwarza je.
  #
  # [link] Link do strony z parametrami.
  def process_link(link)
    puts "link nieodrzucony?"
    return if @existing_links.include?(link)
    puts "tak"
    @mutex.synchronize { @licznik += 1 }
    brand, model, fullname = extract_brand_and_model(link)
    parameters = Fetcher.extract_parameters(link)
    if !parameters.nil? && !parameters.empty?
      check_semicolons(parameters, link, brand, model, fullname)
      @mutex.synchronize do
        @params += "link: #{link};marka: #{brand};model: #{model};nazwa: #{fullname};#{parameters}\n"
        puts @licznik
      end
    end
  end



  ##
  # Główna metoda uruchamiająca proces pobierania i przetwarzania danych.
  def run
    load_existing_links
    links = Fetcher.extract_links_from_xml(@xml_url)
    valuable_links = Fetcher.filter_valuable_links(links)

    thread_pool = []
    queue = Queue.new
    valuable_links.each { |link| queue << link }

    # Start wątków
    @max_threads.times do
      thread_pool << Thread.new do
        while true
          link = queue.pop(true) rescue nil
          break if link.nil?
          process_link(link)
        end
      end
      ensure
      csv = Csv.new(@params, @max_semicolons_params)
      csv.save_to_csv(@csv_filename)
    end

    # Czekaj na zakończenie wszystkich wątków
    thread_pool.each(&:join)

    csv = Csv.new(@params, @max_semicolons_params)
    csv.save_to_csv(@csv_filename)
  end
end

main = Main.new
main.run
