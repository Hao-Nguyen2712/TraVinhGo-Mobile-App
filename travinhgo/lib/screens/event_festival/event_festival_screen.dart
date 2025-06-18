import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:travinhgo/models/event_festival/event_and_festival.dart';

import '../../services/event_festival_service.dart';
import '../../utils/constants.dart';
import '../../widget/event_festival_widget/event_festival_item.dart';
import '../../widget/local_specialty_widget/local_specialty_item.dart';

class EventFestivalScreen extends StatefulWidget {
  const EventFestivalScreen({super.key});

  @override
  State<EventFestivalScreen> createState() => _EventFestivalScreenState();
}

class _EventFestivalScreenState extends State<EventFestivalScreen> {
  List<String> _eventAndFestivalName = [];
  List<EventAndFestival> _eventAndFestivals = [];
  bool _isLoading = true;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchEventFestival();
  }

  Future<void> fetchEventFestival() async {
    final data = await EventFestivalService().getDestination();
    for (final item in data) {
      if (item.images.isNotEmpty) {
        await precacheImage(
          CachedNetworkImageProvider(item.images.first),
          context,
        );
      }
    }

    setState(() {
      _eventAndFestivals = data;
      _eventAndFestivalName = data.map((e) => e.nameEvent).toList();
      _isLoading = false;
    });
  }

  List<EventAndFestival> get _filteredEventFestivals {
    return _eventAndFestivals.where((event) {
      final matchesSearch = _searchQuery.isEmpty ||
          event.nameEvent.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: CustomScrollView(slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: Colors.white,
          title: const Text('Event And Festival'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty)
                    return const Iterable<String>.empty();
                  return _eventAndFestivalName.where((name) => name
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  setState(() {
                    _searchQuery = selection;
                  });
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onSubmitted: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search event or festival',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(60),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: kSearchBackgroundColor,
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final option = options.elementAt(index);
                            return InkWell(
                              onTap: () {
                                onSelected(option);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 12.0),
                                child: Text(
                                  option,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              )),
        ),
        _isLoading
            ? const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1, childAspectRatio: 1.4),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return EventFestivalItem(
                          eventAndFestival: _filteredEventFestivals[index]);
                    },
                    childCount: _filteredEventFestivals.length,
                  ),
                ),
              ),
      ])),
    );
  }
}
