import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travinhgo/models/destination/destination.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travinhgo/services/review_service.dart';

import '../../Models/review/reply.dart';
import '../../Models/review/reply_user_information.dart';
import '../../Models/review/review.dart';
import '../../services/auth_service.dart';
import '../../widget/destination_widget/destination_detail_image_slider.dart';
import '../../widget/review_widget/review_item.dart';
import '../../widget/status_dialog.dart';

class CommentScreen extends StatefulWidget {
  final Destination destination;
  final List<ReviewResponse> reviews;
  bool isReviewsAllowed;

  CommentScreen(
      {super.key,
      required this.destination,
      required this.reviews,
      required this.isReviewsAllowed});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  int currentImage = 0;
  final TextEditingController _commentController = TextEditingController();
  List<File> _selectedImages = [];
  bool _isCommentNotEmpty = false;
  bool _isLoading = true;
  late bool _isAllowed;

  late List<String> allImageDestination;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _isAllowed = widget.isReviewsAllowed;
    fetchDestination();
    _commentController.addListener(() {
      setState(() {
        _isCommentNotEmpty = _commentController.text.trim().isNotEmpty;
      });
    });
    debugPrint('Error during get destination list');
    debugPrint(widget.isReviewsAllowed.toString());
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> fetchDestination() async {
    var sessionId = await AuthService().getSessionId();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (sessionId != null) {
      _error = l10n.reviewOnceWarning;
    } else {
      _error = l10n.loginToReview;
    }
    setState(() {
      allImageDestination = [
        ...widget.destination.images,
        ...?widget.destination.historyStory?.images
      ];
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultiImage();

      final List<String> validExtensions = ['jpg', 'jpeg', 'png'];

      final newImages = <File>[];

      for (final file in pickedFiles) {
        final extension = file.path.split('.').last.toLowerCase();
        if (validExtensions.contains(extension)) {
          newImages.add(File(file.path));
        }
      }

      if (newImages.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.selectJpgOrPng),
          ),
        );
        return;
      }

      final remainingSlots = 3 - _selectedImages.length;
      if (remainingSlots <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.max3ImagesError),
          ),
        );
        return;
      }

      final imagesToAdd = newImages.take(remainingSlots).toList();

      if (newImages.length > remainingSlots) {
        showDialog(
          context: context,
          builder: (context) => StatusDialog(
            isSuccess: false,
            title: AppLocalizations.of(context)!.error,
            message: AppLocalizations.of(context)!.max3ImagesWarning,
            onOkPressed: () {
              Navigator.of(context).pop();
            },
          ),
        );
      }

      setState(() {
        _selectedImages.addAll(imagesToAdd);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.imagePickerError(e.toString())),
          ),
        );
      }
    }
  }

  Future<void> sendReview(ReviewRequest reviewRequest) async {
    ReviewResponse? responseData = await ReviewService()
        .sendReview(reviewRequest); // <- thêm await và dùng kiểu nullable

    _commentController.clear();

    if (responseData != null) {
      setState(() {
        widget.reviews.add(responseData);
        _isAllowed = false;
        _selectedImages.clear();
      });
    } else {
      setState(() {
        _selectedImages.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Giữ lại để tránh body bị resize không cần thiết
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      DestinationDetailImageSlider(
                                        onChange: (index) {
                                          setState(() {
                                            currentImage = index;
                                          });
                                          // Preload ảnh liền kề để tránh load chậm khi vuốt nhanh
                                          if (index + 1 <
                                              allImageDestination.length) {
                                            precacheImage(
                                                CachedNetworkImageProvider(
                                                    allImageDestination[
                                                        index + 1]),
                                                context);
                                          }
                                          if (index - 1 >= 0) {
                                            precacheImage(
                                                CachedNetworkImageProvider(
                                                    allImageDestination[
                                                        index - 1]),
                                                context);
                                          }
                                        },
                                        imageList: allImageDestination,
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  left: 8,
                                  right: 8,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(4.0),
                                              child: Center(
                                                child: IconButton(
                                                    onPressed: () {
                                                      Navigator.pop(context,
                                                          widget.reviews);
                                                    },
                                                    icon: Image.asset(
                                                        'assets/images/navigations/leftarrowwhile.png')),
                                              ),
                                            )),
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey.withOpacity(0.5),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(2.0),
                                            child: IconButton(
                                                iconSize: 18,
                                                onPressed: () {
                                                  Navigator.pop(
                                                      context, widget.reviews);
                                                },
                                                icon: Image.asset(
                                                    'assets/images/navigations/share.png')),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 230,
                                  left: 8,
                                  right: 8,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                        allImageDestination.length,
                                        (index) => AnimatedContainer(
                                              duration: const Duration(
                                                  microseconds: 300),
                                              width: 20,
                                              height: 8,
                                              margin: const EdgeInsets.only(
                                                  right: 3),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: currentImage == index
                                                    ? Colors.white
                                                    : Colors.grey,
                                              ),
                                            )),
                                  ),
                                ),
                              ],
                            ),
                            widget.reviews.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 32.0),
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .noReviewsYet,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                : Column(
                                    children:
                                        widget.reviews.reversed.map((review) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 9),
                                        child: ReviewItem(
                                          review: review,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          !_isAllowed ? null : _buildCommentInputBar(colorScheme),
    );
  }

  Widget _buildCommentInputBar(ColorScheme colorScheme) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final image = _selectedImages[index];
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            image,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 4,
                  ),
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        CupertinoIcons.photo_on_rectangle,
                        color: colorScheme.onPrimaryContainer,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    maxLength: 300,
                    minLines: 1, // số dòng tối thiểu
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.addCommentHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_isCommentNotEmpty)
                  IconButton(
                    icon: Image.asset(
                      'assets/images/navigations/send.png',
                      width: 24,
                      height: 24,
                    ),
                    onPressed: () async {
                      final images = List<File>.from(_selectedImages);
                      if (!_isAllowed) {
                        showDialog(
                          context: context,
                          builder: (context) => StatusDialog(
                            isSuccess: false,
                            title: AppLocalizations.of(context)!.error,
                            message: _error,
                            onOkPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      } else {
                        double _selectedRating = 5;

                        showDialog(
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: Text(
                                      AppLocalizations.of(context)!.tapToRate),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      RatingBar.builder(
                                        initialRating: _selectedRating,
                                        minRating: 1,
                                        direction: Axis.horizontal,
                                        allowHalfRating: false,
                                        itemCount: 5,
                                        itemSize: 40,
                                        itemPadding: const EdgeInsets.symmetric(
                                            horizontal: 4.0),
                                        itemBuilder: (context, _) => const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                        ),
                                        onRatingUpdate: (rating) {
                                          setState(() {
                                            _selectedRating = rating;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text(
                                          AppLocalizations.of(context)!.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        ReviewRequest reviewRequest =
                                            ReviewRequest(
                                          rating: _selectedRating.toInt(),
                                          images: images,
                                          comment: _commentController.text,
                                          destinationId: widget.destination.id,
                                        );
                                        _showLoadingDialog();
                                        await sendReview(reviewRequest);
                                        if (!mounted) return;
                                        Navigator.of(context)
                                            .pop(); // Close loading dialog
                                        Navigator.of(context)
                                            .pop(); // Close rating dialog
                                      },
                                      child: Text(
                                          AppLocalizations.of(context)!.send),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(AppLocalizations.of(context)!.sendingReview),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
