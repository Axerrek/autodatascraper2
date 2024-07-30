# Dokumentacja projektu

## Opis

Projekt jest narzędziem do pobierania, przetwarzania i zapisywania danych dotyczących samochodów z pliku XML i stron internetowych w formacie CSV. Aplikacja pobiera linki z pliku XML, filtruje je, a następnie używa wielowątkowości do pobierania szczegółów o samochodach i zapisuje te dane w pliku CSV.

## Struktura projektu

Projekt składa się z kilku głównych komponentów:

- `Main`: Klasa odpowiedzialna za zarządzanie głównym procesem pobierania, przetwarzania i zapisywania danych.
- `Csv`: Klasa zajmująca się zapisywaniem danych do pliku CSV.
- `Fetcher`: Klasa odpowiedzialna za pobieranie danych z internetu i ich analizowanie.

## Jak to działa

1. **Pobieranie Linków**: Klasa `Fetcher` pobiera i analizuje plik XML z podanego URL-a, aby wyodrębnić linki do stron z danymi o samochodach.
2. **Filtrowanie Linków**: Wyodrębnione linki są filtrowane, aby zachować tylko te wartościowe.
3. **Przetwarzanie Linków**: Klasa `Main` używa wielowątkowości do przetwarzania linków. Pobiera parametry ze stron internetowych i aktualizuje zmienne instancyjne, w tym śledzi parametr z największą liczbą średników.
4. **Zapisywanie Danych**: Klasa `Csv` zapisuje przetworzone dane do pliku CSV.

## Instalacja

1. **Wymagania**: Upewnij się, że masz zainstalowane Ruby oraz gem `nokogiri`, `httparty` i `csv`. Możesz zainstalować je za pomocą:

   ```sh
   gem install nokogiri httparty csv
2. **Pobierz projekt**:

   ```sh
    git clone <URL_REPOZYTORIUM>
    cd <NAZWA_PROJEKTU> 
3. Uruchomienie projektu:

    ```sh
    ruby main.rb
