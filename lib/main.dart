import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:catex/catex.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:camera/camera.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;

var firstCamera;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();

  firstCamera = cameras.first;
  runApp(const MyApp());
}
Future<String> postMathRequest (latex, phrase) async {
  var url = Uri.parse('http://172.20.42.63:5000/solve_matheq');

  Map data = {
    'latex': latex,
    'phrase': phrase
  };
  //encode Map to JSON
  var body = json.encode(data);

  var response = await http.post(url,
      headers: {"Content-Type": "application/json"},
      body: body
  );

  return response.body.replaceAll(r'\\\\', r'\');
}
Future<String> postStatRequest (list, phrase) async {
  var url = Uri.parse('http://172.20.42.63:5000/stats');

  Map data = {
    'list': list,
    'phrase': phrase
  };
  //encode Map to JSON
  var body = json.encode(data);

  var response = await http.post(url,
      headers: {"Content-Type": "application/json"},
      body: body
  );

  return response.body;
}
Future<String> postImageRequest (imagePath) async {
  var url = Uri.parse('http://172.20.42.63:5000/img2table');
  var request = http.MultipartRequest('POST', url);
  request.files.add(await http.MultipartFile.fromPath('file', imagePath));
  var res = await request.send();
  final respStr = await res.stream.bytesToString();

  return respStr;
}
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visual Calculator',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const MyHomePage(title: 'Welcome to Visual Calculator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

SpeechToText _speechToText = SpeechToText();
bool _speechEnabled = false;
String _lastWords = '';
bool press = true;
List history = <String>[];
List contexte = <String>[];
String dropdownvalue = 'Simple Equation';

var items = [
  'Simple Equation',
  'Integral Equation',
  'Derivative Equation',
  'Complex Equation',
  'Derivative With 2 Variables',
];

class _MyHomePageState extends State<MyHomePage> {

  @override
  void initState() {
    super.initState();
    _initSpeech();
    history.removeRange(0, history.length);
    contexte.removeRange(0, contexte.length);
  }
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
      child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
      children: [ ElevatedButton(
        onPressed: () {
         Navigator.push(
        context,
       MaterialPageRoute(builder: (context) => const MathScreen()),
        );
    }, child: const Text(
        'Equation Solver',
        style: TextStyle(fontSize: 13.0),
      ),
      ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TakePictureScreen(camera: firstCamera)),
            );
          }, child: const Text(
          'Data Table Creator',
          style: TextStyle(fontSize: 13.0),
        ),
        ),
    ]),
      ),
    );
  }

}
String equation =r'3 x^{2}+5 x+1 + 2x = 5';
String resp = "waiting";
List<String> equations = [r'3 x^{2}+5 x+1 + 2x = 5', r'\int_{-5}^{7} 5x^{4} * (3x - 4)^{2} -5',
  r'\frac{d}{dx} (\frac{d}{dx}(x^{3} + (2x - 3)^{2})) = 13'
  ,r'(5x^{2} - 9)^{\frac{1}{3}} * 6x = 75',
  r'\frac{d}{dx} (x^{3} * y^{2} + 5x + 4y + 3)'];

class MathScreen extends StatefulWidget {
  const MathScreen({Key? key}) : super(key: key);

