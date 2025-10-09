import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;
 
  final List<Map<String, String>> _pages = [
    {
      "image": "assets/trash_city.png",
      "title": "Your City's Trash Won't Clean Itself",
      "desc": "But let's be honest, neither are you… so let's make it easy! Together we keep our city clean."
    },
    {
      "image": "assets/recycle.png",
      "title": "Dispose Waste Responsibly",
      "desc": "Schedule pickups, track disposal requests, and recycle smarter for a greener tomorrow."
    },
    {
      "image": "assets/clean_city.png",
      "title": "Clean City, Clean Future",
      "desc": "Join hands with others to build a sustainable future. Every small step makes a big difference."
    },
  ];

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.push('/signup');
    }
  }

  Widget _buildPage(Map<String, String> page) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          page["image"]!,
          height: 260.h,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 40.h),
        Text(
          page["title"]!,
          style: TextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        Text(
          page["desc"]!,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[700],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          height: 8.h,
          width: _currentIndex == index ? 24.w : 8.w,
          decoration: BoxDecoration(
            color: _currentIndex == index ? Colors.green : Colors.grey[300],
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),
              _buildIndicator(),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    _currentIndex == _pages.length - 1
                        ? "Get Started"
                        : "Next",
                    style: TextStyle(fontSize: 16.sp, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
