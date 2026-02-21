abstract class BaseApiServices {
  Future<dynamic> getGetApiResponse(String url);
  Future<dynamic> getPostApiResponse(
    String url, {
    required String soapAction,
    required Map<String, dynamic> params,
  });
}
