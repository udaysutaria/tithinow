library;

/// Supported languages in the application.
enum AppLanguage {
  english('English'),
  hindi('हिन्दी'),
  gujarati('ગુજરાતી');

  final String label;
  const AppLanguage(this.label);

  static AppLanguage fromString(String val) => switch (val.toLowerCase()) {
        'hindi' => AppLanguage.hindi,
        'gujarati' => AppLanguage.gujarati,
        _ => AppLanguage.english,
      };
}

/// Auspiciousness / nature of a timing period (Good or Bad).
enum PeriodNature {
  good(
    en: 'Good',
    hi: 'शुभ',
    gu: 'શુભ',
  ),
  bad(
    en: 'Bad',
    hi: 'अशुभ',
    gu: 'અશુભ',
  );

  final String en;
  final String hi;
  final String gu;

  const PeriodNature({
    required this.en,
    required this.hi,
    required this.gu,
  });

  /// Returns the localized label for the period nature.
  String label(AppLanguage lang) => switch (lang) {
        AppLanguage.english => en,
        AppLanguage.hindi => hi,
        AppLanguage.gujarati => gu,
      };

  bool get isGood => this == PeriodNature.good;
  bool get isBad => this == PeriodNature.bad;
}

/// Category titles and labels for Panchang sections.
class PanchangLabels {
  const PanchangLabels._();

  static String englishMonth(AppLanguage lang) => switch (lang) {
        AppLanguage.english => 'English Month',
        AppLanguage.hindi => 'अंग्रेज़ी मास',
        AppLanguage.gujarati => 'અંગ્રેજી માસ',
      };

  static String weekday(AppLanguage lang) => switch (lang) {
        AppLanguage.english => 'Weekday',
        AppLanguage.hindi => 'वार',
        AppLanguage.gujarati => 'વાર',
      };

  static String hinduMonth(AppLanguage lang) => switch (lang) {
        AppLanguage.english => 'Hindu Month',
        AppLanguage.hindi => 'हिंदू मास',
        AppLanguage.gujarati => 'હિન્દુ માસ',
      };

  static String paksha(AppLanguage lang) => switch (lang) {
        AppLanguage.english => 'Paksha',
        AppLanguage.hindi => 'पक्ष',
        AppLanguage.gujarati => 'પક્ષ',
      };

  static String tithi(AppLanguage lang) => switch (lang) {
        AppLanguage.english => 'Tithi',
        AppLanguage.hindi => 'तिथि',
        AppLanguage.gujarati => 'તિથિ',
      };

  static String nakshatra(AppLanguage lang) => switch (lang) {
        AppLanguage.english => 'Nakshatra',
        AppLanguage.hindi => 'नक्षत्र',
        AppLanguage.gujarati => 'નક્ષત્ર',
      };

  static String muhurta(AppLanguage lang) => switch (lang) {
        AppLanguage.english => 'Muhurta',
        AppLanguage.hindi => 'मुहूर्त',
        AppLanguage.gujarati => 'મુહૂર્ત',
      };

  static String choghadiya(AppLanguage lang) => switch (lang) {
        AppLanguage.english => 'Choghadiya',
        AppLanguage.hindi => 'चौघड़िया',
        AppLanguage.gujarati => 'ચોઘડિયા',
      };

  static String yoga(AppLanguage lang) => switch (lang) {
        AppLanguage.english => 'Yoga',
        AppLanguage.hindi => 'योग',
        AppLanguage.gujarati => 'યોગ',
      };

  static String karana(AppLanguage lang) => switch (lang) {
        AppLanguage.english => 'Karana',
        AppLanguage.hindi => 'करण',
        AppLanguage.gujarati => 'કરણ',
      };

  static String rashi(AppLanguage lang) => switch (lang) {
        AppLanguage.english => 'Rashi',
        AppLanguage.hindi => 'राशि',
        AppLanguage.gujarati => 'રાશિ',
      };
}

// =============================================================================
// 1. English Month
// =============================================================================

