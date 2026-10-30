import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_brand_mark.dart';
import '../../../core/widgets/app_icon_tile.dart';
import '../../../core/widgets/app_page_app_bar.dart';
import '../../../core/widgets/app_select_field.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

class PickedProfilePhoto {
  const PickedProfilePhoto({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;
}

abstract interface class ProfilePhotoPicker {
  Future<PickedProfilePhoto?> pickPhoto();
}

class PlatformProfilePhotoPicker implements ProfilePhotoPicker {
  @override
  Future<PickedProfilePhoto?> pickPhoto() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ProfilePhotoPolicy.allowedExtensions,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    String? mimeType;
    try {
      mimeType = file.xFile.mimeType;
    } on UnimplementedError {
      mimeType = null;
    }
    return PickedProfilePhoto(
      fileName: file.name,
      mimeType: ProfilePhotoPolicy.normaliseMimeType(mimeType, file.name),
      bytes: bytes,
    );
  }
}

abstract final class ProfilePhotoPolicy {
  static const maxBytes = 5000000;
  static const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const allowedMimeTypes = {'image/jpeg', 'image/png', 'image/webp'};

  static String normaliseMimeType(String? value, String fileName) {
    final mimeType = value?.toLowerCase().trim();
    if (mimeType == 'image/jpg') return 'image/jpeg';
    if (mimeType != null && mimeType.isNotEmpty) return mimeType;
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => mimeType ?? '',
    };
  }

  static String? validate(PickedProfilePhoto photo) {
    if (!allowedMimeTypes.contains(photo.mimeType) ||
        !_matchesImageSignature(photo)) {
      return 'Choose a JPG, PNG, or WEBP image.';
    }
    if (photo.bytes.isEmpty) return 'The selected image is empty.';
    if (photo.bytes.lengthInBytes > maxBytes) {
      return 'Choose an image smaller than 5 MB.';
    }
    return null;
  }

  static bool _matchesImageSignature(PickedProfilePhoto photo) {
    final bytes = photo.bytes;
    return switch (photo.mimeType) {
      'image/jpeg' =>
        bytes.length >= 3 &&
            bytes[0] == 0xff &&
            bytes[1] == 0xd8 &&
            bytes[2] == 0xff,
      'image/png' =>
        bytes.length >= 8 &&
            bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4e &&
            bytes[3] == 0x47 &&
            bytes[4] == 0x0d &&
            bytes[5] == 0x0a &&
            bytes[6] == 0x1a &&
            bytes[7] == 0x0a,
      'image/webp' =>
        bytes.length >= 12 &&
            bytes[0] == 0x52 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x46 &&
            bytes[8] == 0x57 &&
            bytes[9] == 0x45 &&
            bytes[10] == 0x42 &&
            bytes[11] == 0x50,
      _ => false,
    };
  }
}

class ProfileBackgroundScreen extends StatefulWidget {
  const ProfileBackgroundScreen({
    super.key,
    required this.repository,
    required this.userId,
    this.photoPicker,
    this.accountEmail,
  });

  final ProfileBackgroundRepository repository;
  final String userId;
  final ProfilePhotoPicker? photoPicker;
  final String? accountEmail;

  @override
  State<ProfileBackgroundScreen> createState() =>
      _ProfileBackgroundScreenState();
}

