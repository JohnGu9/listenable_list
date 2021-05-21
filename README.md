# listenable_list

A list notify listener while be modified. 

## Getting Started
```dart
final list = ListenableList<int>(); 
list.addListener((){/* add your listener */}); 
```

### Remember to dispose the list to release resource

```dart
list.dispose(); 
```
