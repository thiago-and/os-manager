import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> fromCamera() async {
    final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    return file?.path;
  }

  Future<String?> fromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    return file?.path;
  }

  Future<String?> fromFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    return result?.files.single.path;
  }
}
