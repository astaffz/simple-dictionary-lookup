import 'package:dictionaryx/dictentry.dart';
import 'package:dictionaryx/dictionary_msa_json_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:settings_ui/settings_ui.dart';

void main() async {
  runApp(MyApp());
  WidgetsFlutterBinding.ensureInitialized();
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);
  static const double ver = 0.1;

  final themeData = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.black38),
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WhatsTheWord',
        theme: themeData,
        home: MyHomePage(),
        themeMode: ThemeMode.light,
        darkTheme: ThemeData.dark(useMaterial3: true),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  static var theme = Brightness.light;
  var dictionary = DictionaryMSAFlutter();
  Brightness getTheme() {
    return theme;
  }

  void setTheme(Brightness mode) {
    theme = mode;
    notifyListeners();
  }

  var entries = <String>[];
  void toggleEntries(String text) {
    if (text.isAlphabetOnly) {
      if (entries.contains(text)) {
        entries.remove(text);
      }
      entries.insert(0, text);
    }
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    // Switch-case for the nav-rail and co-responding page index
    switch (selectedPageIndex) {
      case 0:
        page = SearchPage(); // Home
        break;
      case 1:
        page = HistoryPage(); // History
        break;
      case 2:
        page = SettingsPage(); // Settings
        break;
      default:
        throw UnimplementedError("No widget for $selectedPageIndex!");
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                minWidth: 100,
                extended: false,
                destinations: [
                  NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text(
                        "Home",
                      )),
                  NavigationRailDestination(
                    icon: Icon(Icons.history),
                    label: Text(
                      "History",
                    ),
                  ),
                  NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      label: Text(
                        "Settings",
                      )),
                ],
                selectedIndex: selectedPageIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedPageIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class SearchPage extends StatefulWidget {
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool wordFound = false;
  bool showResult = false;
  DictEntry? _entry;
  String? input;
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final theme = Theme.of(context);
    final TextEditingController wordController = TextEditingController();
    final dictionaryMSAJson = DictionaryMSAFlutter();

    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimaryContainer,
    );
    void lookupWord() async {
      DictEntry? tmp;
      final txt = wordController.text.trim().toString();
      if (txt.isAlphabetOnly && await dictionaryMSAJson.hasEntry(txt)) {
        tmp = await dictionaryMSAJson.getEntry(txt);
      }

      setState(() {
        showResult = true;
        if (tmp != null) {
          wordFound = true;
          _entry = tmp;
        } else {
          _entry = DictEntry('', [], [], []);
          wordFound = false;
        }
      });
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Card(
          color: theme.colorScheme.onInverseSurface,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Is",
                  style: style,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: wordController,
                  autocorrect: false,
                  style: style,
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "an actual word?",
                  style: style,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                appState.toggleEntries(wordController.text);
                setState(() {
                  input = wordController.text;
                  lookupWord();
                });
              },
              icon: Icon(Icons.search),
              label: Text('Search'),
            ),
          ],
        ),
        SizedBox(
          height: 10,
        ),
        showResult
            ? wordFound
                ? WordFoundCard(entry: _entry, theme: theme)
                : Card(
                    // Word does not exist, display red card
                    color: Colors.red,
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.close_rounded,
                            size: 30,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Text(
                            "No, ${input?.toLowerCase()} is not an actual word",
                            style: theme.textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                      color: Colors.black,
                                      offset: Offset.fromDirection(10))
                                ]),
                          ),
                        ],
                      ),
                    ),
                  )
            : Container(),
      ],
    );
  }
}

class WordFoundCard extends StatelessWidget {
  const WordFoundCard({
    super.key,
    required DictEntry? entry,
    required this.theme,
  }) : _entry = entry;

  final DictEntry? _entry;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      // Word exists, display card with meaning
      color: Colors.lightGreenAccent,
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_box,
                  size: 30,
                  color: Colors.green,
                ),
                SizedBox(width: 5),
                Text(
                  "Yes, ${_entry?.word.toLowerCase()} is an actual English word",
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Divider(
              height: 12,
              color: Colors.black,
            ),
            Text(
                _entry!.meanings.isEmpty
                    ? "Its meaning has not been stored in the application's dictionary"
                    : _entry!.meanings.first.description,
                style: TextStyle(color: Colors.black))
          ],
        ),
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    if (appState.entries.isEmpty) {
      return Center(
        child: Text("No entries recorded!"),
      );
    }
    return ListView(
      reverse: false,
      children: [
        SizedBox(
          height: 10,
        ),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "Entries recorded: ${appState.entries.length}",
              ),
            ),
            ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    appState.entries = [];
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      content: Text("History has been cleared!"),
                      duration: const Duration(milliseconds: 800),
                    ));
                  });
                },
                icon: Icon(Icons.delete_forever),
                label: Text("Clear all")),
          ],
        ),
        for (var entry in appState.entries)
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: ExpansionTile(
              backgroundColor: Theme.of(context).cardColor,
              childrenPadding: EdgeInsets.all(8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              leading: Icon(Icons.history_outlined),
              title: Text(
                entry.toLowerCase(),
              ),
              children: <Widget>[
                Row(
                  children: [
                    ElevatedButton(
                      // Delete button
                      onPressed: () {
                        setState(() {
                          appState.entries.remove(entry);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            content: Text("$entry' has been removed!"),
                            duration: const Duration(milliseconds: 600),
                          ));
                        });
                      },
                      child: Text("Delete"),
                    ),
                  ],
                )
              ],
            ),
          ),
      ],
    );
  }
}

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return SettingsList(
      sections: [
        SettingsSection(
          title: Text('Common'),
          tiles: <SettingsTile>[
            SettingsTile.switchTile(
              onToggle: (value) {
                if (Get.isDarkMode) {
                  Get.changeTheme(MyApp().themeData);
                } else {
                  Get.changeTheme(ThemeData.dark(useMaterial3: true));
                }
              },
              initialValue: false,
              leading: Icon(Icons.format_paint),
              title: Text('Change theme'),
            ),
          ],
        ),
      ],
    );
  }
}
