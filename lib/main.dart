import 'package:flutter/material.dart';
import 'dart:math';

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

// 더미 데이터: 이모지와 할당된 노래 목록
// NOTE: 고유 식별자(id)를 추가하여 삭제/수정 시 사용합니다.
List<Map<String, dynamic>> emotionData = [
  {'id': 'e1', 'icon': '😀', 'name': '행복', 'songs': [{'title': 'Happy Song 1', 'artist': 'Artist A'}, {'title': 'Happy Song 2', 'artist': 'Artist B'}, {'title': 'Happy Song 3', 'artist': 'Artist C'}]},
  {'id': 'e2', 'icon': '😢', 'name': '슬픔', 'songs': [{'title': 'Someone Like You', 'artist': 'Adele'}, {'title': 'The Night We Met', 'artist': 'Lord Huron'}]},
  {'id': 'e3', 'icon': '🤩', 'name': '신남', 'songs': [{'title': 'Uptown Funk', 'artist': 'Mark Ronson'}]},
  {'id': 'e4', 'icon': '🧘', 'name': '평온', 'songs': [{'title': 'Calm Instrumental', 'artist': 'Various'}]},
  {'id': 'e5', 'icon': '😡', 'name': '분노', 'songs': []}, // 노래 없는 감정
  {'id': 'e6', 'icon': '😴', 'name': '피곤', 'songs': [{'title': 'Lullaby', 'artist': 'Sleepy Tunes'}]},
  {'id': 'e7', 'icon': '🤔', 'name': '고민', 'songs': []},
  {'id': 'e8', 'icon': '🤪', 'name': '장난', 'songs': [{'title': 'Funny Beat', 'artist': 'Comedian D'}]},
];

