import 'package:flutter/material.dart';

const brandLogoAsset = 'assets/brand/tl3ab_mark.png';
const brandFullLogoAsset = 'assets/brand/tl3ab_app_icon.png';
const brandWordmarkAsset = 'assets/brand/tl3ab_wordmark.png';
const brandLime = Color(0xFFB7FF1A);
const brandArabicFontFallback = <String>[
  'Tajawal',
  'Arial Rounded MT Bold',
  'Geeza Pro',
  'Tahoma',
  'Arial',
];
const brandLatinFontFallback = <String>[
  'Avenir Next',
  'Arial Rounded MT Bold',
  'Arial',
];

bool isArabicLanguage(String languageCode) {
  return languageCode.toLowerCase().startsWith('ar');
}

String brandTitleForLanguage(String languageCode) {
  return isArabicLanguage(languageCode) ? 'تلعب؟' : 'Tl3b?';
}

TextDirection brandTextDirectionForLanguage(String languageCode) {
  return isArabicLanguage(languageCode) ? TextDirection.rtl : TextDirection.ltr;
}

class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 150, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        brandLogoAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'Tl3b logo',
      ),
    );
  }
}

class BrandIconTile extends StatelessWidget {
  const BrandIconTile({this.size = 42, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.32;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.04),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: brandLime.withValues(alpha: 0.16),
            blurRadius: size * 0.24,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius * 0.82),
        child: BrandMark(size: size),
      ),
    );
  }
}

class BrandArabicWordmark extends StatelessWidget {
  const BrandArabicWordmark({this.fontSize = 76, super.key});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      brandWordmarkAsset,
      width: fontSize * 4.4,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'تلعب؟',
    );
  }
}

class BrandBall extends StatelessWidget {
  const BrandBall({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _BallPainter());
  }
}

class _BallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = brandLime
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = size.width * 0.08
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );

    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.35)
      ..cubicTo(
        size.width * 0.40,
        size.height * 0.15,
        size.width * 0.60,
        size.height * 0.85,
        size.width * 0.85,
        size.height * 0.65,
      );

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
