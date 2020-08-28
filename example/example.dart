import 'package:listenable_list/listenable_list.dart';

main() {
  final ListenableList<int> list = ListenableList();
  list.add(1);
  print(list);
  list.addListener(() {
    print('Added elements: ${list.added}');
    print('Removed elements: ${list.removed}');
    print('Changed elements: ${list.changed}');
  });
  list.add(2); // expect print out "Added elements: {1 : 2}"
  list.removeLast(); // expect print out "Removed elements: {1 : 2}"
  list.dispose();
}
