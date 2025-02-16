import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/saved_page.dart';
import 'package:vocechat_client/ui/chats/chat/chat_setting/settings_action_button.dart';
import 'package:vocechat_client/ui/widgets/avatar/avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar_info_tile.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile.dart';
import 'package:vocechat_client/ui/widgets/avatar/user_avatar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile_group.dart';

class DmSettingsPage extends StatefulWidget {
  final ValueNotifier<UserInfoM> userInfoNotifier;

  DmSettingsPage({required this.userInfoNotifier});

  @override
  State<DmSettingsPage> createState() => _DmSettingsPageState();
}

class _DmSettingsPageState extends State<DmSettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(242, 244, 247, 1),
      appBar: AppBar(
        toolbarHeight: barHeight,
        elevation: 0,
        backgroundColor: AppColors.barBg,
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
      ),
      body: SafeArea(
          child: ListView(children: [
        _buildDmInfo(context),
        SizedBox(height: 8),
        _buildItems(widget.userInfoNotifier.value, context)
      ])),
    );
  }

  Widget _buildDmInfo(BuildContext context) {
    return ValueListenableBuilder<UserInfoM>(
        valueListenable: widget.userInfoNotifier,
        builder: (context, userInfoM, _) {
          final userInfo = userInfoM.userInfo;
          return AvatarInfoTile(
            avatar: UserAvatar(
                avatarSize: AvatarSize.s60,
                name: userInfo.name,
                uid: userInfoM.uid,
                avatarBytes: userInfoM.avatarBytes),
            // title: Text(userInfo.name,
            //     style: TextStyle(
            //         fontWeight: FontWeight.w700,
            //         fontSize: 18,
            //         color: AppColors.grey800)),
            title: userInfo.name,
            subtitle: userInfo.email,
          );
        });
  }

  Widget _buildActions() {
    return Container(
      height: 68,
      margin: EdgeInsets.only(top: 28),
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SettingsActionButton(
              icon: Icon(AppIcons.bookmark, size: 24, color: AppColors.grey500),
              text: AppLocalizations.of(context)!.savedItems,
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: ((context) {
                  return SavedItemPage(uid: widget.userInfoNotifier.value.uid);
                })));
              }),
          // SettingsActionButton(
          //     icon: Icon(AppIcons.audio, size: 24, color: AppColors.grey500),
          //     text: AppLocalizations.of(context)!.call,
          //     onTap: () {}),
          // SettingsActionButton(
          //     icon: Icon(AppIcons.video, size: 24, color: AppColors.grey500),
          //     text: AppLocalizations.of(context)!.video,
          //     onTap: () {}),
          // ValueListenableBuilder<UserInfoM>(
          //     valueListenable: widget.userInfoNotifier,
          //     builder: (context, userInfoM, _) {
          //       String muteStr = AppLocalizations.of(context)!.mute;
          //       void Function() muteFunc = () => _mute();
          //       if (userInfoM.properties.enableMute) {
          //         muteStr = AppLocalizations.of(context)!.unmute;
          //         muteFunc = () => _unMute();
          //       }
          //       return SettingsActionButton(
          //           icon: Icon(AppIcons.alert,
          //               size: 24, color: AppColors.grey500),
          //           text: muteStr,
          //           onTap: muteFunc);
          //     }),
        ],
      ),
    );
  }

  Widget _buildItems(UserInfoM userInfoM, BuildContext context) {
    return BannerTileGroup(bannerTileList: [
      BannerTile(
        title: AppLocalizations.of(context)!.savedItems,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: ((context) {
            return SavedItemPage(uid: widget.userInfoNotifier.value.uid);
          })));
        },
      )
    ]);
  }

  Future<bool> _mute({int? expiredAt}) async {
    final reqMap = {
      "add_mute_users": [
        {"uid": widget.userInfoNotifier.value.uid, "expired_at": expiredAt}
      ]
    };

    try {
      final userApi = UserApi(App.app.chatServerM.fullUrl);
      final res = await userApi.mute(json.encode(reqMap));
      if (res.statusCode == 200) {
        await App.app.chatService
            .mute(uid: widget.userInfoNotifier.value.uid, expiredAt: expiredAt);
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return false;
  }

  Future<bool> _unMute() async {
    final reqMap = {
      "remove_mute_users": [widget.userInfoNotifier.value.uid]
    };

    try {
      final userApi = UserApi(App.app.chatServerM.fullUrl);
      final res = await userApi.mute(json.encode(reqMap));
      if (res.statusCode == 200) {
        await App.app.chatService
            .mute(uid: widget.userInfoNotifier.value.uid, unmute: true);
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return false;
  }
}