/// The 12 English (Gregorian) months.
enum EnglishMonth {
  january(
    en: 'January',
    hi: 'जनवरी',
    gu: 'જાન્યુઆરી',
  ),
  february(
    en: 'February',
    hi: 'फ़रवरी',
    gu: 'ફેબ્રુઆરી',
  ),
  march(
    en: 'March',
    hi: 'मार्च',
    gu: 'માર્ચ',
  ),
  april(
    en: 'April',
    hi: 'अप्रैल',
    gu: 'એપ્રિલ',
  ),
  may(
    en: 'May',
    hi: 'मई',
    gu: 'મે',
  ),
  june(
    en: 'June',
    hi: 'जून',
    gu: 'જૂન',
  ),
  july(
    en: 'July',
    hi: 'जुलाई',
    gu: 'જુલાઈ',
  ),
  august(
    en: 'August',
    hi: 'अगस्त',
    gu: 'ઓગસ્ટ',
  ),
  september(
    en: 'September',
    hi: 'सितंबर',
    gu: 'સપ્ટેમ્બર',
  ),
  october(
    en: 'October',
    hi: 'अक्टूबर',
    gu: 'ઓક્ટોબર',
  ),
  november(
    en: 'November',
    hi: 'नवंबर',
    gu: 'નવેમ્બર',
  ),
  december(
    en: 'December',
    hi: 'दिसंबर',
    gu: 'ડિસેમ્બર',
  );

  final String en;
  final String hi;
  final String gu;

  const EnglishMonth({
    required this.en,
    required this.hi,
    required this.gu,
  });

  /// Returns the localized name of the English Month for the specified language.
  String name(AppLanguage lang) => switch (lang) {
        AppLanguage.english => en,
        AppLanguage.hindi => hi,
        AppLanguage.gujarati => gu,
      };

  /// 1-based month number (1 for January, 12 for December).
  int get monthNumber => index + 1;

  /// Resolves an [EnglishMonth] from a [DateTime] instance.
  static EnglishMonth fromDateTime(DateTime date) =>
      EnglishMonth.values[date.month - 1];

  /// Resolves an [EnglishMonth] from a 1-based month number (1 to 12).
  static EnglishMonth fromMonthNumber(int month) =>
      EnglishMonth.values[month - 1];
}

// =============================================================================
// 2. English Day (Weekday / Vaar)
// =============================================================================

/// The 7 days of the week (Vaar).
enum Weekday {
  sunday(
    en: 'Sunday',
    hi: 'रविवार',
    gu: 'રવિવાર',
  ),
  monday(
    en: 'Monday',
    hi: 'सोमवार',
    gu: 'સોમવાર',
  ),
  tuesday(
    en: 'Tuesday',
    hi: 'मंगलवार',
    gu: 'મંગળવાર',
  ),
  wednesday(
    en: 'Wednesday',
    hi: 'बुधवार',
    gu: 'બુધવાર',
  ),
  thursday(
    en: 'Thursday',
    hi: 'गुरुवार',
    gu: 'ગુરુવાર',
  ),
  friday(
    en: 'Friday',
    hi: 'शुक्रवार',
    gu: 'શુક્રવાર',
  ),
  saturday(
    en: 'Saturday',
    hi: 'शनिवार',
    gu: 'શનિવાર',
  );

  final String en;
  final String hi;
  final String gu;

  const Weekday({
    required this.en,
    required this.hi,
    required this.gu,
  });

  /// Returns the localized name of the weekday for the specified language.
  String name(AppLanguage lang) => switch (lang) {
        AppLanguage.english => en,
        AppLanguage.hindi => hi,
        AppLanguage.gujarati => gu,
      };

  /// Resolves a [Weekday] from a [DateTime] instance.
  static Weekday fromDateTime(DateTime date) => switch (date.weekday) {
        DateTime.sunday => Weekday.sunday,
        DateTime.monday => Weekday.monday,
        DateTime.tuesday => Weekday.tuesday,
        DateTime.wednesday => Weekday.wednesday,
        DateTime.thursday => Weekday.thursday,
        DateTime.friday => Weekday.friday,
        DateTime.saturday => Weekday.saturday,
        _ => Weekday.sunday,
      };
}

// =============================================================================
// 3. Hindu Month
// =============================================================================

