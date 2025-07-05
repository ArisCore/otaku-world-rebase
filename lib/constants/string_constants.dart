class StringConstants {
  static const String nullStringConstant = ' - - ';
  static const String nullStringPlaceHolder = ' - ';

  static const socialHeading = 'Connect, Share, and \nDiscover';
  static const socialSubheading =
      'Stay Updated with Global Anime Activities and'
      ' \nInteractions';

  static const noInternet = 'No Internet';
  static const noInternetError =
      'Please check your internet connection and try again!';
  static const somethingWentWrong = 'Something went wrong';
  static const somethingWentWrongError =
      'Something went wrong, Please try again!';
  static const unexpectedError = 'Some Unexpected error occurred!';
  static const validationError = 'Please enter valid text!';
  static const statsNotAvailable = 'Statistics not available!';
  static const messageConfirmation =
      'Are you sure you want to send this message?';
  static const unfollowConfirmation =
      'Their activities will no longer appear in your Following tab.';

  static const settingsConfirmationHeading = 'Save Settings';
  static const listSettingsConfirmationWarning =
      'Your list will reload to reflect the new settings. Do you want to proceed?';
  static const deleteListEntryHeading = 'Delete List Entry';
  static const deleteListEntryWarning =
      'Are you sure you want to delete this list entry?';

  static const urlValidationError = 'Please enter valid url';
  static const imageUrlValidationError = 'Please enter valid image url';

  static const defaultLanguageDropdown = 'Japanese';
}

class LoginConstants {
  static const String loginToAniListHeading = 'Login to Your AniList Account';
  static const String loginToAniListSubHeading =
      "You’ll be redirected to AniList website for login/register. Make sure that url is anilist.co before entering your email and password.";
  static const String registerText =
      'New here? Register on the AniList website and then log in to our app using your new account!';
}

class OnBoardingConstants {
  static const String page1Heading =
      'Explore a World of Anime and Manga Delights!';
  static const String page1Subheading =
      'Browse through an extensive collection of anime series, manga titles, characters, staff members, and studios.';

  static const String page2Heading =
      'Keep Track of Your Anime and Manga Watchlist!';
  static const String page2Subheading =
      "Add the anime series and manga titles you're currently watching, plan to watch, or want to revisit.";

  static const String page3Heading = 'Your Personal Anime and Manga Profile';
  static const String page3Subheading =
      'Access a wealth of information, stats, and customization options to express your unique preferences and fandom.';

  static const String page4Heading =
      'Connect with Anime & Manga Enthusiasts Worldwide!';
  static const String page4Subheading =
      'Stay up-to-date with the latest activities and updates from your friends, followers and global users';
}

class CategorySelectionConstants {
  static const String chooseInterest =
      "Choose your interest and get the best anime recommendations. Don't worry, you can always change it later.";

  static const String leastSelection = '(Choose at least 3)';
}

class HomeConstants {
  static const String discover = 'Discover what interests you...';

  static const String reviewsHeading = 'Reviews';
  static const String reviewsSubheading =
      'Discover what fans are saying, Get insights from fellow anime lovers and Share your thoughts and reviews';

  static const String calendarHeading = 'Calendar';
  static const String calendarSubheading =
      'Stay updated with upcoming episodes and plan your anime viewing schedule';
}

class CalendarConstants {
  static const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

class DiscoverConstants {
  static const animeDiscoverHeading = 'Uncover the wonders of \nAnime';
  static const animeDiscoverSubheading =
      'Explore a Universe of Endless Possibilities, '
      'Unveiling Hidden Gems and Beloved Classics';

  static const mangaDiscoverHeading = 'Unravel the World of \nManga';
  static const mangaDiscoverSubheading = 'Dive into a Universe of Captivating'
      'Narratives and Artistry';
}

class ActivityConstants {
  static const notFound =
      'Oops! It looks like this activity is no longer available. It may have been removed or deleted.';
  static const clientError = 'Something went wrong, Please restart the app!';
  static const somethingWrong = 'Something went wrong!';

  static String subscriptionSuccess(bool subscribed) {
    return '${subscribed ? 'Subscribed' : 'Unsubscribed'} the activity!';
  }

  static const alreadyInProgress = 'Action already in progress. Please wait!';
}

class AboutUsConstants {
  static const String appName = 'Otaku World';
  static const String aboutUsDescription =
      ' is an unofficial AniList client for mobile, designed to give you a smooth, fan‑driven experience for tracking and discovering anime & manga on the go. Built by enthusiasts, Otaku World syncs seamlessly with your AniList account, presents all your lists and progress in a clean, intuitive interface, and makes sharing your favorites with friends effortless. Although it’s not affiliated with AniList, it’s crafted with care to feel right at home for any Otaku.';
  static const String readOurPrivacy = '\n\nRead our privacy policy ';
  static const String contactUs = '\n\nFound a bug or want a new feature? ';
}

class UiConstants {
  static const noImageUrl = '';
  static const noName = '';
}
