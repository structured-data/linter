// Programatic markup for RDFa linter
$(function () {
  // Insert explanatory header
  $('body').prepend(
      $("<header><h1>RDF.rb Distiller Results</h1></header>")
  );
  $('body').append(
      $('<footer>Distilled by <a href="http://linter.kellogg-assoc.com">Structured Data Linter</a> using <a href="http://rdf.rubyforge.org/rdfa">RDF::RDFa Reader</a></footer>')
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
