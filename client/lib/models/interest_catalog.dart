class InterestCategory {
  const InterestCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.interests,
  });

  final String id;
  final String label;
  final String icon;
  final List<String> interests;
}

/// Local preview catalogue for registration. The selected values are canonical
/// names: an interest that appears in more than one category remains one item
/// in the user's profile draft.
const List<InterestCategory> interestCategories = <InterestCategory>[
  InterestCategory(
    id: 'outdoors',
    label: 'Outdoors & Nature',
    icon: '🌲',
    interests: <String>['Hiking', 'Camping', 'Wildlife'],
  ),
  InterestCategory(
    id: 'fitness',
    label: 'Fitness & Exercise',
    icon: '🏋️',
    interests: <String>['Running', 'Yoga', 'Strength Training'],
  ),
  InterestCategory(
    id: 'sports',
    label: 'Sports',
    icon: '⚽',
    interests: <String>['Football', 'Tennis', 'Beach Volleyball'],
  ),
  InterestCategory(
    id: 'adventure',
    label: 'Adventure & Adrenaline',
    icon: '🧗',
    interests: <String>['Rock Climbing', 'Hiking', 'Skydiving'],
  ),
  InterestCategory(
    id: 'winter',
    label: 'Winter Activities',
    icon: '❄️',
    interests: <String>['Skiing', 'Snowboarding', 'Ice Skating'],
  ),
  InterestCategory(
    id: 'travel',
    label: 'Travel',
    icon: '✈️',
    interests: <String>['City Breaks', 'Road Trips', 'Solo Travel'],
  ),
  InterestCategory(
    id: 'food',
    label: 'Food, Cooking & Cuisines',
    icon: '🍳',
    interests: <String>['Cooking', 'Baking', 'Trying New Restaurants'],
  ),
  InterestCategory(
    id: 'drinks',
    label: 'Coffee, Tea & Drinks',
    icon: '☕',
    interests: <String>['Specialty Coffee', 'Tea', 'Wine Tasting'],
  ),
  InterestCategory(
    id: 'music',
    label: 'Music',
    icon: '🎵',
    interests: <String>['Live Music', 'Jazz', 'Playlists'],
  ),
  InterestCategory(
    id: 'movies',
    label: 'Movies & Film',
    icon: '🎬',
    interests: <String>['Cinema', 'Documentaries', 'Film Festivals'],
  ),
  InterestCategory(
    id: 'tv',
    label: 'TV & Streaming',
    icon: '📺',
    interests: <String>['Drama Series', 'Comedy Shows', 'Reality TV'],
  ),
  InterestCategory(
    id: 'books',
    label: 'Books & Reading',
    icon: '📚',
    interests: <String>['Fiction', 'Book Clubs', 'Non-fiction'],
  ),
  InterestCategory(
    id: 'writing',
    label: 'Writing & Literature',
    icon: '✍️',
    interests: <String>['Creative Writing', 'Poetry', 'Journaling'],
  ),
  InterestCategory(
    id: 'arts',
    label: 'Arts & Visual Creativity',
    icon: '🎨',
    interests: <String>['Photography', 'Painting', 'Museums'],
  ),
  InterestCategory(
    id: 'crafts',
    label: 'Crafts & Making',
    icon: '🧵',
    interests: <String>['Ceramics', 'Knitting', 'DIY Projects'],
  ),
  InterestCategory(
    id: 'gaming',
    label: 'Gaming',
    icon: '🎮',
    interests: <String>['Board Games', 'Video Games', 'Trivia Nights'],
  ),
  InterestCategory(
    id: 'social',
    label: 'Social & Going Out',
    icon: '🍻',
    interests: <String>['Dinner Parties', 'Pub Quizzes', 'Dancing'],
  ),
  InterestCategory(
    id: 'theater',
    label: 'Theater & Performing Arts',
    icon: '🎭',
    interests: <String>['Theater', 'Comedy', 'Concerts'],
  ),
  InterestCategory(
    id: 'science',
    label: 'Science & Technology',
    icon: '🔬',
    interests: <String>['Technology', 'Space', 'Science Podcasts'],
  ),
  InterestCategory(
    id: 'learning',
    label: 'Learning & Intellectual Interests',
    icon: '🧠',
    interests: <String>['Languages', 'Online Courses', 'Puzzles'],
  ),
  InterestCategory(
    id: 'culture',
    label: 'Languages & Culture',
    icon: '🌍',
    interests: <String>['Languages', 'Cultural Events', 'Museums'],
  ),
  InterestCategory(
    id: 'style',
    label: 'Fashion, Beauty & Style',
    icon: '👗',
    interests: <String>['Fashion', 'Skincare', 'Vintage Shopping'],
  ),
  InterestCategory(
    id: 'home',
    label: 'Home & Interior',
    icon: '🏠',
    interests: <String>['Interior Design', 'Gardening', 'Home Cooking'],
  ),
  InterestCategory(
    id: 'animals',
    label: 'Animals & Pets',
    icon: '🐾',
    interests: <String>['Dogs', 'Cats', 'Animal Welfare'],
  ),
  InterestCategory(
    id: 'transport',
    label: 'Cars, Motorcycles & Transportation',
    icon: '🚗',
    interests: <String>['Cars', 'Motorcycles', 'Cycling'],
  ),
  InterestCategory(
    id: 'collecting',
    label: 'Collecting',
    icon: '🏺',
    interests: <String>['Vinyl Records', 'Antiques', 'Thrifting'],
  ),
  InterestCategory(
    id: 'history',
    label: 'History & Heritage',
    icon: '🏛️',
    interests: <String>['History', 'Architecture', 'Local Heritage'],
  ),
  InterestCategory(
    id: 'ideas',
    label: 'Mind, Philosophy & Ideas',
    icon: '💭',
    interests: <String>['Philosophy', 'Psychology', 'Deep Conversations'],
  ),
  InterestCategory(
    id: 'wellness',
    label: 'Wellness & Mindfulness',
    icon: '🧘',
    interests: <String>['Meditation', 'Yoga', 'Wellness'],
  ),
  InterestCategory(
    id: 'community',
    label: 'Community & Social Activities',
    icon: '🤝',
    interests: <String>['Volunteering', 'Community Events', 'Meetups'],
  ),
  InterestCategory(
    id: 'spiritual',
    label: 'Spiritual & Reflective Interests',
    icon: '🕯️',
    interests: <String>['Mindfulness', 'Spirituality', 'Journaling'],
  ),
  InterestCategory(
    id: 'business',
    label: 'Business & Entrepreneurship',
    icon: '💼',
    interests: <String>['Entrepreneurship', 'Startups', 'Investing'],
  ),
  InterestCategory(
    id: 'creator',
    label: 'Creator & Digital Media',
    icon: '📱',
    interests: <String>['Content Creation', 'Podcasts', 'Digital Art'],
  ),
];

List<String> interestsForCategory(String categoryID) {
  return interestCategories
      .firstWhere((InterestCategory category) => category.id == categoryID)
      .interests;
}

List<String> searchCatalogInterests(String query) {
  final normalizedQuery = query.trim().toLowerCase();
  final allInterests = <String>{
    for (final category in interestCategories) ...category.interests,
  }.toList()..sort();
  if (normalizedQuery.isEmpty) {
    return allInterests;
  }
  return allInterests
      .where(
        (String interest) => interest.toLowerCase().contains(normalizedQuery),
      )
      .toList();
}
