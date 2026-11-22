import 'dart:core';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:lyric_xx/lyric_xx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';


void main() async{
  ErrorWidget.builder = (_) => const AppErrorWidget();
  MpvAudioKit.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = WindowOptions(
    size: Size(1280, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  final prefs = await SharedPreferences.getInstance();
  final logtake= prefs.getStringList('saved_my_list');
  if(logtake!=null){
    runApp(MyApp());
    runApp(const MyApp());
  }
  else{
    runApp(Myinitial());
    runApp(const Myinitial());
  }}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const MyHomePage(title: ''),);}
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
enum sam{extraSmall, small, medium, large, extraLarge,superLarge}
class _MyHomePageState extends State<MyHomePage> with WindowListener{
  bool playing=false;
  int cursor=0;
  List<String> musicplace=[];
  List<String> now_list=[];
  List<String> music_list=[];
  List<String> lyrics_list=["正在初始化"];
  List<double> lyrics_time=[0.0];
  List<int> index_list=[];
  List now_tag=[];
  List<int> search_list=[];
  List<String> search_artist_list=[];
  List<String> search_album_list=[];
  List<DateTime> time_list=[];
  List<Device> device_list=[];
  int sample=0;
  int bit=0;
  bool exclusive=false;
  double h=720;
  double w=1280;
  ScrollController view_controll=ScrollController();
  int page_index=0;
  PageController page_control = PageController(initialPage: 0);
  PageController search_control = PageController(initialPage: 0);
  final player = Player(configuration: PlayerConfiguration(autoPlay: false));
  final ValueNotifier<double> time_value = ValueNotifier<double>(0);
  final ValueNotifier<int> lyrics_number = ValueNotifier<int>(0);
  double time_max=20;
  dynamic music_name="";
  int player_mode=0;
  bool shuffle_on=false;
  bool shuffling=false;
  Map artist_list={};
  Map album_list={};
  Set search_selected={0};
  List<String> artist_widget=[];
  List<String> album_widget=[];
  List<String> setting_list=["0","","false","20","0","false","2","5"];
  Uint8List music_image=File("assets/images/nothing.jpg").readAsBytesSync();
  Playlist playlist=Playlist([]);
  ColorScheme material_you=ColorScheme.fromSeed(seedColor: Colors.cyan);
  bool auto_scan=false;
  double font_size=20;
  FocusNode focusNode = FocusNode();
  double text_blur=0;
  Set<sam> sample_selection={sam.extraSmall};
  Set<sam> bit_selection={sam.extraSmall};
  Set<sam> volume_selection={sam.superLarge};
  Set<sam> koss_selection={sam.extraSmall};
  double koss_opacity=0;
  Set<sam> goss_selection={sam.medium};
  double goss_strength=60;
  bool extreme_panel=true;
  GlobalKey lyrics_key= GlobalKey();
  double lyrics_height=617.5;


  @override
  void initState(){
    super.initState();
    set_get();
    player.stream.position.listen((pos){
      lyrics_sync();
      time_value.value=pos.inSeconds.toDouble();
    });
   player.stream.path.listen((path){renew(path);});
   player.stream.playlist.listen((part){cursor=part.index;
   if(shuffling){
     now_update(part.items);}});
   windowManager.addListener(this);
   player.stream.audioDevices.listen((devices){device_list=devices;});
   print("初始化完成");
  }

  void renew(String path)async{
    if(playing){
      await player.play();}
    else{
      await player.pause();
    }
    time_value.value=0;
    tag_get(path);
    setState(() {
    });
  }

  void set_get()async{
    final prefs = await SharedPreferences.getInstance();
    final logtake= prefs.getStringList('set_my_list');
    if(logtake!=null){
      if(logtake.length==8){
        setting_list=logtake;
      }
    }
    font_size=double.parse(setting_list[3]);
    if(setting_list[2]=="true"){
      file_scan(setting_list[1]);
      auto_scan=true;
    }
    else {
      auto_scan=false;
      get_file();
    }
    if(setting_list[5]=="true"){
      text_blur=10;
    }
    else{text_blur=0;}
    Map<sam,double> zeta={sam.extraSmall:0,sam.small:0.5,sam.medium:0.7,sam.large:0.9,};
    Map<sam,double> meta={sam.extraSmall:0,sam.small:30,sam.medium:60,sam.large:100,sam.extraLarge:200,};
    Map<sam,double> peta={sam.extraSmall:0,sam.small:20,
      sam.medium:40,sam.large:60,sam.extraLarge:80,sam.superLarge:100};
    Map<String,sam> beta={"0":sam.extraSmall,"1":sam.small,"2":sam.medium,
      "3":sam.large,"4":sam.extraLarge,"5":sam.superLarge};
    volume_selection={?beta[setting_list[7]]};
    player.setVolume(peta[volume_selection.first]!);
    koss_selection={?beta[setting_list[4]]};
    koss_opacity=zeta[koss_selection.first]!;
    goss_selection={?beta[setting_list[6]]};
    goss_strength=meta[goss_selection.first]!;
  }


  void onWindowResized(){
    get_size();
  }
  void get_size()async{
    Size size=await windowManager.getSize();
    lyrics_height=lyrics_key.currentContext!.size!.height;
    w=size.width;
    h=size.height;
    print(w);
    print(h);
    setState(() {
    });
  }