class _ProfileBackgroundScreenState extends State<ProfileBackgroundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _occupationTitle = TextEditingController();
  final _interests = TextEditingController();
  final _targetRoles = TextEditingController();
  final _occupationSearch = TextEditingController();
  final _contactEmail = TextEditingController();
  final _phone = TextEditingController();
  final _githubUrl = TextEditingController();
  final _linkedInUrl = TextEditingController();
  final _upworkUrl = TextEditingController();
  final _jobstreetUrl = TextEditingController();
  final _whatsAppNumber = TextEditingController();
  final List<_AdditionalLinkControllers> _additionalLinks = [];
  late Future<_ProfileData> _dataFuture;
  late ProfileBackground _profile;
  List<EducationRecord> _education = [];
  List<ExperienceRecord> _experience = [];
  OccupationCategory? _occupationCategory;
  CareerStage? _careerStage;
  bool _populated = false;
  bool _listsPopulated = false;
  bool _saving = false;
  bool _photoSaving = false;
  String? _photoUrl;
  String? _photoLoadError;
  Uint8List? _photoPreviewBytes;
  Timer? _photoRefreshTimer;
  String? _scheduledPhotoPath;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _headline.dispose();
    _bio.dispose();
    _occupationTitle.dispose();
    _interests.dispose();
    _targetRoles.dispose();
    _occupationSearch.dispose();
    _contactEmail.dispose();
    _phone.dispose();
    _githubUrl.dispose();
    _linkedInUrl.dispose();
    _upworkUrl.dispose();
    _jobstreetUrl.dispose();
    _whatsAppNumber.dispose();
    for (final link in _additionalLinks) {
      link.dispose();
    }
    _photoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<_ProfileData> _loadData() async {
    final profile = await widget.repository.loadProfile(widget.userId);
    final records = await Future.wait([
      widget.repository.listEducation(widget.userId),
      widget.repository.listExperience(widget.userId),
    ]);
    String? photoUrl;
    String? photoError;
    if (profile?.photoPath case final path?) {
      try {
        photoUrl = await widget.repository.createProfilePhotoSignedUrl(path);
      } catch (_) {
        photoError = 'Profile photo preview could not be loaded.';
      }
    }
    return _ProfileData(
      profile: profile,
      education: records[0] as List<EducationRecord>,
      experience: records[1] as List<ExperienceRecord>,
      photoUrl: photoUrl,
      photoError: photoError,
    );
  }

  void _populate(ProfileBackground profile) {
    if (_populated) return;
    _profile = profile;
    _headline.text = profile.headline;
    _bio.text = profile.bio;
    _occupationTitle.text = profile.occupationTitle;
    _interests.text = profile.interests.join(', ');
    _targetRoles.text = profile.targetRoles.join(', ');
    _contactEmail.text = profile.contactEmail?.trim().isNotEmpty == true
        ? profile.contactEmail!
        : widget.accountEmail?.trim() ?? '';
    _phone.text = profile.phone ?? '';
    _githubUrl.text = profile.githubUrl ?? '';
    _linkedInUrl.text = profile.linkedInUrl ?? '';
    _upworkUrl.text = profile.upworkUrl ?? '';
    _jobstreetUrl.text = profile.jobstreetUrl ?? '';
    _whatsAppNumber.text = profile.whatsAppNumber ?? '';
    _additionalLinks.addAll(
      profile.additionalLinks.map(
        (link) => _AdditionalLinkControllers(link.label, link.url),
      ),
    );
    _occupationCategory = profile.occupationCategory;
    _careerStage = profile.careerStage;
    _populated = true;
  }

  Future<void> _saveProfile() async {
    if (_saving || _photoSaving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
    });
    try {
      final updated = _profileWithCurrentForm(_profile.photoPath);
      await widget.repository.saveBackground(widget.userId, updated);
      _profile = updated;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile saved')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile could not be saved. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        _schedulePhotoUrlRefresh(_profile.photoPath);
      }
    }
  }

  ProfileBackground _profileWithCurrentForm(String? photoPath) =>
      ProfileBackground(
        displayName: _profile.displayName,
        username: _profile.username,
        headline: _headline.text,
        bio: _bio.text,
        occupationCategory: _occupationCategory,
        occupationTitle: _occupationTitle.text,
        careerStage: _careerStage,
        interests: _splitList(_interests.text),
        targetRoles: _splitList(_targetRoles.text),
        photoPath: photoPath,
        contactEmail: _normaliseEmail(_contactEmail.text),
        phone: _normalisePhone(_phone.text),
        githubUrl: _normaliseUrl(_githubUrl.text),
        linkedInUrl: _normaliseUrl(_linkedInUrl.text),
        upworkUrl: _normaliseUpworkUrl(_upworkUrl.text),
        jobstreetUrl: _normaliseUrl(_jobstreetUrl.text),
        whatsAppNumber: _normaliseWhatsAppNumber(_whatsAppNumber.text),
        additionalLinks: _additionalLinks
            .where(
              (link) =>
                  link.label.text.trim().isNotEmpty &&
                  link.url.text.trim().isNotEmpty,
            )
            .map(
              (link) => ProfileContactLink(
                label: link.label.text.trim(),
                url: _normaliseUrl(link.url.text)!,
              ),
            )
            .toList(growable: false),
      );

  void _schedulePhotoUrlRefresh(String? photoPath) {
    if (photoPath == _scheduledPhotoPath &&
        (_photoRefreshTimer?.isActive ?? false)) {
      return;
    }
    _photoRefreshTimer?.cancel();
    _scheduledPhotoPath = photoPath;
    if (photoPath == null) return;
    _photoRefreshTimer = Timer(const Duration(seconds: 90), () {
      unawaited(_refreshPhotoUrl(photoPath));
    });
  }

  Future<void> _refreshPhotoUrl(String photoPath) async {
    if (!mounted || _profile.photoPath != photoPath) return;
    if (_saving || _photoSaving) {
      _schedulePhotoUrlRefresh(photoPath);
      return;
    }
    try {
      final signedUrl = await widget.repository.createProfilePhotoSignedUrl(
        photoPath,
      );
      if (!mounted || _profile.photoPath != photoPath) return;
      setState(() => _photoUrl = signedUrl);
    } catch (_) {
      if (mounted) _showError('Profile photo preview could not be refreshed.');
    } finally {
      if (mounted && _profile.photoPath == photoPath) {
        _schedulePhotoUrlRefresh(photoPath);
      }
    }
  }

  Future<void> _choosePhoto() async {
    if (_saving || _photoSaving) return;
    setState(() => _photoSaving = true);
    try {
      final picker = widget.photoPicker ?? PlatformProfilePhotoPicker();
      final photo = await picker.pickPhoto();
      if (!mounted || photo == null) return;
      final validationError = ProfilePhotoPolicy.validate(photo);
      if (validationError != null) {
        _showError(validationError);
        return;
      }
      final previous = _profile;
      setState(() => _photoPreviewBytes = photo.bytes);
      String? uploadedPath;
      try {
        uploadedPath = await widget.repository.uploadProfilePhoto(
          widget.userId,
          photo.bytes,
          photo.fileName,
          photo.mimeType,
        );
        final updated = _profileWithPhoto(previous, uploadedPath);
        await widget.repository.saveBackground(widget.userId, updated);
        String? signedUrl;
        try {
          signedUrl = await widget.repository.createProfilePhotoSignedUrl(
            uploadedPath,
          );
        } catch (_) {
          _photoLoadError =
              'Photo saved, but its private preview is unavailable.';
        }
        if (!mounted) return;
        setState(() {
          _profile = updated;
          _photoUrl = signedUrl;
          _photoLoadError = signedUrl == null
              ? 'Photo saved, but its private preview is unavailable.'
              : null;
        });
        _schedulePhotoUrlRefresh(uploadedPath);
        var oldPhotoCleanupFailed = false;
        if (previous.photoPath != null) {
          try {
            await widget.repository.deleteProfilePhoto(
              widget.userId,
              previous.photoPath!,
            );
          } catch (_) {
            oldPhotoCleanupFailed = true;
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                oldPhotoCleanupFailed
                    ? 'Photo saved, but the old private file could not be removed.'
                    : 'Profile photo saved',
              ),
            ),
          );
        }
      } catch (_) {
        if (uploadedPath != null) {
          try {
            await widget.repository.deleteProfilePhoto(
              widget.userId,
              uploadedPath,
            );
          } catch (_) {
            // Keep the upload failure visible; an orphaned private file is not public.
          }
        }
        if (mounted) {
          setState(() => _photoPreviewBytes = null);
          _showError('Profile photo could not be saved. Try again.');
        }
      }
    } catch (_) {
      if (mounted) {
        _showError('The selected photo could not be read. Try another image.');
      }
    } finally {
      if (mounted) setState(() => _photoSaving = false);
      _schedulePhotoUrlRefresh(_profile.photoPath);
    }
  }

  Future<void> _removePhoto() async {
    final path = _profile.photoPath;
    if (path == null || _saving || _photoSaving) return;
    if (!await _confirmDelete('Remove this profile photo?') || !mounted) return;
    setState(() => _photoSaving = true);
    try {
      final updated = _profileWithPhoto(_profile, null);
      await widget.repository.saveBackground(widget.userId, updated);
      _profile = updated;
      _photoRefreshTimer?.cancel();
      setState(() {
        _photoUrl = null;
        _photoPreviewBytes = null;
        _photoLoadError = null;
      });
      var cleanupFailed = false;
      try {
        await widget.repository.deleteProfilePhoto(widget.userId, path);
      } catch (_) {
        cleanupFailed = true;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cleanupFailed
                  ? 'Profile photo removed, but its private file could not be deleted.'
                  : 'Profile photo removed',
            ),
          ),
        );
      }
    } catch (_) {
      _showError('Profile photo could not be removed. Try again.');
    } finally {
      if (mounted) setState(() => _photoSaving = false);
    }
  }

  ProfileBackground _profileWithPhoto(ProfileBackground value, String? path) =>
      ProfileBackground(
        displayName: value.displayName,
        username: value.username,
        headline: value.headline,
        bio: value.bio,
        occupationCategory: value.occupationCategory,
        occupationTitle: value.occupationTitle,
        careerStage: value.careerStage,
        interests: value.interests,
        targetRoles: value.targetRoles,
        photoPath: path,
        contactEmail: value.contactEmail,
        phone: value.phone,
        githubUrl: value.githubUrl,
        linkedInUrl: value.linkedInUrl,
        upworkUrl: value.upworkUrl,
        jobstreetUrl: value.jobstreetUrl,
        whatsAppNumber: value.whatsAppNumber,
        additionalLinks: value.additionalLinks,
      );

  Future<void> _addEducation([EducationRecord? record]) async {
    final draft = await showDialog<EducationDraft>(
      context: context,
      builder: (_) => _EducationEditor(initial: record),
    );
    if (draft == null) return;
    try {
      final saved = await widget.repository.saveEducation(
        widget.userId,
        draft,
        id: record?.id,
      );
      if (!mounted) return;
      setState(() {
        _education = [
          saved,
          ..._education.where((item) => item.id != saved.id),
        ];
      });
    } catch (_) {
      _showError(
        'Education could not be saved. Check the details and try again.',
      );
    }
  }

  Future<void> _addExperience([ExperienceRecord? record]) async {
    final draft = await showDialog<ExperienceDraft>(
      context: context,
      builder: (_) => _ExperienceEditor(initial: record),
    );
    if (draft == null) return;
    try {
      final saved = await widget.repository.saveExperience(
        widget.userId,
        draft,
        id: record?.id,
      );
      if (!mounted) return;
      setState(() {
        _experience = [
          saved,
          ..._experience.where((item) => item.id != saved.id),
        ];
      });
    } catch (_) {
      _showError(
        'Experience could not be saved. Check the details and try again.',
      );
    }
  }

  Future<void> _deleteEducation(EducationRecord record) async {
    if (!await _confirmDelete('Delete this education record?')) return;
    try {
      await widget.repository.deleteEducation(widget.userId, record.id);
      if (mounted) {
        setState(() => _education.removeWhere((item) => item.id == record.id));
      }
    } catch (_) {
      _showError('Education record could not be deleted. Try again.');
    }
  }

  Future<void> _deleteExperience(ExperienceRecord record) async {
    if (!await _confirmDelete('Delete this experience record?')) return;
    try {
      await widget.repository.deleteExperience(widget.userId, record.id);
      if (mounted) {
        setState(() => _experience.removeWhere((item) => item.id == record.id));
      }
    } catch (_) {
      _showError('Experience record could not be deleted. Try again.');
    }
  }

  Future<bool> _confirmDelete(String title) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const AppPageAppBar(
        title: 'Profile and background',
        showBrand: false,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: FilledButton(
          key: const Key('saveProfileButton'),
          onPressed: _saving || _photoSaving ? null : _saveProfile,
          child: _saving || _photoSaving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save profile'),
        ),
      ),
      body: FutureBuilder<_ProfileData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ProfileLoadError(
              onRetry: () {
                setState(() => _dataFuture = _loadData());
              },
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          if (data.profile == null) {
            return const Center(
              child: Text('Your profile could not be found.'),
            );
          }
          if (!_populated) {
            _populate(data.profile!);
            _photoUrl = data.photoUrl;
            _photoLoadError = data.photoError;
            _schedulePhotoUrlRefresh(data.profile!.photoPath);
          }
          if (!_listsPopulated) {
            _education = data.education;
            _experience = data.experience;
            _listsPopulated = true;
          }
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.contentMaxWidth,
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width),
                    16,
                    AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width),
                    24,
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(
                          AppTheme.cardRadius,
                        ),
                        border: Border.all(color: AppColors.lightSlate),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppBrandMark(compact: true),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'A fuller picture of your work',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tell people what you do, what you are learning, and the experience you want them to see. Every field here is optional.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionHeading(context, 'Profile photo'),
                    const SizedBox(height: 12),
                    _profilePhotoEditor(context),
                    const SizedBox(height: 28),
                    _sectionHeading(context, 'About you'),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('profileHeadlineField'),
                      controller: _headline,
                      maxLength: 120,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Professional headline (optional)',
                        hintText: 'For example, Community health educator',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('profileBioField'),
                      controller: _bio,
                      maxLength: 2000,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'About your work (optional)',
                        hintText: 'What matters in the work you do?',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _occupationPicker(),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('occupationTitleField'),
                      controller: _occupationTitle,
                      maxLength: 120,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Role or occupation (optional)',
                        hintText: 'Add your own title or specialty',
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppSelectField<CareerStage?>(
                      key: const Key('careerStageField'),
                      value: _careerStage,
                      label: 'Where you are in your career (optional)',
                      items: [
                        const DropdownMenuItem<CareerStage?>(
                          value: null,
                          child: Text('Choose a stage'),
                        ),
                        for (final stage in CareerStage.values)
                          DropdownMenuItem<CareerStage?>(
                            value: stage,
                            child: Text(stage.label),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _careerStage = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('profileInterestsField'),
                      controller: _interests,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Areas of interest (optional)',
                        helperText: 'Separate items with commas',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('profileTargetRolesField'),
                      controller: _targetRoles,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Roles you are interested in (optional)',
                        helperText: 'Separate items with commas',
                      ),
                    ),
                    const SizedBox(height: 28),
                    _sectionHeading(context, 'Profile photo'),
                    const SizedBox(height: 12),
                    _profilePhotoEditor(context),
                    if (_photoLoadError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _photoLoadError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 28),
                    _sectionHeading(context, 'Contact details'),
                    const SizedBox(height: 6),
                    Text(
                      'These details stay private until you choose them for a published portfolio.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('profileContactEmailField'),
                      controller: _contactEmail,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Public contact email (optional)',
                        hintText: 'you@example.com',
                      ),
                      validator: _validateOptionalEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('profilePhoneField'),
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone (optional)',
                        hintText: '+1 555 0100',
                      ),
                      validator: _validateOptionalPhone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('profileGithubUrlField'),
                      controller: _githubUrl,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'GitHub URL (optional)',
                        hintText: 'github.com/your-name',
                      ),
                      validator: _validateOptionalUrl,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('profileLinkedInUrlField'),
                      controller: _linkedInUrl,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'LinkedIn URL (optional)',
                        hintText: 'linkedin.com/in/your-name',
                      ),
                      validator: _validateOptionalUrl,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('profileUpworkUrlField'),
                      controller: _upworkUrl,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Upwork profile URL (optional)',
                        hintText: 'upwork.com/freelancers/your-name',
                      ),
                      validator: _validateOptionalUpworkUrl,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('profileJobstreetUrlField'),
                      controller: _jobstreetUrl,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'JobStreet URL (optional)',
                        hintText: 'jobstreet.com/profile/your-name',
                      ),
                      validator: _validateOptionalUrl,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('profileWhatsAppNumberField'),
                      controller: _whatsAppNumber,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp number (optional)',
                        helperText: 'Include your country code',
                        hintText: '+1 555 0100',
                      ),
                      validator: _validateOptionalWhatsApp,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Additional links (optional)',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add a label so visitors understand each link.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    for (
                      var index = 0;
                      index < _additionalLinks.length;
                      index++
                    )
                      _additionalLinkEditor(index, _additionalLinks[index]),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        key: const Key('addProfileLinkButton'),
                        onPressed: _saving || _photoSaving
                            ? null
                            : () => setState(
                                () => _additionalLinks.add(
                                  _AdditionalLinkControllers(),
                                ),
                              ),
                        icon: const Icon(Icons.add_link),
                        label: const Text('Add another link'),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _sectionHeading(context, 'Education and training'),
                    const SizedBox(height: 6),
                    Text(
                      'Include a course in progress, a completed qualification, or any learning you want to share.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    if (_education.isEmpty)
                      const _NoRecords(label: 'No education added')
                    else
                      for (final record in _education)
                        _BackgroundRecordTile(
                          icon: Icons.school_outlined,
                          title: record.title,
                          subtitle: [
                            if (record.institution.isNotEmpty)
                              record.institution,
                            record.status.label,
                          ].join(' · '),
                          onTap: () => _addEducation(record),
                          onDelete: () => _deleteEducation(record),
                          deleteTooltip: 'Delete education record',
                        ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => _addEducation(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add education'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionHeading(context, 'Experience'),
                    const SizedBox(height: 6),
                    Text(
                      'Paid work is only one kind of experience. You can include freelance, volunteer, community, caregiving, or independent work.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    if (_experience.isEmpty)
                      const _NoRecords(label: 'No experience added')
                    else
                      for (final record in _experience)
                        _BackgroundRecordTile(
                          icon: Icons.work_outline,
                          title: record.title,
                          subtitle: [
                            record.type.label,
                            if (record.organization?.isNotEmpty == true)
                              record.organization!,
                            if (record.isCurrent) 'Current',
                          ].join(' · '),
                          onTap: () => _addExperience(record),
                          onDelete: () => _deleteExperience(record),
                          deleteTooltip: 'Delete experience record',
                        ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => _addExperience(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add experience'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _chooseOccupationCategory() async {
    _occupationSearch.clear();
    final selected = await showModalBottomSheet<OccupationCategory>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final query = _occupationSearch.text.trim().toLowerCase();
          final categories = OccupationCategory.values.where(
            (category) => category.label.toLowerCase().contains(query),
          );
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * .7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a field of work',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('occupationSearchField'),
                      controller: _occupationSearch,
                      autofocus: true,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Search fields',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final category in categories)
                            ListTile(
                              title: Text(category.label),
                              onTap: () =>
                                  Navigator.pop(sheetContext, category),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (selected != null && mounted) {
      setState(() => _occupationCategory = selected);
    }
  }

  Widget _occupationPicker() => InkWell(
    key: const Key('occupationCategoryField'),
    onTap: _chooseOccupationCategory,
    borderRadius: BorderRadius.circular(12),
    child: InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Field of work (optional)',
        suffixIcon: Icon(Icons.search),
      ),
      child: Text(
        _occupationCategory?.label ?? 'Search or choose a field',
        style: _occupationCategory == null
            ? TextStyle(color: Theme.of(context).hintColor)
            : null,
      ),
    ),
  );

  Widget _profilePhotoEditor(BuildContext context) {
    final hasPhoto = _profile.photoPath != null || _photoPreviewBytes != null;
    final preview = _photoPreviewBytes != null
        ? Image.memory(_photoPreviewBytes!, fit: BoxFit.cover)
        : _photoUrl == null
        ? null
        : Image.network(
            _photoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.broken_image_outlined, size: 36),
          );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.lightSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: ColoredBox(
                    color: AppColors.white,
                    child:
                        preview ?? const Icon(Icons.person_outline, size: 42),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPhoto ? 'Your profile photo' : 'Add a profile photo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This is the photo used in your portfolio and photo resume. '
                      'It stays private until you choose to include it.',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('chooseProfilePhotoButton'),
                onPressed: _saving || _photoSaving ? null : _choosePhoto,
                icon: _photoSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        hasPhoto ? Icons.refresh : Icons.add_a_photo_outlined,
                      ),
                label: Text(hasPhoto ? 'Replace photo' : 'Choose photo'),
              ),
              if (hasPhoto)
                TextButton.icon(
                  key: const Key('removeProfilePhotoButton'),
                  onPressed: _saving || _photoSaving ? null : _removePhoto,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove photo'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'JPG, PNG, or WEBP, up to 5 MB.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _additionalLinkEditor(int index, _AdditionalLinkControllers link) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                key: Key('profileAdditionalLinkLabel-$index'),
                controller: link.label,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Label (optional)',
                ),
                validator: (value) => _validateAdditionalLinkLabel(value, link),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextFormField(
                key: Key('profileAdditionalLinkUrl-$index'),
                controller: link.url,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'URL (optional)'),
                validator: (value) => _validateAdditionalLinkUrl(value, link),
              ),
            ),
            IconButton(
              tooltip: 'Remove additional link',
              onPressed: _saving || _photoSaving
                  ? null
                  : () => setState(() {
                      final removed = _additionalLinks.removeAt(index);
                      removed.dispose();
                    }),
              icon: const Icon(Icons.remove_circle_outline),
            ),
          ],
        ),
      );

  Widget _sectionHeading(BuildContext context, String title) {
    final icon = switch (title) {
      'Profile photo' => Icons.photo_camera_outlined,
      'About you' => Icons.person_outline,
      'Contact details' => Icons.contact_mail_outlined,
      'Education and training' => Icons.school_outlined,
      _ => Icons.volunteer_activism_outlined,
    };
    return Row(
      children: [
        AppIconTile(
          icon: icon,
          size: 36,
          iconSize: 18,
          color: title == 'Education and training'
              ? AppColors.teal
              : AppColors.amber,
          backgroundColor: title == 'Education and training'
              ? AppColors.tealContainer
              : AppColors.amberContainer,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.profile,
    required this.education,
    required this.experience,
    required this.photoUrl,
    required this.photoError,
  });
  final ProfileBackground? profile;
  final List<EducationRecord> education;
  final List<ExperienceRecord> experience;
  final String? photoUrl;
  final String? photoError;
}

class _AdditionalLinkControllers {
  _AdditionalLinkControllers([String label = '', String url = ''])
    : label = TextEditingController(text: label),
      url = TextEditingController(text: url);

  final TextEditingController label;
  final TextEditingController url;

  void dispose() {
    label.dispose();
    url.dispose();
  }
}

class _NoRecords extends StatelessWidget {
  const _NoRecords({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
  );
}

class _BackgroundRecordTile extends StatelessWidget {
  const _BackgroundRecordTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onDelete,
    required this.deleteTooltip,
  });

  final String title;
  final IconData icon;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String deleteTooltip;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      onTap: onTap,
      leading: AppIconTile(
        icon: icon,
        color: icon == Icons.school_outlined ? AppColors.teal : AppColors.amber,
        backgroundColor: icon == Icons.school_outlined
            ? AppColors.tealContainer
            : AppColors.amberContainer,
        size: 42,
        iconSize: 20,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: IconButton(
        tooltip: deleteTooltip,
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
      ),
    ),
  );
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIconTile(
            icon: Icons.cloud_off_outlined,
            size: 54,
            iconSize: 25,
          ),
          const SizedBox(height: 16),
          Text(
            'Profile details could not be loaded',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Check your connection and try again.'),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class _EducationEditor extends StatefulWidget {
  const _EducationEditor({this.initial});
  final EducationRecord? initial;

  @override
  State<_EducationEditor> createState() => _EducationEditorState();
}

