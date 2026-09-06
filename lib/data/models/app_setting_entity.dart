import 'package:objectbox/objectbox.dart';

@Entity()
class AppSettingEntity {
  @Id()
  int id = 0;

  @Index()
  String key;

  String value;

  AppSettingEntity({
    this.id = 0,
    required this.key,
    required this.value,
  });
}
