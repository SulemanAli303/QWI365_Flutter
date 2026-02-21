import '../utils/api_urls.dart';

class SoapHelper {
  static String buildEnvelope(String methodName, Map<String, dynamic> params) {
    StringBuffer p = StringBuffer();
    params.forEach((key, value) {
      p.write('<$key>$value</$key>');
    });

    return '<?xml version="1.0" encoding="utf-8"?>'
        '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xmlns:xsd="http://www.w3.org/2001/XMLSchema" '
        'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'
        '<soap:Body>'
        '<$methodName xmlns="${ApiUrls.namespace}">'
        '${p.toString()}'
        '</$methodName>'
        '</soap:Body>'
        '</soap:Envelope>';
  }
}
