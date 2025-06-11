import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/models/Tag/Tag.dart';
import 'package:travinhgo/services/tag_service.dart';

class TagProvider extends ChangeNotifier {
  final List<Tag> _tags = [];

  List<Tag> get tags => _tags;

  Future<void> fetchDestinationType() async {
    try {
      List<Tag> tagsFetch = await TagService().getTags();
      _tags.clear();
      _tags.addAll(tagsFetch);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch markers: $e');
    }
  }

  Tag getTagById(String tagId) {
    return _tags.firstWhere(
      (t) => t.id == tagId,
      orElse: () => throw Exception('tag with id ${tagId} not found'),
    );
  }

  static TagProvider of(BuildContext context,
      {bool listen = true}) {
    return Provider.of<TagProvider>(context, listen: listen);
  }
}
