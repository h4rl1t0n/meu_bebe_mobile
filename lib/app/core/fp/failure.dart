class Failure implements Exception {
  final String message;
  const Failure({this.message = ''});
}

class CustomMessageError extends Failure {
  const CustomMessageError(String message) : super(message: message);

  static CustomMessageError getMessage(String error) {
    return CustomMessageError(error);
  }
}