  void tag_get(path)async{
    final metadata=await readMetadata(File(path),getImage: true);
    if(metadata.pictures.isNotEmpty){
      music_image=metadata.pictures[0].bytes;}
    else{
      music_image=File("assets/images/nothing.jpg").readAsBytesSync();
    }
    material_you=await ColorScheme.fromImageProvider(provider: MemoryImage(music_image));
    time_max=metadata.duration!.inSeconds.toDouble();
    now_tag.clear();
    if(metadata.artist!=null){
      now_tag.add(metadata.artist!.split(RegExp("/")));}
    else{
      now_tag.add("未知歌手");
    }
    if(metadata.album!=null){
      now_tag.add(metadata.album);}
    else{
      now_tag.add("专辑");
    }
    if (metadata.title != null) {
      music_name=metadata.title!;
    }
    else {
      music_name=path.split("/").last;
    }
    sample=metadata.sampleRate!;
    bit=metadata.bitrate!~/sample;
    if(metadata.lyrics!=null){
      final relist = await Lyricxx_c.decodeLrcString(metadata.lyrics!);
      lyrics_number.value=0;
      lyrics_time.clear();
      lyrics_list.clear();
      for(var i in relist.lrc){
        lyrics_list.add(i.content);
        lyrics_time.add(i.time);
      };}
    else{
      lyrics_time=[0.0];
      lyrics_list=["暂无歌词"];
      lyrics_number.value=0;
    }
    setState(() {
    });
}

  void modeking(){
    print("模式");
    if(player_mode==0){
      player.setLoop(Loop.playlist);}
    else{
      player.setLoop(Loop.file);
      if(player_mode==2){
        playing=false;}
      player.play();
    }

  }
  void file_load()async{
    String? selectedDirectory = await FilePicker.getDirectoryPath();
    if(selectedDirectory!=null){
      setting_list[1]=selectedDirectory;
      file_scan(selectedDirectory);
    }
    else{
      warning_show(context);
    }
  }

