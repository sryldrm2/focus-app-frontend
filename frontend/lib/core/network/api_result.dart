class ApiResult<T> {
  final bool success;
  final String? message;
  final T? data;

  const ApiResult({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object? raw) fromData,
  ) {
    return ApiResult<T>(
      success: json['success'] == true,
      message: json['message'] as String?,
      data: json.containsKey('data') ? fromData(json['data']) : null,
    );
  }
}