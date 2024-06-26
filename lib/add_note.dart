import 'package:flutter/material.dart';
import 'package:seshat/models/note.dart';
import 'package:seshat/utils/icons.dart';
import 'package:seshat/db/db.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:seshat/widgets/selectionText.dart';

class AddNote extends StatefulWidget {
  const AddNote({super.key, required this.width, required this.height});
  final double width;
  final double height;

  @override
  State<AddNote> createState() => _AddNotePage();
}

class _AddNotePage extends State<AddNote> with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  bool _created = false;
  final String _defaultTitle = "Untitled";
  var _id = null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.inactive:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _addNote();
        });
        break;

      default:
        break;
    }
  }

  void _checkTextSelection() {
    if (_textController.text.isNotEmpty) {
      _textController.selection = TextSelection(
          baseOffset: 0, extentOffset: _textController.text.length);
    }
  }

  Future<void> _addNote() async {
    String title = _titleController.text;
    final String text = _textController.text;

    final bool emptyText = text.isEmpty;
    final bool emptyTitle = title.isEmpty;

    if (emptyTitle && emptyText && !_created) {
      return;
    }

    if (_created && _id == null) {
      int id = await lastInsertedId();
      setState(() {
        _id = id;
      });
    }

    if (emptyTitle) {
      title = _defaultTitle;
    }

    try {
      if (emptyTitle && emptyText && _created) {
        await deleteNote(_id);
        setState(() {
          _created = false;
        });
      } else if (!_created) {
        await insertNote(Note(title: title, text: text));
        setState(() {
          _created = true;
        });
      } else {
        await updateNote(Note(text: text, title: title, id: _id));
      }
    } catch (error) {
      Fluttertoast.showToast(
          msg: "Error on Save Note",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.white,
          textColor: const Color.fromARGB(255, 244, 67, 54),
          fontSize: 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double height = widget.height;
    final double width = widget.width;
    const double topBarSize = 120.0;
    final double bodySize = height - topBarSize;

    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
        onPopInvoked: (didPop) async => {await _addNote()},
        child: SelectionText(
            child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: AppBar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                elevation: 0,
              )),
          body: SizedBox(
            width: width,
            height: height,
            child: Column(
              children: [
                Container(
                    height: topBarSize,
                    color: Theme.of(context).colorScheme.primary,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(26, 10, 26, 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: width,
                            child: Align(
                                alignment: Alignment.bottomLeft,
                                child: IconButton(
                                  onPressed: () => {Navigator.pop(context)},
                                  icon: BackIcon,
                                )),
                          ),
                          SizedBox(
                            width: width,
                            child: Container(
                              alignment: Alignment.bottomLeft,
                              child: TextField(
                                maxLength: 20,
                                keyboardType: TextInputType.text,
                                controller: _titleController,
                                onTapOutside: (event) =>
                                    {FocusScope.of(context).unfocus()},
                                cursorColor:
                                    Theme.of(context).colorScheme.secondary,
                                textAlign: TextAlign.center,
                                showCursor: true,
                                style: const TextStyle(
                                    fontSize: 32,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                    hintText: _defaultTitle,
                                    contentPadding: const EdgeInsets.all(0),
                                    hintMaxLines: 1,
                                    border: InputBorder.none,
                                    counterText: '',
                                    hintStyle: const TextStyle(
                                        fontSize: 32,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          )
                        ],
                      ),
                    )),
                Container(
                  color: Theme.of(context).colorScheme.primary,
                  height: bodySize -
                      (keyboardHeight != 0 ? keyboardHeight - 10 : 0),
                  width: width,
                  padding: const EdgeInsets.fromLTRB(36, 16, 36, 16),
                  child: Container(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onDoubleTap: _checkTextSelection,
                      child: TextField(
                          autofocus: true,
                          cursorColor: Theme.of(context).colorScheme.secondary,
                          keyboardType: TextInputType.multiline,
                          textAlign: TextAlign.start,
                          maxLines: null,
                          expands: true,
                          maxLength: 20000,
                          controller: _textController,
                          onTapOutside: (event) =>
                              {FocusScope.of(context).unfocus()},
                          showCursor: true,
                          style: const TextStyle(
                              fontSize: 24, fontFamily: 'Roboto'),
                          decoration: const InputDecoration(
                              hintText: "Type Something...",
                              contentPadding: EdgeInsets.all(0),
                              hintMaxLines: 1,
                              border: InputBorder.none,
                              counterText: '',
                              hintStyle: TextStyle(
                                  fontSize: 24,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )));
  }
}
