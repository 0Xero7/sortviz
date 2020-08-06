
List<RegExp> patterns = [
  RegExp(r'\b[0-9]+\b'),
  RegExp(r'(\+|\-|\*|\/|%|(>=)|(<=)|(==)|(!=)|>|<|=|\(|\)|{|}|\;)'),
  RegExp(r'\b([a-zA-Z_]+[a-zA-Z0-9_]*)\b'),
];

final RegExp whitespace = RegExp(r'[ \n\t]');

List<String> lex(String source) {
  var tokens = List<String>();

  var _token = "";
  var newToken = "";
  for (int i = 0; i < source.length; ++i) {
    newToken += source[i];

    bool match = false;
    for (var exp in patterns) {
      if (exp.stringMatch(newToken)?.length == newToken.length) { match = true; break; }
    }

    if (match) { _token = newToken; continue; }
    if (_token.trim() != '') { tokens.add(_token); _token = ""; }

    if (source[i] == ' ' || source[i] == '\t' || source[i] == '\n')
      newToken = "";
    else {
      newToken = source[i];
      _token = newToken;
    }
  }

  if (newToken.trim() != '') tokens.add(newToken);

  return tokens;
}