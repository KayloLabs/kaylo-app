import '../../../core/models/service_item.dart';

/// Language-understanding layer for voice search.
///
/// The recogniser hands us a natural sentence in English, Malayalam,
/// Hindi, or Tamil; catalog names are English. Matching therefore works
/// on weighted intents (strong terms name the trade, weak terms describe
/// the problem) with fuzzy token comparison, so "water is dripping from
/// the pipe" or "பாட்டியை பார்த்துக்க ஆள் வேணும்" resolve without the
/// exact service word ever being spoken. Pure functions, unit-tested.

class _Term {
  final String text;
  final int weight;
  const _Term(this.text, this.weight);
}

const int _strong = 5;
const int _weak = 2;

/// Intent vocabulary per service family. The family key must be a
/// substring of the English catalog name it targets.
const Map<String, List<_Term>> _intents = {
  'plumb': [
    _Term('plumb', _strong), _Term('pipe', _strong), _Term('tap', _strong),
    _Term('faucet', _strong), _Term('leak', _strong), _Term('drip', _strong),
    _Term('sink', _strong), _Term('toilet', _strong), _Term('flush', _strong),
    _Term('drain', _strong), _Term('blocked', _strong),
    _Term('പ്ലംബ', _strong), _Term('പൈപ്പ്', _strong), _Term('ടാപ്പ്', _strong),
    _Term('ചോർച്ച', _strong), _Term('ചോര', _strong), _Term('ക്ലോസറ്റ്', _strong),
    _Term('பிளம்ப', _strong), _Term('குழாய்', _strong), _Term('கசிவு', _strong),
    _Term('ஒழுகு', _strong),
    _Term('प्लंब', _strong), _Term('नल', _strong), _Term('पाइप', _strong),
    _Term('रिसाव', _strong), _Term('टपक', _strong), _Term('नाली', _strong),
    _Term('water', _weak), _Term('bathroom', _weak), _Term('വെള്ളം', _weak),
    _Term('കുളിമുറി', _weak), _Term('தண்ணீர்', _weak), _Term('குளியலறை', _weak),
    _Term('पानी', _weak), _Term('बाथरूम', _weak),
  ],
  'electric': [
    _Term('electric', _strong), _Term('wiring', _strong), _Term('wire', _strong),
    _Term('socket', _strong), _Term('switch', _strong), _Term('fan', _strong),
    _Term('bulb', _strong), _Term('tube', _strong), _Term('light', _strong),
    _Term('power', _strong), _Term('current', _strong), _Term('shock', _strong),
    _Term('fuse', _strong),
    _Term('വൈദ്യുത', _strong), _Term('കറന്റ്', _strong), _Term('ഫാൻ', _strong),
    _Term('ബൾബ്', _strong), _Term('സ്വിച്ച്', _strong), _Term('ലൈറ്റ്', _strong),
    _Term('மின்', _strong), _Term('விசிறி', _strong), _Term('பல்பு', _strong),
    _Term('சுவிட்ச்', _strong), _Term('பவர்', _strong), _Term('கரண்ட்', _strong),
    _Term('बिजली', _strong), _Term('पंखा', _strong), _Term('बल्ब', _strong),
    _Term('लाइट', _strong), _Term('करंट', _strong), _Term('स्विच', _strong),
  ],
  'coconut': [
    _Term('coconut', _strong), _Term('climber', _strong), _Term('pluck', _strong),
    _Term('തേങ്ങ', _strong), _Term('തെങ്ങ', _strong),
    _Term('தேங்காய்', _strong), _Term('தென்னை', _strong),
    _Term('नारियल', _strong),
    _Term('tree', _weak), _Term('മരം', _weak), _Term('மரம்', _weak),
    _Term('पेड़', _weak),
  ],
  'arecanut': [
    _Term('arecanut', _strong), _Term('areca', _strong), _Term('betel', _strong),
    _Term('അടയ്ക്ക', _strong), _Term('കവുങ്ങ', _strong),
    _Term('பாக்கு', _strong), _Term('கமுகு', _strong),
    _Term('सुपारी', _strong),
  ],
  'garden': [
    _Term('garden', _strong), _Term('lawn', _strong), _Term('grass', _strong),
    _Term('weeds', _strong), _Term('hedge', _strong), _Term('mow', _strong),
    _Term('തോട്ടം', _strong), _Term('പുല്ല്', _strong), _Term('ചെടി', _strong),
    _Term('தோட்டம்', _strong), _Term('புல்', _strong), _Term('செடி', _strong),
    _Term('களை', _strong),
    _Term('बगीच', _strong), _Term('घास', _strong), _Term('पौध', _strong),
    _Term('माली', _strong),
    _Term('plants', _weak), _Term('overgrown', _weak),
  ],
  'clean': [
    _Term('clean', _strong), _Term('mop', _strong), _Term('sweep', _strong),
    _Term('dust', _strong), _Term('dirty', _strong),
    _Term('വൃത്തി', _strong), _Term('ക്ലീൻ', _strong), _Term('തുടയ്ക്ക', _strong),
    _Term('சுத்தம்', _strong), _Term('சுத்த', _strong), _Term('துடை', _strong),
    _Term('सफाई', _strong), _Term('झाड़ू', _strong), _Term('पोछा', _strong),
    _Term('गंदा', _strong),
    _Term('mess', _weak),
  ],
  'caregiver': [
    _Term('caregiver', _strong), _Term('carer', _strong), _Term('nurse', _strong),
    _Term('nursing', _strong),
    _Term('പരിചരണ', _strong), _Term('നഴ്സ്', _strong), _Term('ശുശ്രൂഷ', _strong),
    _Term('பராமரிப்', _strong), _Term('செவிலி', _strong), _Term('கவனிப்', _strong),
    _Term('देखभाल', _strong), _Term('नर्स', _strong),
    _Term('mother', _weak), _Term('father', _weak), _Term('grandmother', _weak),
    _Term('grandfather', _weak), _Term('elderly', _weak),
    _Term('അമ്മ', _weak), _Term('അച്ഛൻ', _weak), _Term('അമ്മൂമ്മ', _weak),
    _Term('അപ്പൂപ്പൻ', _weak),
    _Term('அம்மா', _weak), _Term('அப்பா', _weak), _Term('பாட்டி', _weak),
    _Term('தாத்தா', _weak),
    _Term('माँ', _weak), _Term('पिताजी', _weak), _Term('दादी', _weak),
    _Term('दादा', _weak),
  ],
  'medicine': [
    _Term('medicine', _strong), _Term('tablet', _strong), _Term('pills', _strong),
    _Term('dose', _strong), _Term('pharmacy', _strong),
    _Term('മരുന്ന', _strong), _Term('ഗുളിക', _strong),
    _Term('மருந்த', _strong), _Term('மாத்திரை', _strong),
    _Term('दवा', _strong), _Term('गोली', _strong),
  ],
};

