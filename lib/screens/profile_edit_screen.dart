import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../helpers.dart';
import 'change_username_screen.dart';
import '../handlers/database_handler.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account and profile settings')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: ListView(
            children: [
              ListTile(
                title: Text('Change Avatar'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final source = await showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: Icon(Icons.photo_library),
                                title: Text('Photos'),
                                onTap: () => Navigator.of(
                                  context,
                                ).pop(ImageSource.gallery),
                              ),
                              ListTile(
                                leading: Icon(Icons.camera_alt),
                                title: Text('Camera'),
                                onTap: () => Navigator.of(
                                  context,
                                ).pop(ImageSource.camera),
                              ),
                            ],
                          ),
                        );
                      },
                    );

                    if (source == null) return;

                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: source);

                    if (pickedFile != null && context.mounted) {
                      final croppedFile = await ImageCropper().cropImage(
                        sourcePath: pickedFile.path,
                        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
                        uiSettings: [
                          AndroidUiSettings(
                              toolbarTitle: 'Position Avatar',
                              toolbarColor: Theme.of(context).colorScheme.primary,
                              toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              initAspectRatio: CropAspectRatioPreset.square,
                              lockAspectRatio: true,
                              hideBottomControls: false
                          ),
                          IOSUiSettings(
                            title: 'Position Avatar',
                            aspectRatioLockEnabled: true,
                            resetButtonHidden: true
                          )
                        ]
                      );

                      if (croppedFile == null || !context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Uploading avatar...')),
                      );

                      final uid = getUid();
                      final file = File(croppedFile.path);

                      final storageRef = FirebaseStorage.instance.ref().child(
                        'avatars/$uid.jpg',
                      );
                      await storageRef.putFile(file, SettableMetadata(contentType: 'image/jpeg'));

                      final downloadUrl = await storageRef.getDownloadURL();

                      await db.collection('Users').doc(uid).update({
                        'photoUrl': downloadUrl,
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Avatar updated successfully'),
                          ),
                        );
                      }
                    }
                  },
                  child: Text('Upload'),
                ),
              ),
              ListTile(
                title: Text('Change username'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeUsernameScreen(),
                      ),
                    );
                  },
                  child: Text('Change'),
                ),
              ),
              ListTile(
                title: Text('Sign out'),
                trailing: FilledButton(
                  onPressed: () async {
                    await signOut(context);
                  },
                  child: Text('Sign out'),
                ),
              ),
              ListTile(
                title: Text('Delete the account'),
                trailing: FilledButton(
                  style: ButtonStyle(backgroundColor: .all(Colors.red)),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Account Deletion'),
                      content: Text(
                        'Are you sure you want to delete your account? '
                        'All of your data will be deleted.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'Cancel'),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await deleteAccount(getUid());
                            if (!context.mounted) return;
                            Navigator.pop(context, 'Delete');
                            await signOut(context);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                  child: Text('Delete'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
