import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaylo/features/workers/data/supabase_workers_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'discovery requires issued approval but retains off-duty partners',
    () async {
      final requests = <Uri>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        httpClient: MockClient((request) async {
          requests.add(request.url);
          return http.Response(
            jsonEncode([
              {
                'worker_id': 'partner-off-duty',
                'full_name': 'Approved partner',
                'is_available': false,
                'is_bookable': true,
                'skill_ids': ['plumbing'],
              },
              {
                'worker_id': 'partner-on-duty',
                'full_name': 'Approved available partner',
                'is_available': true,
                'is_bookable': true,
                'skill_ids': ['plumbing'],
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      final repo = SupabaseWorkersRepository(client);
      for (final rows in [
        await repo.getWorkersByServiceId('plumbing'),
        await repo.searchWorkers('Approved'),
      ]) {
        expect(rows.map((w) => w.isAvailable), [false, true]);
      }
      for (final request in requests) {
        expect(request.queryParameters['is_bookable'], 'eq.true');
        expect(request.queryParameters.containsKey('is_available'), isFalse);
      }
    },
  );
}
