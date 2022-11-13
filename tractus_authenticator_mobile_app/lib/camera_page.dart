import 'package:flutter/material.dart';
import 'package:flutter_mrz_scanner/flutter_mrz_scanner.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import "NFC.dart";

final logger = Logger();

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool isParsed = false;
  MRZController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
      ),
      body: FutureBuilder<PermissionStatus>(
        future: Permission.camera.request(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == PermissionStatus.granted) {

            print("object");
            return MRZScanner(
              withOverlay: true,
              onControllerCreated: onControllerCreated,
            );
          }
          if (snapshot.data == PermissionStatus.permanentlyDenied) {

            openAppSettings();
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Awaiting for permissions'),
                ),
                Text('Current status: ${snapshot.data?.toString()}'),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    controller?.stopPreview();
    super.dispose();
  }

  void onControllerCreated(MRZController controller) {
    this.controller = controller;
    controller.onParsed = (result) async {
      logger.i("Is parsed: $isParsed");
      logger.i(result);
      if (isParsed) {
        return;
      }
      isParsed = true;
      List<String> arr =
          result.birthDate.toString().substring(0, 10).split("-");
      String birth = arr[1] + '/' + arr[2] + '/' + arr[0];
      List<String> arr1 =
          result.expiryDate.toString().substring(0, 10).split("-");
      String expiry = arr1[1] + '/' + arr1[2] + '/' + arr1[0];
      Map dict = {
        'documentType': result.documentType,
        'country': result.countryCode,
        'surnames': result.surnames,
        'givenNames': result.givenNames,
        'documentNumber': result.documentNumber,
        'nationalityCode': result.nationalityCountryCode,
        'birthdate': birth,
        'sex': result.sex.toString(),
        'expiryDate': expiry,
        'personalNumber': result.personalNumber,
        'personalNumber2': result.personalNumber2,
        'bio_image': "Null",
      };

      await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
                  content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Document type: ${result.documentType}'),
                  Text('Country: ${result.countryCode}'),
                  Text('Surnames: ${result.surnames}'),
                  Text('Given names: ${result.givenNames}'),
                  Text('Document number: ${result.documentNumber}'),
                  Text('Nationality code: ${result.nationalityCountryCode}'),
                  Text('Birthdate: ${result.birthDate}'),
                  Text('Sex: ${result.sex}'),
                  Text('Expriy date: ${result.expiryDate}'),
                  Text('Personal number: ${result.personalNumber}'),
                  Text('Personal number 2: ${result.personalNumber2}'),
                  ElevatedButton(
                      child: const Text('Confirm'),
                      onPressed: () {
                        isParsed = false;
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: ((context) =>
                                    MrtdHomePage(dict: dict))),
                            (route) => false);
                      }),
                ],
              )));
    };

    controller.onError = (error) => print(error);

    controller.startPreview();
  }
}
