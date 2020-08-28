import 'package:flutter_test/flutter_test.dart';

import 'package:listenable_list/listenable_list.dart';

void main() {
  test('adds one to input values', () {
    final ListenableList<int> list = ListenableList();
    expect(list.length, 0);
    int counter = 0;
    list.addListener(() {
      counter++;
    });
    list.add(1);
    expect(counter, 1);
    list.add(1);
    expect(counter, 2);
    list.dispose();
  });
}
