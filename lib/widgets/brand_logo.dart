import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

const _markAsset = 'assets/logo/gridlearn_mark.svg';
const _logoAsset = 'assets/logo/gridlearn_logo.svg';

/// Relación de aspecto del logo completo (icono + palabra), de su viewBox.
const logoAspectRatio = 1228 / 1152;

/// Solo el icono (la grilla con las fichas A, birrete y B).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _markAsset,
      width: size,
      height: size,
      semanticsLabel: 'GridLearn',
    );
  }
}

/// Logo completo (icono y la palabra GridLearn), para pantallas de entrada.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 220});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _logoAsset,
      width: width,
      height: width / logoAspectRatio,
      semanticsLabel: 'GridLearn',
    );
  }
}

/// La palabra "GridLearn" en dos tonos como en el logo: "Grid" en azul marino
/// y "Learn" en naranja, en Nunito extra negrita.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.fontSize = 26});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final base = AppTheme.heading(fontSize, weight: FontWeight.w900);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Grid', style: base.copyWith(color: AppColors.navy)),
          TextSpan(text: 'Learn', style: base.copyWith(color: AppColors.orange)),
        ],
      ),
      semanticsLabel: 'GridLearn',
      maxLines: 1,
      softWrap: false,
    );
  }
}

/// Icono + palabra en una fila, para el encabezado.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.markSize = 34, this.fontSize = 26});

  final double markSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: markSize),
        SizedBox(width: markSize * 0.28),
        BrandWordmark(fontSize: fontSize),
      ],
    );
  }
}
