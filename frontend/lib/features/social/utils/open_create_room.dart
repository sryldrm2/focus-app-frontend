import 'package:flutter/material.dart';
import 'package:focus_app/features/social/widgets/create_room_sheet.dart';

void showCreateRoomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const CreateRoomSheet(),
  );
}
