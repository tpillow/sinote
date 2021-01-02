import 'package:alert_dialog/alert_dialog.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:prompt_dialog/prompt_dialog.dart';

import 'data.dart';
import 'note_settings.dart';

class NoteView extends StatefulWidget {
  final String noteTitle;

  NoteView(this.noteTitle, {Key key}) : super(key: key);

  @override
  _NoteViewState createState() => _NoteViewState();
}

class _NoteViewState extends State<NoteView> {
  NoteData _data = NoteData("", false);
  ScrollController _scroller = ScrollController();

  @override
  void initState() {
    super.initState();
    _reloadData();
  }

  Future<void> _reloadData() async {
    _data = await DataManager.instance
        .getNoteData(widget.noteTitle, shallow: false);
    setState(() {});
  }

  Future<void> _scrollToBottom() async {
    await _scroller.animateTo(_scroller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${_data.title} (${_data.notes.length})"),
        centerTitle: true,
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView(
              children: _makeNoteList(context),
              scrollController: _scroller,
              onReorder: (oi, ni) async {
                if (ni > oi) ni--;
                _data.notes.insert(ni, _data.notes.removeAt(oi));
                await DataManager.instance.saveNoteData(_data);
                await _reloadData();
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _createMainButton(Icon(Icons.create), "New", () async {
                  String text = await prompt(
                    context,
                    title: Text("Note"),
                    hintText: "Write your note here",
                    autoFocus: true,
                    minLines: 1,
                    maxLines: 512,
                  );
                  if (text != null) {
                    _data.notes.add(text);
                    await DataManager.instance.saveNoteData(_data);
                    await _reloadData();
                    await _scrollToBottom();
                  }
                }),
                _createMainButton(Icon(Icons.paste), "New (Paste)", () async {
                  ClipboardData clipData =
                      await Clipboard.getData("text/plain");
                  if (clipData.text.trim() == "") {
                    await alert(context,
                        title: Text("Cannot Create New Note"),
                        content: Text(
                            "The clipboard did not contain any data to paste."));
                  } else {
                    _data.notes.add(clipData.text);
                    await DataManager.instance.saveNoteData(_data);
                    await _reloadData();
                    await _scrollToBottom();
                  }
                }),
                _createMainButton(Icon(Icons.copy), "Copy All", () async {
                  ClipboardData clipData =
                      ClipboardData(text: _data.toString());
                  await Clipboard.setData(clipData);
                  toast("All notes copied.");
                }),
                _createMainButton(Icon(Icons.settings), "Settings", () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) => NoteSettings(_data.title)));
                  await _reloadData();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _makeNoteList(BuildContext context) {
    return List.generate(
      _data.notes.length,
      (i) => ListTile(
        key: ValueKey(i),
        //tileColor: Colors.black45,
        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        title: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.greenAccent,
              width: 2,
            ),
            borderRadius: BorderRadius.all(Radius.circular(8)),
            color: Colors.black45,
          ),
          padding: EdgeInsets.fromLTRB(8, 8, 0, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _data.notes[i],
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () async {
                      String text = await prompt(
                        context,
                        title: Text("Edit Note"),
                        initialValue: _data.notes[i],
                        hintText: "Write your note here",
                        autoFocus: true,
                        minLines: 1,
                        maxLines: 512,
                      );
                      if (text != null) {
                        _data.notes[i] = text;
                        await DataManager.instance.saveNoteData(_data);
                        await _reloadData();
                      }
                    },
                    iconSize: 16,
                  ),
                  IconButton(
                    icon: Icon(Icons.copy),
                    onPressed: () async {
                      ClipboardData clipData =
                          ClipboardData(text: _data.notes[i]);
                      await Clipboard.setData(clipData);
                      toast("Note copied.");
                    },
                    iconSize: 16,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      if (await confirm(context,
                          title: Text(
                              "Are you sure you wish to delete this note? This cannot be undone."),
                          content: Text(
                              "Are you sure you wish to delete this note?"))) {
                        _data.notes.removeAt(i);
                        await DataManager.instance.saveNoteData(_data);
                        await _reloadData();
                      }
                    },
                    iconSize: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Column _createMainButton(Icon icon, String text, void Function() onPress) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: icon,
          onPressed: onPress,
        ),
        Text(text),
      ],
    );
  }
}
