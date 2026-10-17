import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/infrastructure/datasources/auth_service.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';
import 'package:toktok/presentation/widgets/shared/video_scrollable_view.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final discoverProvider = context.watch<DiscoverProvider>();

    return Scaffold(
      body: Stack(
        children: [
          discoverProvider.initialLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : VideoScrollableView(videos: discoverProvider.videos),
              
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => AuthService().logout(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}