class _EducationEditorState extends State<_EducationEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _institution = TextEditingController(
    text: widget.initial?.institution ?? '',
  );
  late final _description = TextEditingController(
    text: widget.initial?.description ?? '',
  );
  late EducationLevel? _level = widget.initial?.level;
  late EducationStatus _status =
      widget.initial?.status ?? EducationStatus.inProgress;
  late DateTime? _startDate = widget.initial?.startDate;
  late DateTime? _endDate = widget.initial?.endDate;

  Future<void> _pickDate({required bool start}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: (start ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        _startDate = selected;
      } else {
        _endDate = selected;
      }
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _institution.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Add education' : 'Edit education'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('educationTitleField'),
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Course or qualification',
              ),
              validator: (value) => value?.trim().isNotEmpty == true
                  ? null
                  : 'Enter a course or qualification',
            ),
            TextFormField(
              key: const Key('educationInstitutionField'),
              controller: _institution,
              decoration: const InputDecoration(
                labelText: 'School or provider (optional)',
              ),
            ),
            const SizedBox(height: 12),
            AppSelectField<EducationLevel?>(
              value: _level,
              label: 'Level (optional)',
              items: [
                const DropdownMenuItem<EducationLevel?>(
                  value: null,
                  child: Text('Choose a level'),
                ),
                for (final level in EducationLevel.values)
                  DropdownMenuItem<EducationLevel?>(
                    value: level,
                    child: Text(level.label),
                  ),
              ],
              onChanged: (value) => setState(() => _level = value),
            ),
            const SizedBox(height: 12),
            AppSelectField<EducationStatus>(
              value: _status,
              label: 'Progress',
              items: [
                for (final status in EducationStatus.values)
                  DropdownMenuItem<EducationStatus>(
                    value: status,
                    child: Text(status.label),
                  ),
              ],
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
            Row(
              children: [
                Expanded(
                  child: _OptionalDateButton(
                    label: 'Start date',
                    value: _startDate,
                    onPressed: () => _pickDate(start: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OptionalDateButton(
                    label: 'End date',
                    value: _endDate,
                    onPressed: () => _pickDate(start: false),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            EducationDraft(
              title: _title.text,
              institution: _institution.text,
              level: _level,
              status: _status,
              startDate: _startDate,
              endDate: _endDate,
              description: _description.text,
            ),
          );
        },
        child: const Text('Save education'),
      ),
    ],
  );
}

class _ExperienceEditor extends StatefulWidget {
  const _ExperienceEditor({this.initial});
  final ExperienceRecord? initial;

  @override
  State<_ExperienceEditor> createState() => _ExperienceEditorState();
}

class _ExperienceEditorState extends State<_ExperienceEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _organization = TextEditingController(
    text: widget.initial?.organization ?? '',
  );
  late final _description = TextEditingController(
    text: widget.initial?.description ?? '',
  );
  late ExperienceType _type = widget.initial?.type ?? ExperienceType.employment;
  late bool _isCurrent = widget.initial?.isCurrent ?? false;
  late DateTime? _startDate = widget.initial?.startDate;
  late DateTime? _endDate = widget.initial?.endDate;

  Future<void> _pickDate({required bool start}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: (start ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        _startDate = selected;
      } else {
        _endDate = selected;
      }
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _organization.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Add experience' : 'Edit experience'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('experienceTitleField'),
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Role or experience',
              ),
              validator: (value) => value?.trim().isNotEmpty == true
                  ? null
                  : 'Enter a role or experience',
            ),
            TextFormField(
              controller: _organization,
              decoration: const InputDecoration(
                labelText: 'Organization (optional)',
              ),
            ),
            const SizedBox(height: 12),
            AppSelectField<ExperienceType>(
              key: const Key('experienceTypeField'),
              value: _type,
              label: 'Type of experience',
              items: [
                for (final type in ExperienceType.values)
                  DropdownMenuItem<ExperienceType>(
                    value: type,
                    child: Text(type.label),
                  ),
              ],
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            CheckboxListTile(
              key: const Key('experienceCurrentField'),
              contentPadding: EdgeInsets.zero,
              value: _isCurrent,
              title: const Text('I do this currently'),
              onChanged: (value) => setState(() => _isCurrent = value ?? false),
            ),
            Row(
              children: [
                Expanded(
                  child: _OptionalDateButton(
                    label: 'Start date',
                    value: _startDate,
                    onPressed: () => _pickDate(start: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OptionalDateButton(
                    label: 'End date',
                    value: _endDate,
                    onPressed: _isCurrent
                        ? null
                        : () => _pickDate(start: false),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'What you did (optional)',
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            ExperienceDraft(
              title: _title.text,
              organization: _organization.text.trim().isEmpty
                  ? null
                  : _organization.text.trim(),
              type: _type,
              startDate: _startDate,
              endDate: _isCurrent ? null : _endDate,
              isCurrent: _isCurrent,
              description: _description.text,
            ),
          );
        },
        child: const Text('Save experience'),
      ),
    ],
  );
}

class _OptionalDateButton extends StatelessWidget {
  const _OptionalDateButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });
  final String label;
  final DateTime? value;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.calendar_today_outlined, size: 16),
    label: Text(
      value == null
          ? label
          : '${value!.year}-${value!.month.toString().padLeft(2, '0')}',
    ),
  );
}

