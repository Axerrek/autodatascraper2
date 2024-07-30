# frozen_string_literal: true

require 'csv'

# Klasa odpowiedzialna za zapis parametrów do pliku CSV.
#
# Ta klasa przyjmuje dane w formacie tekstowym, przetwarza je i zapisuje do pliku CSV.
# Parametry są przechowywane w atrybutach instancji i używane do tworzenia kolumn oraz
# wypełniania wierszy w pliku CSV.
class Csv
  # Atrybuty instancji
  attr_accessor :params, :max_semicolons_parameters

  # Inicjalizuje nowy obiekt Csv.
  #
  # [params] Parametry w formacie tekstowym, które mają być zapisane do pliku CSV.
  #
  # [max_semicolons_parameters] Parametry z największą liczbą średników, używane do generowania nagłówków kolumn.
  def initialize(params, max_semicolons_parameters)
    @params = params
    @max_semicolons_parameters = max_semicolons_parameters
  end

  # Wyciąga nagłówki kolumn z parametrów.
  #
  # Metoda dzieli łańcuch z maksymalną liczbą średników na pary klucz-wartość,
  # wyciąga klucze i zwraca unikalne nagłówki kolumn.
  #
  # @return [Array<String>] Tablica unikalnych nagłówków kolumn.
  def extract_columns
    columns = @max_semicolons_parameters.split(';').map do |pair|
      key, _ = pair.split(':', 2)
      key.strip
    end
    columns.uniq
  end

  # Zapisuje parametry do pliku CSV.
  #
  # Metoda najpierw ekstraktuje kolumny, a następnie tworzy plik CSV,
  # zapisując wiersze z danymi. Dla każdego wiersza sprawdza dostępność kluczy
  # i dodaje odpowiednie wartości, a jeśli klucz jest nieobecny, wstawia "brak danych".
  #
  # Plik CSV jest zapisywany pod nazwą podaną w parametrze.
  #
  # [filename] Nazwa pliku, do którego zostaną zapisane dane w formacie CSV.
  def save_to_csv(filename)
    columns = extract_columns
    CSV.open(filename, 'w:UTF-8', write_headers: true, headers: columns) do |csv|
      @params.split("\n").each do |line|
        next if line.strip.empty?
        row = columns.map do |col|
          entry = line.split(';').find { |pair| pair.start_with?(col) }
          entry ? entry.split(':', 2).last.to_s.strip : 'brak danych'
        end
        csv << row
      end
    end
  end
end