/// The 12 Hindu Months in the lunar calendar.
///
/// Starts with Chaitra (month 1 in the lunisolar calendar).
enum HinduMonth {
  chaitra(
    en: 'Chaitra',
    hi: 'चैत्र',
    gu: 'ચૈત્ર',
  ),
  vaishakha(
    en: 'Vaishakha',
    hi: 'वैशाख',
    gu: 'વૈશાખ',
  ),
  jyeshtha(
    en: 'Jyeshtha',
    hi: 'ज्येष्ठ',
    gu: 'જેઠ',
  ),
  ashadha(
    en: 'Ashadha',
    hi: 'आषाढ़',
    gu: 'અષાઢ',
  ),
  shravana(
    en: 'Shravana',
    hi: 'श्रावण',
    gu: 'શ્રાવણ',
  ),
  bhadrapada(
    en: 'Bhadrapada',
    hi: 'भाद्रपद',
    gu: 'ભાદરવો',
  ),
  ashwin(
    en: 'Ashwin',
    hi: 'आश्विन',
    gu: 'આસો',
  ),
  kartika(
    en: 'Kartika',
    hi: 'कार्तिक',
    gu: 'કારતક',
  ),
  margashirsha(
    en: 'Margashirsha',
    hi: 'मार्गशीर्ष',
    gu: 'માગશર',
  ),
  pausha(
    en: 'Pausha',
    hi: 'पौष',
    gu: 'પોષ',
  ),
  magha(
    en: 'Magha',
    hi: 'माघ',
    gu: 'મહા',
  ),
  phalguna(
    en: 'Phalguna',
    hi: 'फाल्गुन',
    gu: 'ફાગણ',
  );

  final String en;
  final String hi;
  final String gu;

  const HinduMonth({
    required this.en,
    required this.hi,
    required this.gu,
  });

  /// Returns the localized name of the Hindu Month for the specified language.
  String name(AppLanguage lang) => switch (lang) {
        AppLanguage.english => en,
        AppLanguage.hindi => hi,
        AppLanguage.gujarati => gu,
      };

  /// 1-based month number (1 to 12).
  int get number => index + 1;
}

// =============================================================================
// 4. Paksha
// =============================================================================

/// The two lunar fortnights (Pakshas) in a Hindu month.
enum Paksha {
  shukla(
    en: 'Shukla Paksha',
    hi: 'शुक्ल पक्ष',
    gu: 'શુક્લ પક્ષ',
  ),
  krishna(
    en: 'Krishna Paksha',
    hi: 'कृष्ण पक्ष',
    gu: 'કૃષ્ણ પક્ષ',
  );

  final String en;
  final String hi;
  final String gu;

  const Paksha({
    required this.en,
    required this.hi,
    required this.gu,
  });

  /// Returns the localized name of the Paksha for the specified language.
  String name(AppLanguage lang) => switch (lang) {
        AppLanguage.english => en,
        AppLanguage.hindi => hi,
        AppLanguage.gujarati => gu,
      };

  /// Resolves a 1-based lunar day (1 to 30) to its corresponding [Paksha].
  ///
  /// - Days 1..15 -> [shukla]
  /// - Days 16..30 -> [krishna]
  static Paksha fromLunarDay(int day) {
    final normalized = ((day - 1) % 30) + 1;
    return normalized <= 15 ? Paksha.shukla : Paksha.krishna;
  }
}

// =============================================================================
// 5. Tithi
// =============================================================================

/// The 16 Tithi names (1 to 14 for both fortnights, plus Purnima and Amavasya).
enum Tithi {
  pratipada(
    en: 'Pratipada',
    hi: 'प्रतिपदा',
    gu: 'પડવો',
  ),
  dwitiya(
    en: 'Dwitiya',
    hi: 'द्वितीया',
    gu: 'બીજ',
  ),
  tritiya(
    en: 'Tritiya',
    hi: 'तृतीया',
    gu: 'ત્રીજ',
  ),
  chaturthi(
    en: 'Chaturthi',
    hi: 'चतुर्थी',
    gu: 'ચોથ',
  ),
  panchami(
    en: 'Panchami',
    hi: 'पंचमी',
    gu: 'પાંચમ',
  ),
  shashthi(
    en: 'Shashthi',
    hi: 'षष्ठी',
    gu: 'છઠ્ઠ',
  ),
  saptami(
    en: 'Saptami',
    hi: 'सप्तमी',
    gu: 'સાતમ',
  ),
  ashtami(
    en: 'Ashtami',
    hi: 'अष्टमी',
    gu: 'આઠમ',
  ),
  navami(
    en: 'Navami',
    hi: 'नवमी',
    gu: 'નોમ',
  ),
  dashami(
    en: 'Dashami',
    hi: 'दशमी',
    gu: 'દશમ',
  ),
  ekadashi(
    en: 'Ekadashi',
    hi: 'एकादशी',
    gu: 'અગિયારસ',
  ),
  dwadashi(
    en: 'Dwadashi',
    hi: 'द्वादशी',
    gu: 'બારસ',
  ),
  trayodashi(
    en: 'Trayodashi',
    hi: 'त्रयोदशी',
    gu: 'તેરસ',
  ),
  chaturdashi(
    en: 'Chaturdashi',
    hi: 'चतुर्दशी',
    gu: 'ચૌદસ',
  ),
  purnima(
    en: 'Purnima',
    hi: 'पूर्णिमा',
    gu: 'પૂનમ',
  ),
  amavasya(
    en: 'Amavasya',
    hi: 'अमावस्या',
    gu: 'અમાસ',
  );

