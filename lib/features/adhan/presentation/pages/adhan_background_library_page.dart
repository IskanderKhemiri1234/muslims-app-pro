import 'dart:io';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/mumin_adhan_audio_handler.dart';
import 'mumin_adhan_experience_page.dart';

class AdhanBackgroundLibraryPage extends StatefulWidget {
 const AdhanBackgroundLibraryPage({super.key});
 @override State<AdhanBackgroundLibraryPage> createState()=>_AdhanBackgroundLibraryPageState();
}
class _AdhanBackgroundLibraryPageState extends State<AdhanBackgroundLibraryPage>{
 static const _selectedKey='mumin_adhan_selected_mosque_image_v1',_galleryKey='mumin_adhan_mosque_gallery_v1';
 static const _bundled=['assets/images/mosques/mumin_mosque.jpg','assets/images/adhan/mumin_adhan_hero.jpg'];
 List<String> _images=List.of(_bundled);String? _selected;bool _loading=true,_picking=false;
 String _t(String a,String e,String f){final c=Localizations.localeOf(context).languageCode;return c=='en'?e:c=='fr'?f:a;}
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{final p=await SharedPreferences.getInstance();if(!mounted)return;setState((){_images=<String>{..._bundled,...?p.getStringList(_galleryKey)}.toList();_selected=p.getString(_selectedKey);_loading=false;});}
 Future<void> _select(String path)async{final ok=await(await SharedPreferences.getInstance()).setString(_selectedKey,path);if(!ok){_message(_t('تعذر حفظ الخلفية.','Could not save background.','Impossible d’enregistrer le fond.'));return;}if(mounted)setState(()=>_selected=path);}
 Future<void> _pick()async{if(_picking)return;setState(()=>_picking=true);try{final x=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:88,maxWidth:2200);if(x==null)return;final d=await getApplicationDocumentsDirectory();final ext=x.path.contains('.')?x.path.substring(x.path.lastIndexOf('.')):'.jpg';final dest=File(d.path+'/mumin_adhan_background_'+DateTime.now().microsecondsSinceEpoch.toString()+ext);await File(x.path).copy(dest.path);final list=<String>{..._images,dest.path}.toList();final p=await SharedPreferences.getInstance();final a=await p.setStringList(_galleryKey,list),b=await p.setString(_selectedKey,dest.path);if(!a||!b)throw StateError('Could not save background');if(mounted)setState((){_images=list;_selected=dest.path;});}catch(_){_message(_t('تعذرت إضافة الصورة.','Could not add image.','Impossible d’ajouter l’image.'));}finally{if(mounted)setState(()=>_picking=false);}}
 Future<void> _preview()async{final a=context.read<MuminAdhanAudioHandler>();await Navigator.of(context).push<void>(MaterialPageRoute<void>(fullscreenDialog:true,builder:(_)=>MuminAdhanExperiencePage(prayer:Prayer.fajr,previewMode:true,audioHandlerOverride:a)));}
 Widget _image(String p){if(p.startsWith('assets/'))return Image.asset(p,fit:BoxFit.cover,errorBuilder:(_,__,___)=>_missing());final f=File(p);return f.existsSync()?Image.file(f,fit:BoxFit.cover,errorBuilder:(_,__,___)=>_missing()):_missing();}
 Widget _missing()=>const ColoredBox(color:Color(0xFF071C17),child:Center(child:Icon(Icons.broken_image_outlined,color:Colors.white54)));
 void _message(String s){if(!mounted)return;ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content:Text(s)));}
 @override Widget build(BuildContext context){final th=Theme.of(context);final cs=th.colorScheme;return Scaffold(appBar:AppBar(title:Text(_t('مكتبة خلفيات الأذان','Adhan background library','Bibliothèque des arrière-plans')),centerTitle:true),body:_loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:[
 Text(_t('اختر خلفية مستقلة عن الصوت. يمكنك إضافة صور من هاتفك ومعاينة شاشة الأذان فوراً.','Choose a background independently from audio. Add images from your phone and preview the Adhan screen instantly.','Choisissez un arrière-plan indépendant du son. Ajoutez des images et prévisualisez immédiatement.'),style:th.textTheme.bodyMedium?.copyWith(color:cs.onSurfaceVariant,height:1.5)),
 const SizedBox(height:16),
 GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:_images.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.08),itemBuilder:(c,i){final p=_images[i],chosen=p==_selected||(_selected==null&&p==_bundled.first);return InkWell(onTap:()=>_select(p),borderRadius:BorderRadius.circular(18),child:ClipRRect(borderRadius:BorderRadius.circular(18),child:Stack(fit:StackFit.expand,children:[_image(p),if(chosen)const Positioned(top:8,right:8,child:CircleAvatar(backgroundColor:Color(0xFFD8B66A),child:Icon(Icons.check_rounded,color:Color(0xFF071C17)))),Positioned(bottom:0,left:0,right:0,child:Container(color:Colors.black54,padding:const EdgeInsets.all(8),child:Text(p.startsWith('assets/')?_t('من الحزمة','Bundled','Incluse'):_t('من الهاتف','From phone','Du téléphone'),style:const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.w700))))])));}),
 const SizedBox(height:14),
 OutlinedButton.icon(onPressed:_picking?null:_pick,icon:_picking?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.add_photo_alternate_outlined),label:Text(_t('إضافة صورة من الهاتف','Add image from phone','Ajouter une image'))),
 const SizedBox(height:12),
 FilledButton.icon(onPressed:_preview,icon:const Icon(Icons.visibility_rounded),label:Text(_t('معاينة شاشة الأذان الآن','Preview Adhan screen now','Prévisualiser maintenant')),style:FilledButton.styleFrom(backgroundColor:const Color(0xFF075B46),foregroundColor:Colors.white,padding:const EdgeInsets.symmetric(vertical:14)))
 ]));}
}