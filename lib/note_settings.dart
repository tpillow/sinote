import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:prompt_dialog/prompt_dialog.dart';

import 'data.dart';

class NoteSettings extends StatefulWidget {
  final String noteTitle;

  NoteSettings(this.noteTitle, {Key key}) : super(key: key);

  @override
  _NoteSettingsState createState() => _NoteSettingsState();
}

class _NoteSettingsState extends State<NoteSettings> {
  bool _passwordInUse = false;

  @override
  void initState() {
    super.initState();
    _reloadSettings();
  }

  Future<void> _reloadSettings() async {
    _passwordInUse =
        await DataManager.instance.hasPasswordSet(widget.noteTitle);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Note Settings"),
        centerTitle: true,
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            value: _passwordInUse,
            title: Text("Password Protected?"),
            onChanged: (bool usePassword) async {
              if (usePassword) {
                String password = await prompt(
                  context,
                  title: Text("Set Password"),
                  hintText: "Password (this is NOT stored securely!)",
                  autoFocus: true,
                  textOK: Text("Set Password"),
                  textCancel: Text("Cancel"),
                  obscureText: true,
                );

                if (password != null) {
                  await DataManager.instance
                      .setPassword(widget.noteTitle, password);
                  toast("Password set.");
                  await _reloadSettings();
                } else {
                  toast("Password settings unchanged.");
                }
              } else {
                await DataManager.instance.setPassword(widget.noteTitle, null);
                toast("Password unset.");
                await _reloadSettings();
              }
            },
          ),
          ListTile(
            title: Text("Delete All Notes"),
            onTap: () async {
              if (await confirm(
                context,
                title: Text("Delete All Notes?"),
                content: Text("Are you sure? This cannot be undone."),
              )) {
                NoteData data = await DataManager.instance
                    .getNoteData(widget.noteTitle, shallow: false);
                data.notes.clear();
                await DataManager.instance.saveNoteData(data);
                toast("All notes deleted.");
              }
            },
          ),
        ],
      ),
    );
  }
}
