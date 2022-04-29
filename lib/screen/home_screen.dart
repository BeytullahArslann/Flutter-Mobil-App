import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobilproje2/screen/gallery_screen.dart';
import 'package:mobilproje2/screen/hescode_screen.dart';
import 'package:mobilproje2/screen/profile_screen.dart';
import 'package:mobilproje2/screen/todos_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

//https://docs.flutter.dev/cookbook/design/drawer
//https://www.flutterant.com/switching-themes-in-flutter-apps/

class HomeScreen extends StatefulWidget {
  _homeScreen createState() => _homeScreen();
}

String title = "Yapılacaklar";

class _homeScreen extends State<HomeScreen> {
  int selectedIndex = 0;
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeModel(),
      child: Consumer<ThemeModel>(
          builder: (context, ThemeModel themeNotifier, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          theme: themeNotifier.isDark ? ThemeData.dark() : ThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: [
                IconButton(
                    icon: Icon(themeNotifier.isDark
                        ? Icons.nightlight_round
                        : Icons.wb_sunny),
                    onPressed: () {
                      themeNotifier.isDark
                          ? themeNotifier.isDark = false
                          : themeNotifier.isDark = true;
                    })
              ],
            ),
            drawer: _HomeScreenState((int index) {
              setState(() {
                selectedIndex = index;
              });
            }, selectedIndex),
            body: Builder(
              builder: (context) {
                if (selectedIndex == 0) {
                  return TodoList();
                }
                if (selectedIndex == 1) {
                  return GalleryScreen();
                }
                if (selectedIndex == 2) {
                  return HesCodeScreen();
                }
                if (selectedIndex == 3) {
                  return ProfileScreen();
                }
                if (selectedIndex == 9) {
                  return ProfileScreen();
                }
                return Container();
              },
            ),
          ),
        );
      }),
    );
  }
}

class _HomeScreenState extends StatelessWidget {
  final Function onIndexChanged;
  final int selectedIndex;
  FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  _HomeScreenState(this.onIndexChanged, this.selectedIndex);

  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
      children: [
        UserAccountsDrawerHeader(
          decoration: BoxDecoration(
            color: Colors.cyan,
          ),
          currentAccountPicture: StreamBuilder<QuerySnapshot>(
            stream: _firebaseFirestore.collection("profil").snapshots(),
            builder: (context, snapshot) {
              return snapshot.hasError
                  ? Center(
                      child: Text("İnternet bağlantınızı kontrol edin"),
                    )
                  : snapshot.data?.size! != null
                      ? GridView.count(
                          crossAxisCount: 1,
                          children: snapshot.data!.docs
                              .map(
                                (e) => Container(
                                    child: GestureDetector(
                                  child: PopupMenuButton<String>(
                                    onSelected: handleClick,
                                    child: CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(e.get("url")),
                                    ),
                                    itemBuilder: (BuildContext context) {
                                      return {'Degiştir'}.map((String choice) {
                                        return PopupMenuItem<String>(
                                          value: e.get("id").toString(),
                                          child: Text(choice),
                                        );
                                      }).toList();
                                    },
                                  ),
                                )),
                              )
                              .toList(),
                        )
                      : Container(
                          child: Center(
                          child: Text("Yükleniyor..."),
                        ));
            },
          ),
          accountName: StreamBuilder<QuerySnapshot>(
            stream: _firebaseFirestore.collection("profil").snapshots(),
            builder: (context, snapshot) {
              return snapshot.hasError
                  ? Center(
                      child: Text("İnternet bağlantınızı kontrol edin"),
                    )
                  : snapshot.data?.size! != null
                      ? Container(
                          height: 50,
                          child: ListView(
                            padding: EdgeInsets.only(top: 35),
                            children: snapshot.data!.docs
                                .map(
                                  (e) => Text(
                                    e.get("name"),
                                  ),
                                )
                                .toList(),
                          ),
                        )
                      : Container(
                          child: Center(
                          child: Text("Yükleniyor..."),
                        ));
            },
          ),
          accountEmail: StreamBuilder<QuerySnapshot>(
            stream: _firebaseFirestore.collection("profil").snapshots(),
            builder: (context, snapshot) {
              return snapshot.hasError
                  ? Center(
                      child: Text("İnternet bağlantınızı kontrol edin"),
                    )
                  : snapshot.data?.size! != null
                      ? Container(
                          height: 25,
                          child: ListView(
                            padding: EdgeInsets.only(top: 10),
                            children: snapshot.data!.docs
                                .map(
                                  (e) => Text(
                                    e.get("email"),
                                  ),
                                )
                                .toList(),
                          ),
                        )
                      : Container(
                          child: Center(
                          child: Text("Yükleniyor..."),
                        ));
            },
          ),
        ),
        ListTile(
          title: Text('Yapılacaklar'),
          leading: Icon(Icons.list_alt),
          selected: selectedIndex == 0,
          onTap: () {
            title = "Yapılacaklar";
            Navigator.of(context).pop();
            onIndexChanged(0);
          },
        ),
        ListTile(
          title: Text('Fotograflar'),
          leading: Icon(Icons.photo_album),
          selected: selectedIndex == 1,
          onTap: () {
            Navigator.of(context).pop();
            title = "Fotograflar";
            onIndexChanged(1);
          },
        ),
        ListTile(
          title: Text('Hes Kod'),
          leading: Icon(Icons.medical_services_rounded),
          selected: selectedIndex == 2,
          onTap: () {
            Navigator.of(context).pop();
            title = "Hes Kod";
            onIndexChanged(2);
          },
        ),
        ListTile(
          title: Text('Profil'),
          leading: Icon(Icons.emoji_people_outlined),
          selected: selectedIndex == 3,
          onTap: () {
            Navigator.of(context).pop();
            title = "Profil";
            onIndexChanged(3);
          },
        ),
      ],
    ));
  }

  handleClick(String value) {
    print("value");
    title = "Profil";
    onIndexChanged(9);
  }
}

class ThemePreferences {
  static const PREF_KEY = "pref_key";

  setTheme(bool value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool(PREF_KEY, value);
  }

  getTheme() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getBool(PREF_KEY) ?? false;
  }
}

class ThemeModel extends ChangeNotifier {
  bool _isDark = false;
  ThemePreferences _preferences = ThemePreferences();
  bool get isDark => _isDark;

  ThemeModel() {
    _isDark = false;
    _preferences = ThemePreferences();
    getPreferences();
  }
  set isDark(bool value) {
    _isDark = value;
    _preferences.setTheme(value);
    notifyListeners();
  }

  getPreferences() async {
    _isDark = await _preferences.getTheme();
    notifyListeners();
  }
}
