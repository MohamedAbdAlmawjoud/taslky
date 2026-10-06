import 'package:flutter/material.dart';

import 'app_views.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});
  @override
  Widget build(BuildContext context) =>
      const AuthPage(register: false, forgot: true);
}
