import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const MyHomePage(title: 'Music Player'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AudioPlayer audioPlayer = AudioPlayer();
  String? filePath;
  String songTitle='';
  int maxduration=1,currentpos=0;
  String currentposlabel="00:00";
  dynamic albumArt='assets/art/albumart.png';
  String trackName='',albumName='',url='https://www.soundhelix.com/examples/mp3/SoundHelix-Song-15.mp3';


  @override
  initState() {
    audioPlayer.onPlayerStateChanged.listen((PlayerState s)  {
      setState(() {
        print('audioplayer state $s');
        if(audioPlayer.state==PlayerState.COMPLETED || audioPlayer.state==PlayerState.STOPPED){
          currentpos=0;
          currentposlabel="00:00";
        }
      });
    });

    audioPlayer.onDurationChanged.listen((Duration d) { //get the duration of audio
      maxduration = d.inMilliseconds;
      setState(() {

      });
    });

    audioPlayer.onAudioPositionChanged.listen((Duration  p){
      currentpos = p.inMilliseconds; //get the current position of playing audio

      //generating the duration label
      int shours = Duration(milliseconds:currentpos).inHours;
      int sminutes = Duration(milliseconds:currentpos).inMinutes;
      int sseconds = Duration(milliseconds:currentpos).inSeconds;

      int rhours = shours;
      int rminutes = sminutes - (shours * 60);
      int rseconds = sseconds - (sminutes * 60 + shours * 60 * 60);

      currentposlabel = (rhours<1)?((rseconds<10)?"$rminutes:0$rseconds":"$rminutes:$rseconds"):"$rhours:$rminutes:$rseconds";

      setState(() {
        //refresh the UI
      });
    });

    super.initState();

  }

  playLocal() async {
    if(filePath!=null) {
      try {
        int result = await audioPlayer.play(filePath!, isLocal: true);
        if (result == 1) {
          print('success');
        }
      }
      catch (e) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: Colors.grey[400],
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey.shade900, Colors.grey.shade200])),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
                width: MediaQuery.of(context).size.width*0.6,
                height: MediaQuery.of(context).size.width*0.6,
                child: (albumArt.runtimeType==String)?Image.asset(albumArt):Image.memory(albumArt)
            ),
            SizedBox(
              height: 10,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width*0.6,
              child: Text('${trackName}', maxLines: 1,softWrap: false, overflow: TextOverflow.fade,),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width*0.6,
              child: Text('${albumName}',maxLines: 1, overflow: TextOverflow.fade,),
            ),
            SizedBox(
              height: 30,
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(
                    iconSize: 50,
                    icon: Icon(Icons.skip_previous),
                    onPressed: () {

                    },
                  ),
                  IconButton(
                    iconSize: 50,
                    icon: Icon(Icons.stop),
                    onPressed: () {
                      stop();
                    },
                  ),
                  IconButton(
                    iconSize: 50,
                    icon: (audioPlayer.state == PlayerState.PLAYING)? Icon(Icons.pause):Icon(Icons.play_arrow),
                    onPressed: () {
                      if(audioPlayer.state!=PlayerState.PLAYING) {
                        playLocal();
                      }
                      else {
                        pause();
                      }
                    },
                  ),
                  IconButton(
                    iconSize: 50,
                    icon: Icon(Icons.skip_next),
                    onPressed: () {
                      play();
                    },
                  ),
                  IconButton(
                    iconSize: 50,
                    icon: Icon(Icons.library_music_rounded),
                    onPressed: () {
                      _pickFile();
                    },
                  ),
                ]
            ),
            (filePath!=null)?Text(currentposlabel):Text(''),
            Container(
                child: Slider(
                  value: currentpos.toDouble(),
                  min: 0.0,
                  max: maxduration.toDouble()+1000.0,
                  label: currentposlabel,
                  onChanged: (double value) async {
                    int seekval = value.round();
                    int result = await audioPlayer.seek(Duration(milliseconds: seekval));
                    if(result == 1){ //seek successful
                      currentpos = seekval;
                    }else{
                      print("Seek unsuccessful.");
                    }
                  },
                )
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);

    // if no file is picked
    if (result == null) return;

    // we will log the name, size and path of the
    // first picked file (if multiple are selected)
    filePath=result.files.first.path;
    songTitle=result.files.first.name;
    final metadata = await MetadataRetriever.fromFile(File(result.files.first.path!));
    List<File> files = result.paths.map((path) => File(path!)).toList();
    print('files are     ${files[0]}');
    if(metadata.albumArt!=null){
      albumArt=metadata.albumArt;
    }
    else {
      albumArt='assets/art/albumart.png';
    }
    trackName=(metadata.trackName!=null)?metadata.trackName!:'';
    albumName=(metadata.albumName!=null)?metadata.albumName!:'';
    setState(() {

    });
  }

  play() async {
    int result = await audioPlayer.play(url);
    if (result == 1) {
      // success
    }
  }

  void pause() async{
    try {
      int result = await audioPlayer.pause();
      if (result == 1) {
        print('success');

      }
    }
    catch (e) {
      print(e);
    }
  }

  void skipNext() {

  }

  void stop() async{
    try {
      int result = await audioPlayer.stop();
      if (result == 1) {
        print('success');
      }
    }
    catch (e) {
      print(e);
    }
  }

}