  final String en;
  final String hi;
  final String gu;

  const Tithi({
    required this.en,
    required this.hi,
    required this.gu,
  });

  /// Returns the localized name of the Tithi for the specified language.
  String name(AppLanguage lang) => switch (lang) {
        AppLanguage.english => en,
        AppLanguage.hindi => hi,
        AppLanguage.gujarati => gu,
      };

  /// Resolves a 1-based lunar day (1 to 30) to its corresponding [Tithi].
  ///
  /// - Days 1..14 (Shukla) -> [pratipada] .. [chaturdashi]
  /// - Day 15 (Shukla Purnima) -> [purnima]
  /// - Days 16..29 (Krishna) -> [pratipada] .. [chaturdashi]
  /// - Day 30 (Krishna Amavasya) -> [amavasya]
  static Tithi fromLunarDay(int day) {
    final normalized = ((day - 1) % 30) + 1;
    if (normalized == 15) return Tithi.purnima;
    if (normalized == 30) return Tithi.amavasya;
    final baseIndex = (normalized > 15 ? normalized - 15 : normalized) - 1;
    return Tithi.values[baseIndex];
  }
}

// =============================================================================
// 6. Nakshatra
// =============================================================================

/// The 27 Nakshatras (Lunar Mansions) in Vedic astrology.
///
/// Indexed 0 to 26 (1 to 27 by [number]). Ashwini is 0 (0° Aries).
enum Nakshatra {
  ashwini(
    en: 'Ashwini',
    hi: 'अश्विनी',
    gu: 'અશ્વિની',
  ),
  bharani(
    en: 'Bharani',
    hi: 'भरणी',
    gu: 'ભરણી',
  ),
  krittika(
    en: 'Krittika',
    hi: 'कृत्तिका',
    gu: 'કૃત્તિકા',
  ),
  rohini(
    en: 'Rohini',
    hi: 'रोहिणी',
    gu: 'રોહિણી',
  ),
  mrigashira(
    en: 'Mrigashira',
    hi: 'मृगशिरा',
    gu: 'મૃગશીર્ષ',
  ),
  ardra(
    en: 'Ardra',
    hi: 'आर्द्रा',
    gu: 'આર્દ્રા',
  ),
  punarvasu(
    en: 'Punarvasu',
    hi: 'पुनर्वसु',
    gu: 'પુનર્વસુ',
  ),
  pushya(
    en: 'Pushya',
    hi: 'पुष्य',
    gu: 'પુષ્ય',
  ),
  ashlesha(
    en: 'Ashlesha',
    hi: 'आश्लेषा',
    gu: 'આશ્લેષા',
  ),
  magha(
    en: 'Magha',
    hi: 'मघा',
    gu: 'મઘા',
  ),
  purvaPhalguni(
    en: 'Purva Phalguni',
    hi: 'पूर्व फाल्गुनी',
    gu: 'પૂર્વાફાલ્ગુની',
  ),
  uttaraPhalguni(
    en: 'Uttara Phalguni',
    hi: 'उत्तर फाल्गुनी',
    gu: 'ઉત્તરાફાલ્ગુની',
  ),
  hasta(
    en: 'Hasta',
    hi: 'हस्त',
    gu: 'હસ્ત',
  ),
  chitra(
    en: 'Chitra',
    hi: 'चित्रा',
    gu: 'ચિત્રા',
  ),
  swati(
    en: 'Swati',
    hi: 'स्वाती',
    gu: 'સ્વાતિ',
  ),
  vishakha(
    en: 'Vishakha',
    hi: 'विशाखा',
    gu: 'વિશાખા',
  ),
  anuradha(
    en: 'Anuradha',
    hi: 'अनुराधा',
    gu: 'અનુરાધા',
  ),
  jyeshtha(
    en: 'Jyeshtha',
    hi: 'ज्येष्ठा',
    gu: 'જ્યે્ઠા',
  ),
  mula(
    en: 'Mula',
    hi: 'मूल',
    gu: 'મૂળ',
  ),
  purvaAshadha(
    en: 'Purva Ashadha',
    hi: 'पूर्वाषाढ़ा',
    gu: 'પૂર્વાષાઢા',
  ),
  uttaraAshadha(
    en: 'Uttara Ashadha',
    hi: 'उत्तराषाढ़ा',
    gu: 'ઉત્તરાષાઢા',
  ),
  shravana(
    en: 'Shravana',
    hi: 'श्रवण',
    gu: 'શ્રવણ',
  ),
  dhanishtha(
    en: 'Dhanishtha',
    hi: 'धनिष्ठा',
    gu: 'ધનિષ્ઠા',
  ),
  shatabhisha(
    en: 'Shatabhisha',
    hi: 'शतभिषा',
    gu: 'શતભિષા',
  ),
  purvaBhadrapada(
    en: 'Purva Bhadrapada',
    hi: 'पूर्व भाद्रपदा',
    gu: 'પૂર્વાભાદ્રપદા',
  ),
  uttaraBhadrapada(
    en: 'Uttara Bhadrapada',
    hi: 'उत्तर भाद्रपदा',
    gu: 'ઉત્તરાભાદ્રપદા',
  ),
  revati(
    en: 'Revati',
    hi: 'रेवती',
    gu: 'રેવતી',
  );

