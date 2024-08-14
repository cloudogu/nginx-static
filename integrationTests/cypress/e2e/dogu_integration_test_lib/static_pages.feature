Feature: Searches for the custom HTML page

    Scenario: entering the resource URL into browser and opening the static HTML page
      When the user requests the static HTML page
      Then a static HTML page gets displayed

    Scenario: entering the resource URL of a unknown dogu into browser
      When the user requests the unknown dogu
      Then a static 404 HTML page gets displayed