
import 'dart:collection';

Map<String, int> precedence = { 
  '=': -100, 
  '(': 0, 
  ')': 0, 
  '.': 10, 
  '+': 1, 
  '-': 1, 
  '*': 2, 
  '/': 2,
  '%': 3,

  '&&': 4,
  '||': 4,

  '>': 5,
  '>=': 5,
  '<': 5,
  '<=': 5,
  '==': 5,
  '!=': 5,
};

HashSet<String> keywords = { 'func', 'while', 'if', 'for', 'return', 'in', 'print', 'else' } as HashSet<String>;

// if something is not a number and not a keyword and not a operator then its a identifier
bool isIdentifier(String token) => 
  (int.tryParse(token) == null && !keywords.contains(token) && !precedence.containsKey(token));