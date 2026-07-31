class PadelBackendMock {
  PadelBackendMock.seeded() : _addedByMe = {}, _addedMe = {};

  final Set<String> _addedByMe;
  final Set<String> _addedMe;

  Set<String> get addedByMe => Set.unmodifiable(_addedByMe);
  Set<String> get addedMe => Set.unmodifiable(_addedMe);

  bool isAddedByMe(String accountId) => _addedByMe.contains(accountId);

  bool isAddedMe(String accountId) => _addedMe.contains(accountId);

  bool isMutual(String accountId) {
    return _addedByMe.contains(accountId) && _addedMe.contains(accountId);
  }

  void addByMe(String accountId) {
    _addedByMe.add(accountId);
  }

  void removeByMe(String accountId) {
    _addedByMe.remove(accountId);
  }

  void addIncoming(String accountId) {
    _addedMe.add(accountId);
  }

  void removeIncoming(String accountId) {
    _addedMe.remove(accountId);
  }
}