List<String> _splitList(String text) => text
    .split(',')
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .toSet()
    .toList(growable: false);

String? _validateOptionalEmail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return _normaliseEmail(text) == null ? 'Enter a valid email address' : null;
}

String? _validateOptionalPhone(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return _normalisePhone(text) == null
      ? 'Enter 7 to 15 digits, with an optional + country code'
      : null;
}

String? _validateOptionalWhatsApp(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return _normaliseWhatsAppNumber(text) == null
      ? 'Enter a WhatsApp number with 7 to 15 digits'
      : null;
}

String? _validateOptionalUrl(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return _normaliseUrl(text) == null
      ? 'Enter a valid http:// or https:// link'
      : null;
}

String? _validateOptionalUpworkUrl(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return _normaliseUpworkUrl(text) == null
      ? 'Enter a valid Upwork profile URL'
      : null;
}

String? _validateAdditionalLinkLabel(
  String? value,
  _AdditionalLinkControllers link,
) {
  if (link.url.text.trim().isNotEmpty && (value?.trim().isEmpty ?? true)) {
    return 'Add a label for this link';
  }
  return null;
}

String? _validateAdditionalLinkUrl(
  String? value,
  _AdditionalLinkControllers link,
) {
  final text = value?.trim() ?? '';
  if (link.label.text.trim().isNotEmpty && text.isEmpty) {
    return 'Add a URL for this link';
  }
  return text.isNotEmpty && _normaliseUrl(text) == null
      ? 'Enter a valid http:// or https:// link'
      : null;
}

String? _normaliseEmail(String value) {
  final email = value.trim().toLowerCase();
  if (email.isEmpty) return null;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) ? email : null;
}

String? _normalisePhone(String value) {
  final phone = value.trim().replaceAll(RegExp(r'[\s().-]'), '');
  if (phone.isEmpty) return null;
  return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone) ? phone : null;
}

String? _normaliseWhatsAppNumber(String value) {
  final number = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (number.isEmpty) return null;
  return RegExp(r'^[0-9]{7,15}$').hasMatch(number) ? number : null;
}

String? _normaliseUrl(String value) {
  var text = value.trim();
  if (text.isEmpty) return null;
  if (!text.contains('://')) text = 'https://$text';
  final uri = Uri.tryParse(text);
  if (uri == null ||
      !(uri.scheme == 'http' || uri.scheme == 'https') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri.toString();
}

String? _normaliseUpworkUrl(String value) {
  final url = _normaliseUrl(value);
  if (url == null) return null;
  final uri = Uri.parse(url);
  if (uri.scheme != 'https' ||
      !{'upwork.com', 'www.upwork.com'}.contains(uri.host.toLowerCase()) ||
      !uri.path.startsWith('/freelancers/')) {
    return null;
  }
  return url;
}
