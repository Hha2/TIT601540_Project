import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/app_usage.dart';
import '../../widgets/mood_chart.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  List<double> _moodTrend = [];
  List<Map<String, dynamic>> _events = [];
  List<AppUsageEntry> _usage = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    final svc = FirestoreService(uid);
    final moods = await svc.getMoodsLast7Days();
    final events = await svc.getTaskCompletionEventsLast7Days();
    final usage = await svc.getAppUsageLast7Days();
    final grouped = <String, List<int>>{};
    final now = DateTime.now();
    for (int i=6;i>=0;i--) { grouped[DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days:i)))] = []; }
    for (final m in moods) { grouped[m.date]?.add(m.mood); }
    if (!mounted) return;
    setState(() {
      _moodTrend = grouped.values.map((v)=>v.isEmpty?2.0:v.reduce((a,b)=>a+b)/v.length).toList();
      _events = events;
      _usage = usage;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().theme;
    final goals = context.watch<GoalsProvider>();
    final stability = goals.stabilityScore;
    final risk = (goals.skipProbability * 100).round().clamp(0, 100);
    final bestWindow = _bestWindow();
    final recovery = _recoveryText(goals);
    final distraction = _biggestDistraction();

    return Scaffold(
      backgroundColor: theme.background,
      body: RefreshIndicator(
        color: theme.accent,
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _Header(theme: theme)),
          if (_loading)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
          else ...[
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16,16,16,0), child: _SummaryCard(theme: theme, stability: stability, risk: risk, bestWindow: bestWindow, recovery: recovery))),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16,14,16,0), child: _CalendarHeatmap(theme: theme, events: _events))),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16,14,16,0), child: _PatternCard(theme: theme, title: 'Completion pattern', subtitle: 'Based on actual task completion timestamps', children: _timeBars(theme)))),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16,14,16,0), child: _MoodCard(theme: theme, data: _moodTrend))),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16,14,16,0), child: _PatternCard(theme: theme, title: 'Distraction signal', subtitle: distraction == null ? 'No logged usage yet. Add usage data to reveal distraction patterns.' : '${distraction.appName} took the most logged time this week.', children: [_usageLine(theme, distraction)]))),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16,14,16,28), child: _AdviceCard(theme: theme, goals: goals, risk: risk, bestWindow: bestWindow))),
          ],
        ]),
      ),
    );
  }

  String _bestWindow() {
    final counts = {'Morning':0,'Afternoon':0,'Evening':0,'Night':0};
    for (final e in _events) { counts[_bucket(e['hour'] as int? ?? 12)] = counts[_bucket(e['hour'] as int? ?? 12)]! + 1; }
    final sorted = counts.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
    return sorted.first.value == 0 ? 'Learning' : sorted.first.key;
  }
  String _bucket(int h) { if(h>=5&&h<12) return 'Morning'; if(h>=12&&h<17) return 'Afternoon'; if(h>=17&&h<21) return 'Evening'; return 'Night'; }
  String _recoveryText(GoalsProvider goals) { if(goals.totalOverdueDays>0) return '${goals.totalOverdueDays} overdue day(s)'; if(goals.currentStreak>0) return '${goals.currentStreak} day streak'; return 'baseline building'; }
  AppUsageEntry? _biggestDistraction(){ if(_usage.isEmpty) return null; final by=<String,int>{}; final cat=<String,String>{}; for(final u in _usage){by[u.appName]=(by[u.appName]??0)+u.minutes; cat[u.appName]=u.category;} final sorted=by.entries.toList()..sort((a,b)=>b.value.compareTo(a.value)); final top=sorted.first; return AppUsageEntry(id:top.key, appName:top.key, category:cat[top.key]??'Others', minutes:top.value, date:'', timestamp:DateTime.now()); }

  List<Widget> _timeBars(dynamic theme) {
    final counts={'Morning':0,'Afternoon':0,'Evening':0,'Night':0};
    for(final e in _events){counts[_bucket(e['hour'] as int? ?? 12)]=counts[_bucket(e['hour'] as int? ?? 12)]!+1;}
    final max=counts.values.fold<int>(1,(a,b)=>a>b?a:b);
    final icons={'Morning':Icons.wb_sunny_rounded,'Afternoon':Icons.light_mode_rounded,'Evening':Icons.nights_stay_rounded,'Night':Icons.bedtime_rounded};
    return counts.entries.map((e)=>Padding(padding:const EdgeInsets.only(bottom:12),child:Row(children:[SizedBox(width:112,child:Row(children:[Icon(icons[e.key],color:theme.accent,size:18),const SizedBox(width:8),Text(e.key,style:TextStyle(color:theme.textMuted,fontWeight:FontWeight.w700,fontSize:12))])),Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:e.value/max, minHeight:9, backgroundColor:theme.border, valueColor:AlwaysStoppedAnimation(theme.accent)))),const SizedBox(width:10),Text('${e.value}',style:TextStyle(color:theme.text,fontWeight:FontWeight.w900))]))).toList();
  }
  Widget _usageLine(dynamic theme, AppUsageEntry? d){ if(d==null) return Text('Nothing harmful detected yet. This becomes useful after usage logging exists.',style:TextStyle(color:theme.textMuted,height:1.4)); return Row(children:[Icon(Icons.phone_android_rounded,color:theme.danger),const SizedBox(width:10),Expanded(child:Text('${d.appName} • ${d.formattedTime} logged',style:TextStyle(color:theme.text,fontWeight:FontWeight.w800))),]); }
}

