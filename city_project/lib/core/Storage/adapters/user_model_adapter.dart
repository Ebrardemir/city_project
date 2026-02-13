import 'package:city_project/Features/Login/model/user_model.dart';
import 'package:hive/hive.dart';

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 1; // Uygulama genelinde benzersiz olduğundan emin ol

  @override
  UserModel read(BinaryReader reader) {
    // Yazma sırasıyla aynı sırada okumalısın
    return UserModel(
      id: reader.read() as int,
      fullName: reader.read() as String,
      email: reader.read() as String,
      passwordHash: reader.read() as String,
      role: reader.read() as String,
      score: reader.read() as int,
      cityId: reader.read() as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    // Verileri hangi sırayla yazarsan read kısmında o sırayla okursun
    writer
      ..write(obj.id)
      ..write(obj.fullName)
      ..write(obj.email)
      ..write(obj.passwordHash)
      ..write(obj.role)
      ..write(obj.score)
      ..write(obj.cityId);
  }
}