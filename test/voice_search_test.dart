import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo/core/models/service_item.dart';
import 'package:kaylo/features/home/application/voice_search.dart';

ServiceItem _service(String id, String name, String category) => ServiceItem(
      id: id,
      name: name,
      category: category,
      description: '',
      iconPath: '',
      basePrice: 0,
    );

void main() {
  final pool = [
    _service('1', 'Coconut Plucking', 'farm'),
    _service('2', 'Arecanut Harvesting', 'farm'),
    _service('3', 'Gardening', 'home'),
    _service('4', 'Plumbing', 'home'),
    _service('5', 'Electrical', 'home'),
    _service('6', 'House Cleaning', 'home'),
    _service('7', 'Caregiver Visit', 'care'),
    _service('8', 'Medicine Delivery', 'care'),
  ];

  String top(String transcript) =>
      matchServicesToTranscript(transcript, pool).first.name;

  group('exact service words', () {
    test('single word "Care" finds Caregiver Visit',
        () => expect(top('Care'), 'Caregiver Visit'));
    test('English plumber', () => expect(top('I need a plumber'), 'Plumbing'));
    test('Malayalam plumber',
        () => expect(top('എനിക്ക് ഒരു പ്ലംബറെ വേണം'), 'Plumbing'));
    test('Tamil plumber',
        () => expect(top('எனக்கு பிளம்பர் வேணும்'), 'Plumbing'));
    test('direct name', () => expect(top('coconut plucking'), 'Coconut Plucking'));
  });

  group('natural sentences without the service word', () {
    test('leaking tap', () => expect(top('the tap in my bathroom is leaking'), 'Plumbing'));
    test('dripping water', () => expect(top('water is dripping from the pipe'), 'Plumbing'));
    test('broken fan', () => expect(top('my fan is not working'), 'Electrical'));
    test('no power', () => expect(top('there is no power in the wall socket'), 'Electrical'));
    test('overgrown grass', () => expect(top('the grass has grown too much'), 'Gardening'));
    test('care for grandmother', () => expect(top('someone to look after my grandmother'), 'Caregiver Visit'));
    test('buy pills', () => expect(top('need to buy pills for my father'), 'Medicine Delivery'));
  });

  group('natural Malayalam', () {
    test('leaking pipe', () => expect(top('വീട്ടിലെ പൈപ്പ് ചോരുന്നു'), 'Plumbing'));
    test('coconut plucking', () => expect(top('തേങ്ങ പറിക്കാൻ ആളെ വേണം'), 'Coconut Plucking'));
    test('no current', () => expect(top('കറന്റ് പോയി'), 'Electrical'));
    test('medicines', () => expect(top('അമ്മയ്ക്ക് മരുന്ന് വേണം'), 'Medicine Delivery'));
  });

  group('natural Tamil', () {
    test('leaking pipe', () => expect(top('குழாய் ஒழுகுது'), 'Plumbing'));
    test('no current', () => expect(top('கரண்ட் போச்சு'), 'Electrical'));
    test('care for grandmother', () => expect(top('பாட்டியை பார்த்துக்க ஆள் வேணும்'), 'Caregiver Visit'));
    test('tablets', () => expect(top('மாத்திரை வாங்கணும்'), 'Medicine Delivery'));
    test('coconut inflected', () => expect(top('தேங்காயை பறிக்கணும்'), 'Coconut Plucking'));
  });

  group('natural Hindi', () {
    test('dripping tap', () => expect(top('नल टपक रहा है'), 'Plumbing'));
    test('electric work', () => expect(top('बिजली का काम है'), 'Electrical'));
    test('house cleaning', () => expect(top('घर की सफाई करनी है'), 'House Cleaning'));
    test('nurse for grandmother', () => expect(top('दादी के लिए नर्स चाहिए'), 'Caregiver Visit'));
    test('medicines', () => expect(top('दवा चाहिए'), 'Medicine Delivery'));
  });

  group('fuzzy tolerance', () {
    test('plural pipes matches pipe',
        () => expect(top('the pipes are very old'), 'Plumbing'));
    test('gardening stem', () => expect(top('need some gardening done'), 'Gardening'));
    test('trades never collide: plumber is not climber', () {
      final matches = matchServicesToTranscript('I need a plumber', pool);
      expect(matches.first.name, 'Plumbing');
      expect(matches.map((s) => s.name), isNot(contains('Coconut Plucking')));
    });
  });

  group('no false positives', () {
    test('unrelated speech', () {
      expect(matchServicesToTranscript('what is the weather today', pool),
          isEmpty);
    });
    test('empty transcript', () {
      expect(matchServicesToTranscript('   ', pool), isEmpty);
    });
    test('generic word house alone does not match cleaning', () {
      expect(matchServicesToTranscript('my house is big', pool), isEmpty);
    });
  });
}
