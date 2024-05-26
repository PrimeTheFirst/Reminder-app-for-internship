import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'dart:collection';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';

void main() {
  const oneSec = Duration(seconds: 1);
  Timer.periodic(oneSec, (Timer t) => reminders());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final List<String> activities = [
    'Wake up',
    'Go to gym',
    'Breakfast',
    'Meetings',
    'Lunch',
    'Quick nap',
    'Go to library',
    'Dinner',
    'Go to sleep',
  ];

  final TextEditingController dayController = TextEditingController();
  final TextEditingController activityController = TextEditingController();
  TimeOfDay? selectedTime;
  TimePickerEntryMode entryMode = TimePickerEntryMode.dial;
  Orientation? orientation;
  TextDirection textDirection = TextDirection.ltr;
  MaterialTapTargetSize tapTargetSize = MaterialTapTargetSize.padded;
  bool use24HourTime = false;
  var prefs = {
    "Monday": {},
    'Tuesday': {},
    'Wednesday': {},
    'Thursday': {},
    'Friday': {},
    'Saturday': {},
    'Sunday': {},
  };
  String? selectedDay;
  String? selectedActivity;
  final TextEditingController textEditingController = TextEditingController();

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  // @override
  // void dispose() {
  //   dayController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          children: [
            dropdown(context, days, dayController, "Select day"),
            dropdown(
                context, activities, activityController, "Select activity"),
            ElevatedButton(
                onPressed: () async {
                  final TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime ?? TimeOfDay.now(),
                    initialEntryMode: entryMode,
                    orientation: orientation,
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          materialTapTargetSize: tapTargetSize,
                        ),
                        child: Directionality(
                          textDirection: textDirection,
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              alwaysUse24HourFormat: use24HourTime,
                            ),
                            child: child!,
                          ),
                        ),
                      );
                    },
                  );
                  setState(() {
                    selectedTime = time;
                  });
                },
                child: const Text("Select time")),
            ElevatedButton(
                onPressed: () {
                  prefs[selectedDay]![selectedActivity.toString()] =
                      (selectedTime!.hour * 60) + selectedTime!.minute;
                  prefs.forEach((temp, value) async {
                    var sortedKeys = prefs[temp]!.keys.toList(growable: false)
                      ..sort((k1, k2) =>
                          prefs[temp]![k1].compareTo(prefs[temp]![k2]));
                    LinkedHashMap sortedMap = LinkedHashMap.fromIterable(
                        sortedKeys,
                        key: (k) => k,
                        value: (k) => prefs[temp]![k]);
                    final SharedPreferences preferences =
                        await SharedPreferences.getInstance();
                    await preferences.setString(temp, jsonEncode(sortedMap));
                    print(temp);
                  });
                },
                child: const Text("Update"))
          ],
        ),
      ),
    );
  }

  DropdownButtonHideUnderline dropdown(BuildContext context,
      List<String> options, TextEditingController controller, String label) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).hintColor,
          ),
        ),
        items: options
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ))
            .toList(),
        value: (label == 'Select day') ? selectedDay : selectedActivity,
        onChanged: (value) {
          setState(() {
            if (label == 'Select day') {
              selectedDay = value;
            } else {
              selectedActivity = value;
            }
          });
        },
        buttonStyleData: const ButtonStyleData(
          padding: EdgeInsets.symmetric(horizontal: 16),
          height: 40,
          width: 200,
        ),
        dropdownStyleData: const DropdownStyleData(
          maxHeight: 200,
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 40,
        ),
        dropdownSearchData: DropdownSearchData(
          searchController: controller,
          searchInnerWidgetHeight: 50,
          searchInnerWidget: Container(
            height: 50,
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 4,
              right: 8,
              left: 8,
            ),
            child: TextFormField(
              expands: true,
              maxLines: null,
              controller: controller,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                hintText: 'Search for an item...',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          searchMatchFn: (item, searchValue) {
            return item.value.toString().contains(searchValue);
          },
        ),
        //This to clear the search value when you close the menu
        onMenuStateChange: (isOpen) {
          if (!isOpen) {
            controller.clear();
          }
        },
      ),
    );
  }
}

int reminder_count = 0;
reminders() async {
  DateTime today = DateTime.now();
  String day = '';
  switch (today.weekday) {
    case 1:
      day = 'Monday';
      break;
    case 2:
      day = 'Tuesday';
      break;
    case 3:
      day = 'Wednesday';
      break;
    case 4:
      day = 'Thursday';
      break;
    case 5:
      day = 'Friday';
      break;
    case 6:
      day = 'Saturday';
      break;
    case 7:
      day = 'Sunday';
      break;
  }
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  // prefs.clear();
  if (prefs.getString(day) != null) {
    if (reminder_count < jsonDecode(prefs.getString(day)!).values.length) {
      // print(jsonDecode(prefs.getString(day)!));
      int val =
          jsonDecode(prefs.getString(day)!).values.elementAt(reminder_count);

      double reminderHours = ((val - (val % 60)) / 60);
      int reminderMin = val % 60;
      if (reminderHours == today.hour.toDouble()) {
        if (reminderMin == today.minute) {
          SystemSound.play(SystemSoundType.alert);
          reminder_count += 1;
        }
      }
    }
  }
}
