class ResponseHelper {
  final dynamic _context;

  ResponseHelper(this._context);

  dynamic success(dynamic data, {String message = 'Success'}) {
    return _context.res.json({
      'success': true,
      'message': message,
      'data': data,
    });
  }

  dynamic error({
    required String message,
    int statusCode = 400,
    String? code,
    dynamic details,
  }) {
    return _context.res.json({
      'success': false,
      'error': {
        'message': message,
        'code': code ?? 'UNKNOWN_ERROR',
        'details': details,
      }
    }, statusCode);
  }
}
