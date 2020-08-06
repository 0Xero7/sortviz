
List<String> lex(String source) {
  var tokens = List<String>();

  var temp = source.split(new RegExp('[\n\t ]'));
  for (var i in temp)
    if (i.trim() != '')
      tokens.add(i.trim());

  return tokens;
}