  void file_scan(String path)async{
    print(path);
    if(Directory(path).existsSync()){
      List<File> folder=[];
      folder = Directory(path)
          .listSync(recursive: true)
          .whereType<File>()
          .where((element) =>
      element.path.endsWith(".ogg") ||
          element.path.endsWith(".m4a") ||
          element.path.endsWith(".mp3") ||
          element.path.endsWith(".flac")||
          element.path.endsWith(".wav"))
          .toList();
      if(folder.isNotEmpty){
        musicplace.clear();
        for(int i=0; i<folder.length; i++ ){
          musicplace.add(folder[i].path);
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('saved_my_list', musicplace);
        player.openAll(List.generate(musicplace.length,(index)=>Media(musicplace[index])));
        player.play();
        player.pause();
        index_list=List.generate(musicplace.length,(index)=>index);
        name_update();
        dorino(setting_list[0]);
        renew(musicplace[0]);
        right_show(context);
      }
      else{
        warning_show(context);
    }}
    else{warning_show(context);}
  }

  void get_file()async{
    final prefs = await SharedPreferences.getInstance();
    final logtake= prefs.getStringList('saved_my_list');
    if(logtake!=null){
      musicplace=logtake;
      musicplace.retainWhere((path) =>File(path).existsSync());
      if(musicplace.isNotEmpty){
        renew(musicplace[0]);
        player.openAll(List.generate(musicplace.length,(index)=>Media(musicplace[index])));
        index_list=List.generate(musicplace.length,(index)=>index);
        name_update();}
      else{
        warning_show(context);
      }
    }
    else{warning_show(context);}


  }
  
  void now_update(List<Media> part){
    now_list.clear();
    for(Media path in part){
      final metadata= readMetadata(File(path.uri),getImage: false);
      now_list.add(metadata.title!);
    }
    shuffling=false;
  }

  void name_update()async{
    music_list.clear();
    album_widget.clear();
    artist_widget.clear();
    album_list.clear();
    artist_list.clear();
    time_list.clear();
    for(int i=0; i<musicplace.length; i++) {
      final time = await FileStat.stat(musicplace[i]);
      time_list.add(time.changed);
      final metadata = readMetadata(File(musicplace[i]), getImage: false);
      if (metadata.title != null) {
        music_list.add(metadata.title!);
      }
      else {
        music_list.add(musicplace[i].split("/").last);
      }
      if (metadata.artist != null) {
        for (String z in metadata.artist!.split(RegExp("/"))) {
          if (artist_list.containsKey(z)) {
            artist_list[z].add(i);
          }
          else {
            artist_list[z] = [i];
            artist_widget.add(z);
          }
        }
      }
      else {
        if (artist_list.containsKey("未知歌手")) {
          artist_list["未知歌手"].add(i);
        }
        else {
          artist_list["未知歌手"] = [i];
          artist_widget.add("未知歌手");
        }
      }
      if (metadata.album != null) {
        if (album_list.containsKey(metadata.album)) {
          album_list[metadata.album].add(i);
        }
        else {
          album_list[metadata.album] = [i];
          album_widget.add(metadata.album!);
        }
      }
      else {
        if (album_list.containsKey("未知专辑")) {
          album_list["未知专辑"].add(i);
        }
        else {
          album_list["未知专辑"] = [i];
          album_widget.add("未知专辑");
        }
      }
    }
    for(String i in music_list){
      now_list.add(i);
    }
    print("内容加载");
  }

  Uint8List get_image(int num) {
    final metadata= readMetadata(File(musicplace[num]),getImage:true);
    if(metadata.pictures.isNotEmpty){
        return metadata.pictures[0].bytes;}
    else{
      return File("assets/images/nothing.jpg").readAsBytesSync();
    }
  }
  void art_update(){}

  void timer(value){
    time_value.value=value;
    player.seek(Duration(seconds:time_value.value.toInt()));
    for(int i=0; i<lyrics_time.length; i++){
      if(lyrics_time[min(i+1,lyrics_time.length)]>time_value.value){
        lyrics_number.value=i;
        view_controll.animateTo(i.toDouble()*(font_size+22)-0.5*lyrics_height+font_size,
            duration: Duration(milliseconds: 100),curve: Curves.ease);
        break;}}
  }

  Widget time_progress(context, double value,_){
    return SliderTheme(data: SliderThemeData(thumbShape:
    RoundSliderThumbShape(elevation: 0), valueIndicatorShape: PaddleSliderValueIndicatorShape(),
        trackHeight: 20),
        child: Slider(label: Duration(seconds: value.toInt()).toString(),
          value:value, onChanged:(double value){timer(value);},max: time_max,));

  }

  void list_click(int index){
    player.replace(cursor,Media(musicplace[index]));
    now_list[cursor]=music_list[index];
  }

  void play()async{
    if(playing){await player.pause();}
    else{
      await player.play();}
    setState(() {playing=!playing;});

  }
  void lyrics_sync(){
    if (lyrics_number.value +1<lyrics_list.length){
      if(time_value.value>lyrics_time[lyrics_number.value+1]){
        lyrics_number.value++;
        if(page_index==0||!extreme_panel){
        view_controll.animateTo(lyrics_number.value.toDouble()*(font_size+22)-0.5*lyrics_height+font_size,
            duration:Duration(milliseconds: 100),
          curve: Curves.linear
        );}}}
  }

  void lyrics_update(String path)async{
    final metadata= await readMetadata(File(path),getImage:false);
    if(metadata.lyrics!=null){
    final relist = await Lyricxx_c.decodeLrcString(metadata.lyrics!);
    lyrics_number.value=0;
    lyrics_time.clear();
    lyrics_list.clear();
    for(var i in relist.lrc){
      lyrics_list.add(i.content);
      lyrics_time.add(i.time);
    };}
    else{
      lyrics_time=[0.0];
      lyrics_list=["暂无歌词"];
      lyrics_number.value=0;
    }
  }

  void lyrics_click(num){
    lyrics_number.value=num;
    view_controll.animateTo(num.toDouble()*(font_size+22)-0.5*lyrics_height+font_size, duration: Duration(milliseconds: 100),curve: Curves.ease);
    time_value.value=lyrics_time[num];
    player.seek(Duration(seconds:time_value.value.toInt()));
  }

  Widget lyrics_display(context, int value,_){
    return ScrollConfiguration(behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false)
        , child:Expanded(key: lyrics_key,child:ListView.builder(
        itemCount: lyrics_list.length, itemExtent: font_size+22,controller: view_controll,
        itemBuilder: (BuildContext ctxt, int index) {return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          title: Text(lyrics_list[index],
          style: TextStyle(fontSize: font_size,shadows: [Shadow(color: Colors.white,blurRadius: text_blur)]),),
          selected: index==value,
          selectedColor:material_you.surfaceBright,selectedTileColor: material_you.onPrimaryFixedVariant,
          onTap: (){lyrics_click(index);},);})
        ,));
  }

  void tag_show(BuildContext context) {
    List<Widget> _use=[];
    _use.add(ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
      title: Text(now_tag[1]),leading: Icon(Icons.album),
      onTap: (){art_show(context,album_list[now_tag[1]],now_tag[1]);},));
    for(String i in now_tag[0]){
      _use.add(ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
        title: Text(i),leading: Icon(Icons.account_box),
        onTap:(){art_show(context,artist_list[i], i);} ,));}
    _use.add(ListTile(title: Text("$sample"+"hz / "+"$bit"+"bit"),leading: Icon(Icons.graphic_eq),));
    
    AlertDialog alert=AlertDialog(backgroundColor: material_you.surface,
      content: SizedBox(child: ListView(children: _use,itemExtent: 42,),width: 50,height: 200,)
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;},);}

  void now_show(BuildContext context){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext context,setstate)
        {return now_use(context,setstate);});},);
  }
  Widget now_use(context,setState){
    return AlertDialog(
        content: SizedBox(height: h,width: 300,child: ListView.builder(itemExtent: 42.0,
            itemCount: now_list.length,
            itemBuilder: (BuildContext ctxt, int index)
            {return ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                selected: cursor==index,
                selectedTileColor: material_you.onSecondaryContainer,
                selectedColor: material_you.onSecondary,
                title: Text(now_list[index_list[index]]),
              onTap: (){now_click(index, setState);});}))
    );
  }
  void now_click(index,setState){
    player.jump(index);
    setState(() {
      cursor=index;
    });

  }
  void re_list(){
    now_list.clear();
    player.openAll(List.generate(musicplace.length,(index)=>Media(musicplace[index])));
    now_list=List.from(music_list);
    setState(() {
      shuffle_on=false;
    });
  }

  void the_list(List<int> place){
    player.clearPlaylist();
    now_list.clear();
    player.openAll(List.generate(place.length,(index)=>Media(musicplace[place[index]])));
    now_list=List.generate(place.length,(index)=>music_list[place[index]]);
    setState(() {
      shuffle_on=false;
    });
  }

  void art_show(BuildContext context,place,name){
    AlertDialog alert=AlertDialog(
        content: SizedBox(width: w*0.6,height: h*0.6,child:Row(children:[
              Column(children:[ClipRRect(borderRadius: const BorderRadius.all(Radius.circular(44)),
                  child: Image.memory(get_image(place[0]),cacheHeight: 400,cacheWidth: 400,)),
                Expanded(child:TextButton.icon(icon: Icon(Icons.exit_to_app),
                  label: Text(name),onPressed: (){the_list(place);},)),
                ]),
          Expanded(child: ListView.builder(itemExtent: 42.0,
              itemCount: place.length,
              itemBuilder: (BuildContext ctxt, int index)
              {return ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                title: Text(music_list[place[index]]),
                onTap: (){list_click(place[index]);},);}))])));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;},);
  }
  void awsome_music(){
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {return StatefulBuilder(builder: (BuildContext context,setstate)
      {return device_use(context, setstate);});},);
  }


  Widget device_use(context,setState){
    List<Widget> zeta=(List<Widget>.generate(
        device_list.length,(int index) =>ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
      title: Text(device_list[index].description),
      onTap: (){device_change(index);},)));
    zeta.insert(0, ListTile(leading:Icon(Icons.headphones),title: Text("设备列表"),));
    zeta.add(Divider());
    zeta.add(ListTile(title: Text("音量设置"),leading: Icon(Icons.volume_up),));
    zeta.add(SegmentedButton<sam>(segments: const <ButtonSegment<sam>>[
      ButtonSegment<sam>(label: Text("0"),value: sam.extraSmall),
      ButtonSegment<sam>(label: Text("20%"),value: sam.small),
      ButtonSegment<sam>(label: Text("40%"),value: sam.medium),
      ButtonSegment<sam>(label: Text("60%"),value: sam.large),
      ButtonSegment<sam>(label: Text("80%"),value: sam.extraLarge),
      ButtonSegment<sam>(label: Text("100%"),value: sam.superLarge)],
        selected:volume_selection,
        onSelectionChanged: (Set<sam> newSelection){volume_change(newSelection, setState);}
    ),);
    zeta.add(Divider());
    zeta.add(ListTile(title: Text("独占模式"),trailing: Switch(value: exclusive,
        onChanged: (bool value){exclusive_on(value,setState);}),));
    zeta.add(ListTile(title: Text("采样率设置"),leading: Icon(Icons.graphic_eq_sharp),));
    zeta.add(SegmentedButton<sam>(segments: const <ButtonSegment<sam>>[
        ButtonSegment<sam>(label: Text("Auto"),value: sam.extraSmall),
          ButtonSegment<sam>(label: Text("44.1Khz"),value: sam.small),
        ButtonSegment<sam>(label: Text("48khz"),value: sam.medium),
        ButtonSegment<sam>(label: Text("96khz"),value: sam.large),
        ButtonSegment<sam>(label: Text("192khz"),value: sam.extraLarge),
        ButtonSegment<sam>(label: Text("384khz"),value: sam.superLarge)],
          selected:sample_selection,
          onSelectionChanged: (Set<sam> newSelection){sample_change(newSelection, setState);}
      ),);
    zeta.add(Divider());
    zeta.add(ListTile(title: Text("比特率设置"),leading: Icon(Icons.equalizer),));
    zeta.add(SegmentedButton<sam>(segments: const <ButtonSegment<sam>>[
      ButtonSegment<sam>(label: Text("Auto"),value: sam.extraSmall),
      ButtonSegment<sam>(label: Text("16-bit"),value: sam.small),
      ButtonSegment<sam>(label: Text("32-bit"),value: sam.medium),
      ButtonSegment<sam>(label: Text("浮点32-bit"),value: sam.large),
      ButtonSegment<sam>(label: Text("浮点64-bit"),value: sam.extraLarge),
      ButtonSegment<sam>(label: Text("浮点64-bit"),value: sam.superLarge)],
        selected:bit_selection,
        onSelectionChanged: (Set<sam> newSelection){bit_change(newSelection, setState);}
    ),);
    zeta.add(Divider());
    zeta.add(ListTile(title: Text("Tips:开启独占模式设备音量将失效"),leading: Icon(Icons.error),));

    return Container(child: ListView(children: zeta),height: h*0.5,);
  }
  void sample_change(Set<sam> newSelection,setState){
    Map zeta={sam.extraSmall:0,sam.small:44100,sam.medium:48000,sam.large:96000,
      sam.extraLarge:192000,sam.superLarge:384000};
    sample_selection=newSelection;
    player.setAudioSampleRate(zeta[newSelection.first]);
    setState(() {
    });
  }
  void bit_change(Set<sam> newSelection,setState){
    Map zeta={sam.extraSmall:Format.auto,sam.small:Format.s16,sam.medium:Format.s32,sam.large:Format.float32,
      sam.extraLarge:Format.s64,sam.superLarge:Format.float64};
    bit_selection=newSelection;
    player.setAudioFormat(zeta[newSelection.first]);
    setState(() {
    });
  }
  void volume_change(Set<sam> newSelection,setState){
    Map<sam,double> zeta={sam.extraSmall:0,sam.small:20,sam.medium:40,sam.large:60,
      sam.extraLarge:80,sam.superLarge:100};
    Map<sam,String> meta={sam.extraSmall:"0",sam.small:"1",
      sam.medium:"2",sam.large:"3",sam.extraLarge:"4",sam.superLarge:"5"};
    volume_selection=newSelection;
    setting_list[7]=meta[volume_selection.first]!;
    player.setVolume(zeta[newSelection.first]!);
    setState(() {
    });
  }

  void device_change(int index)async{
    await player.setAudioDevice(device_list[index]);
  }
  void exclusive_on(bool value,setState)async{
    exclusive=value;
    player.setAudioExclusive(value);
    setState(() {
    });;
  }

  void page_change(int value){
    setState(() {
      page_index=value;
    });
    page_control.jumpToPage(value);
  }
  void shuffle(){
    shuffling=true;
    setState(() {
      shuffle_on=!shuffle_on;
    });
    player.setShuffle(shuffle_on);
  }

  void search_get(String value){
    search_list.clear();
    search_album_list.clear();
    search_artist_list.clear();
    String milano=value.toLowerCase();
    for(int i=0; i<music_list.length; i++){
      if(music_list[i].toLowerCase().contains(milano.toLowerCase())){
        search_list.add(i);}}
    for(String i in artist_widget){
      if (i.toLowerCase().contains(milano)){
        search_artist_list.add(i);
      }
    }
    for(String i in album_widget){
      if (i.toLowerCase().contains(milano)){
        search_album_list.add(i);
      }
    }
  }


  void right_show(BuildContext context){
    AlertDialog alert=AlertDialog(content: SizedBox(width: 300,height: 100,child:
    ListTile(title: Text("扫描完成"),leading: Icon(Icons.celebration),)),);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;},);
  }
  
  void warning_show(BuildContext context){
    AlertDialog alert=AlertDialog(content: SizedBox(width: 300,height: 300,child: 
      ListView(children: [Text("文件夹出现变动请重新扫描"),
        ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
          title: Text("文件夹选择"),onTap: file_load,leading: Icon(Icons.folder),)],),),);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;},);
  }

  Widget font_size_change(context,setState){
    return AlertDialog(content: SizedBox(width:160,height: 60,child: Row(children: [
      Icon(Icons.text_fields),
      IconButton(onPressed: (){font_size_use(-1, setState);},icon: Icon(Icons.arrow_left)),
      Text("$font_size"),IconButton(onPressed: (){font_size_use(1,setState);},icon: Icon(Icons.arrow_right))
    ],)));
  }
  void font_size_use(double value,setState){
    setState(() {font_size=(font_size+value)%40;
    });
  }
  void text_blur_on(value){
    setting_list[5]="$value";
    if(value){
      text_blur=10;
    }
    else{text_blur=0;}
    setState(() {
    });

  }

  void text_show(BuildContext context){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext context,setState){return font_size_change(context,setState);});
      });
  }

  void dorino(String order){
    if(order=="0"){
      index_list=List.generate(musicplace.length,(index)=>index);
      index_list.sort((a, b) => music_list[a].compareTo(music_list[b]));
    }
    else if(order=="1"){
      index_list.sort((a, b) => time_list[a].compareTo(time_list[b]));
    }
    else if(order=="2"){
      index_list.sort((a, b) => time_list[b].compareTo(time_list[a]));
    }
    now_list=List.from(music_list);
    player.openAll(List<Media>.generate(
        musicplace.length, (index) => Media(musicplace[index_list[index]])));
    setState(() {
    });
    setting_list[0]=order;
  }

  PopupMenuButton order_pop(){
    return PopupMenuButton(child:Icon(Icons.list),itemBuilder: (BuildContext context){
      return [PopupMenuItem(child: ListTile(title: Text("按首字母排序"),onTap: (){dorino("0");
      })),
        PopupMenuItem(child: ListTile(title: Text("按修改时间升序"),onTap: (){
          dorino("1");
        },)),
        PopupMenuItem(child: ListTile(title: Text("按修改时间降序"),onTap: (){
          dorino("2");
        }))];
    });
  }

  void set_load()async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('set_my_list',setting_list);
    List<String> milano=[];
    for(int i in index_list){
      milano.add(musicplace[i]);}
    musicplace=List.from(milano);
    await prefs.setStringList('saved_my_list', musicplace);
    player.dispose();
    exit(0);
  }

  void set_clear()async{
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  Widget search_display(context,setState){
    List<Widget> segment=[SegmentedButton(segments: [
      ButtonSegment(value: 0,label: Text("歌曲"),icon: Icon(Icons.audiotrack_outlined)),
      ButtonSegment(value: 1,label: Text("艺术家"),icon: Icon(Icons.person)),
      ButtonSegment(value: 2,label: Text("专辑"),icon: Icon(Icons.album))],
      selected:search_selected,
    onSelectionChanged: (set){search_change(setState, set);},)];

    List<Widget> roma=List<Widget>.generate(
          search_list.length, (index) => ListTile(title: Text(music_list[search_list[index]]),
          onTap: (){list_click(search_list[index_list[index]]);}));
    List<Widget> ferenze=List<Widget>.generate(
          search_artist_list.length, (index) => ListTile(title: Text(search_artist_list[index]),
          onTap: (){art_show(context, artist_list[search_artist_list[index]],search_artist_list[index]);}));
    List<Widget> bronia=List<Widget>.generate(
          search_album_list.length, (index) => ListTile(title: Text(search_album_list[index]),
          onTap: (){art_show(context, album_list[search_album_list[index]],search_album_list[index]);}));

    return AlertDialog(content:SizedBox(child: Theme(data:ThemeData(colorScheme: material_you),
        child: PageView(controller: search_control,
        children: [ListView(children: segment+roma),
      ListView(children: segment+ferenze),
      ListView(children: segment+bronia,)])),width:w*0.8,height: h*0.8,));
  }
  void search_change(setState,set){
    search_control.jumpToPage(set.first);
    search_selected=set;
    setState(() {
    });
  }

  void search_show(BuildContext context){
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (BuildContext context,setState){return search_display(context,setState);});
        });
  }


  void hot_key(KeyEvent value){
    if(value is KeyDownEvent){
    if(value.logicalKey.debugName=="Page Up"||value.logicalKey.debugName=="Key ±"){
      player.previous();
    }
    else if(value.logicalKey.debugName=="Page Down"||value.logicalKey.debugName=="Key °"){
      player.next();
    }
    else if(value.logicalKey.debugName=="Space"||value.logicalKey.debugName=="Media Play Pause"){
      play();
    }}
  }

  void koss_change(Set<sam> newSelection){
      Map<sam,double> zeta={sam.extraSmall:0,sam.small:0.5,sam.medium:0.7,sam.large:0.9,};
      Map<sam,String> beta={sam.extraSmall:"0",sam.small:"1",sam.medium:"2",sam.large:"3",};
      koss_selection=newSelection;
      koss_opacity=zeta[newSelection.first]!;
      setting_list[4]=beta[newSelection.first]!;
      setState(() {
      });
  }
  void goss_change(Set<sam> newSelection){
    Map<sam,double> zeta={sam.extraSmall:0,sam.small:30,sam.medium:60,sam.large:100,sam.extraLarge:200};
    Map<sam,String> beta={sam.extraSmall:"0",sam.small:"1",sam.medium:"2",sam.large:"3",sam.extraLarge:"4"};
    goss_selection=newSelection;
    goss_strength=zeta[newSelection.first]!;
    setting_list[6]=beta[newSelection.first]!;
    setState(() {
    });
  }
  void panel_on()async{
    extreme_panel=true;
    w=1280;
    h=720;
    lyrics_height=617.5;
    await windowManager.setSize(Size(1280, 720));
    await windowManager.setAlwaysOnTop(false);
    setState(() {
    });
  }
  void panel_off()async{
    extreme_panel=false;
    lyrics_height=40;
    await windowManager.setSize(Size(600,80));
    await windowManager.setAlwaysOnTop(true);
    setState(() {
    });
  }


  final List<NavigationRailDestination> destinations = const [
    NavigationRailDestination(icon: Icon(Icons.music_note),label: Text("播放")),
    NavigationRailDestination(icon: Icon(Icons.reorder),label: Text("列表")),
    NavigationRailDestination(icon: Icon(Icons.person),label: Text("艺术家")),
    NavigationRailDestination(icon: Icon(Icons.album),label: Text("专辑")),
    NavigationRailDestination(icon: Icon(Icons.settings),label: Text("设置"))
  ];

  Widget player_page(context){
    Widget roma=Padding(padding: const EdgeInsetsGeometry.all(20),child:
    Row(children: [Column(mainAxisAlignment: MainAxisAlignment.center,
        children:[ClipRRect(borderRadius:const BorderRadius.all(Radius.circular(22)),
            child: Image.memory(music_image,width: h*0.55,height: h*0.55,cacheHeight: 700,cacheWidth: 700,)),

          Row(mainAxisAlignment: MainAxisAlignment.center,
              children:[IconButton(onPressed:(){player.previous();}, icon: Icon(Icons.chevron_left)),
                IconButton(onPressed: play, selectedIcon: Icon(Icons.crop_din),
                  icon: Icon(Icons.radio_button_off), isSelected: playing,),
                IconButton(onPressed:(){player.next();}, icon: Icon(Icons.chevron_right)),
              ]),

          TextButton(child: Text(music_name),onPressed: (){tag_show(context);},),
          Row(children: [Builder(builder: (drawer) {return IconButton(icon: const Icon(Icons.menu),
              onPressed: () {now_show(drawer);});}),
            IconButton(icon: Icon(Icons.headphones),onPressed: awsome_music,),
            IconButton(onPressed: shuffle, icon: Icon(Icons.shuffle),
              selectedIcon: Icon(Icons.shuffle_on),
              isSelected: shuffle_on,),
            IconButton(onPressed:(){setState(() {player_mode=(player_mode+1)%3;
            modeking();});},
              icon: Icon([Icons.skip_next,Icons.repeat_one,Icons.pause_outlined][player_mode]),
              isSelected: shuffle_on,),
          ],),
          ValueListenableBuilder<double>(
            builder: time_progress,
            valueListenable: time_value,)

        ]),ValueListenableBuilder<int>(
      builder: lyrics_display,
      valueListenable: lyrics_number,)
    ]));

    return Stack(children: [
      Positioned.fill(child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaY: goss_strength,sigmaX: goss_strength),
            child:Image.memory(music_image,fit: BoxFit.fill,opacity: AlwaysStoppedAnimation(koss_opacity),))),
      roma
    ]);
  }
  Widget list_page(context){
    return Padding(padding: const EdgeInsets.all(20),child:Column(children: [SizedBox(height: 50,
        child: Row(children: [SearchBar(hintText: "search",
            onSubmitted: (value){search_get(value);
          search_show(context);},),
          order_pop(),IconButton(onPressed: re_list, icon: Icon(Icons.music_note))])
    ),
      Expanded(child: ListView.builder(itemCount: music_list.length, itemExtent: 42,
          itemBuilder: (BuildContext ctxt, int index)
          {return ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)))
            ,title: Text(music_list[index_list[index]]),onTap: (){list_click(index_list[index]);},);})
      )],));
  }
  Widget artist_page(context){
    return Padding(padding: const EdgeInsets.all(20),child:Column(children: [
      const ListTile(title: Text("艺术家")),
      Expanded(child:GridView.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.9,
      ),itemCount: artist_widget.length,
          itemBuilder: (context, int index){
            return ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
              title:ClipRRect(borderRadius: const BorderRadius.all(Radius.circular(22)),
                  child:Image.memory(
                    get_image(artist_list[artist_widget[index]][0]),cacheWidth: 180,cacheHeight: 180,)),
              subtitle: Text(artist_widget[index]),
              onTap: (){art_show(context,artist_list[artist_widget[index]],artist_widget[index]);},);
          }))]));
  }
  Widget album_page(context){
    return Padding(padding: const EdgeInsets.all(20),child:Column(children:
    [const ListTile(title: Text("专辑")),
      Expanded(child: CarouselView.builder(itemCount:album_widget.length,
          itemExtent: h-200,
          itemBuilder: (context, int index){
            return ListTile(title:ClipRRect(borderRadius: const BorderRadius.all(Radius.circular(22)),
                child:Image.memory(cacheHeight: 1000,cacheWidth: 1000,
                    get_image(album_list[album_widget[index]][0]))),
              subtitle: Text(album_widget[index]),
              onTap: (){art_show(context,album_list[album_widget[index]],album_widget[index]);},);
          }))
    ]));
  }
  Widget set_page(context){
    return Padding(padding: const EdgeInsets.all(20),child:ListView(children: [
      ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
        title: Text("文件夹选择"),onTap: file_load,leading: Icon(Icons.folder),),
      ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
        title: Text("重新扫描文件夹"),leading: Icon(Icons.refresh),onTap:(){file_scan(setting_list[1]);},),
      ListTile(title: Text("每次启动是否扫描文件夹"),leading: Icon(Icons.auto_mode),
        trailing: Switch(value: auto_scan, onChanged: (value){setState(() {
          auto_scan=value;
        });
        setting_list[2]="$auto_scan";}),),
    Divider(),
    ListTile(title: Text("高斯模糊效果"),leading: Icon(Icons.blur_linear),
    trailing: SegmentedButton<sam>(segments: const <ButtonSegment<sam>>[
      ButtonSegment<sam>(label: Text("关闭"),value: sam.extraSmall),
      ButtonSegment<sam>(label: Text("低档"),value: sam.small),
      ButtonSegment<sam>(label: Text("中档"),value: sam.medium),
      ButtonSegment<sam>(label: Text("高档"),value: sam.large),],
        selected:koss_selection,
        onSelectionChanged: (Set<sam> newSelection){koss_change(newSelection);}
    ),
    ),
      ListTile(title: Text("高斯模糊强度"),leading: Icon(Icons.blur_linear),
        trailing: SegmentedButton<sam>(segments: const <ButtonSegment<sam>>[
          ButtonSegment<sam>(label: Text("关闭"),value: sam.extraSmall),
          ButtonSegment<sam>(label: Text("低档"),value: sam.small),
          ButtonSegment<sam>(label: Text("中档"),value: sam.medium),
          ButtonSegment<sam>(label: Text("高档"),value: sam.large),
          ButtonSegment<sam>(label: Text("极高档"),value: sam.extraLarge),],
            selected:goss_selection,
            onSelectionChanged: (Set<sam> newSelection){goss_change(newSelection);}
        ),
      ),
      ListTile(title: Text("是否开启字体阴影"),leading: Icon(Icons.blur_on),
        trailing: Switch(value: bool.parse(setting_list[5]), onChanged: (value){text_blur_on(value);}),),
      ListTile(leading: Icon(Icons.text_fields),
        title: Text("歌词字体大小调节"),onTap: (){text_show(context);},),
      Divider(),
      ListTile(title: Text("清空本地缓存"),leading: Icon(Icons.cleaning_services),onTap: set_clear,),
      ListTile(title: Text("版本号：1.01"),leading: Icon(Icons.computer),)]));
  }

  @override
  Widget build(BuildContext context) {
    if (extreme_panel){
    return Theme(data: ThemeData(colorScheme: material_you,brightness: Brightness.light),
        child:KeyboardListener(autofocus: true,focusNode: focusNode,onKeyEvent: hot_key ,child:Scaffold(
      appBar: AppBar(toolbarHeight: 50,leadingWidth:90,backgroundColor: material_you.primaryContainer,
          actions: [
            IconButton(onPressed: panel_off, icon: Icon(Icons.dashboard_outlined)),
            IconButton(onPressed: (){windowManager.minimize();}, icon: Icon(Icons.radio_button_off)),
            IconButton(onPressed: (){windowManager.maximize();get_size();}, icon: Icon(Icons.crop_din)),
            IconButton(onPressed: (){set_load();}, icon: Icon(Icons.close)),],
        leading: const DragToMoveArea(child:Card())),
      body:Center(
        child:Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[Card(clipBehavior: Clip.antiAlias,
              child: NavigationRail(destinations:destinations,onDestinationSelected: page_change
              , selectedIndex: page_index,backgroundColor: material_you.secondaryContainer))
            ,Expanded(child: Card(clipBehavior: Clip.antiAlias,
                child: PageView(controller: page_control
              ,children: [
                player_page(context), list_page(context), artist_page(context),
                      album_page(context), set_page(context),
          ])
            ))
          ])
      ),
    )));}
    else{
      return Theme(data: ThemeData(colorScheme: material_you,brightness: Brightness.light),
        child: Scaffold(appBar: AppBar(toolbarHeight: 30,leadingWidth:30,
          leading: const DragToMoveArea(child:Card()),actions: [Text(music_name),
          IconButton(onPressed:(){player.previous();}, icon: Icon(Icons.chevron_left)),
          IconButton(onPressed: play, selectedIcon: Icon(Icons.crop_din),
            icon: Icon(Icons.radio_button_off), isSelected: playing,),
          IconButton(onPressed:(){player.next();}, icon: Icon(Icons.chevron_right)),
          IconButton(icon: Icon(Icons.dashboard_outlined),onPressed:panel_on,),
          IconButton(onPressed: (){set_load();}, icon: Icon(Icons.close))],),
          
          body: Row(mainAxisAlignment: MainAxisAlignment.center,
              children:[
                ValueListenableBuilder<int>(
                  builder: lyrics_display,
                  valueListenable: lyrics_number,)
              ]),),);
    }
  }

}

