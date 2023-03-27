import 'package:flutgpt/controller/chat_controller.dart';
import 'package:flutgpt/views/home_view/components/chat_card.dart';
import 'package:flutgpt/views/home_view/components/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomeViewBody extends StatefulWidget {
  const HomeViewBody({super.key});

  @override
  State<HomeViewBody> createState() => _HomeViewBodyState();
}

class _HomeViewBodyState extends State<HomeViewBody> {
  ChatController chatController = Get.put(ChatController());
  TextEditingController inputController = TextEditingController();
  final ScrollController _controller = ScrollController(keepScrollOffset: true);


  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  // This is what you're looking for!
  void scrollDown() {
    if (_controller.position.maxScrollExtent > 0) {
      _controller.animateTo(
        _controller.position.maxScrollExtent,
        duration: const Duration(seconds: 2),
        curve: Curves.fastOutSlowIn,
      );
    }
  }


  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      inputController.text = inputController.text + _lastWords;
    });
  }

  @override
  Widget build(BuildContext buildContext) {
    return GetBuilder<ChatController>(builder: (context) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: chatController
                    .chats[chatController.chatIndex].messages.isEmpty
                ? const EmptyState()
                : SingleChildScrollView(
                    controller: _controller,
                    child: Column(
                      children: [
                        ListView.builder(
                            // controller: _controller,
                            primary: false,
                            shrinkWrap: true,
                            itemCount: chatController
                                .chats[chatController.chatIndex]
                                .messages
                                .length,
                            itemBuilder: (context, index) {
                              final message = chatController
                                  .chats[chatController.chatIndex]
                                  .messages
                                  .reversed
                                  .toList();

                              // To scroll down to the bottom of the list after the list is built
                              WidgetsBinding.instance
                                  .addPostFrameCallback((_) => scrollDown());

                              return ChatCard(
                                messageBlock: message[index],
                              );
                            }),
                        Visibility(
                          visible: chatController.isLoading &&
                              chatController.chatIndex ==
                                  chatController.promptIndex,
                          child: const OtherCard(type: OtherCardType.loading),
                        ),
                        Visibility(
                          visible: chatController
                                  .chats[chatController.chatIndex].error !=
                              null,
                          child: OtherCard(
                            type: OtherCardType.error,
                            response: chatController
                                .chats[chatController.chatIndex].error,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          customChatInput(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                onPressed:
                // If not yet listening for speech start, otherwise stop
                _speechToText.isNotListening ? _startListening : _stopListening,
                tooltip: 'Tap to speak',
                child: Icon(_speechToText.isNotListening ? Icons.mic : Icons.pause,
                    color: Theme.of(buildContext).primaryColor),
              ),
            ]
          ),
          const SizedBox(
            height: 18,
          ),
        ],
      );
    });
  }

  Column customChatInput() {
    return Column(
      children: [
        const Divider(
          height: 1,
          thickness: 1,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor,
                  spreadRadius: 0.5,
                  blurRadius: 7,
                  offset: const Offset(0, 2), // changes position of shadow
                ),
              ],
              color: Theme.of(context).inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(5.0),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: TextField(
                      enabled: !chatController.isLoading,
                      onSubmitted: (value) {
                        _handleSendPressed(inputController.text);
                      },
                      controller: inputController,
                      cursorColor: Colors.white,
                      cursorRadius: const Radius.circular(5),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                GestureDetector(
                  onTap: () {
                    if (inputController.text.isNotEmpty) {
                      _handleSendPressed(inputController.text);
                    }
                  },
                  child: SizedBox(
                      height: 15,
                      width: 15,
                      child: Image.asset(
                        'assets/send.png',
                        fit: BoxFit.fitHeight,
                      )),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 6,
        ),
      ],
    );
  }

  InputOptions inputOptions() {
    return const InputOptions(
        sendButtonVisibilityMode: SendButtonVisibilityMode.always);
  }

  DefaultChatTheme defaultChatTheme() {
    return DefaultChatTheme(
      userAvatarImageBackgroundColor: Colors.white,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      //  inputBackgroundColor: Colors.red,
      sendButtonIcon: Image.asset('assets/send.png'),
    );
  }

  void _handleSendPressed(String message) {
    chatController.handleSendPressed(message);
  }


}
