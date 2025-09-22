import 'package:a_i_t/data/teachers_data.dart';
import 'package:a_i_t/models/teacher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final teachersProvider=Provider<List<Teacher>>((ref){
  return teachersAvailable;
});