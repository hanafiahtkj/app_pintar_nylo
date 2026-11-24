import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/resources/widgets/profile/profile_body_widget.dart';

class ProfilePage extends NyStatefulWidget {
  static RouteView path = ('/profile', (_) => ProfilePage());

  ProfilePage({super.key}) : super(child: () => _ProfilePageState());
}

class _ProfilePageState extends NyPage<ProfilePage> {
  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  Widget view(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: false,
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: const ProfileBodyWidget(),
    );
  }
}