  final String en;
  final String hi;
  final String gu;

  const Nakshatra({
    required this.en,
    required this.hi,
    required this.gu,
  });

  /// Returns the localized name of the Nakshatra for the specified language.
  String name(AppLanguage lang) => switch (lang) {
        AppLanguage.english => en,
        AppLanguage.hindi => hi,
        AppLanguage.gujarati => gu,
      };

  /// 1-based index (1 to 27) matching standard Vedic enumeration.
  int get number => index + 1;
}

// =============================================================================
// 7. Muhurta
// =============================================================================

/// Auspicious and inauspicious Muhurtas, Yogas, and timing periods.
enum Muhurta {
  brahmaMuhurta(
    en: 'Brahma Muhurta',
    hi: 'ब्रह्म मुहूर्त',
    gu: 'બ્રહ્મ મુહૂર્ત',
  ),
  pratahSandhya(
    en: 'Pratah Sandhya',
    hi: 'प्रातः संध्या',
    gu: 'પ્રાતઃ સંધ્યા',
  ),
  abhijitMuhurta(
    en: 'Abhijit Muhurta',
    hi: 'अभिजीत मुहूर्त',
    gu: 'અભિજિત મુહૂર્ત',
  ),
  rahuKalam(
    en: 'Rahu Kalam',
    hi: 'राहु काल',
    gu: 'રાહુ કાળ',
  ),
  yamaganda(
    en: 'Yamaganda',
    hi: 'यमगण्ड काल',
    gu: 'યમગંડ કાળ',
  ),
  vijayaMuhurta(
    en: 'Vijaya Muhurta',
    hi: 'विजय मुहूर्त',
    gu: 'વિજય મુહૂર્ત',
  ),
  godhuliMuhurta(
    en: 'Godhuli Muhurta',
    hi: 'गोधूलि मुहूर्त',
    gu: 'ગોધૂલિ મુહૂર્ત',
  ),
  sayahnaSandhya(
    en: 'Sayahna Sandhya',
    hi: 'सायाह्न संध्या',
    gu: 'સાયં સંધ્યા',
  ),
  vidaalYoga(
    en: 'Vidaal Yoga',
    hi: 'विदाल योग',
    gu: 'વિડાલ યોગ',
  ),
  amritKalam(
    en: 'Amrit Kalam',
    hi: 'अमृत काल',
    gu: 'અમૃત કાળ',
  ),
  gulikaiKalam(
    en: 'Gulikai Kalam',
    hi: 'गुलिक काल',
    gu: 'ગુલિક કાળ',
  ),
  nishitaMuhurta(
    en: 'Nishita Muhurta',
    hi: 'निशीथ मुहूर्त',
    gu: 'નિશિથ મુહૂર્ત',
  ),
  sarvarthaSiddhiYoga(
    en: 'Sarvartha Siddhi Yoga',
    hi: 'सर्वार्थ सिद्धि योग',
    gu: 'સર્વાર્થ સિદ્ધિ યોગ',
  ),
  raviYoga(
    en: 'Ravi Yoga',
    hi: 'रवि योग',
    gu: 'રવિ યોગ',
  ),
  aadalYoga(
    en: 'Aadal Yoga',
    hi: 'आदल योग',
    gu: 'આડલ યોગ',
  ),
  durMuhurtam(
    en: 'Dur Muhurtam',
    hi: 'दुर्मुहूर्त',
    gu: 'દુર્મુહૂર્ત',
  ),
  varjyam(
    en: 'Varjyam',
    hi: 'वर्ज्य',
    gu: 'વર્જ્ય કાળ',
  );

