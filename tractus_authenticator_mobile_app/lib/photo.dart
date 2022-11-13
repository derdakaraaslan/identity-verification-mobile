import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'result.dart' as resultPage;
import 'globals.dart' as global;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isnotempty = false;
  List<File>? _images = [];
  final imagePicker = ImagePicker();
  Future getImage() async {
    final image = await imagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      _images!.add(File(image!.path));
      isnotempty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: GridView.count(
        primary: false,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        crossAxisCount: 5,
        children: <Widget>[
          // if olmadan hata veriyor mu kontrol et
          if (isnotempty)
            for (var item in _images!)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.teal[100],
                child:
                    item == null ? const Icon(Icons.image) : Image.file(item),
              ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.teal[100],
            child: IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () {
                if (_images!.length < 10) {
                  getImage();
                } else {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return const AlertDialog(
                          title: Text('You already take 10 photos.'),
                        );
                      });
                }
              },
              color: Colors.blue,
            ),
          ),
        ],
      )),
      floatingActionButton: FloatingActionButton(
        heroTag: "2",
        onPressed: () async {
          bool allIsDone = true;
          if (_images!.length < 1) {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  String number = (10 - _images!.length).toString();
                  return AlertDialog(
                    title: Text(
                        'You must take 10 photos. Please take $number more photos'),
                  );
                });
          } else {
            String id = global.process_id;
            final url = global.url + "process/$id/face";
            Uint8List imagebytes;

            for (File item in _images!) {
              imagebytes = await item.readAsBytes();
              String base64string = base64.encode(imagebytes);
              var response = await http.post(
                Uri.parse(url),
                body: jsonEncode(<String, String>{"face": base64string}),
              );
              print(response.body);
              if (response.statusCode == 200) {
                debugPrint("Done");
              } else {
                allIsDone = false;
                throw Exception('basarisiz');
              }
            }
          }

          if (allIsDone) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: ((context) => const resultPage.MyHomePage())),
                (root) => false);
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.send),
      ),
    );
  }
}