// 사용자가 선택할 수 있는 이모지 목록
final List<String> availableEmojis = [
  '😊', '😭', '🥳', '😎', '😜', '🧐', '😡', '🤯',
  '🫠', '🥺', '🤯', '😍', '😇', '🤩', '🥲', '🥰',
  '🤯', '😱', '😈', '💪', '🎉', '💖', '🌟', '✨',
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
  String _currentSong = '재생 중인 노래 없음';
  String _currentEmotion = '';
  // ⭐ 노래 재생 상태 (일시 정지/재생)
  bool _isPlaying = false;
  String? _deletingEmotionId;
  // ⭐ 재생 위치 더미 상태 (초 단위)
  double _currentPosition = 0.0;
  double _totalDuration = 180.0; // 3분 0초

  // 시간(초)을 "분:초" 형식의 문자열로 변환하는 헬퍼 함수
  String _formatDuration(double seconds) {
    if (seconds.isNaN || seconds.isInfinite) return '0:00';
    int totalSeconds = seconds.round();
    int minutes = totalSeconds ~/ 60;
    int remainingSeconds = totalSeconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // 노래 재생 로직
  void _playRandomSong(Map<String, dynamic> emotion) {
    if (_deletingEmotionId != null) {
      setState(() {
        _deletingEmotionId = null;
      });
      return;
    }

    final songs = emotion['songs'] as List<Map<String, dynamic>>;
    if (songs.isEmpty) {
      setState(() {
        _currentSong = '${emotion['name']}에 할당된 노래가 없습니다.';
        _currentEmotion = emotion['icon'] as String;
        _isPlaying = false;
        _currentPosition = 0.0;
        _totalDuration = 180.0; // 기본값 유지
      });
      return;
    }

    // 무작위 노래 선택
    final randomIndex = Random().nextInt(songs.length);
    final selectedSong = songs[randomIndex];
    final songTitle = selectedSong['title'];
    final songArtist = selectedSong['artist'];

    setState(() {
      _currentEmotion = emotion['icon'] as String;
      _currentSong = '$songTitle - $songArtist';
      _isPlaying = true; // 노래 재생 시작
      _currentPosition = 0.0; // 새 노래 시작 시 재생 위치 초기화
    });

    print('▶️ ${emotion['name']} 감정으로 $songTitle (무작위) 재생 시작');
  }

  // 재생/일시 정지 토글 로직
  void _togglePlayPause() {
    if (_currentSong == '재생 중인 노래 없음') {
      print('재생할 노래가 없습니다. 먼저 이모지를 선택하세요.');
      return;
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
    print(_isPlaying ? '▶️ 노래 재생' : '⏸️ 노래 일시 정지');
  }

  // ⭐ 중지 버튼 로직
  void _stopPlayback() {
    if (_currentSong == '재생 중인 노래 없음') return;

    setState(() {
      _currentSong = '재생 중인 노래 없음';
      _currentEmotion = '';
      _isPlaying = false;
      _currentPosition = 0.0;
    });
    print('⏹️ 노래 재생 중지 및 상태 초기화');
  }

  // 이모지 삭제 로직
  void _deleteEmotion(String id) {
    setState(() {
      emotionData.removeWhere((e) => e['id'] == id);
      _deletingEmotionId = null; // 삭제 후 상태 리셋

      // 삭제된 이모지가 현재 재생 중인 이모지였다면 상태 초기화
      if (emotionData.every((e) => e['icon'] != _currentEmotion)) {
        _stopPlayback(); // 노래 중지 로직 재사용
      }
    });
    print('✅ ID: $id 감정이 삭제되었습니다.');
  }

  // 이모지 수정 다이얼로그를 띄우는 함수
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

  // 이모지 추가 다이얼로그를 띄우는 함수
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

  // --- UI 위젯 ---

  // 버튼 스타일을 캡슐화한 헬퍼 위젯
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
        border: Border.all(
          color: color,
          width: 1.5,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 16),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  // 개별 이모지 타일 위젯
  Widget _buildEmotionTile(Map<String, dynamic> emotion) {
    final emotionId = emotion['id'] as String;
    final isDeleting = _deletingEmotionId == emotionId;

    // 삭제 버튼 클릭 핸들러
    void handleDeletePress() {
      if (isDeleting) {
        _deleteEmotion(emotionId);
      } else {
        setState(() {
          _deletingEmotionId = emotionId;
        });
      }
    }

    // 타일 자체의 클릭 핸들러 (재생 로직은 _playRandomSong에서 삭제 대기 상태를 검사함)
    void handleTileTap() {
      if (_deletingEmotionId != null && _deletingEmotionId != emotionId) {
        setState(() {
          _deletingEmotionId = null;
        });
      } else {
        _playRandomSong(emotion);
      }
    }

    return Stack(
      children: [
        // 1. 실제 클릭 가능한 이모지 컨텐츠 영역
        InkWell(
          onTap: handleTileTap,
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

        // 2. 우측 상단 버튼들
        Positioned(
          top: 0,
          right: 0,
          child: Row(
            children: [
              // 수정 버튼: 삭제 대기 상태일 때는 숨김
              if (!isDeleting)
                _buildStyledButton(
                  icon: Icons.edit,
                  color: Colors.blue,
                  onPressed: () => _showEditEmotionDialog(emotion), // ⭐ 수정 다이얼로그 호출
                ),

              // 삭제 버튼: 상태에 따라 아이콘 변경 (기본: delete, 대기: close/X)
              _buildStyledButton(
                icon: isDeleting ? Icons.close : Icons.delete,
                color: isDeleting ? Colors.red.shade700 : Colors.red,
                onPressed: handleDeletePress,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 배경 탭 시 삭제 대기 상태 리셋을 위한 위젯
  Widget _buildBodyContent(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_deletingEmotionId != null) {
                setState(() {
                  _deletingEmotionId = null;
                  print('삭제 대기 상태 리셋');
                });
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
                  final emotion = emotionData[index];
                  return _buildEmotionTile(emotion);
                },
              ),
            ),
          ),
        ),

        _buildAddEmotionButton(),

        _buildPlaybackBar(),
      ],
    );
  }

  // 이모지 추가 버튼 위젯
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

  // 하단 재생 바 위젯 (대폭 수정됨)
  Widget _buildPlaybackBar() {
    final isActive = _currentSong != '재생 중인 노래 없음';
    final playPauseIcon = _isPlaying ? Icons.pause : Icons.play_arrow;

    return Container(
      // 높이를 늘려 진행바와 버튼을 모두 담습니다.
      padding: const EdgeInsets.only(top: 8.0, bottom: 10.0, left: 10.0, right: 10.0),
      decoration: const BoxDecoration(
        color: Color(0xFF333333),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 진행바 및 시간 표시
          // ⭐ isActive 여부와 관계없이 공간을 확보하기 위해 Container/Row 사용
          Row(
            children: [
              Text(
                _formatDuration(_currentPosition), // 현재 시각
                style: TextStyle(color: isActive ? Colors.white70 : Colors.transparent, fontSize: 12),
              ),
              Expanded(
                child: Slider(
                  value: _currentPosition,
                  min: 0.0,
                  max: _totalDuration,
                  activeColor: isActive ? appBarColor : Colors.grey.shade700, // 비활성화 시 회색
                  inactiveColor: Colors.grey.shade700,
                  onChanged: isActive ? (newValue) { // 활성화 상태일 때만 슬라이더 조정 가능
                    // 진행바를 눌러 시각 조정 시뮬레이션
                    setState(() {
                      _currentPosition = newValue;
                    });
                    print('🔊 시각 조정: ${_formatDuration(newValue)}');
                  } : null, // 비활성화 상태일 때는 null
                ),
              ),
              Text(
                _formatDuration(_totalDuration), // 노래 전체 시각
                style: TextStyle(color: isActive ? Colors.white70 : Colors.transparent, fontSize: 12),
              ),
            ],
          ),

          // 2. 노래 정보 및 컨트롤 버튼
          Row(
            children: <Widget>[
              // 이모지 및 노래 정보
              Text(
                _currentEmotion,
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '현재 재생 중:',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      _currentSong,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // ⭐ 중지 버튼 (Stop)
              IconButton(
                icon: const Icon(Icons.stop, color: Colors.white, size: 30),
                onPressed: _stopPlayback, // 중지 로직 연결
              ),
              // ⭐ 재생/일시 정지 버튼 (Play/Pause)
              IconButton(
                icon: Icon(playPauseIcon, color: Colors.white, size: 30),
                onPressed: _togglePlayPause,
              ),
            ],
          ),
        ],
      ),
    );
  }

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

// =========================================================
// 이모지 추가 다이얼로그
// =========================================================

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
      print('오류: 이모지 아이콘과 감정 이름을 모두 입력해야 합니다.');
      return;
    }

    final newEmotion = {
      'id': 'e_${DateTime.now().microsecondsSinceEpoch}',
      'icon': emojiIcon,
      'name': emotionName,
      'songs': <Map<String, dynamic>>[], // 노래 객체 목록으로 변경
    };

    Navigator.of(context).pop(newEmotion);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 1. 제목 및 닫기 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '이모지 추가하기',
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

              // 2. 이모지 선택 영역
              const Text('이모지 선택', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: availableEmojis.map((emoji) {
                  final isSelected = _selectedEmoji == emoji;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedEmoji = emoji;
                        _emojiInputController.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected ? widget.appBarColor.withOpacity(0.5) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? widget.appBarColor : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 15),

              // 3. 또는 직접 입력 필드
              TextField(
                controller: _emojiInputController,
                decoration: InputDecoration(
                  labelText: '또는 직접 입력',
                  hintText: '😄',
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _emojiInputController.clear();
                      setState(() {
                        _selectedEmoji = null;
                      });
                    },
                  ),
                ),
                onChanged: (text) {
                  setState(() {
                    _selectedEmoji = null;
                  });
                },
              ),

              const SizedBox(height: 20),

              // 4. 감정 이름 입력 필드
              const Text('감정 이름', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _nameInputController,
                decoration: const InputDecoration(
                  hintText: '예: 행복, 슬픔, 사랑',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),

              const SizedBox(height: 10),
              const Text('노래는 나중에 추가할 수 있어요', style: TextStyle(fontSize: 12, color: Colors.grey)),

              const SizedBox(height: 30),

              // 5. 취소 / 추가하기 버튼
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
                      onPressed: _addNewEmotion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.appBarColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 5,
                      ),
                      child: const Text('추가하기', style: TextStyle(fontSize: 16)),
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

// =========================================================
// 감정 수정 다이얼로그 (새로운 위젯)
// =========================================================

class _EditEmotionDialog extends StatefulWidget {
  final Color appBarColor;
  final String emotionIcon;
  final String emotionName;
  // 노래 데이터 구조가 변경되었습니다.
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
  // 다이얼로그 내부에서 관리될 노래 목록
  late List<Map<String, dynamic>> _songs;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 초기 노래 목록을 복사하여 내부 상태로 사용합니다.
    _songs = List<Map<String, dynamic>>.from(widget.initialSongs);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  // 노래 목록에서 항목을 삭제하는 로직
  void _deleteSong(int index) {
    setState(() {
      _songs.removeAt(index);
    });
  }

  // 새 노래를 목록에 추가하는 로직
  void _addSong() {
    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();

    if (title.isEmpty) {
      print('오류: 노래 제목은 필수입니다.');
      return;
    }

    setState(() {
      _songs.add({
        'title': title,
        'artist': artist.isNotEmpty ? artist : '알 수 없는 아티스트',
      });
      // 입력 필드 초기화
      _titleController.clear();
      _artistController.clear();
    });
  }

  // 변경된 노래 목록을 메인 화면으로 반환
  void _saveChanges() {
    // 다이얼로그를 닫고 수정된 노래 목록을 반환합니다.
    Navigator.of(context).pop(_songs);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 1. 제목 및 닫기 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '노래 관리', // 제목 변경
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

            // 2. 이모지 정보 표시
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

            // 3. 노래 목록.
            Text(
              '노래 목록 (${_songs.length}개)',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 10),

            // 노래 목록 리스트 뷰
            LimitedBox(
              maxHeight: 200, // 최대 높이 제한
              child: _songs.isEmpty
                  ? const Center(
                child: Text('할당된 노래가 없습니다.', style: TextStyle(color: Colors.grey)),
              )
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  final song = _songs[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      // ⭐ 원형 배경 추가
                      width: 24, // 원의 크기
                      height: 24,
                      decoration: BoxDecoration(
                        color: widget.appBarColor, // 민트색 배경
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}', // 순서 번호
                          style: const TextStyle(
                            color: Colors.black, // 텍스트는 검은색으로
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

            // 4. 새 노래 추가 필드
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

            const SizedBox(height: 20),

            // 노래 추가 버튼
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

            // 5. 취소 / 저장하기 버튼
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
                    onPressed: _saveChanges, // 저장 로직 연결
                    style: ElevatedButton.styleFrom(
                      // 민트색 계열로 버튼 스타일
                      backgroundColor: widget.appBarColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 5,
                    ),
                    child: const Text('저장하기', style: TextStyle(fontSize: 16)), // 텍스트 변경
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}