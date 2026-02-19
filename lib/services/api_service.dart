import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://carbon.expert365.com.au/Aqua365.asmx";

  Future<SharedPreferences> getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future<String?> soapRequest({
    required String operation,
    required String body,
  }) async {
    final String soapMessage =
        """
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    $body
  </soap:Body>
</soap:Envelope>
""";
log(  "Constructed SOAP message for operation: $operation with body: $body");
    try {
      final response = await http.post(
        Uri.parse("$baseUrl?op=$operation"),
        headers: {
          "Content-Type": "text/xml; charset=utf-8",
          "SOAPAction": "http://tempuri.org/$operation",
          "Host": "carbon.expert365.com.au",
        },
        body: soapMessage,
      );log(  "SOAP request sent for operation: $operation with body: $body");

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  String parseSoapResponse(String responseBody, String operation) {
    final document = XmlDocument.parse(responseBody);
    final result = document
        .findAllElements("${operation}Result")
        .first
        .innerText;
    return result;
  }
}
