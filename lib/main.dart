import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
void main() => runApp(VideoEditorApp());

class VideoEditorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VideoEditorScreen(),
    );
  }
}

class VideoEditorScreen extends StatefulWidget {
  @override
  _VideoEditorScreenState createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  VideoPlayerController? _controller;
  String? _videoPath;

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      setState(() {
        _videoPath = result.files.single.path;
        _controller = VideoPlayerController.file(File(_videoPath!))
          ..initialize().then((_) {
            setState(() {});
          });
      });
    }
  }

  Future<void> _trimVideo() async {
    if (_videoPath == null) return;
    String outputPath = '/storage/emulated/0/Download/trimmed_video.mp4';
    await FFmpegKit.execute(
        '-i $_videoPath -ss 00:00:05 -to 00:00:10 -c copy $outputPath');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Video trimmed and saved to $outputPath')),
    );
  }

  Future<void> _mergeVideos(String video1, String video2) async {
    String outputPath = '/storage/emulated/0/Download/merged_video.mp4';
    await FFmpegKit.execute(
        '-i $video1 -i $video2 -filter_complex "[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1" $outputPath');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Videos merged and saved to $outputPath')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Editor'),
      ),
      body: Column(
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ElevatedButton(
            onPressed: _pickVideo,
            child: Text('Pick Video'),
          ),
          ElevatedButton(
            onPressed: _trimVideo,
            child: Text('Trim Video (5s to 10s)'),
          ),
          ElevatedButton(
            onPressed: () async {
              // For simplicity, pick two videos to merge
              final result1 = await FilePicker.platform.pickFiles(type: FileType.video);
              final result2 = await FilePicker.platform.pickFiles(type: FileType.video);
              if (result1 != null && result2 != null) {
                await _mergeVideos(result1.files.single.path!, result2.files.single.path!);
              }
            },
            child: Text('Merge Two Videos'),
          ),
        ],
      ),
    );
  }
}
