import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service để theo dõi trạng thái mạng và đồng bộ Firestore
class NetworkService {
  /// Lắng nghe thay đổi mạng (Wi-Fi, 4G, hoặc mất mạng)
  Stream<bool> get onStatusChange async* {
    await for (var result in Connectivity().onConnectivityChanged) {
      final online = result != ConnectivityResult.none;

      // Khi có mạng lại → bật Firestore online sync
      if (online) {
        await FirebaseFirestore.instance.enableNetwork();
      } else {
        // Khi mất mạng → chuyển Firestore sang chế độ offline
        await FirebaseFirestore.instance.disableNetwork();
      }

      yield online;
    }
  }

  /// Kiểm tra mạng hiện tại
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
