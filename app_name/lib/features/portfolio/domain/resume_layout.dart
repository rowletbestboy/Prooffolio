enum ResumeLayout {
  atsFriendly,
  visual;

  String get label => switch (this) {
    ResumeLayout.atsFriendly => 'ATS-friendly format',
    ResumeLayout.visual => 'Photo resume',
  };
}