class Myinitial extends StatelessWidget {
  const Myinitial({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const initialHome(title: ''),);}
}

class initialHome extends StatefulWidget {
  const initialHome({super.key, required this.title});
  final String title;

  @override
  State<initialHome> createState() => initialPage();
}

class initialPage extends State<initialHome> {
   List<String> musicplace=[];
   bool have_music=false;

   void right_show(BuildContext context){
     AlertDialog alert=AlertDialog(content: SizedBox(width: 300,height: 100,child:
     ListTile(title: Text("扫描完成"),leading: Icon(Icons.celebration),)),);

     showDialog(
       context: context,
       builder: (BuildContext context) {
         return alert;},);
   }

   void file_scan()async{
     String? selectedDirectory = await FilePicker.getDirectoryPath();
     List<File> folder=[];
     if(selectedDirectory!=null) {
       folder = Directory(selectedDirectory)
           .listSync(recursive: true)
           .whereType<File>()
           .where((element) =>
       element.path.toLowerCase().endsWith(".ogg") ||
           element.path.toLowerCase().endsWith(".m4a") ||
           element.path.toLowerCase().endsWith(".mp3") ||
           element.path.toLowerCase().endsWith(".flac")||
           element.path.endsWith(".wav"))
           .toList();
     }
     if(folder.isNotEmpty){
       for(int i=0; i<folder.length; i++ ){
         musicplace.add(folder[i].path);
       }
       final prefs = await SharedPreferences.getInstance();
       await prefs.setStringList('saved_my_list', musicplace);
       right_show(context);
       setState(() {have_music=true;
       });
     }
   }
   void end_initial(){
     if(have_music){
       Navigator.pop(context);
     Navigator.push(
       context,
       MaterialPageRoute<void>(
         builder: (context) => const MyApp(),
       ),
     );
   }
   }

   @override
    Widget build(BuildContext context) {
  return Scaffold(floatingActionButton:IconButton(
    onPressed: end_initial, icon: Icon(Icons.incomplete_circle),isSelected: have_music,
  selectedIcon: Icon(Icons.navigate_next),),
      appBar: AppBar(title: Text("欢迎使用Wind Player请先完成如下设置"),toolbarHeight: 100,),
      body: Center(child: Column(children: [
        ListTile(leading: Icon(Icons.folder_copy),
          title:Text("选择音乐文件夹"),onTap: file_scan,)],),),);
   }
}
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({super.key});

  void set_clear()async{
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning,
              size: 200,
              color: Colors.amber,
            ),
            const SizedBox(height: 48),
            TextButton(
              child: const Text('So... something funny happened click to clear cache',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              )),onPressed: set_clear),
            const SizedBox(height: 16),
            const Text(
              'This error is crazy large it covers your whole screen. But no worries'
                  ' though, we\'re working to fix it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}