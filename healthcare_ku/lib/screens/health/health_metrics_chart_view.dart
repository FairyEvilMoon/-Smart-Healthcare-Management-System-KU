import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class HealthMetricsChartView extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const HealthMetricsChartView({Key? key, required this.data})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String htmlContent = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <script src="https://cdnjs.cloudflare.com/ajax/libs/react/18.2.0/umd/react.production.min.js"></script>
          <script src="https://cdnjs.cloudflare.com/ajax/libs/react-dom/18.2.0/umd/react-dom.production.min.js"></script>
          <script src="https://cdnjs.cloudflare.com/ajax/libs/recharts/2.12.0/Recharts.js"></script>
        </head>
        <body>
          <div id="root"></div>
          <script>
            const data = ${jsonEncode(data)};
            // Your React component code will be injected here
          </script>
        </body>
      </html>
    ''';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(htmlContent);

    return SizedBox(
      height: 300,
      child: WebViewWidget(controller: controller),
    );
  }
}
