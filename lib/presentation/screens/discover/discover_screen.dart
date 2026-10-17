import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:toktok/infrastructure/datasources/auth_service.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';
import 'package:toktok/presentation/screens/upload/upload_screen.dart';
import 'package:toktok/presentation/widgets/shared/feed_bottom_bar.dart';
import 'package:toktok/presentation/widgets/shared/video_scrollable_view.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final discoverProvider = context.watch<DiscoverProvider>();
    final darkBase = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final darkTheme = darkBase.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(darkBase.textTheme),
    );

    return Theme(
      data: darkTheme,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildFeed(discoverProvider),

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
        bottomNavigationBar: FeedBottomBar(
          onAddPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UploadScreen()),
          ),
        ),
      ),
    );
  }

  Widget _buildFeed(DiscoverProvider provider) {
    if (provider.initialLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (provider.error != null) {
      return Center(child: Text(provider.error!));
    }
    if (provider.videos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aún no hay publicaciones.\nToca + para subir la primera.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return VideoScrollableView(videos: provider.videos);
  }
}