/// Words too generic to count as a direct catalog-name hit
/// ("house" must not drag every sentence to House Cleaning).
const Set<String> _genericNameWords = {
  'house', 'home', 'visit', 'delivery', 'harvesting',
};

/// Ranks catalog services against a spoken sentence, best first.
List<ServiceItem> matchServicesToTranscript(
  String transcript,
  List<ServiceItem> pool,
) {
  final text = transcript.toLowerCase().trim();
  if (text.isEmpty) return const [];
  // Keep combining marks (\p{M}) with their letters: Tamil, Malayalam
  // and Devanagari vowel signs are marks, and splitting on them would
  // shred every word in those scripts.
  final tokens = text
      .split(RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return const [];

  final scored = <(ServiceItem, int)>[];
  for (final service in pool) {
    final name = service.name.toLowerCase();
    var score = 0;

    // Direct hit: a spoken token fuzzily matches a specific name word.
    for (final nameWord in name.split(' ')) {
      if (nameWord.length < 4 || _genericNameWords.contains(nameWord)) {
        continue;
      }
      if (tokens.any((t) => _fuzzyMatch(t, nameWord))) score += _strong + 1;
    }

    // Intent hit: the sentence carries this family's vocabulary.
    _intents.forEach((family, terms) {
      if (!name.contains(family)) return;
      var best = 0;
      for (final term in terms) {
        final hit = text.contains(term.text.toLowerCase()) ||
            tokens.any((t) => _fuzzyMatch(t, term.text.toLowerCase()));
        if (hit && term.weight > best) best = term.weight;
      }
      score += best;
    });

    if (score > 0) scored.add((service, score));
  }

  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final entry in scored) entry.$1];
}

/// Token-level fuzzy comparison: exact, prefix (4+ runes), or small
/// edit distance. Rune-based so Malayalam, Tamil, and Devanagari
/// inflections ("தேங்காயை" vs "தேங்காய்") land within distance 1.
bool _fuzzyMatch(String token, String term) {
  if (token == term) return true;
  final tokenRunes = token.runes.toList();
  final termRunes = term.runes.toList();
  final minLen =
      tokenRunes.length < termRunes.length ? tokenRunes.length : termRunes.length;
  if (minLen >= 4 &&
      (token.startsWith(term) || term.startsWith(token))) {
    return true;
  }
  if (minLen < 4) return false;
  // Distance 2 only for long words: at 6-7 letters it lets unrelated
  // trades collide (plumber/climber, leaking/cleaning).
  final allowed = minLen >= 8 ? 2 : 1;
  if ((tokenRunes.length - termRunes.length).abs() > allowed) return false;
  return _levenshtein(tokenRunes, termRunes) <= allowed;
}

int _levenshtein(List<int> a, List<int> b) {
  final prev = List<int>.generate(b.length + 1, (i) => i);
  final curr = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    curr[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      curr[j] = [
        curr[j - 1] + 1,
        prev[j] + 1,
        prev[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    prev.setAll(0, curr);
  }
  return prev[b.length];
}