class _Header extends StatelessWidget { final dynamic theme; const _Header({required this.theme}); @override Widget build(BuildContext context)=>Container(decoration:BoxDecoration(gradient:theme.headerGradient),child:SafeArea(bottom:false,child:Padding(padding:const EdgeInsets.fromLTRB(20,20,20,28),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Insights',style:const TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:8),Text('Patterns that help you recover, not pressure you.',style:TextStyle(color:Colors.white.withValues(alpha:.76)))]))));}
class _SummaryCard extends StatelessWidget { final dynamic theme; final int stability; final int risk; final String bestWindow; final String recovery; const _SummaryCard({required this.theme,required this.stability,required this.risk,required this.bestWindow,required this.recovery}); @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:theme.card,borderRadius:BorderRadius.circular(24),border:Border.all(color:theme.border)),child:Column(children:[Row(children:[_Metric(theme:theme,label:'Stability',value:'$stability%',icon:Icons.shield_rounded),_Metric(theme:theme,label:'Skip risk',value:'$risk%',icon:Icons.trending_down_rounded),_Metric(theme:theme,label:'Best window',value:bestWindow,icon:Icons.schedule_rounded)]),const SizedBox(height:14),Container(width:double.infinity,padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:theme.accentSoft,borderRadius:BorderRadius.circular(18)),child:Text('Recovery status: $recovery. The goal is not perfection — it is returning faster after a miss.',style:TextStyle(color:theme.text,height:1.35,fontWeight:FontWeight.w700)))]));}
class _Metric extends StatelessWidget { final dynamic theme; final String label; final String value; final IconData icon; const _Metric({required this.theme,required this.label,required this.value,required this.icon}); @override Widget build(BuildContext context)=>Expanded(child:Column(children:[Icon(icon,color:theme.accent),const SizedBox(height:8),Text(value,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:theme.text,fontSize:17,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(label,style:TextStyle(color:theme.textMuted,fontSize:11,fontWeight:FontWeight.w700))]));}
class _CalendarHeatmap extends StatelessWidget { final dynamic theme; final List<Map<String,dynamic>> events; const _CalendarHeatmap({required this.theme,required this.events}); @override Widget build(BuildContext context){ final keys=events.map((e)=>DateFormat('yyyy-MM-dd').format(e['timestamp'] as DateTime)).toSet(); final now=DateTime.now(); return Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:theme.card,borderRadius:BorderRadius.circular(24),border:Border.all(color:theme.border)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('7-day consistency calendar',style:TextStyle(color:theme.text,fontWeight:FontWeight.w900,fontSize:16)),const SizedBox(height:14),Row(children:List.generate(7,(i){final day=now.subtract(Duration(days:6-i)); final done=keys.contains(DateFormat('yyyy-MM-dd').format(day)); return Expanded(child:Column(children:[Container(width:36,height:36,decoration:BoxDecoration(color:done?theme.accent:theme.background,borderRadius:BorderRadius.circular(12),border:Border.all(color:done?theme.accent:theme.border)),child:Icon(done?Icons.check_rounded:Icons.remove_rounded,color:done?Colors.white:theme.textFaint)),const SizedBox(height:6),Text(DateFormat('E').format(day).substring(0,1),style:TextStyle(color:theme.textMuted,fontSize:11,fontWeight:FontWeight.w800))]));}))]));}}
class _PatternCard extends StatelessWidget { final dynamic theme; final String title; final String subtitle; final List<Widget> children; const _PatternCard({required this.theme,required this.title,required this.subtitle,required this.children}); @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:theme.card,borderRadius:BorderRadius.circular(24),border:Border.all(color:theme.border)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:TextStyle(color:theme.text,fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:5),Text(subtitle,style:TextStyle(color:theme.textMuted,fontSize:12)),const SizedBox(height:16),...children]));}
class _MoodCard extends StatelessWidget { final dynamic theme; final List<double> data; const _MoodCard({required this.theme,required this.data}); @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:theme.card,borderRadius:BorderRadius.circular(24),border:Border.all(color:theme.border)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Mood vs momentum',style:TextStyle(color:theme.text,fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:6),Text('Mood check-ins help explain why some days are easier than others.',style:TextStyle(color:theme.textMuted,fontSize:12)),const SizedBox(height:14),SizedBox(height:105,child:MoodLineChart(data:data,theme:theme))]));}
class _AdviceCard extends StatelessWidget { final dynamic theme; final GoalsProvider goals; final int risk; final String bestWindow; const _AdviceCard({required this.theme,required this.goals,required this.risk,required this.bestWindow}); @override Widget build(BuildContext context){ final msg=risk>65?'High-risk day. Do one tiny task now and use Reflect if you feel stuck.':goals.totalOverdueDays>0?'Clear the oldest active day before starting anything new.':'Your pattern is stable enough. Protect it with one small action.'; return Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:theme.linearGradient,borderRadius:BorderRadius.circular(24)),child:Row(children:[const Icon(Icons.auto_awesome_rounded,color:Colors.white),const SizedBox(width:12),Expanded(child:Text('$msg Best window: $bestWindow.',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,height:1.35)))]));}}