  final String en;
  final String hi;
  final String gu;

  const Muhurta({
    required this.en,
    required this.hi,
    required this.gu,
  });

  /// Returns the localized name of the Muhurta/Yoga for the specified language.
  String name(AppLanguage lang) => switch (lang) {
        AppLanguage.english => en,
        AppLanguage.hindi => hi,
        AppLanguage.gujarati => gu,
      };

  /// Nature of the Muhurta/timing period (Good or Bad).
  PeriodNature get nature => switch (this) {
        Muhurta.brahmaMuhurta ||
        Muhurta.pratahSandhya ||
        Muhurta.abhijitMuhurta ||
        Muhurta.vijayaMuhurta ||
        Muhurta.godhuliMuhurta ||
        Muhurta.sayahnaSandhya ||
        Muhurta.amritKalam ||
        Muhurta.nishitaMuhurta ||
        Muhurta.sarvarthaSiddhiYoga ||
        Muhurta.raviYoga =>
          PeriodNature.good,
        Muhurta.rahuKalam ||
        Muhurta.yamaganda ||
        Muhurta.gulikaiKalam ||
        Muhurta.vidaalYoga ||
        Muhurta.aadalYoga ||
        Muhurta.durMuhurtam ||
        Muhurta.varjyam =>
          PeriodNature.bad,
      };

  bool get isGood => nature.isGood;
  bool get isBad => nature.isBad;
}

// =============================================================================
// 8. Choghadiya
// =============================================================================

/// The 7 types of Choghadiya used in Vedic astrology.
enum Choghadiya {
  amrit(
    en: 'Amrit',
    hi: 'अमृत',
    gu: 'અમૃત',
  ),
  shubh(
    en: 'Shubh',
    hi: 'शुभ',
    gu: 'શુભ',
  ),
  labh(
    en: 'Labh',
    hi: 'लाभ',
    gu: 'લાભ',
  ),
  chal(
    en: 'Chal',
    hi: 'चल',
    gu: 'ચલ',
  ),
  udveg(
    en: 'Udveg',
    hi: 'उद्वेग',
    gu: 'ઉદ્વેગ',
  ),
  rog(
    en: 'Rog',
    hi: 'रोग',
    gu: 'રોગ',
  ),
  kaal(
    en: 'Kaal',
    hi: 'काल',
    gu: 'કાળ',
  );

  final String en;
  final String hi;
  final String gu;

  const Choghadiya({
    required this.en,
    required this.hi,
    required this.gu,
  });

  /// Returns the localized name of the Choghadiya for the specified language.
  String name(AppLanguage lang) => switch (lang) {
        AppLanguage.english => en,
        AppLanguage.hindi => hi,
        AppLanguage.gujarati => gu,
      };

  /// Nature of the Choghadiya (Good or Bad).
  PeriodNature get nature => switch (this) {
        Choghadiya.amrit ||
        Choghadiya.shubh ||
        Choghadiya.labh ||
        Choghadiya.chal =>
          PeriodNature.good,
        Choghadiya.udveg ||
        Choghadiya.rog ||
        Choghadiya.kaal =>
          PeriodNature.bad,
      };

  bool get isGood => nature.isGood;
  bool get isBad => nature.isBad;
}

// =============================================================================
// 9. Yoga (Solilunar Yogas)
// =============================================================================

