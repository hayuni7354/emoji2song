import 'package:flutter/material.dart';
import 'dart:math';
// ⭐ 가벼운 오디오 패키지 (audioplayers)
import 'package:audioplayers/audioplayers.dart';

// Hex 코드를 Flutter Color 객체로 변환하는 헬퍼 함수
Color hexToColor(String code) {
  String colorString = code.startsWith('#') ? code.substring(1) : code;
  if (colorString.length == 6) {
    colorString = 'FF$colorString';
  }
  return Color(int.parse(colorString, radix: 16));
}

// 요청하신 색상: #8EFFE0
final Color appBarColor = hexToColor('#8EFFE0');

// ⭐ [수정됨] Heavy Drum, Thoughtful Chime 삭제
List<Map<String, dynamic>> emotionData = [
  {
    'id': 'e1',
    'icon': '😀',
    'name': '행복',
    'songs': [
      {'title': 'Space Adventure', 'artist': 'Demo', 'url': 'https://luan.xyz/files/audio/nasa_on_a_mission.mp3'},
      {'title': 'Cartoon Boing', 'artist': 'Google', 'url': 'https://actions.google.com/sounds/v1/cartoon/cartoon_boing.ogg'}
    ]
  },
  {
    'id': 'e2',
    'icon': '😢',
    'name': '슬픔',
    'songs': [
      {'title': 'Ambient Drift', 'artist': 'Demo', 'url': 'https://luan.xyz/files/audio/ambient_c_motion.mp3'},
      {'title': 'Heavy Rain', 'artist': 'Google', 'url': 'https://actions.google.com/sounds/v1/weather/rain_heavy_loud.ogg'}
    ]
  },
  {
    'id': 'e3',
    'icon': '🤩',
    'name': '신남',
    'songs': [
      {'title': 'Winning Coin', 'artist': 'Google', 'url': 'https://actions.google.com/sounds/v1/cartoon/wood_plank_flicks.ogg'},
      {'title': 'Positive Loop', 'artist': 'Demo', 'url': 'https://s3-us-west-2.amazonaws.com/s.cdpn.io/3/success.mp3'}
    ]
  },
  {
    'id': 'e5',
    'icon': '😡',
    'name': '분노',
    'songs': [
      // 'Heavy Drum' 삭제됨
      {'title': 'Thunder Crack', 'artist': 'Google', 'url': 'https://actions.google.com/sounds/v1/weather/thunder_crack.ogg'}
    ]
  },
  {
    'id': 'e6',
    'icon': '😴',
    'name': '피곤',
    'songs': [
      {'title': 'Coffee Shop', 'artist': 'Google', 'url': 'https://actions.google.com/sounds/v1/ambiences/coffee_shop.ogg'}
    ]
  },
  {
    'id': 'e7',
    'icon': '🤔',
    'name': '고민',
    'songs': [
      {'title': 'Clock Ticking', 'artist': 'Google', 'url': 'https://actions.google.com/sounds/v1/alarms/mechanical_clock_ring.ogg'},
      // 'Thoughtful Chime' 삭제됨
    ]
  },
];

final List<String> availableEmojis = [
  '😊', '😭', '🥳', '😎', '😜', '🧐', '😡', '🤯',
  '🫠', '🥺', '😍', '😇', '🤩', '🥲', '🥰', '😳',
  '😨', '😈', '💪', '🎉', '💖', '🌟', '✨', '🥶',
];

void main() {
  runApp(const MusicAppByEmotion());
}

