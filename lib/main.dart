import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Cache Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const VideoDemoPage(),
    );
  }
}

class VideoDemoPage extends StatefulWidget {
  const VideoDemoPage({super.key});

  @override
  State<VideoDemoPage> createState() => _VideoDemoPageState();
}

class _VideoDemoPageState extends State<VideoDemoPage> {
  late VideoPlayerController _controller;
  String _loadingTimeUncached = "Uncached loading time: Not measured";
  String _loadingTimeCached = "Cached loading time: Not measured";
  String _cachingTime = "Caching time: Not measured";
  String _cacheStatus = "Cache status: Checking...";
  bool _isInitialized = false;
  bool _isVideoCached = false;
  final String videoUrl =
      "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4";
  final _cacheManager = DefaultCacheManager(); // Custom instance for control

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });
    _checkCacheStatus(); // Check cache status on init
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Check if the video is already cached
  Future<void> _checkCacheStatus() async {
    final fileInfo = await _cacheManager.getFileFromCache(videoUrl);
    setState(() {
      _isVideoCached = fileInfo != null;
      _cacheStatus =
          "Cache status: ${_isVideoCached ? 'Cached' : 'Not cached'}";
    });
  }

  // Function to measure and play uncached video
  Future<void> _playUncachedVideo() async {
    setState(() {
      _loadingTimeUncached = "Uncached loading time: Measuring...";
      _isInitialized = false;
    });

    _controller.dispose();
    final startTime = DateTime.now();

    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime).inMilliseconds;
        setState(() {
          _loadingTimeUncached = "Uncached loading time: $duration ms";
          _isInitialized = true;
          _controller.play();
        });

        // Cache the video after playing uncached
        _cacheManager
            .getSingleFile(videoUrl)
            .then((fileInfo) {
              setState(() {
                _isVideoCached = true;
                _cacheStatus = "Cache status: Cached";
              });
            })
            .catchError((error) {
              setState(() {
                _cacheStatus = "Cache status: Failed to cache ($error)";
              });
            });
      });
  }

  // Function to measure and play cached video
  Future<void> _playCachedVideo() async {
    setState(() {
      _loadingTimeCached = "Cached loading time: Measuring...";
      _cachingTime = "Caching time: Measuring...";
      _isInitialized = false;
    });

    _controller.dispose();

    // Measure caching time
    final cacheStartTime = DateTime.now();
    final fileInfo = await _cacheManager.getSingleFile(videoUrl);
    final cacheEndTime = DateTime.now();
    final cachingDuration =
        cacheEndTime.difference(cacheStartTime).inMilliseconds;

    // Measure playback initialization time
    final playbackStartTime = DateTime.now();
    _controller = VideoPlayerController.file(fileInfo)
      ..initialize().then((_) {
        final playbackEndTime = DateTime.now();
        final playbackDuration =
            playbackEndTime.difference(playbackStartTime).inMilliseconds;
        setState(() {
          _cachingTime = "Caching time: $cachingDuration ms";
          _loadingTimeCached = "Cached loading time: $playbackDuration ms";
          _isInitialized = true;
          _isVideoCached = true;
          _cacheStatus = "Cache status: Cached";
          _controller.play();
        });
      });
  }

  // Function to clear the cache
  Future<void> _clearCache() async {
    await _cacheManager.emptyCache();
    setState(() {
      _isVideoCached = false;
      _cacheStatus = "Cache status: Not cached";
      _cachingTime = "Caching time: Not measured";
      _loadingTimeCached = "Cached loading time: Not measured";
    });
    await _checkCacheStatus(); // Re-check after clearing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Cache Demo")),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Video Player
              _isInitialized
                  ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                  : const CircularProgressIndicator(),
              const SizedBox(height: 20),

              // Display Information
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loadingTimeUncached,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _loadingTimeCached,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(_cachingTime, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(_cacheStatus, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _playUncachedVideo,
                    child: const Text("Play Uncached"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isVideoCached ? _playCachedVideo : null,
                    child: const Text("Play Cached"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _clearCache,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text("Clear Cache"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