/// The 27 Solilunar Yogas (Nitya Yogas) in Vedic astrology.
///
/// Calculated from: (Moon Longitude + Sun Longitude) % 360 / 13°20'.
enum Yoga {
  vishkambha(
    en: 'Vishkambha',
    hi: 'विष्कुम्भ',
    gu: 'વિષ્કંભ',
  ),
  priti(
    en: 'Priti',
    hi: 'प्रीति',
    gu: 'પ્રીતિ',
  ),
  ayushman(
    en: 'Ayushman',
    hi: 'आयुष्मान्',
    gu: 'આયુષ્માન',
  ),
  saubhagya(
    en: 'Saubhagya',
    hi: 'सौभाग्य',
    gu: 'સૌભાગ્ય',
  ),
  shobhana(
    en: 'Shobhana',
    hi: 'शोभन',
    gu: 'શોભન',
  ),
  atiganda(
    en: 'Atiganda',
    hi: 'अतिगण्ड',
    gu: 'અતિગંડ',
  ),
  sukarma(
    en: 'Sukarma',
    hi: 'सुकर्मा',
    gu: 'સુકર્મા',
  ),
  dhriti(
    en: 'Dhriti',
    hi: 'धृति',
    gu: 'ધૃતિ',
  ),
  shoola(
    en: 'Shoola',
    hi: 'शूल',
    gu: 'શૂળ',
  ),
  ganda(
    en: 'Ganda',
    hi: 'गण्ड',
    gu: 'ગંડ',
  ),
  vriddhi(
    en: 'Vriddhi',
    hi: 'वृद्धि',
    gu: 'વૃદ્ધિ',
  ),
  dhruva(
    en: 'Dhruva',
    hi: 'ध्रुव',
    gu: 'ધ્રુવ',
  ),
  vyaghata(
    en: 'Vyaghata',
    hi: 'व्याघात',
    gu: 'વ્યાઘાત',
  ),
  harshana(
    en: 'Harshana',
    hi: 'हर्षण',
    gu: 'હર્ષણ',
  ),
  vajra(
    en: 'Vajra',
    hi: 'वज्र',
    gu: 'વજ્ર',
  ),
  siddhi(
    en: 'Siddhi',
    hi: 'सिद्धि',
    gu: 'સિદ્ધિ',
  ),
  vyatipata(
    en: 'Vyatipata',
    hi: 'व्यतीपात',
    gu: 'વ્યતીપાત',
  ),
  variyan(
    en: 'Variyan',
    hi: 'वरीयान्',
    gu: 'વરીયાન',
  ),
  parigha(
    en: 'Parigha',
    hi: 'परिघ',
    gu: 'પરિઘ',
  ),
  shiva(
    en: 'Shiva',
    hi: 'शिव',
    gu: 'શિવ',
  ),
  siddha(
    en: 'Siddha',
    hi: 'सिद्ध',
    gu: 'સિદ્ધ',
  ),
  sadhya(
    en: 'Sadhya',
    hi: 'साध्य',
    gu: 'સાધ્ય',
  ),
  shubha(
    en: 'Shubha',
    hi: 'शुभ',
    gu: 'શુભ',
  ),
  shukla(
    en: 'Shukla',
    hi: 'शुक्ल',
    gu: 'શુક્લ',
  ),
  brahma(
    en: 'Brahma',
    hi: 'ब्रह्म',
    gu: 'બ્રહ્મ',
  ),
  indra(
    en: 'Indra',
    hi: 'इन्द्र',
    gu: 'ઇન્દ્ર',
  ),
  vaidhriti(
    en: 'Vaidhriti',
    hi: 'वैधृति',
    gu: 'વૈધૃતિ',
  );

  final String en;
  final String hi;
  final String gu;

  const Yoga({
    required this.en,
    required this.hi,
    required this.gu,
  });

  /// Returns the localized name of the Yoga for the specified language.
  String name(AppLanguage lang) => switch (lang) {
        AppLanguage.english => en,
        AppLanguage.hindi => hi,
        AppLanguage.gujarati => gu,
      };

  /// 1-based index (1 to 27).
  int get number => index + 1;

  /// Resolves a [Yoga] from the sum of the Moon and Sun longitudes in degrees.
  static Yoga fromArc(double totalArcDegrees) {
    final normalized = totalArcDegrees % 360.0;
    final yogaIndex = (normalized / (360.0 / 27.0)).floor() % 27;
    return Yoga.values[yogaIndex];
  }
}

// =============================================================================
// 10. Karana (Half-Tithis)
// =============================================================================

/// The 11 Karanas (half of a Tithi) in Vedic astrology.
///
/// 4 fixed (Sthira) and 7 movable (Chara) Karanas repeat across 60 slots in a lunar month.
enum Karana {
  bava(
    en: 'Bava',
    hi: 'बव',
    gu: 'બવ',
  ),
  balava(
    en: 'Balava',
    hi: 'बालव',
    gu: 'બાલવ',
  ),
  kaulava(
    en: 'Kaulava',
    hi: 'कौलव',
    gu: 'કૌલવ',
  ),
  taitila(
    en: 'Taitila',
    hi: 'तैतिल',
    gu: 'તૈતિલ',
  ),
  garija(
    en: 'Garija',
    hi: 'गरिज',
    gu: 'ગરિજ',
  ),
  vanija(
    en: 'Vanija',
    hi: 'वणिज',
    gu: 'વણિજ',
  ),
  vishti(
    en: 'Vishti (Bhadra)',
    hi: 'विष्टि (भद्रा)',
    gu: 'વિષ્ટિ (ભદ્રા)',
  ),
  shakuni(
    en: 'Shakuni',
    hi: 'शकुनि',
    gu: 'શકુનિ',
  ),
  chatushpada(
    en: 'Chatushpada',
    hi: 'चतुष्पाद',
    gu: 'ચતુષ્પાદ',
  ),
  naga(
    en: 'Naga',
    hi: 'नाग',
    gu: 'નાગ',
  ),
  kintughna(
    en: 'Kintughna',
    hi: 'किंस्तुघ्न',
    gu: 'કિંસ્તુઘ્ન',
  );

