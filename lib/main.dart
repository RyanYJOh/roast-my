
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'custom_widgets.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:lottie/lottie.dart'; // lottie 애니메이션을 사용
import 'dart:typed_data';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:amplitude_flutter/amplitude.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:js' as js;
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(MyApp());
  initializeAmplitude();
}

void initializeAmplitude() async {
  js.context.callMethod('amplitude', ['init', '936ded9e0084471e45cd16f47b36d779']);
}

void logEvent(String eventName, [Map<String, dynamic>? properties]) {
    js.context.callMethod('amplitude', ['logEvent', eventName, properties ?? {}]);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPT의 인스타 로스트 🔥',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'gowun',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 204, 45, 169)),
      ),
      home: ImageUploaderPage(),
      supportedLocales: [
        const Locale('en', 'US'),
        const Locale('ko', 'KR'), // 한국어 추가
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );

  }
}

class ImageUploaderPage extends StatefulWidget {
  @override
  _ImageUploaderPageState createState() => _ImageUploaderPageState();
}

class _ImageUploaderPageState extends State<ImageUploaderPage> {
  String? imageBase64;
  String analysisResult = '';
  bool isLoading = false;
  bool isRoastButtonDisabled = false;

  // late Timer _timer;
  late Timer _timer = Timer(Duration(seconds: 0), () {}); // 초기화

  int _currentIndex = 0;
  final List<String> _messages = [
    "비웃는 중...",
    "조롱하는 중...",
    "상처받을까봐 조심하(지 않)는 중...",
    "비꼬는 중...",
    "어이없어하는 중...",
    "로스트하는 중...",
  ];

