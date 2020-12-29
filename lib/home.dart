import 'package:alert_dialog/alert_dialog.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:prompt_dialog/prompt_dialog.dart';

import 'data.dart';
import 'note_view.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<NoteData> _noteData = List<NoteData>();

  @override
  void initState() {
    super.initState();
    _reloadNoteData();
    TextFormField();
  }

  Future<void> _reloadNoteData() async {
    _noteData = await DataManager.instance.getAllNoteData();
    _noteData.sort((a, b) => a.title.compareTo(b.title));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sinote"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: _makeNoteDataListWidgets(context),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.create_new_folder_outlined),
                      onPressed: () async {
                        String title = await prompt(
                          context,
                          title: Text("Create Note"),
                          hintText: "New note title",
                          autoFocus: true,
                        );
                        if (title != null) {
                          if (!await DataManager.instance.hasNoteData(title)) {
                            await DataManager.instance.createNoteData(title);
                            await _reloadNoteData();
                          } else {
                            await alert(
                              context,
                              title: Text(
                                  "There's already a note with that name!"),
                            );
                          }
                        }
                      },
                    ),
                    Text("New Note File"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _makeNoteDataListWidgets(BuildContext context) {
    return List.generate(_noteData.length, (i) {
      List<Widget> children = [
        Text(
          _noteData[i].title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ];
      final bool hasPasswordSet = _noteData[i].hasPasswordSet;
      if (hasPasswordSet) children.insert(0, Icon(Icons.lock));

      return InkWell(
        onTap: () async {
          // Validate password
          if (hasPasswordSet) {
            String password = await prompt(
              context,
              title: Text("Enter password"),
              hintText: "Password",
              autoFocus: true,
              obscureText: true,
            );
            if (password != null) {
              if (!await DataManager.instance
                  .validatePassword(_noteData[i].title, password)) {
                toast("Invalid password.");
                return;
              }
            } else {
              return;
            }
          }

          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (ctx) => NoteView(_noteData[i].title)));
          await _reloadNoteData();
        },
        onLongPress: () async {
          // Show popup menu
          final int actionId = await showMenu(
            context: context,
            position: RelativeRect.fill,
            items: [
              PopupMenuItem(
                value: 1,
                child: Text("Rename"),
              ),
              PopupMenuItem(
                value: 2,
                child: Text("Delete"),
              ),
            ],
          );

          // Validate password
          if (hasPasswordSet) {
            String password = await prompt(
              context,
              title: Text("Enter password"),
              hintText: "Password",
              autoFocus: true,
              obscureText: true,
            );
            if (password != null) {
              if (!await DataManager.instance
                  .validatePassword(_noteData[i].title, password)) {
                toast("Invalid password.");
                return;
              }
            } else {
              return;
            }
          }

          // Perform the long-press action
          switch (actionId) {
            case 1: // Rename
              String newTitle = await prompt(
                context,
                title: Text("Rename ${_noteData[i].title}"),
                initialValue: _noteData[i].title,
                hintText: "New title",
                autoFocus: true,
              );
              if (newTitle != null && newTitle != _noteData[i].title) {
                if (await DataManager.instance.hasNoteData(newTitle)) {
                  await alert(
                    context,
                    title: Text("There's already a note with that name!"),
                  );
                } else {
                  await DataManager.instance
                      .renameNoteData(_noteData[i].title, newTitle);
                  await _reloadNoteData();
                }
              }
              break;
            case 2: // Delete
              if (await confirm(context,
                  title: Text(
                      "Are you sure you wish to delete this note? This cannot be undone."),
                  content: Text(
                      "Are you sure you wish to delete ${_noteData[i].title}?"))) {
                await DataManager.instance.deleteNoteData(_noteData[i].title);
                await _reloadNoteData();
              }
              break;
          }
        },
        child: Container(
          padding: EdgeInsets.all(8),
          margin: EdgeInsets.all(8),
          color: Colors.black45,
          child: Row(
            children: children,
          ),
        ),
      );
    });
  }
}
