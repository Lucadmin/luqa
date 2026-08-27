import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';

class AuthBootstrapScreen extends StatelessWidget {
  const AuthBootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = LuqaPalette.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: palette.raised,
                      borderRadius: BorderRadius.circular(LuqaRadii.control),
                    ),
                  ),
                  const SizedBox(height: LuqaSpacing.xxl),
                  Container(
                    width: 248,
                    height: 34,
                    decoration: BoxDecoration(
                      color: palette.raised,
                      borderRadius: BorderRadius.circular(LuqaRadii.compact),
                    ),
                  ),
                  const SizedBox(height: LuqaSpacing.md),
                  Container(
                    width: 184,
                    height: 18,
                    decoration: BoxDecoration(
                      color: palette.raised,
                      borderRadius: BorderRadius.circular(LuqaRadii.compact),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
