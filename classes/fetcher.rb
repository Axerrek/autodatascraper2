require 'nokogiri'
require 'httparty'

# Klasa odpowiedzialna za pobieranie i analizowanie danych z internetu.
#
# Klasa `Fetcher` dostarcza metody do pobierania plików XML, wyciągania linków, filtrowania linków
# oraz analizowania stron samochodowych, aby wydobyć szczegółowe parametry.
class Fetcher
  # Pobiera i parsuje plik XML z URL-a, wyciąga linki.
  #
  # Ta metoda łączy się z podanym URL-em, pobiera zawartość XML, a następnie
  # wykorzystuje bibliotekę Nokogiri do analizy i ekstrakcji linków z elementów `<url><loc>`.
  #
  # [xml_url] URL pliku XML, który ma być pobrany i analizowany.
  #
  # @return [Array<String>] Tablica linków wyciągniętych z pliku XML. Jeśli wystąpił błąd, zwracana jest pusta tablica.
  def self.extract_links_from_xml(xml_url)
    response = HTTParty.get(xml_url)
    if response.success?
      doc = Nokogiri::XML(response.body)
      doc.remove_namespaces!
      links = doc.xpath('//url/loc').map(&:text).map(&:strip)
      links
    else
      puts "Błąd pobierania pliku XML: #{response.code} - #{response.message}"
      []
    end
  end

  # Filtruje linki, zachowując tylko te z 6 lub więcej znakami '/'.
  #
  # Ta metoda przyjmuje tablicę linków i zwraca tylko te, które zawierają
  # co najmniej 6 znaków '/' (co oznacza co najmniej 5 segmentów w URL-u).
  #
  # [links] Tablica linków do przefiltrowania.
  # @return [Array<String>] Tablica linków, które zawierają co najmniej 6 znaków '/'.
  def self.filter_valuable_links(links)
    links.select { |link| link.count('/') >= 6 }
  end

  # Pobiera i analizuje stronę samochodu, wydobywając parametry.
  #
  # Ta metoda łączy się z podanym URL-em, pobiera zawartość strony, a następnie
  # wykorzystuje Nokogiri do analizy HTML i wydobywania parametrów samochodu z elementów
  # z klasami `.dt-row`, `.dt-row__text`, oraz `.dt-param-value`.
  #
  # Metoda obsługuje błędy HTTP i próbuje ponownie w przypadku niepowodzenia, do maksymalnie 100 prób.
  #
  # [link] URL strony samochodu, którą należy pobrać i przeanalizować.
  # @return [String] Łańcuch parametrów w formacie "label: value;", gdzie `value` to wartość parametru lub "brak danych",
  #                   jeśli wartość nie jest dostępna. W przypadku błędów i przekroczenia maksymalnej liczby prób, zwracany jest komunikat o błędzie.
  def self.extract_parameters(link)
    max_attempts = 100
    attempts = 0

    begin
      attempts += 1
      response = HTTParty.get(link)
      if response.success?
        doc = Nokogiri::HTML(response.body)

        data_strings = ""
        doc.css('.dt-row').each do |row|
          label_element = row.at_css('.dt-row__text')
          value_element = row.at_css('.dt-param-value')
          if label_element && value_element
            label = label_element['data-label'] || label_element.text.strip
            value = value_element && !value_element.text.strip.empty? ? value_element.text.strip : 'brak danych'
            data_strings += "#{label}: #{value};"
          end
        end
        return data_strings
      else
        puts "Błąd HTTP: #{response.code} - URL: #{link}, próba #{attempts}"
        raise "HTTP error"
      end

    rescue => e
      puts "Błąd: #{e.message} - URL: #{link}, próba #{attempts}"
      sleep(attempts / 5.0)
      retry if attempts < max_attempts
      'Błąd w pobieraniu danych'
    end
  end
end
