import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'app_exceptions.dart';
import 'base_api_service.dart';
import 'soap_helper.dart';

class NetworkApiService extends BaseApiServices {
  @override
  Future getGetApiResponse(String url) async {
    dynamic responseJson;
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      responseJson = returnResponse(response);
    } on SocketException {
      throw NoInternetException('No Internet Connection');
    }
    return responseJson;
  }

  @override
  Future getPostApiResponse(
    String url, {
    required String soapAction,
    required Map<String, dynamic> params,
  }) async {
    dynamic responseJson;

    // Get the method name from the soapAction if possible, or just use the one passed in params if we changed the interface
    // For simplicity, we'll assume the URL or action contains the method name or use a separate field
    // Let's refine the interface to pass the methodName explicitly or derive it.
    // In our case, the methodName is usually the last part of the SOAP action or explicitly known.

    // For this implementation, we'll assume 'params' contains a special key '_methodName'
    // or we'll pass it separately. Let's update the interface slightly for better usability.

    String methodName = params.remove('_methodName') ?? '';
    String soapBody = SoapHelper.buildEnvelope(methodName, params);

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'text/xml; charset=utf-8',
              'SOAPAction': soapAction,
            },
            body: soapBody,
          )
          .timeout(const Duration(seconds: 20));

      responseJson = returnResponse(response);
    } on SocketException {
      throw NoInternetException('No Internet Connection');
    }

    return responseJson;
  }

  dynamic returnResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return response.body;
      case 400:
        throw BadRequestException(response.body.toString());
      case 404:
        throw AppException(response.body.toString(), 'Not Found');
      case 500:
        throw FetchDataException(
          'Error occurred while communicating with server with status code : ${response.statusCode}',
        );
      default:
        throw FetchDataException(
          'Error occurred while communicating with server with status code : ${response.statusCode}',
        );
    }
  }

  // Helper method to parse SOAP response and extract inner JSON/String
  static dynamic parseSoapResponse(
    String responseBody,
    String resultElementName,
  ) {
    try {
      final document = XmlDocument.parse(responseBody);
      final resultElement = document.findAllElements(resultElementName).first;
      final resultText = resultElement.innerText;

      // Check if it's a JSON string
      if (resultText.startsWith('[') || resultText.startsWith('{')) {
        return jsonDecode(resultText);
      }
      return resultText;
    } catch (e) {
      throw FetchDataException('Failed to parse SOAP response: $e');
    }
  }
}