  final String en;
  final String hi;
  final String gu;

  const Karana({
    required this.en,
    required this.hi,
    required this.gu,
  });

  /// Returns the localized name of the Karana for the specified language.
  String name(AppLanguage lang) => switch (lang) {
        AppLanguage.english => en,
        AppLanguage.hindi => hi,
        AppLanguage.gujarati => gu,
      };

  /// Whether this is one of the 4 fixed (Sthira) Karanas.
  bool get isFixed =>
      this == shakuni ||
      this == chatushpada ||
      this == naga ||
      this == kintughna;

  /// Resolves the Karana for a given 1-based Karana slot (1 to 60) in a lunar month.
  ///
  /// - Slot 1: Kintughna
  /// - Slots 2..57: repeating 7 movable Karanas (Bava..Vishti)
  /// - Slot 58: Shakuni
  /// - Slot 59: Chatushpada
  /// - Slot 60: Naga
  static Karana fromSlot(int slot) {
    final normalized = ((slot - 1) % 60) + 1;
    if (normalized == 1) return Karana.kintughna;
    if (normalized >= 2 && normalized <= 57) {
      final movableIndex = (normalized - 2) % 7;
      return Karana.values[movableIndex];
    }
    if (normalized == 58) return Karana.shakuni;
    if (normalized == 59) return Karana.chatushpada;
    return Karana.naga;
  }
}

// =============================================================================
// 11. Rashi (Zodiac Signs)
// =============================================================================

/// The 12 Rashis (Zodiac Signs) in Vedic astrology.
///
/// Each Rashi spans exactly 30° of the sidereal zodiac (0° to 360°).
enum Rashi {
  mesha(
    en: 'Mesha (Aries)',
    hi: 'मेष',
    gu: 'મેષ',
  ),
  vrishabha(
    en: 'Vrishabha (Taurus)',
    hi: 'वृषभ',
    gu: 'વૃષભ',
  ),
  mithuna(
    en: 'Mithuna (Gemini)',
    hi: 'मिथुन',
    gu: 'મિથુન',
  ),
  karka(
    en: 'Karka (Cancer)',
    hi: 'कर्क',
    gu: 'કર્ક',
  ),
  simha(
    en: 'Simha (Leo)',
    hi: 'सिंह',
    gu: 'સિંહ',
  ),
  kanya(
    en: 'Kanya (Virgo)',
    hi: 'कन्या',
    gu: 'કન્યા',
  ),
  tula(
    en: 'Tula (Libra)',
    hi: 'तुला',
    gu: 'તુલા',
  ),
  vrishchika(
    en: 'Vrishchika (Scorpio)',
    hi: 'वृश्चिक',
    gu: 'વૃશ્ચિક',
  ),
  dhanu(
    en: 'Dhanu (Sagittarius)',
    hi: 'धनु',
    gu: 'ધનુ',
  ),
  makara(
    en: 'Makara (Capricorn)',
    hi: 'मकर',
    gu: 'મકર',
  ),
  kumbha(
    en: 'Kumbha (Aquarius)',
    hi: 'कुम्भ',
    gu: 'કુંભ',
  ),
  meena(
    en: 'Meena (Pisces)',
    hi: 'मीन',
    gu: 'મીન',
  );

  final String en;
  final String hi;
  final String gu;

  const Rashi({
    required this.en,
    required this.hi,
    required this.gu,
  });

  /// Returns the localized name of the Rashi for the specified language.
  String name(AppLanguage lang) => switch (lang) {
        AppLanguage.english => en,
        AppLanguage.hindi => hi,
        AppLanguage.gujarati => gu,
      };

  /// 1-based sign number (1 for Mesha, 12 for Meena).
  int get number => index + 1;

  /// Resolves the [Rashi] from a celestial longitude in degrees (0.0 to 360.0).
  static Rashi fromDegrees(double degrees) {
    final normalized = degrees % 360.0;
    final rashiIndex = (normalized / 30.0).floor() % 12;
    return Rashi.values[rashiIndex];
  }
}

