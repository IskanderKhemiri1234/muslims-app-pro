import 'package:flutter/material.dart';
import 'adhan_audio_library_page.dart';
import 'adhan_background_library_page.dart';

class AdhanMediaSettingsPage extends StatelessWidget {
 const AdhanMediaSettingsPage({super.key});
 String _t(BuildContext c,String a,String e,String f){final l=Localizations.localeOf(c).languageCode;return l=='en'?e:l=='fr'?f:a;}
 void _open(BuildContext c,Widget p)=>Navigator.of(c).push<void>(MaterialPageRoute<void>(builder:(_)=>p));
 @override Widget build(BuildContext context){final th=Theme.of(context);return Scaffold(appBar:AppBar(title:Text(_t(context,'تخصيص شاشة الأذان','Adhan experience settings','Personnaliser l’écran Adhan')),centerTitle:true),body:ListView(padding:const EdgeInsets.all(16),children:[
 Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),gradient:const LinearGradient(colors:[Color(0xFF0B5944),Color(0xFF061C17)]),border:Border.all(color:const Color(0x66D8B66A))),child:Text(_t(context,'الصوت والخلفية إعدادان مستقلان. افتح كل مكتبة لإدارة اختيارها واختبارها دون التأثير على الأخرى.','Sound and background are independent. Manage each library without changing the other.','Le son et l’arrière-plan sont indépendants. Gérez chaque bibliothèque séparément.'),style:th.textTheme.bodyMedium?.copyWith(color:Colors.white,height:1.5))),
 const SizedBox(height:18),
 _Entry(icon:Icons.graphic_eq_rounded,title:_t(context,'مكتبة أصوات الأذان','Adhan sound library','Bibliothèque des sons'),subtitle:_t(context,'اختيار تسجيل واحد واختبار كل تسجيل منفرداً','Select one recording and test each independently','Choisir un enregistrement et tester chaque son'),onTap:()=>_open(context,const AdhanAudioLibraryPage())),
 const SizedBox(height:12),
 _Entry(icon:Icons.wallpaper_rounded,title:_t(context,'مكتبة خلفيات الأذان','Adhan background library','Bibliothèque des arrière-plans'),subtitle:_t(context,'اختيار الصور وإضافتها ومعاينة الشاشة فوراً','Select and add images, then preview instantly','Choisir des images et prévisualiser immédiatement'),onTap:()=>_open(context,const AdhanBackgroundLibraryPage()))
 ]));}
}
class _Entry extends StatelessWidget{
 const _Entry({required this.icon,required this.title,required this.subtitle,required this.onTap});
 final IconData icon;final String title,subtitle;final VoidCallback onTap;
 @override Widget build(BuildContext context){final th=Theme.of(context);return Material(color:th.colorScheme.surface,borderRadius:BorderRadius.circular(20),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(20),child:Padding(padding:const EdgeInsets.all(17),child:Row(children:[Container(width:48,height:48,decoration:BoxDecoration(color:const Color(0x1FD8B66A),borderRadius:BorderRadius.circular(15)),child:Icon(icon,color:const Color(0xFFD8B66A),size:25)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:th.textTheme.titleSmall?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(subtitle,style:th.textTheme.bodySmall?.copyWith(color:th.colorScheme.onSurfaceVariant,height:1.4))])),const Icon(Icons.chevron_right_rounded,color:Color(0xFFD8B66A))]))));}
}