import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/mumin_adhan_audio_handler.dart';

class AdhanAudioLibraryPage extends StatefulWidget {
  const AdhanAudioLibraryPage({super.key});
  @override
  State<AdhanAudioLibraryPage> createState() => _AdhanAudioLibraryPageState();
}
class _AdhanAudioLibraryPageState extends State<AdhanAudioLibraryPage> {
  static const _selectionKey = 'mumin_adhan_selected_audio_id_v1';
  static const _legacyModeKey = 'mumin_adhan_audio_mode_v1';
  // Register future complete Adhan recordings here; only the selected id is played.\n  static const _items = <_Recording>[
    _Recording('adhan_recording_1','assets/audio/notifications/adhan_takbeer_twice.mp3','تسجيل الأذان الأول','Adhan recording 1','Enregistrement Adhan 1'),
    _Recording('adhan_recording_2','assets/audio/adhan/adhan_full.mp3','تسجيل الأذان الثاني','Adhan recording 2','Enregistrement Adhan 2'),
  ];
  String _selected = _items.first.id;
  String? _testing;
  bool _loading = true;
  String _t(String ar,String en,String fr) {
    final c=Localizations.localeOf(context).languageCode;
    return c=='en'?en:c=='fr'?fr:ar;
  }
  String _name(_Recording r)=>_t(r.ar,r.en,r.fr);
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    final p=await SharedPreferences.getInstance();
    var id=p.getString(_selectionKey);
    if(id==null){id=p.getString(_legacyModeKey)=='full'?_items[1].id:_items[0].id;await p.setString(_selectionKey,id);}
    if(!mounted)return;
    setState(()=>_selected=_items.any((e)=>e.id==id)?id!:_items.first.id);
    setState(()=>_loading=false);
  }
  Future<void> _select(_Recording r) async {
    final a=context.read<MuminAdhanAudioHandler>(); await a.stop();
    final ok=await (await SharedPreferences.getInstance()).setString(_selectionKey,r.id);
    if(!ok){_message(_t('تعذر حفظ اختيار الصوت.','Could not save audio selection.','Impossible d’enregistrer le choix audio.'));return;}
    if(mounted)setState(()=>_selected=r.id);
  }
  Future<void> _test(_Recording r) async {
    if(_testing!=null)return;setState(()=>_testing=r.id);
    try {final a=context.read<MuminAdhanAudioHandler>();await a.stop();await a.playAsset(r.asset,title:_name(r));}
    catch(_){_message(_t('تعذر تشغيل التسجيل.','Could not play recording.','Impossible de lire l’enregistrement.'));}
    finally{if(mounted)setState(()=>_testing=null);}
  }
  void _message(String s){if(!mounted)return;ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content:Text(s)));}
  @override Widget build(BuildContext context){
    final th=Theme.of(context);final cs=th.colorScheme;
    return Scaffold(appBar:AppBar(title:Text(_t('مكتبة أصوات الأذان','Adhan sound library','Bibliothèque des sons Adhan')),centerTitle:true),
      body:_loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:[
        Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),gradient:const LinearGradient(colors:[Color(0xFF0B5944),Color(0xFF061C17)]),border:Border.all(color:const Color(0x66D8B66A))),
          child:Text(_t('اختر تسجيلاً واحداً من مكتبة الأذان. كلا التسجيلين أذان كامل، ويمكن اختبار كل واحد منفرداً قبل اعتماده.','Choose one recording. Both files are complete Adhan recordings and can be tested independently.','Choisissez un enregistrement. Les deux fichiers sont des Adhan complets et peuvent être testés séparément.'),style:th.textTheme.bodyMedium?.copyWith(color:Colors.white,height:1.5))),
        const SizedBox(height:18),
        for(final r in _items) Padding(padding:const EdgeInsets.only(bottom:12),child:Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:_selected==r.id?const Color(0x14D8B66A):cs.surface,borderRadius:BorderRadius.circular(20),border:Border.all(color:_selected==r.id?const Color(0xFFD8B66A):cs.outlineVariant,width:_selected==r.id?1.8:1)),
          child:Column(children:[
            Row(children:[const CircleAvatar(backgroundColor:Color(0x1FD8B66A),child:Icon(Icons.graphic_eq_rounded,color:Color(0xFFD8B66A))),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(_name(r),style:th.textTheme.titleSmall?.copyWith(fontWeight:FontWeight.w800)),Text(_t('تسجيل أذان كامل','Complete Adhan recording','Enregistrement Adhan complet'),style:th.textTheme.bodySmall?.copyWith(color:cs.onSurfaceVariant))])),if(_selected==r.id)const Icon(Icons.check_circle_rounded,color:Color(0xFFD8B66A))else Icon(Icons.radio_button_unchecked_rounded,color:cs.onSurfaceVariant)]),
            const SizedBox(height:12),Row(children:[
              Expanded(child:OutlinedButton.icon(onPressed:_testing==null?()=>_test(r):null,icon:_testing==r.id?const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.play_arrow_rounded),label:Text(_t('اختبار هذا الصوت','Test this sound','Tester ce son')))),
              const SizedBox(width:10),
              Expanded(child:FilledButton(onPressed:_selected==r.id?null:()=>_select(r),style:FilledButton.styleFrom(backgroundColor:const Color(0xFF075B46),foregroundColor:Colors.white),child:Text(_selected==r.id?_t('الصوت المعتمد','Selected','Sélectionné'):_t('اعتماد الصوت','Select sound','Sélectionner'))))
            ])
          ]))),
        Text(_t('المكتبة قابلة لإضافة تسجيلات أخرى لاحقاً، وإعداداتها مستقلة عن الخلفيات.','More recordings can be added later; this library is independent from backgrounds.','D’autres enregistrements pourront être ajoutés ; cette bibliothèque est indépendante des arrière-plans.'),style:th.textTheme.bodySmall?.copyWith(color:cs.onSurfaceVariant))
      ]));
  }
}
class _Recording {
  const _Recording(this.id,this.asset,this.ar,this.en,this.fr);
  final String id,asset,ar,en,fr;
}