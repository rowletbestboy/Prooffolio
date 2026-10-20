enum SkillCategory {
  agricultureEnvironment('agriculture_environment', 'Agriculture and environment'),
  artsMediaDesign('arts_media_design', 'Arts, media, and design'),
  businessAdministration('business_administration', 'Business and administration'),
  constructionTrades('construction_trades', 'Construction and skilled trades'),
  educationTraining('education_training', 'Education and training'),
  engineeringManufacturing('engineering_manufacturing', 'Engineering and manufacturing'),
  healthcareCare('healthcare_care', 'Healthcare and care services'),
  hospitalityTourism('hospitality_tourism', 'Hospitality and tourism'),
  technologyDigital('technology_digital', 'Technology and digital work'),
  lawPublicService('law_public_service', 'Law and public service'),
  scienceResearch('science_research', 'Science and research'),
  salesCustomerService('sales_customer_service', 'Sales and customer service'),
  transportLogistics('transport_logistics', 'Transportation and logistics'),
  virtualAssistanceRemoteOperations(
    'virtual_assistance_remote_operations',
    'Virtual assistance and remote operations',
  ),
  communicationLanguages('communication_languages', 'Communication and languages'),
  leadershipProjectManagement(
    'leadership_project_management',
    'Leadership and project management',
  ),
  other('other', 'Other');

  const SkillCategory(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static SkillCategory fromDatabase(String? value) {
    const legacyTechnologyValues = {
      'programming_languages',
      'mobile_development',
      'web_development',
      'backend_development',
      'databases',
      'embedded_systems_iot',
      'networking_systems',
      'software_engineering',
      'testing_debugging',
      'technical_documentation',
    };
    if (legacyTechnologyValues.contains(value)) {
      return SkillCategory.technologyDigital;
    }
    return SkillCategory.values.firstWhere(
      (category) => category.databaseValue == value,
      orElse: () => SkillCategory.other,
    );
  }
}

enum SkillStatus {
  learning('learning', 'Learning'),
  practicing('practicing', 'Practicing'),
  applied('applied', 'Applied in a project');

  const SkillStatus(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static SkillStatus fromDatabase(String? value) =>
      SkillStatus.values.firstWhere(
        (status) => status.databaseValue == value,
        orElse: () => SkillStatus.learning,
      );
}

class SkillDraft {
  const SkillDraft({
    required this.name,
    required this.category,
    required this.status,
  });

  final String name;
  final SkillCategory category;
  final SkillStatus status;

  Map<String, dynamic> toRpcParameters(String? id, List<String> projectIds) => {
    'p_skill_id': id,
    'p_name': name.trim(),
    'p_category': category.databaseValue,
    'p_status': status.databaseValue,
    'p_project_ids': projectIds,
  };
}

class Skill {
  const Skill({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.status,
    required this.projectIds,
    required this.projectTitles,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final SkillCategory category;
  final SkillStatus status;
  final List<String> projectIds;
  final List<String> projectTitles;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    category: SkillCategory.fromDatabase(json['category'] as String?),
    status: SkillStatus.fromDatabase(json['status'] as String?),
    projectIds: _stringList(json['project_ids']),
    projectTitles: _stringList(json['project_titles']),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

List<String> _stringList(dynamic value) => value is List
    ? value.map((item) => item.toString()).toList(growable: false)
    : const [];
