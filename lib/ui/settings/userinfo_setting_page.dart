import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/api/models/user/user_info.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_alert_dialog.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/widgets/app_textfield.dart';
import 'package:vocechat_client/ui/widgets/avatar/avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar/user_avatar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/ui/widgets/avatar_info_tile.dart';

class UserInfoSettingPage extends StatefulWidget {
  final ValueNotifier<UserInfoM?> userInfoNotifier;

  UserInfoSettingPage(this.userInfoNotifier);

  @override
  State<UserInfoSettingPage> createState() => _UserInfoSettingPageState();
}

class _UserInfoSettingPageState extends State<UserInfoSettingPage> {
  final TextEditingController _nameController = TextEditingController();

  final ValueNotifier<bool> _doneBtnNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _uploadNotifier = ValueNotifier(false);

  late final UserInfo? _userInfo;
  late bool _nameChanged;

  @override
  void initState() {
    super.initState();
    _userInfo = widget.userInfoNotifier.value?.userInfo;
    _nameController.text = _userInfo?.name ?? "";

    _nameChanged = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.pageBg,
        appBar: AppBar(
          toolbarHeight: barHeight,
          elevation: 0,
          backgroundColor: AppColors.barBg,
          leading: CupertinoButton(
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97),
              onPressed: () => Navigator.pop(context)),
          actions: [
            ValueListenableBuilder<bool>(
                valueListenable: _doneBtnNotifier,
                builder: (context, enableBtn, _) {
                  if (enableBtn) {
                    return CupertinoButton(
                        onPressed: onDone,
                        child: Text("Done",
                            style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 17,
                                color: AppColors.primary400)));
                  }
                  return SizedBox.shrink();
                })
          ],
        ),
        body: SafeArea(
            child: Column(
          children: [
            _buildAvatar(),
            SizedBox(height: 8),
            _buildTextFields(),
          ],
        )));
  }

  Widget _buildAvatar() {
    return AvatarInfoTile(
      avatar: ValueListenableBuilder<UserInfoM?>(
          valueListenable: widget.userInfoNotifier,
          builder: (context, userInfoM, _) {
            return UserAvatar(
                uid: userInfoM?.uid ?? -1,
                avatarSize: AvatarSize.s84,
                name: userInfoM?.userInfo.name ?? "",
                avatarBytes: userInfoM?.avatarBytes ?? Uint8List(0));
          }),
      title: _userInfo?.name ?? "",
      subtitleWidget: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: ValueListenableBuilder<bool>(
              valueListenable: _uploadNotifier,
              builder: (context, isUploading, _) {
                if (isUploading) {
                  return CupertinoActivityIndicator();
                }
                return CupertinoButton(
                  onPressed: _changeAvatar,
                  child: Text(AppLocalizations.of(context)!.setNewAvatar,
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: AppColors.primary400)),
                );
              })),
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              header: "Name",
              controller: _nameController,
              maxLength: 32,
              autofocus: true,
              onChanged: (text) {
                if (text == _userInfo?.name) {
                  _nameChanged = false;
                } else {
                  _nameChanged = true;
                }

                _doneBtnNotifier.value = _nameChanged;
              },
            ),
          ],
        ),
      ],
    );
  }

  void _changeAvatar() async {
    final ImagePicker _picker = ImagePicker();
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _uploadNotifier.value = true;
      Uint8List bytes = await image.readAsBytes();
      bytes = await FlutterImageCompress.compressWithList(bytes, quality: 25);
      final userApi = UserApi(App.app.chatServerM.fullUrl);
      final res = await userApi.uploadAvatar(bytes);
      if (res.statusCode == 200) {
        App.logger.info("User Avatar changed.");
        _uploadNotifier.value = false;
        return;
      } else if (res.statusCode == 413) {
        App.logger.severe("Payload too large");
        await showAppAlert(
            context: context,
            title: "Upload Error",
            content: "Avatar size exceeds limit.",
            actions: [
              AppAlertDialogAction(
                  text: "OK", action: () => Navigator.pop(context))
            ]);
        _uploadNotifier.value = false;
        return;
      }
    } else {
      _uploadNotifier.value = false;
      return;
    }
  }

  void onDone() async {
    String name = _nameController.text;

    try {
      await _updateName(name, context);
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _updateName(String name, BuildContext context) async {
    final userApi = UserApi(App.app.chatServerM.fullUrl);
    final res = await userApi.updateUserInfo(name: name);

    if (res.statusCode == 200 && res.data != null) {
      // update
      App.logger.info("Username updated. name: $name");
      Navigator.pop(context);
      return;
    } else if (res.statusCode == 409 && res.data != null) {
      final reason = json.decode(res.data)["reason"] as String?;
      if (reason != null && reason == "name_conflict") {
        App.logger.warning("Name Conflict! name: $name");
        // pop alert: name conflict
      }
    }
  }
}
