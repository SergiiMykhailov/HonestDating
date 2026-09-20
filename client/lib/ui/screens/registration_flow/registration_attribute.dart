enum RegistrationAttributeStep {
  sexualOrientation,
  datingIntention,
  height,
  bodyType,
  languagesSpoken,
  countryOfOrigin,
  religion,
  socialOrientation,
  goingOut,
  livingArrangement,
  diet,
  exercise,
  alcohol,
  smoking,
  recreationalDrugs,
  pets,
  children,
  educationLevel,
  currentStudy,
  workStatus,
  politicalViews,
}

extension RegistrationAttributeStepDetails on RegistrationAttributeStep {
  int get registrationStep => index + 5;

  RegistrationAttributeStep? get next {
    final nextIndex = index + 1;
    return nextIndex < RegistrationAttributeStep.values.length
        ? RegistrationAttributeStep.values[nextIndex]
        : null;
  }

  String get title {
    switch (this) {
      case RegistrationAttributeStep.sexualOrientation:
        return 'What is your sexual orientation?';
      case RegistrationAttributeStep.datingIntention:
        return 'What are you looking for?';
      case RegistrationAttributeStep.height:
        return 'How tall are you?';
      case RegistrationAttributeStep.bodyType:
        return 'How would you describe your body type?';
      case RegistrationAttributeStep.languagesSpoken:
        return 'Which languages do you speak?';
      case RegistrationAttributeStep.countryOfOrigin:
        return 'Where are you from?';
      case RegistrationAttributeStep.religion:
        return 'What is your religion?';
      case RegistrationAttributeStep.socialOrientation:
        return 'How social are you?';
      case RegistrationAttributeStep.goingOut:
        return 'How do you like to go out?';
      case RegistrationAttributeStep.livingArrangement:
        return 'What is your living arrangement?';
      case RegistrationAttributeStep.diet:
        return 'What is your diet?';
      case RegistrationAttributeStep.exercise:
        return 'How often do you exercise?';
      case RegistrationAttributeStep.alcohol:
        return 'How often do you drink alcohol?';
      case RegistrationAttributeStep.smoking:
        return 'Do you smoke?';
      case RegistrationAttributeStep.recreationalDrugs:
        return 'Do you use recreational drugs?';
      case RegistrationAttributeStep.pets:
        return 'What is your relationship with pets?';
      case RegistrationAttributeStep.children:
        return 'What is your relationship with children?';
      case RegistrationAttributeStep.educationLevel:
        return 'What is your education level?';
      case RegistrationAttributeStep.currentStudy:
        return 'Are you studying now?';
      case RegistrationAttributeStep.workStatus:
        return 'What is your work status?';
      case RegistrationAttributeStep.politicalViews:
        return 'What are your political views?';
    }
  }

  String get body {
    switch (this) {
      case RegistrationAttributeStep.languagesSpoken:
        return 'Choose the languages you can speak. You can select up to five.';
      case RegistrationAttributeStep.height:
        return 'Choose your preferred unit and enter your height.';
      default:
        return 'Tap one option to choose it and continue.';
    }
  }

  bool get allowsMultipleChoices =>
      this == RegistrationAttributeStep.languagesSpoken;
}

const List<String> registrationLanguages = <String>[
  'Arabic',
  'Chinese',
  'English',
  'Estonian',
  'Finnish',
  'French',
  'German',
  'Hindi',
  'Italian',
  'Japanese',
  'Korean',
  'Polish',
  'Portuguese',
  'Russian',
  'Spanish',
  'Swedish',
  'Ukrainian',
];

const List<String> registrationCountries = <String>[
  'Australia',
  'Brazil',
  'Canada',
  'China',
  'Estonia',
  'Finland',
  'France',
  'Germany',
  'India',
  'Italy',
  'Japan',
  'Mexico',
  'Poland',
  'Spain',
  'Sweden',
  'United Kingdom',
  'United States',
];

const List<String> registrationReligions = <String>[
  'Christianity',
  'Islam',
  'Judaism',
  'Hinduism',
  'Buddhism',
  'Sikhism',
  'Other Religion',
  'No Religion',
];

