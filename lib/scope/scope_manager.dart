
import 'dart:collection';
import 'dart:math';

import 'package:sortviz/ast/astidentifier.dart';

class _Scope {
  int id;
  int parentId;
  HashMap<String, ASTIdentifier> identifiers;

  _Scope(this.id, this.parentId) {
    identifiers = HashMap<String, ASTIdentifier>();
  }

  bool contains(String name) => this.identifiers.containsKey(name);

  ASTIdentifier getIdentifier(String name) {
    if (this.identifiers.containsKey(name)) return this.identifiers[name];
    return null;
  }

  void setIdentifier(String name, {ASTIdentifier value}) {
    this.identifiers[name] = value;
    if (value == null) this.identifiers[name] = ASTIdentifier(name: name);
  }
}

class ScopeManager {
  HashMap<int, _Scope> scopes;
  int activeScope;

  ListQueue<int> scopeStack;

  ScopeManager() {
    scopes = HashMap<int, _Scope>();
    scopeStack = ListQueue<int>();

    // add a default global scope
    scopes[0] = _Scope(0, -1);
    activeScope = 0;

    scopeStack.add(0);
  }

  ASTIdentifier tryGet(String name) {
    int currentID = activeScope;

    while (currentID != -1) {
      if (scopes[currentID].contains(name)) return scopes[currentID].getIdentifier(name);
      currentID = scopes[currentID].parentId;
    }

    throw Exception('Identifier $name not defined.');
  }

  int _getDescendantScopeWhereExists(String name) {
    int currentID = activeScope;

    while (currentID != -1) {
      if (scopes[currentID].contains(name)) return currentID;
      currentID = scopes[currentID].parentId;
    }
    return null;
  }

  void setInScope(String name, {ASTIdentifier value}) {
    var _scopedQuery = _getDescendantScopeWhereExists(name);
    _scopedQuery ??= activeScope;
    
    scopes[_scopedQuery].setIdentifier(name, value: value);
    // else _scopedQuery.value = value;
  }

  void pushScopeToRoot() {
    int newID = Random.secure().nextInt(100000);
    while (scopes.containsKey(newID)) newID = Random.secure().nextInt(100000);

    // add a new scope with global scope as the parent 
    scopes[newID] = _Scope(newID, 0);
    scopeStack.add(newID);
    activeScope = newID;
  }

  void pushScopeToCurrent() {
    int newID = Random.secure().nextInt(100000);
    while (scopes.containsKey(newID)) newID = Random.secure().nextInt(100000);

    // add a new scope with global scope as the parent 
    scopes[newID] = _Scope(newID, activeScope);
    scopeStack.add(newID);
    activeScope = newID;
  }

  void popScope() {
    scopes.remove(activeScope);
    scopeStack.removeLast();
    activeScope = scopeStack.last;
  }
}