  @override
  State<MathScreen> createState() => _MathScreenState();
}
class _MathScreenState extends State<MathScreen> {
  @override
  void initState() {
    super.initState();
    var _now = DateTime
        .now()
        .second
        .toString();
    Timer _everySecond = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        _now = DateTime
            .now()
            .second
            .toString();
      });
    });
  }
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }

    void _startListening() async {
      await _speechToText.listen(onResult: _onSpeechResult);
      setState(() {});
    }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text('Equation Solver')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
        children: [CaTeX(equation),
          DropdownButton(
            value: dropdownvalue,
            icon: const Icon(Icons.keyboard_arrow_down),
            items: items.map((String items) {
              return DropdownMenuItem(
                value: items,
                child: Text(items),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                dropdownvalue = newValue!;
                equation = equations[items.indexOf(dropdownvalue)];
                history.removeRange(0, history.length);
                contexte.removeRange(0, contexte.length);
              });
            },
          ),
        ],
      ),
      ),
      bottomSheet: Container(
        width: MediaQuery.of(context).size.width,
          color: Colors.purple,

          child: Text(_lastWords,
            textAlign: TextAlign.center,
            style: const TextStyle(
            color: Colors.white,
              fontSize: 16.0
          )),


        ),

        floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
        Container(
        margin:EdgeInsets.all(10),
      child: FloatingActionButton(
      onPressed: () {
        if(press){
        _startListening();
        setState(() {
          press = false;
        });
        }
        else{
          _stopListening();
        setState(() {
          press = true;
          contexte.add(equation);
          var response = postMathRequest(equation, _lastWords);
          history.add("Command: " + _lastWords + "\n\n");
          response.then((value) {
            equation = value;
            equation = equation.replaceAll("\\\\", r"\");
          });
        });}
      },

      child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic)
    ),
    ),
    Container(
    margin:EdgeInsets.all(10),
    child: FloatingActionButton(
    onPressed: () {
      equation = contexte.removeLast();
      history.removeLast();
    },
    child: const Icon(Icons.undo)
    ),
    ),
    ]),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children:  [
        DrawerHeader(
        decoration: BoxDecoration(
        color: Colors.purple,
        ),
        child: Text('History',
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Colors.white,
            fontSize: 16.0),),
      ),
        ListTile(
          title: Text(history.join(),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.black54,
                fontSize: 12.0),
        )),
    ])),
    );
  }
}
String original = '';
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Take a Picture')),
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return CameraPreview(_controller);
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
        onPressed: () async {
      try { await _initializeControllerFuture;

      final image = await _controller.takePicture();

      var response = postImageRequest(image.path);
      resp = '';
      response.then((value) { original = value;
        var resplist = value.split(']');
      for (int i = 0; i < resplist.length - 2; i++) {
        resp += 'Row ' + (i+1).toString() + ': ' + resplist[i] + '\n';
        resp = resp.replaceAll(']', '');
        resp = resp.replaceAll('[', '');
        resp = resp.replaceAll(',', '  ');
      }});
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TableScreen(
          ),
        ),
      );
      } catch (e) {
        print(e);
      }
        },
          child: const Icon(Icons.camera_alt),
        ),
    );
  }
}
String result = '';
String tempresult = '';
class TableScreen extends StatefulWidget {
  const TableScreen({Key? key}) : super(key: key);

  @override
  State<TableScreen> createState() => _TableScreenState();
}
class _TableScreenState extends State<TableScreen> {
  @override
  void initState() {
    super.initState();
    var _now = DateTime
        .now()
        .second
        .toString();
    Timer _everySecond = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        _now = DateTime
            .now()
            .second
            .toString();
      });
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(title: const Text('Dataset Generated')),
      body: Column(

    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [Text(resp,
      textAlign: TextAlign.center),
      ]),
      bottomSheet: Container(
        width: MediaQuery.of(context).size.width,
        color: Colors.purple,

        child: Text(result,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0
            )),


      ),

      floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              margin:EdgeInsets.all(10),
              child: FloatingActionButton(
                  onPressed: () {
                    if(press){
                      _startListening();
                      setState(() {
                        press = false;
                      });
                    }
                    else{
                      _stopListening();
                      setState(() {
                        press = true;
                        result = '';
                        var response = postStatRequest(original, _lastWords);

                       response.then((value) {
                         history.add("Command: " + _lastWords + "\n");
                         history.add("Result: " + value + "\n\n");
                        tempresult = value;
                         List reslist = tempresult.split(',');
                         for (int i = 0; i < reslist.length; i++) {
                           result += i.toString() + ': ' + reslist[i] + '\n';
                           result = result.replaceAll(']', '');
                           result = result.replaceAll('[', '');
                         }
                         result += "Command: " + _lastWords;
                       });

                      }
                      );}
                  },

                  child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic)
              ),
            ),
            Container(
              margin:EdgeInsets.all(10),
              child: FloatingActionButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MyHomePage(title: 'Welcome Again...',
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.home_filled)
              ),
            ),
          ]),
      drawer: Drawer(
          child: ListView(
              padding: EdgeInsets.zero,
              children:  [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.purple,
                  ),
                  child: Text('History',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.0),),
                ),
                ListTile(
                    title: Text(history.join(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12.0),
                    )),
              ])),
    );
  }
}
