import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebContainer extends StatefulWidget {
  final url;

  WebContainer(this.url);

  @override
  _WebContainerState createState() => _WebContainerState(this.url);
}

class _WebContainerState extends State<WebContainer> {
  Future<bool> _onBackPressed() {
    return showDialog(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (context) => new AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            title: new Text("Exit Chase Client App?"),
            content: new Text("Do you want to close the App?"),
            actions: <Widget>[
              FlatButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  "No",
                  style: TextStyle(fontSize: 16.0, color: Colors.red),
                ),
              ),
              FlatButton(
                onPressed: () => SystemChannels.platform
                    .invokeMethod<void>('SystemNavigator.pop'),
                child: Text(
                  "Yes",
                  style: TextStyle(fontSize: 16.0, color: Colors.blue),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  var _url;
  final _key = UniqueKey();

  _WebContainerState(this._url);

  @override
  void initState() {
    super.initState();
  }

  WebViewController _myController;
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  String result = "VIN Scan";

  Future _scanQR() async {
    try {
      String qrResult = await BarcodeScanner.scan();
      setState(() {
        result = qrResult;
        debugPrint("ScanResult: $result");
      });
    } on PlatformException catch (ex) {
      if (ex.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          result = "Error:Camera permission was denied";
        });
      } else {
        setState(() {
          result = "Error:Unknown Error $ex";
        });
      }
    } on FormatException {
      setState(() {
        result = "Error:You pressed the back button before scanning anything";
      });
    } catch (ex) {
      setState(() {
        result = "Error:Unknown Error $ex";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
        onWillPop: _onBackPressed,
        child: new Scaffold(
          // We're using a Builder here so we have a context that is below the Scaffold
          // to allow calling Scaffold.of(context) so we can show a SnackBar.
          body: Builder(builder: (BuildContext context) {
            return WebView(
              key: _key,
              initialUrl: _url,
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) {
                _controller.complete(webViewController);
                _myController = webViewController;
                _myController.clearCache();
              },
              // ignore: prefer_collection_literals
              javascriptChannels: <JavascriptChannel>[
                _toasterJavascriptChannel(context),
                _scanVINJavascriptChannel(context),
              ].toSet(),
              onPageStarted: (String url) {
                print('Page started loading: $url');
              },
              onPageFinished: (String url) {
                print('Page finished loading: $url');
                setState(() {
                  //_loadedPage = true;
                });
                _myController.evaluateJavascript(
                    'document.body.classList.add("client-app-view");');
              },
              gestureNavigationEnabled: true,
            );
          }),
        ));
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) async {
          showSnackBar(context, message.message);
          debugPrint(message.message);
        });
  }

  JavascriptChannel _scanVINJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'ScanVIN',
        onMessageReceived: (JavascriptMessage message) async {
          debugPrint(message.message);
          await _scanQR();
          debugPrint(result);
          _myController.evaluateJavascript(
              'document.getElementById("vinInput").value = \"$result\"');
        });
  }

  void showSnackBar(BuildContext context, String snackBarText) {
    final toastSnackBar = SnackBar(
        content: Text(snackBarText),
        duration: new Duration(seconds: 5),
        action: SnackBarAction(
          label: "OKAY",
          onPressed: () => debugPrint(snackBarText),
        ));

    Scaffold.of(context).showSnackBar(toastSnackBar);
  }
}