class MusicAppByEmotion extends StatelessWidget {
  const MusicAppByEmotion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '감정 음악 앱',
      theme: ThemeData(
        primaryColor: appBarColor,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // ⭐ AudioPlayer 인스턴스 (audioplayers 패키지)
  final AudioPlayer _player = AudioPlayer();

  String _currentSong = '재생 중인 노래 없음';
  String _currentEmotion = '';
  bool _isPlaying = false;
  String? _deletingEmotionId;

  double _currentPosition = 0.0;
  double _totalDuration = 0.0;
  bool _showNoSongMessage = false;

  @override
  void initState() {
    super.initState();

    // 1. 재생 위치 변경 리스너
    _player.onPositionChanged.listen((Duration p) {
      if (mounted) {
        setState(() {
          _currentPosition = p.inSeconds.toDouble();
        });
      }
    });

    // 2. 전체 길이 변경 리스너
    _player.onDurationChanged.listen((Duration d) {
      if (mounted) {
        setState(() {
          _totalDuration = d.inSeconds.toDouble();
        });
      }
    });

    // 3. 재생 상태 변경 리스너
    _player.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isPlaying = (state == PlayerState.playing);
        });
      }
    });

    // 4. 재생 완료 리스너
    _player.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(double seconds) {
    if (seconds.isNaN || seconds.isInfinite) return '0:00';
    int totalSeconds = seconds.round();
    int minutes = totalSeconds ~/ 60;
    int remainingSeconds = totalSeconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _playRandomSong(Map<String, dynamic> emotion) async {
    if (_deletingEmotionId != null) {
      setState(() {
        _deletingEmotionId = null;
      });
      return;
    }

    final songs = List<Map<String, dynamic>>.from(emotion['songs'] as List);

    if (songs.isEmpty) {
      _stopPlayback();

      setState(() {
        _currentSong = '재생 중인 노래 없음';
        _currentEmotion = '';
        _isPlaying = false;
        _showNoSongMessage = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showNoSongMessage = false;
          });
        }
      });
      return;
    }

    final randomIndex = Random().nextInt(songs.length);
    final selectedSong = songs[randomIndex];
    final songTitle = selectedSong['title'];
    final songArtist = selectedSong['artist'];
    final songUrl = selectedSong['url'];

    setState(() {
      _currentEmotion = emotion['icon'] as String;
      _currentSong = '$songTitle - $songArtist';
      _showNoSongMessage = false;
    });

    print('▶️ ${emotion['name']} 감정으로 재생 시도');

    try {
      if (songUrl != null && songUrl.isNotEmpty) {
        // ⭐ audioplayers: UrlSource 사용
        await _player.play(UrlSource(songUrl));
      } else {
        print("URL이 비어 있습니다.");
      }
    } catch (e) {
      print("오디오 재생 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('재생 실패: 인터넷 연결이나 URL을 확인해주세요.\n$e')),
        );
      }
    }
  }

  void _togglePlayPause() async {
    if (_currentSong == '재생 중인 노래 없음') return;

    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  void _stopPlayback() async {
    if (_currentSong == '재생 중인 노래 없음') return;

    await _player.stop();
    // audioplayers는 stop 시 위치가 0으로 초기화됨

    setState(() {
      _currentSong = '재생 중인 노래 없음';
      _currentEmotion = '';
      _isPlaying = false;
      _currentPosition = 0.0;
      _totalDuration = 0.0;
      _showNoSongMessage = false;
    });
  }

  void _deleteEmotion(String id) {
    setState(() {
      emotionData.removeWhere((e) => e['id'] == id);
      _deletingEmotionId = null;
      _showNoSongMessage = false;

      if (emotionData.every((e) => e['icon'] != _currentEmotion)) {
        _stopPlayback();
      }
    });
    print('✅ ID: $id 감정이 삭제되었습니다.');
  }

  Future<void> _showEditEmotionDialog(Map<String, dynamic> emotion) async {
    if (_deletingEmotionId != null) {
      setState(() {
        _deletingEmotionId = null;
      });
    }

    final updatedSongs = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (BuildContext context) {
        return _EditEmotionDialog(
          appBarColor: appBarColor,
          emotionIcon: emotion['icon'] as String,
          emotionName: emotion['name'] as String,
          initialSongs: List<Map<String, dynamic>>.from(emotion['songs'] as List),
        );
      },
    );

    if (updatedSongs != null) {
      setState(() {
        final index = emotionData.indexWhere((e) => e['id'] == emotion['id']);
        if (index != -1) {
          emotionData[index]['songs'] = updatedSongs;
        }
      });
      print('✅ 감정 "${emotion['name']}"의 노래 목록이 업데이트되었습니다.');
    }
  }

  Future<void> _showAddEmotionDialog() async {
    if (_deletingEmotionId != null) {
      setState(() {
        _deletingEmotionId = null;
      });
    }

    final newEmotion = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return _AddEmotionDialog(appBarColor: appBarColor);
      },
    );

    if (newEmotion != null) {
      setState(() {
        emotionData.add(newEmotion);
      });
      print('✅ 새로운 감정 "${newEmotion['name']}"이 목록에 추가되었습니다.');
    }
  }

  Widget _buildStyledButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.only(top: 5, right: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 16),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildEmotionTile(Map<String, dynamic> emotion) {
    final emotionId = emotion['id'] as String;
    final isDeleting = _deletingEmotionId == emotionId;

    return Stack(
      children: [
        InkWell(
          onTap: () {
            if (_deletingEmotionId != null && _deletingEmotionId != emotionId) {
              setState(() => _deletingEmotionId = null);
            } else {
              _playRandomSong(emotion);
            }
          },
          child: Container(
            margin: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    emotion['icon'] as String,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    emotion['name'] as String,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          top: 0,
          right: 0,
          child: Row(
            children: [
              if (!isDeleting)
                _buildStyledButton(
                  icon: Icons.edit,
                  color: Colors.blue,
                  onPressed: () => _showEditEmotionDialog(emotion),
                ),

              _buildStyledButton(
                icon: isDeleting ? Icons.close : Icons.delete,
                color: isDeleting ? Colors.red.shade700 : Colors.red,
                onPressed: () {
                  if (isDeleting) {
                    _deleteEmotion(emotionId);
                  } else {
                    setState(() => _deletingEmotionId = emotionId);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_deletingEmotionId != null) {
                    setState(() => _deletingEmotionId = null);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: emotionData.length,
                    itemBuilder: (context, index) {
                      return _buildEmotionTile(emotionData[index]);
                    },
                  ),
                ),
              ),
            ),

            _buildAddEmotionButton(),
            _buildPlaybackBar(),
          ],
        ),

        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            opacity: _showNoSongMessage ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  '노래를 추가해 주세요!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddEmotionButton() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [appBarColor.withOpacity(0.8), appBarColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: appBarColor.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showAddEmotionDialog,
            borderRadius: BorderRadius.circular(30),
            child: const Center(
              child: Text(
                '이모지 추가',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackBar() {
    final isActive = _currentSong != '재생 중인 노래 없음';
    final playPauseIcon = _isPlaying ? Icons.pause : Icons.play_arrow;

    return Container(
      padding: const EdgeInsets.only(top: 8.0, bottom: 10.0, left: 10.0, right: 10.0),
      decoration: const BoxDecoration(
        color: Color(0xFF333333),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: TextStyle(
                  color: isActive ? Colors.white70 : Colors.transparent,
                  fontSize: 18,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: appBarColor,
                    inactiveTrackColor: Colors.grey.shade700,
                    thumbColor: appBarColor,
                    overlayColor: appBarColor.withOpacity(0.4),
                    thumbShape: isActive ? const RoundSliderThumbShape(enabledThumbRadius: 6.0) : SliderComponentShape.noThumb,
                    overlayShape: isActive ? const RoundSliderOverlayShape(overlayRadius: 14.0) : SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: min(_currentPosition, _totalDuration),
                    min: 0.0,
                    max: _totalDuration > 0 ? _totalDuration : 1.0,
                    onChanged: isActive ? (newValue) {
                      _player.seek(Duration(seconds: newValue.toInt()));
                    } : null,
                  ),
                ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: TextStyle(
                  color: isActive ? Colors.white70 : Colors.transparent,
                  fontSize: 18,
                ),
              ),
            ],
          ),

          Row(
            children: <Widget>[
              Text(
                _currentEmotion,
                style: const TextStyle(fontSize: 36, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '현재 재생 중:',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                    Text(
                      _currentSong,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(Icons.stop, color: Colors.white, size: 45),
                onPressed: isActive ? _stopPlayback : null,
              ),
              IconButton(
                icon: Icon(playPauseIcon, color: Colors.white, size: 45),
                onPressed: isActive ? _togglePlayPause : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ⭐ 필수 build 메서드 추가 (Scaffold 반환)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('감정 기반 음악 재생기', style: TextStyle(color: Colors.black)),
        backgroundColor: appBarColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              print('설정 페이지로 이동');
            },
          ),
        ],
      ),
      body: _buildBodyContent(context),
    );
  }
}

// ... (나머지 Dialog 클래스들은 기존과 동일) ...
class _AddEmotionDialog extends StatefulWidget {
  final Color appBarColor;
  const _AddEmotionDialog({required this.appBarColor});

  @override
  State<_AddEmotionDialog> createState() => _AddEmotionDialogState();
}

class _AddEmotionDialogState extends State<_AddEmotionDialog> {
  String? _selectedEmoji;
  final TextEditingController _emojiInputController = TextEditingController();
  final TextEditingController _nameInputController = TextEditingController();

  @override
  void dispose() {
    _emojiInputController.dispose();
    _nameInputController.dispose();
    super.dispose();
  }

  void _addNewEmotion() {
    final emojiIcon = (_selectedEmoji ?? _emojiInputController.text.trim()).trim();
    final emotionName = _nameInputController.text.trim();

    if (emojiIcon.isEmpty || emotionName.isEmpty) {
      return;
    }

    final newEmotion = {
      'id': 'e_${DateTime.now().microsecondsSinceEpoch}',
      'icon': emojiIcon,
      'name': emotionName,
      'songs': <Map<String, dynamic>>[],
    };

    Navigator.of(context).pop(newEmotion);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('이모지 추가하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 20),
              const Align(alignment: Alignment.centerLeft, child: Text('이모지 선택', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0, runSpacing: 4.0,
                children: availableEmojis.map((emoji) {
                  final isSelected = _selectedEmoji == emoji;
                  return InkWell(
                    onTap: () => setState(() { _selectedEmoji = emoji; _emojiInputController.clear(); }),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected ? widget.appBarColor.withOpacity(0.5) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? widget.appBarColor : Colors.grey.shade300, width: 1.5),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _emojiInputController,
                decoration: InputDecoration(
                  labelText: '또는 직접 입력',
                  hintText: '😄',
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  suffixIcon: IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () => setState(() { _emojiInputController.clear(); _selectedEmoji = null; })),
                ),
                onChanged: (text) => setState(() => _selectedEmoji = null),
              ),
              const SizedBox(height: 20),
              const Align(alignment: Alignment.centerLeft, child: Text('감정 이름', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 10),
              TextField(controller: _nameInputController, decoration: const InputDecoration(hintText: '예: 행복, 슬픔, 사랑', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
              const SizedBox(height: 10),
              const Text('노래는 나중에 추가할 수 있어요', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 30),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                Expanded(child: ElevatedButton(onPressed: () => Navigator.of(context).pop(), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0), child: const Text('취소', style: TextStyle(fontSize: 16)))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: _addNewEmotion, style: ElevatedButton.styleFrom(backgroundColor: widget.appBarColor, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 5), child: const Text('추가하기', style: TextStyle(fontSize: 16)))),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditEmotionDialog extends StatefulWidget {
  final Color appBarColor;
  final String emotionIcon;
  final String emotionName;
  final List<Map<String, dynamic>> initialSongs;

  const _EditEmotionDialog({
    required this.appBarColor,
    required this.emotionIcon,
    required this.emotionName,
    required this.initialSongs,
  });

  @override
  State<_EditEmotionDialog> createState() => _EditEmotionDialogState();
}

class _EditEmotionDialogState extends State<_EditEmotionDialog> {
  late List<Map<String, dynamic>> _songs;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  int _selectedSourceType = 0;

  @override
  void initState() {
    super.initState();
    _songs = List<Map<String, dynamic>>.from(widget.initialSongs);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _deleteSong(int index) {
    setState(() {
      _songs.removeAt(index);
    });
  }

  void _addSong() {
    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();
    final url = _urlController.text.trim();

    if (title.isEmpty) { return; }

    if (_selectedSourceType == 1) {
      showDialog(context: context, builder: (ctx) => AlertDialog(content: const Text('아직 미구현된 기능입니다. 공개 URL 방식을 이용해주세요.'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('확인'))]));
      return;
    }

    setState(() {
      _songs.add({'title': title, 'artist': artist.isNotEmpty ? artist : '알 수 없는 아티스트', 'url': url.isNotEmpty ? url : 'https://example.com/default.mp3'});
      _titleController.clear(); _artistController.clear(); _urlController.clear();
    });
  }

  void _saveChanges() {
    Navigator.of(context).pop(_songs);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '노래 관리',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Center(
                child: Column(
                  children: [
                    Text(
                      widget.emotionIcon,
                      style: const TextStyle(fontSize: 48),
                    ),
                    Text(
                      widget.emotionName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                '노래 목록 (${_songs.length}개)',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 10),

              LimitedBox(
                maxHeight: 150,
                child: _songs.isEmpty
                // ⭐ 1. 빈 목록 높이 조절
                    ? Container(
                  height: 60,
                  alignment: Alignment.center,
                  child: const Text('할당된 노래가 없습니다.', style: TextStyle(color: Colors.grey)),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: widget.appBarColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      title: Text(song['title'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(song['artist'] as String, style: const TextStyle(fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteSong(index),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              const Text('새 노래 추가', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '노래 제목',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _artistController,
                decoration: const InputDecoration(
                  hintText: '아티스트 (선택 사항)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),

              // 소스 선택 버튼 (URL / 파일)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSourceType = 0; // URL 모드
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedSourceType == 0 ? widget.appBarColor.withOpacity(0.2) : Colors.transparent,
                          border: Border.all(color: _selectedSourceType == 0 ? widget.appBarColor : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(child: Text('공개 URL', style: TextStyle(fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSourceType = 1; // 파일 모드
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedSourceType == 1 ? widget.appBarColor.withOpacity(0.2) : Colors.transparent,
                          border: Border.all(color: _selectedSourceType == 1 ? widget.appBarColor : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(child: Text('파일 업로드', style: TextStyle(fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 선택된 모드에 따른 입력 필드
              if (_selectedSourceType == 0)
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    hintText: 'https://example.com/song.mp3',
                    labelText: '오디오 URL',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    prefixIcon: Icon(Icons.link),
                  ),
                )
              else
                InkWell(
                  onTap: () {
                    // ⭐ 3. 오류 메시지 우선순위 해결 (showDialog 사용)
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        content: const Text('아직 미구현된 기능입니다. 공개 URL 방식을 이용해주세요.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade100,
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.cloud_upload, color: Colors.grey, size: 30),
                        SizedBox(height: 5),
                        // ⭐ 2. 텍스트 변경
                        Text('눌러서 파일 선택', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addSong,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('노래 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.appBarColor.withOpacity(0.2),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('취소', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.appBarColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 5,
                      ),
                      child: const Text('저장하기', style: TextStyle(fontSize: 16)),
                    ),
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