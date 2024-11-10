import "dart:developer";
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class MongoDatabase {
  static late mongo
      .Db db; // Declare `db` as a static variable so it can be reused
  static late mongo
      .DbCollection collection; // Declare `collection` as a static variable

  static Future<void> connect() async {
    db = await mongo.Db.create(
        'mongodb+srv://vnv2005:27R4XU7oDMKPNsYy@cluster0.hwj4p.mongodb.net');
    await db.open();
    inspect(db);
    collection = db.collection('student');
    print('Database connected');
  }

  static Future<Map<String, dynamic>?> getStudentById(String id) async {
    try {
      // Query the database for a student with the specified ID
      var student = await collection.findOne(mongo.where.eq('id', id));

      if (student != null) {
        print("Student found: $student");
        return student;
      } else {
        print("No student found with id: $id");
        return null;
      }
    } catch (e) {
      print("Error fetching student: $e");
      return null;
    }
  }
}
