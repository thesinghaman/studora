class Logger {
  final dynamic _context;

  Logger(this._context);

  void info(String message, [Map<String, dynamic>? meta]) {
    _log('INFO', message, meta);
  }

  void error(String message, [dynamic error, StackTrace? stack]) {
    _context.error('ERROR: $message');
    if (error != null) _context.error('Details: $error');
    if (stack != null) _context.error('Stack: $stack');
  }

  void _log(String level, String message, [Map<String, dynamic>? meta]) {
    final timestamp = DateTime.now().toIso8601String();
    final metaString = meta != null ? ' | Meta: $meta' : '';
    _context.log('[$timestamp] [$level] $message$metaString');
  }
}
