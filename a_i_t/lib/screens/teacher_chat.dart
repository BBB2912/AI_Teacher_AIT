import 'dart:convert';
import 'package:a_i_t/models/teacher.dart';
import 'package:a_i_t/screens/auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TeacherChatScreen extends StatefulWidget {
  const TeacherChatScreen({
    super.key,
    required this.teacher,
    required this.currentUser,
    required this.studentDetails,
  });
  final Teacher teacher;
  final User? currentUser;
  final Map<String, dynamic>? studentDetails;

  @override
  State<TeacherChatScreen> createState() => _TeacherChatScreenState();
}

class _TeacherChatScreenState extends State<TeacherChatScreen> {
  late WebSocketChannel channel;
  final TextEditingController _controller = TextEditingController();
  var isprocessing = false;

  @override
  void initState() {
    super.initState();

    // 🔹 connect to FastAPI websocket
    channel = WebSocketChannel.connect(
      Uri.parse(
        "ws://10.0.2.2:8000/ws/messages?uid=${widget.currentUser!.uid}&teacher=${widget.teacher.teacherName.toLowerCase()}",
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    channel.sink.close();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) {
      return;
    }
    setState(() {
      isprocessing = true;
    });
    final url = Uri.parse("http://10.0.2.2:8000/teacherResponse/");

    // 🔹 Send message payload to FastAPI
    final payload = {
      "studentDetails": widget.studentDetails,
      "userId": widget.currentUser!.uid,
      "userQuery": _controller.text,
      "teacher": widget.teacher.teacherName.toLowerCase(),
    };
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      setState(() {
        isprocessing = false;
      });
    } catch (e) {
      logger.w("⚠️ Exception: $e");
    }

    _controller.clear();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.teacher.teacherName,
            style: Theme.of(context).textTheme.headlineLarge!.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/images/logo.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.15),
                BlendMode.dstATop,
              ),
            ),
          ),
          child: Column(
            children: [
              // 🔹 Chat messages stream
              Expanded(
                child: StreamBuilder(
                  stream: channel.stream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // 🔹 Backend sends full messages table every few seconds
                    final List<dynamic> data = jsonDecode(
                      snapshot.data as String,
                    );

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final msg = data[index];

                        final isUser = msg['type'] == 'user' ? true : false;

                        Widget child;
                        if (isUser) {
                          child = Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              msg['response'],
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          );
                        } else {
                          child = Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ParsedText(
                              text: msg['response'],
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 16,
                              ),
                              parse: [
                                MatchText(
                                  type: ParsedType.CUSTOM,
                                  pattern: r'\[img:(.*?)\]',
                                  renderWidget:
                                      ({
                                        required String pattern,
                                        required String text,
                                      }) {
                                        final url =
                                            RegExp(
                                              r'\[img:(.*?)\]',
                                            ).firstMatch(text)?.group(1) ??
                                            '';
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: url,
                                              width: 220,
                                              height: 160,
                                              fit: BoxFit.cover,
                                              placeholder: (ctx, _) =>
                                                  const SizedBox(
                                                    width: 10,
                                                    height: 10,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                              errorWidget: (ctx, _, __) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                  ),
                                            ),
                                          ),
                                        );
                                      },
                                ),
                                MatchText(
                                  type: ParsedType.CUSTOM,
                                  pattern: r'\*\*(.*?)\*\*',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  renderText:
                                      ({
                                        required String pattern,
                                        required String str,
                                      }) {
                                        final boldText =
                                            RegExp(
                                              r'\*\*(.*?)\*\*',
                                            ).firstMatch(str)?.group(1) ??
                                            str;
                                        return {'display': boldText};
                                      },
                                ),
                                // 🎥 Video (just show URL and open in browser)
                                MatchText(
                                  type: ParsedType.CUSTOM,
                                  pattern: r'\[video:(.*?)\]',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                  onTap: (url) {
                                    final match = RegExp(
                                      r'\[video:(.*?)\]',
                                    ).firstMatch(url);
                                    if (match != null) {
                                      _openUrl(match.group(1)!);
                                    }
                                  },
                                  renderText:
                                      ({
                                        required String str,
                                        required String pattern,
                                      }) {
                                        final match = RegExp(
                                          r'\[video:(.*?)\]',
                                        ).firstMatch(str);
                                        return {
                                          'display': match != null
                                              ? match.group(1)!
                                              : str,
                                        };
                                      },
                                ),

                                // 🎵 Audio (just show URL and open in browser)
                                MatchText(
                                  type: ParsedType.CUSTOM,
                                  pattern: r'\[audio:(.*?)\]',
                                  style: const TextStyle(
                                    color: Colors.purple,
                                    decoration: TextDecoration.underline,
                                  ),
                                  onTap: (url) {
                                    final match = RegExp(
                                      r'\[audio:(.*?)\]',
                                    ).firstMatch(url);
                                    if (match != null) {
                                      _openUrl(match.group(1)!);
                                    }
                                  },
                                  renderText:
                                      ({
                                        required String str,
                                        required String pattern,
                                      }) {
                                        final match = RegExp(
                                          r'\[audio:(.*?)\]',
                                        ).firstMatch(str);
                                        return {
                                          'display': match != null
                                              ? match.group(1)!
                                              : str,
                                        };
                                      },
                                ),

                                // 📎 Normal links
                                MatchText(
                                  type: ParsedType.URL,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                  onTap: (url) => _openUrl(url),
                                ),
                              ],
                            ),
                            // child: Text(
                            //   teacherResponse,
                            //   style: const TextStyle(color: Colors.black),
                            // ),
                          );
                        }

                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: child,
                        );
                      },
                    );
                  },
                ),
              ),

              // 🔹 Input field at bottom
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 200,
                  minHeight: 60,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 2,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 20,
                          decoration: const InputDecoration(
                            hintText: "Enter your query...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      if (!isprocessing)
                        IconButton(
                          onPressed: () async {
                            await _sendMessage();
                          },
                          icon: const Icon(Icons.send),
                          style: IconButton.styleFrom(
                            shape: const CircleBorder(),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                          ),
                        ),
                      if (isprocessing) CircularProgressIndicator(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