List<String> registrationOptionsFor(RegistrationAttributeStep step) {
  switch (step) {
    case RegistrationAttributeStep.sexualOrientation:
      return const <String>[
        'Straight',
        'Gay/Lesbian',
        'Bisexual',
        'Pansexual',
        'Asexual',
        'Queer',
        'Other',
      ];
    case RegistrationAttributeStep.datingIntention:
      return const <String>[
        'Long-Term Relationship',
        'Long-Term, Open to Short-Term',
        'Short-Term, Open to Long-Term',
        'Short-Term Relationship',
        'Not Dating — Friendship Only',
      ];
    case RegistrationAttributeStep.bodyType:
      return const <String>[
        'Slim',
        'Average',
        'Athletic',
        'Muscular',
        'Curvy',
        'Large',
        'Other',
      ];
    case RegistrationAttributeStep.languagesSpoken:
      return registrationLanguages;
    case RegistrationAttributeStep.countryOfOrigin:
      return registrationCountries;
    case RegistrationAttributeStep.religion:
      return registrationReligions;
    case RegistrationAttributeStep.socialOrientation:
      return const <String>['Introvert', 'Ambivert', 'Extrovert'];
    case RegistrationAttributeStep.goingOut:
      return const <String>[
        'Homebody',
        'Sometimes Goes Out',
        'Enjoys Going Out',
      ];
    case RegistrationAttributeStep.livingArrangement:
      return const <String>[
        'Live Alone',
        'Live with Roommates',
        'Live with Family',
        'Live with a Partner',
      ];
    case RegistrationAttributeStep.diet:
      return const <String>[
        'No Restrictions',
        'Vegetarian',
        'Vegan',
        'Pescatarian',
        'Halal',
        'Kosher',
        'Other',
      ];
    case RegistrationAttributeStep.exercise:
      return const <String>[
        'Never',
        'Occasionally',
        '1–2 times a week',
        '3–4 times a week',
        '5+ times a week',
      ];
    case RegistrationAttributeStep.alcohol:
      return const <String>['Never', 'Rarely', 'Occasionally', 'Regularly'];
    case RegistrationAttributeStep.smoking:
      return const <String>['Never', 'Occasionally', 'Regularly'];
    case RegistrationAttributeStep.recreationalDrugs:
      return const <String>['Never', 'Occasionally', 'Regularly'];
    case RegistrationAttributeStep.pets:
      return const <String>[
        "No Pets, Doesn't Want Any",
        'No Pets, Wants Pets',
        'No Pets, Open to Pets',
        "Has Pets, Doesn't Want More",
        'Has Pets, Wants More',
        'Has Pets, Open to More',
      ];
    case RegistrationAttributeStep.children:
      return const <String>[
        "No Children, Doesn't Want Any",
        'No Children, Wants Children',
        'No Children, Open to Children',
        "Has Children, Doesn't Want More",
        'Has Children, Wants More',
        'Has Children, Open to More',
      ];
    case RegistrationAttributeStep.educationLevel:
      return const <String>[
        'High School',
        'Vocational / Trade School',
        'Associate Degree',
        'Bachelor\'s Degree',
        'Master\'s Degree',
        'Doctoral Degree',
        'Other',
      ];
    case RegistrationAttributeStep.currentStudy:
      return const <String>[
        'Not Currently Studying',
        'Undergraduate Student',
        'Graduate Student',
        'Doctoral Student',
        'Vocational / Trade Student',
        'Other Student',
      ];
    case RegistrationAttributeStep.workStatus:
      return const <String>[
        'Employed',
        'Self-Employed',
        'Entrepreneur',
        'Retired',
        'Not Currently Working',
      ];
    case RegistrationAttributeStep.politicalViews:
      return const <String>[
        'Left',
        'Center-Left',
        'Center',
        'Center-Right',
        'Right',
        'Other',
        'Not Political',
      ];
    case RegistrationAttributeStep.height:
      return const <String>[];
  }
}
