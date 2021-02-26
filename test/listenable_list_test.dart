import 'package:flutter_test/flutter_test.dart';
import 'package:listenable_list/listenable_list.dart';

void main() {
  test('adds one to input values not-null', () {
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

  test('adds one to input values nullable', () {
    final ListenableList<int?> list = ListenableList();
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
