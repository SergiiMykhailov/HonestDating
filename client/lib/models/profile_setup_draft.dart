class ProfileSetupDraft {
  const ProfileSetupDraft({
    this.firstName = '',
    this.lastName = '',
    this.dateOfBirth,
    this.gender = '',
    this.orientation = '',
    this.relationshipIntention = '',
    this.heightCentimeters = '',
    this.bodyType = '',
    this.hairColor = '',
    this.eyeColor = '',
    this.languages = const <String>[],
    this.countryOfOrigin = '',
    this.religion = '',
    this.religiosity = '',
    this.socialOrientation = '',
    this.goingOut = '',
    this.hosting = '',
    this.livingArrangement = '',
    this.livingEnvironment = '',
    this.diet = '',
    this.foodRestrictions = const <String>[],
    this.exercise = '',
    this.sleepSchedule = '',
    this.alcohol = '',
    this.smoking = '',
    this.recreationalDrugs = '',
    this.pets = '',
    this.children = '',
    this.travelFrequency = '',
    this.educationLevel = '',
    this.currentEducation = '',
    this.employment = '',
    this.mainPhotoPath,
    this.galleryPhotoPaths = const <String>[],
    this.aboutMe = '',
    this.interests = const <String>[],
  });

  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String gender;
  final String orientation;
  final String relationshipIntention;
  final String heightCentimeters;
  final String bodyType;
  final String hairColor;
  final String eyeColor;
  final List<String> languages;
  final String countryOfOrigin;
  final String religion;
  final String religiosity;
  final String socialOrientation;
  final String goingOut;
  final String hosting;
  final String livingArrangement;
  final String livingEnvironment;
  final String diet;
  final List<String> foodRestrictions;
  final String exercise;
  final String sleepSchedule;
  final String alcohol;
  final String smoking;
  final String recreationalDrugs;
  final String pets;
  final String children;
  final String travelFrequency;
  final String educationLevel;
  final String currentEducation;
  final String employment;
  final String? mainPhotoPath;
  final List<String> galleryPhotoPaths;
  final String aboutMe;
  final List<String> interests;

  int? get age {
    final dateOfBirth = this.dateOfBirth;
    if (dateOfBirth == null) {
      return null;
    }

    final today = DateTime.now();
    var age = today.year - dateOfBirth.year;
    final birthdayHasPassed =
        today.month > dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day >= dateOfBirth.day);
    if (!birthdayHasPassed) {
      age -= 1;
    }
    return age;
  }

  String? get zodiacSign {
    final dateOfBirth = this.dateOfBirth;
    if (dateOfBirth == null) {
      return null;
    }

    final month = dateOfBirth.month;
    final day = dateOfBirth.day;
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) {
      return 'Aries';
    }
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) {
      return 'Taurus';
    }
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) {
      return 'Gemini';
    }
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) {
      return 'Cancer';
    }
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) {
      return 'Leo';
    }
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) {
      return 'Virgo';
    }
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) {
      return 'Libra';
    }
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) {
      return 'Scorpio';
    }
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
      return 'Sagittarius';
    }
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) {
      return 'Capricorn';
    }
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
      return 'Aquarius';
    }
    return 'Pisces';
  }

  String? get yearAnimal {
    final dateOfBirth = this.dateOfBirth;
    if (dateOfBirth == null) {
      return null;
    }

    const animals = <String>[
      'Rat',
      'Ox',
      'Tiger',
      'Rabbit',
      'Dragon',
      'Snake',
      'Horse',
      'Goat',
      'Monkey',
      'Rooster',
      'Dog',
      'Pig',
    ];
    return animals[(dateOfBirth.year - 4) % animals.length];
  }

  bool get hasValidHeight {
    final height = int.tryParse(heightCentimeters.trim());
    return height != null && height >= 80 && height <= 250;
  }

  bool get isBasicComplete =>
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty &&
      dateOfBirth != null &&
      gender.isNotEmpty &&
      orientation.isNotEmpty &&
      relationshipIntention.isNotEmpty;

  bool get isPhysicalComplete =>
      hasValidHeight &&
      bodyType.isNotEmpty &&
      hairColor.isNotEmpty &&
      eyeColor.isNotEmpty;

  bool get isIdentityComplete =>
      languages.isNotEmpty &&
      countryOfOrigin.isNotEmpty &&
      religion.isNotEmpty &&
      (religion == 'No Religion' || religiosity.isNotEmpty);

  bool get isLifestyleComplete =>
      socialOrientation.isNotEmpty &&
      goingOut.isNotEmpty &&
      hosting.isNotEmpty &&
      livingArrangement.isNotEmpty &&
      livingEnvironment.isNotEmpty &&
      diet.isNotEmpty &&
      foodRestrictions.isNotEmpty &&
      exercise.isNotEmpty &&
      sleepSchedule.isNotEmpty &&
      alcohol.isNotEmpty &&
      smoking.isNotEmpty &&
      recreationalDrugs.isNotEmpty &&
      pets.isNotEmpty &&
      children.isNotEmpty &&
      travelFrequency.isNotEmpty &&
      educationLevel.isNotEmpty &&
      currentEducation.isNotEmpty &&
      employment.isNotEmpty;

  bool get isComplete =>
      isBasicComplete &&
      isPhysicalComplete &&
      isIdentityComplete &&
      isLifestyleComplete;

  bool get isReadyForMobileCompletion =>
      isComplete &&
      mainPhotoPath != null &&
      aboutMe.trim().isNotEmpty &&
      interests.isNotEmpty;

  ProfileSetupDraft copyWith({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? orientation,
    String? relationshipIntention,
    String? heightCentimeters,
    String? bodyType,
    String? hairColor,
    String? eyeColor,
    List<String>? languages,
    String? countryOfOrigin,
    String? religion,
    String? religiosity,
    String? socialOrientation,
    String? goingOut,
    String? hosting,
    String? livingArrangement,
    String? livingEnvironment,
    String? diet,
    List<String>? foodRestrictions,
    String? exercise,
    String? sleepSchedule,
    String? alcohol,
    String? smoking,
    String? recreationalDrugs,
    String? pets,
    String? children,
    String? travelFrequency,
    String? educationLevel,
    String? currentEducation,
    String? employment,
    String? mainPhotoPath,
    List<String>? galleryPhotoPaths,
    String? aboutMe,
    List<String>? interests,
  }) {
    return ProfileSetupDraft(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      orientation: orientation ?? this.orientation,
      relationshipIntention:
          relationshipIntention ?? this.relationshipIntention,
      heightCentimeters: heightCentimeters ?? this.heightCentimeters,
      bodyType: bodyType ?? this.bodyType,
      hairColor: hairColor ?? this.hairColor,
      eyeColor: eyeColor ?? this.eyeColor,
      languages: languages ?? this.languages,
      countryOfOrigin: countryOfOrigin ?? this.countryOfOrigin,
      religion: religion ?? this.religion,
      religiosity: religiosity ?? this.religiosity,
      socialOrientation: socialOrientation ?? this.socialOrientation,
      goingOut: goingOut ?? this.goingOut,
      hosting: hosting ?? this.hosting,
      livingArrangement: livingArrangement ?? this.livingArrangement,
      livingEnvironment: livingEnvironment ?? this.livingEnvironment,
      diet: diet ?? this.diet,
      foodRestrictions: foodRestrictions ?? this.foodRestrictions,
      exercise: exercise ?? this.exercise,
      sleepSchedule: sleepSchedule ?? this.sleepSchedule,
      alcohol: alcohol ?? this.alcohol,
      smoking: smoking ?? this.smoking,
      recreationalDrugs: recreationalDrugs ?? this.recreationalDrugs,
      pets: pets ?? this.pets,
      children: children ?? this.children,
      travelFrequency: travelFrequency ?? this.travelFrequency,
      educationLevel: educationLevel ?? this.educationLevel,
      currentEducation: currentEducation ?? this.currentEducation,
      employment: employment ?? this.employment,
      mainPhotoPath: mainPhotoPath ?? this.mainPhotoPath,
      galleryPhotoPaths: galleryPhotoPaths ?? this.galleryPhotoPaths,
      aboutMe: aboutMe ?? this.aboutMe,
      interests: interests ?? this.interests,
    );
  }
}
