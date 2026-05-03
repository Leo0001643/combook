import 'dart:ui';

import 'package:flutter/material.dart';

/// `GlassOrb` — true iOS 17 / iPadOS 17 frosted-glass marble.
///
/// The 3-D effect is built from six layered visual elements:
///
///   ┌──────────────────────────────────────────────────────────────┐
///   │ 1. Outer drop shadow      — tinted, bottom-right, blur 18    │
///   │ 2. Outer specular shadow  — pure white, top-left, blur 12    │
///   │ 3. BackdropFilter blur    — actual frosted background        │
///   │ 4. Radial body gradient   — convex marble bulge feel         │
///   │ 5. Inner crescent shadow  — bottom-right tint *inside* orb   │
///   │ 6. Inner specular rim     — white highlight *inside* top-left│
///   │ 7. 1 px white glass rim   — defines edge against any bg      │
///   └──────────────────────────────────────────────────────────────┘
///
/// Layers 5 and 6 are key — Flutter has no native inner-shadow primitive,
/// so we fake it by painting an *oversized circle with a thick coloured
/// border* offset outside the clip — `ClipOval` then keeps only the
/// portion bleeding back into the orb, producing a perfect inner ring.
///
/// ```dart
/// GlassOrb(
///   size: 56,
///   tintColor: context.primary,
///   child: Icon(Icons.spa_rounded, color: context.primary, size: 26),
/// )
/// ```
class GlassOrb extends StatelessWidget {
  final double size;
  final Widget child;

  /// Theme accent — drives shadow tint and the deepest gradient stop.
  /// The orb body itself stays predominantly white so the icon reads.
  final Color? tintColor;

  /// Set false on heavy lists where compositing is expensive.
  final bool enableBlur;

  const GlassOrb({
    super.key,
    required this.child,
    this.size      = 52,
    this.tintColor,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final tint = tintColor ?? const Color(0xFF8C7FB0);

    // ── Layer 5: oversized circle with thick tinted border, offset
    //    bottom-right.  The visible portion (after ClipOval) is the
    //    inner crescent shadow that gives the convex-marble bulge.
    final innerCrescent = Positioned(
      right:  -size * 0.22,
      bottom: -size * 0.28,
      width:   size * 1.4,
      height:  size * 1.4,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: tint.withValues(alpha: 0.45),
              width: size * 0.16,
            ),
          ),
        ),
      ),
    );

    // ── Layer 6: oversized white-bordered circle, offset top-left.
    //    Visible portion = bright inner specular rim.
    final innerSpecular = Positioned(
      left: -size * 0.14,
      top:  -size * 0.18,
      width:   size * 1.28,
      height:  size * 1.28,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.95),
              width: size * 0.09,
            ),
          ),
        ),
      ),
    );

    // ── Layer 4: convex radial gradient (light bulb at upper-left)
    final body = DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.6),
          radius: 1.0,
          colors: [
            Colors.white,
            Color.lerp(Colors.white, tint, 0.18)!,
          ],
          stops: const [0.30, 1.0],
        ),
      ),
      child: const SizedBox.expand(),
    );

    // Stack the body + inner shadows + child icon, clipped to a circle
    Widget orbContent = ClipOval(
      child: Stack(children: [
        Positioned.fill(child: body),
        innerCrescent,
        innerSpecular,
        Positioned.fill(child: Center(child: child)),
      ]),
    );

    // ── Layer 3: real frosted-glass blur (lets background bleed through)
    if (enableBlur) {
      orbContent = ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child:  orbContent,
        ),
      );
    }

    // ── Layers 1 & 2: outer drop shadow + outer specular highlight
    //    Layer 7: 1 px glass rim border defining the orb edge
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(                            // drop shadow
            color:        tint.withValues(alpha: 0.42),
            offset:       const Offset(4, 8),
            blurRadius:   18,
            spreadRadius: 0,
          ),
          const BoxShadow(                      // specular highlight
            color:        Colors.white,
            offset:       Offset(-4, -4),
            blurRadius:   12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: orbContent,
    );
  }
}
