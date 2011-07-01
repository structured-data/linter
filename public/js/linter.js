// Programatic markup for Structured Data linter
$(function () {
  // Insert explanatory header
  $('body').prepend(
      $("<header><h1>Structured Data Linter Results</h1></header>")
  );
  $('body').append(
      $('<footer>Distilled by <a href="http://linter.structured-data.org">Structured Data Linter</a></footer>')
  );
  $('div[about]').each(function() {
      $(this).prepend($("<h2>").text('About: ' + $(this).attr('about')));
  });
  $('div[resource]').each(function() {
      $(this).prepend($("<h2>").text('Resource: ' + $(this).attr('resource')));
  });
  // Add language identifier
  $('li[lang]').each(function() {
     var lang = $(this).attr('lang');
     $(this).prepend($("<span class='lang'>" + lang + ": </span>"));
  });
});