  @override
  void initState() {
    super.initState();
    logEvent('Pageview roast-home');
    // Amplitude.getInstance(instanceName: "default").logEvent("Pageview roast-home", eventProperties: {});
    if (isLoading) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 2000), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _messages.length;
        });
      }
    });
  }

  void pickImage() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final reader = html.FileReader();
      reader.readAsDataUrl(uploadInput.files![0]);
      reader.onLoadEnd.listen((e) async {
        if (reader.result != null) {
          String originalImage = reader.result.toString();

          // 원본 이미지 정보 출력
          html.ImageElement imgElement = html.ImageElement(src: originalImage);
          await imgElement.onLoad.first; // 이미지 로드 대기
          print('원본 이미지 크기: ${imgElement.width} x ${imgElement.height}');

          // 이미지 크기를 줄이는 캔버스 생성
          final int targetWidth = 800; // 원하는 너비로 조정
          final int targetHeight = (imgElement.height! * targetWidth / imgElement.width!).toInt();

          final html.CanvasElement canvas = html.CanvasElement(width: targetWidth, height: targetHeight);
          final ctx = canvas.context2D;
          ctx.drawImageScaled(imgElement, 0, 0, targetWidth, targetHeight);

          // 캔버스에서 압축된 이미지를 Low Resolution으로 변환 (압축 품질 낮추기)
          String compressedImage = canvas.toDataUrl('image/jpeg', 0.3); // 0.3으로 압축 품질 낮추기 (0.0 - 1.0)

          // 압축된 이미지 크기 및 품질 출력
          final Uint8List compressedBytes = Base64Decoder().convert(compressedImage.split(',').last);
          print('압축된 이미지 파일 크기: ${compressedBytes.lengthInBytes / 1024} KB');
          print('압축된 이미지 크기: ${targetWidth} x ${targetHeight}');

          // 압축된 이미지를 사용
          setState(() {
            imageBase64 = compressedImage.split(',').last; // base64만 추출
          });
        } else {
          print('Image upload failed or cancelled.');
        }
      });
    });
  }

  Future<void> analyzeImage() async {
    if (imageBase64 == null || isRoastButtonDisabled) return;
    // Amplitude.getInstance(instanceName: "default").logEvent("Click start-roast", eventProperties: {});
    logEvent('Click start-roast');

    setState(() {
      isRoastButtonDisabled = true;
      isLoading = true;
      _currentIndex = 0; 
    });
    _startTimer();

    try {
      var keyResponse = await http.get(Uri.parse('https://heuton.kr/api/roast-my'));
      if (keyResponse.statusCode != 200) {
        setState(() {
          analysisResult = 'Failed to get API key from the backend.';
        });
        return;
      }
      
      var apiKey = jsonDecode(keyResponse.body)['oak']; // 백엔드가 반환하는 key를 사용

      var response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          // 'model': 'gpt-4o-2024-08-06',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful assistant.'},
            {'role': 'user', 'content': [
              {'type': 'text', 'text': 'This screenshot is my Instagram profile page. I want you to roast it in two brief paragraphs. Be as sarcastic, cynical, and revolting as possible. Point out specific photos to roast. IMPORTANT: your response has to be in perfectly fluent Korean, easy and straightforward language, and non-honorific.'},
              {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'}}
            ]}
          ],
          'max_tokens': 300
        }),
      );

      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(response.body);
        if (decodedResponse != null && decodedResponse['choices'] != null && decodedResponse['choices'].isNotEmpty) {
          setState(() {
            // UTF-8 디코딩 적용
            analysisResult = utf8.decode(decodedResponse['choices'][0]['message']['content'].codeUnits);
          });
          // Amplitude.getInstance(instanceName: "default").logEvent("View result", eventProperties: {});
          logEvent('View result');
        } else {
          setState(() {
            analysisResult = 'No valid response from the server.';
          });
        }
      } else {
        setState(() {
          analysisResult = 'Failed to get response from API. Status code: ${response.statusCode}';
        });
      }
    } catch (error) {
      setState(() {
        analysisResult = 'An error occurred: $error';
      });
    } finally {
      setState(() {
        isLoading = false;
        isRoastButtonDisabled = false;
      });
      _timer.cancel(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
      onRefresh: () async {
        // 페이지를 새로고침할 때 전체 페이지를 다시 로드
        // 현재 화면을 재로딩하기 위해 아래 방식으로 처리 가능
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
        );
      },
      child: Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: analysisResult.isEmpty ? AssetImage('images/background.png') : AssetImage('images/background_blur.png'), // 배경 이미지 설정
          fit: BoxFit.cover, // 이미지가 화면에 꽉 차도록 설정
        ),
      ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // SizedBox(height:20),
                  if (analysisResult.isNotEmpty)
                  AdSenseBanner(),
                  if (analysisResult.isEmpty)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: Colors.white.withOpacity(0.8),
                    ),
                    child: Column(
                      children: [
                        Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Align(
                                alignment: Alignment.center, // 좌측 정렬
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    'images/roast_insta_logo.png',
                                    width: 80,
                                    height: 80,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: analysisResult.isEmpty ? EdgeInsets.only(bottom: 20) : EdgeInsets.only(bottom: 10),
                              child: Text(
                                'GPT의 인스타 로스트',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            '*로스트(Roast)란?',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87, ),
                                            softWrap: true, // 텍스트가 화면을 벗어날 경우 줄바꿈을 허용
                                            overflow: TextOverflow.visible, // 넘칠 경우 텍스트가 잘리지 않도록 설정
                                          ),
                                          SizedBox(height:10),
                                          Text(
                                            '상대방을 비꼬는 방식으로 지적하며 조롱하는 것을 의미해요. GPT가 내 인스타 프로필을 로스트합니다.',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87, ),
                                            softWrap: true, // 텍스트가 화면을 벗어날 경우 줄바꿈을 허용
                                            overflow: TextOverflow.visible, // 넘칠 경우 텍스트가 잘리지 않도록 설정
                                            textAlign: TextAlign.center,
                                          ),
                                          Divider(color: Colors.black54,),
                                          Text(
                                            '⚠️상처주의. 재미로만 즐겨주세요!',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87, ),
                                            softWrap: true, // 텍스트가 화면을 벗어날 경우 줄바꿈을 허용
                                            overflow: TextOverflow.visible, // 넘칠 경우 텍스트가 잘리지 않도록 설정
                                          ),
                                        ],
                                      ),
                                    )
                                  ),
                                ),
                              ],
                            ),
                          
                        ],
                    ),
                  ),
                  if (analysisResult.isEmpty)
                  AdSenseBanner(),
                  Column(
                    children: [
                    if (imageBase64 != null && analysisResult.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(imageBase64!),
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    isLoading
                    ? Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 82, 21, 21).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8),
                            child: AnimatedTextKit(
                              animatedTexts: [
                                for (var message in _messages)
                                  TyperAnimatedText(
                                    message,
                                    textStyle: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    speed: Duration(milliseconds: 50),
                                  ),
                              ],
                              totalRepeatCount: 1,
                              pause: Duration(milliseconds: 1500),
                              displayFullTextOnTap: true,
                              stopPauseOnTap: true,
                              isRepeatingAnimation: true,
                              onNextBeforePause: (index, isLast) {
                                setState(() {
                                  _currentIndex = (_currentIndex + 1) % _messages.length;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                    : analysisResult.isEmpty
                      ? imageBase64 != null
                        ? CustomButtonFlatPrimaryLg(
                          icon: Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20,),
                          buttonText: '로스트 시작!',
                          onPressed: isRoastButtonDisabled ? null : analyzeImage,
                          isEnabled: !isRoastButtonDisabled,
                        )
                        : Column(
                          children: [
                            _buildUploadButton(),
                            SizedBox(height:10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black54.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(10)
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                                child: Text('(GPT 인스타 로스트는 이미지를 별도로 저장하지 않습니다.)', style:TextStyle(fontSize: 12, color: Colors.white, )),
                              )
                            )
                          ],
                        )
                      : Container()
                    ],
                  ),
                  // SizedBox(height: 20),
                  if (analysisResult.isNotEmpty)
                  Container(
                    // margin: EdgeInsets.only(top: 20),
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 1 / 1.7, 
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(imageBase64!), // 이미지 데이터
                                  fit: BoxFit.cover, // 이미지가 가득 차도록
                                )
                              ),
                            ),
                            // 이미지 위에 결과 텍스트를 겹쳐서 표시
                            Positioned.fill(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        'images/roast_insta_logo.png',
                                        width: 40,
                                        height: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ),
                            Positioned.fill(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.8), // 텍스트 배경을 어둡게 추가
                                      borderRadius: BorderRadius.circular(8), // 둥근 모서리 적용
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                                    child: Text(
                                      analysisResult, // 결과 텍스트
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        color: Colors.white, // 텍스트는 흰색으로 설정
                                        shadows: [
                                          Shadow(
                                            blurRadius: 12.0,
                                            color: Colors.black.withOpacity(0.7), // 텍스트 그림자 추가
                                            offset: Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.start,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (analysisResult.isNotEmpty)
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: CustomButtonFlatPrimaryLg(
                                icon: Icon(Icons.share_sharp, color: Colors.white, size: 14,),
                                buttonText: '친구에게도 알려주기',
                                onPressed: copyCurrentPageUrl,
                              ),
                            ),
                            AdSenseBanner(),
                          ],
                        ),
                        if (analysisResult.isEmpty)
                        AdSenseBanner(),
                        SizedBox(height:100)
                      ],
                    ),
                  )
                ],
              )
            ),
          ),
        ),
      ),
      )
    );
  }

  Widget _buildUploadButton() {
    logEvent('Click upload-image');
    // Amplitude.getInstance(instanceName: "default").logEvent("Click upload-image", eventProperties: {});
    return GestureDetector(
      onTap: pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.5), width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload, size: 48, color: Colors.white),
              SizedBox(height: 16),
              Text(
                '인스타 프로필 스크린샷 업로드',
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void copyCurrentPageUrl() {
    // 현재 페이지의 URL 가져오기
    final currentUrl = html.window.location.href;

    // 클립보드 지원 여부 확인 후 복사 시도
    if (html.window.navigator.clipboard != null) {
      html.window.navigator.clipboard!.writeText(currentUrl).then((_) {
        Fluttertoast.showToast(
          msg: '🔗 링크가 복사되었어요!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        logEvent('Click share');
        // Amplitude.getInstance(instanceName: "default").logEvent("Click share", eventProperties: {});
      }).catchError((err) {
        print('URL 복사에 실패했습니다: $err');
      });
    } else {
      print('클립보드 복사가 이 브라우저에서 지원되지 않습니다.');
    }
  }

}

class AdSenseBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Google AdSense 스크립트 삽입
    html.ScriptElement script = html.ScriptElement()
      ..async = true
      ..src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-4115089612942348'
      ..crossOrigin = 'anonymous';

    // AdSense 광고 DIV 삽입
    html.DivElement adDiv = html.DivElement()
      ..style.width = '100%'
      ..style.height = 'auto'
      ..innerHtml = '''
        <ins class="adsbygoogle"
             style="display:block"
             data-ad-client="ca-pub-4115089612942348"
             data-ad-slot="6408931683"
             data-ad-format="auto"
             data-full-width-responsive="true"></ins>
        <script>
             (adsbygoogle = window.adsbygoogle || []).push({});
        </script>
      ''';

    // 플러터 위젯 내에 광고 스크립트 추가
    html.document.body!.append(script);
    html.document.body!.append(adDiv);

    return Container(
      height: 80, // 광고 높이 조정
      child: Center(child: Text('')),
    );
  }
}

