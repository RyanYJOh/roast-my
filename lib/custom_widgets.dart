// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:lottie/lottie.dart'; // lottie 애니메이션을 사용

class CustomButtonFlatPrimaryLg extends StatefulWidget {
  final String buttonText;
  final Icon icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;

  const CustomButtonFlatPrimaryLg({
    Key? key,
    required this.buttonText,
    this.onPressed,
    required this.icon,
    this.isLoading = false,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  _CustomButtonFlatPrimaryLgState createState() => _CustomButtonFlatPrimaryLgState();
}

class _CustomButtonFlatPrimaryLgState extends State<CustomButtonFlatPrimaryLg> {
  late Timer _timer;
  int _currentIndex = 0;
  final List<String> _messages = [
    "이미지 보는 중...",
    "로스트하는 중...",
    "비웃는 중...",
    "어이없어하는 중...",
    "비꼬는 중...",
    "로스트하는 중...",
    "상처받을까봐 조심하(지 않)는 중..."
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isLoading) {
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
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _messages.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: widget.isLoading
          ? Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: Lottie.asset('lotties/fire.json'),
                  ),
                  SizedBox(height: 10),
                  AnimatedTextKit(
                    animatedTexts: [
                      TyperAnimatedText(
                        _messages[_currentIndex],
                        textStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 150, 33, 25),
                        ),
                        speed: Duration(milliseconds: 50),
                      ),
                    ],
                    totalRepeatCount: 1,
                    displayFullTextOnTap: true,
                    stopPauseOnTap: true,
                  ),
                ],
              ),
            )
          : Container(
              width: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                // color: widget.isEnabled ? Color.fromARGB(255, 42, 42, 42) : Colors.grey,
                color: widget.isEnabled ? Color.fromARGB(255, 150, 33, 25) : Colors.grey,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Color.fromARGB(255, 98, 42, 42),offset: Offset(2, 2),blurRadius: 3,),
                ],
              ),
              child: widget.isEnabled
                  ? InkWell(
                      onTap: widget.onPressed,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              widget.icon,
                              SizedBox(width:5),
                              Text(
                                widget.buttonText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                          
                        ),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Text(
                          widget.buttonText,
                          style: TextStyle(
                            color: Color.fromARGB(255, 233, 233, 233),
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ),
    );
  }
}