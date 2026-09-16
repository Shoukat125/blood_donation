import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ✅ FIX: ab yeh IP "hardcoded" nahi hai — build-time pe override ho sakti hai
  // taake Play Store wali build kisi bhi network pe chale, sirf tumhare WiFi pe nahi.
  //
  // LOCAL TESTING (apne phone se laptop ke backend tak):
  //   flutter run
  //   (neeche wali _phoneWifiIp use hogi — apne laptop ka WiFi IPv4 yahan daalo)
  //
  // PRODUCTION BUILD (Play Store ke liye, real hosted backend ke saath):
  //   flutter build apk --dart-define=API_BASE_URL=https://your-backend.onrender.com
  //   (yeh URL code mein kahin edit nahi karna padega)
  static const String _phoneWifiIp = '192.168.100.4';

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    return kIsWeb ? 'http://localhost:8000' : 'http://$_phoneWifiIp:8000';
  }

  // ✅ FIX (#1): global navigator key — jab token expire/invalid ho (401),
  // yeh app ko bina context errors ke /login pe bhej deta hai.
  // main.dart mein MaterialApp(navigatorKey: ApiService.navigatorKey, ...) set karna zaroori hai.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Kisi bhi authenticated response ko decode karte waqt yeh check karta hai
  // ke session expire to nahi hui — agar 401 aaya, token clear karke login screen pe bhej dega.
  static Future<dynamic> _decode(http.Response response) async {
    if (response.statusCode == 401) {
      await clearToken();
      final nav = navigatorKey.currentState;
      if (nav != null) {
        nav.pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return {'error': 'Invalid server response'};
    }
  }


  // ==================
  // TOKEN HELPERS
  // ==================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ✅ Issue 10: auto-send / auto-login check — true if a token is already saved
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ==================
  // ONBOARDING HELPERS
  // ==================
  static Future<bool> isOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_seen') ?? false;
  }

  static Future<void> setOnboardingSeen(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', seen);
  }

  // ==================
  // AUTH APIS
  // ==================

  // Register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String bloodType,
    required String city,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': name,       // ✅ FIX 1: name → full_name
          'email': email,
          'password': password,
          'blood_type': bloodType,
          'city': city,
          'phone': phone,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['access_token'] != null) {
        await saveToken(data['access_token']);
      }
      return data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Forgot Password (request 6-digit code)
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Reset Password (with 6-digit code)
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'new_password': newPassword,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Logout
  static Future<void> logout() async {
    await clearToken();
  }

  // ==================
  // DONOR APIS
  // ==================

  // Get All Donors
  static Future<List<dynamic>> getDonors({
    String? bloodType,
    String? city,
    bool availableOnly = true,
  }) async {
    try {
      String url = '$baseUrl/api/donors/';
      List<String> params = [];
      // ✅ FIX: encode values — otherwise "B+" becomes "B " (the server
      // decodes a raw '+' as a space), so blood-type filters never match.
      if (bloodType != null) params.add('blood_type=${Uri.encodeQueryComponent(bloodType)}');
      if (city != null) params.add('city=${Uri.encodeQueryComponent(city)}');
      params.add('available_only=$availableOnly');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final token = await getToken();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return await _decode(response);
    } catch (e) {
      return [];
    }
  }

  // Get Single Donor
  static Future<Map<String, dynamic>> getDonor(int donorId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/donors/$donorId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return await _decode(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get My Profile
  static Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/donors/me/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return await _decode(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Update My Profile
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? city,
    bool? isAvailable,
    int? age,
    String? gender,
    String? bloodType,
    bool? notifyAllTypes,
    String? lastDonation,
  }) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/api/donors/me/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (name != null) 'full_name': name,
          if (phone != null) 'phone': phone,
          if (city != null) 'city': city,
          if (isAvailable != null) 'is_available': isAvailable,
          if (age != null) 'age': age,
          if (gender != null) 'gender': gender,
          if (bloodType != null) 'blood_type': bloodType,
          if (notifyAllTypes != null) 'notify_all_types': notifyAllTypes,
          if (lastDonation != null) 'last_donation': lastDonation,
        }),
      );
      return await _decode(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ==================
  // BLOOD REQUEST APIS
  // ==================

  // Create Blood Request
  static Future<Map<String, dynamic>> createRequest({
    required String bloodType,
    required int units,
    required String hospital,
    required String urgency,
    required String city,
    String patientName = 'Patient',
    int? patientAge,
    String? patientGender,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/requests/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'blood_type': bloodType,
          'units_needed': units,      // ✅ FIX 2: units → units_needed
          'hospital': hospital,
          'urgency': urgency,
          'city': city,
          'patient_name': patientName, // ✅ Real form value now, was hardcoded
          if (patientAge != null) 'patient_age': patientAge,
          if (patientGender != null) 'patient_gender': patientGender,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get All Requests
  static Future<List<dynamic>> getRequests() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/requests/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return await _decode(response);
    } catch (e) {
      return [];
    }
  }

  // Update Request Status
  static Future<Map<String, dynamic>> updateRequestStatus({
    required int requestId,
    required String status,
  }) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/api/requests/$requestId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get Single Request (used for live polling on the confirmation screen)
  static Future<Map<String, dynamic>> getRequest(int requestId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/requests/$requestId'),
        headers: {'Content-Type': 'application/json'},
      );
      return await _decode(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get My Donor Notifications (pending matched requests for this donor)
  static Future<List<dynamic>> getMyNotifications() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/requests/notifications/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final decoded = await _decode(response);
      return decoded is List ? decoded : [];
    } catch (e) {
      return [];
    }
  }

  // Accept / Decline a donor notification
  static Future<Map<String, dynamic>> respondToNotification({
    required int notificationId,
    required String status, // 'Accepted' or 'Declined'
  }) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/api/requests/notifications/$notificationId/respond'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );
      final decoded = await _decode(response);
      if (response.statusCode != 200) {
        return {'error': decoded['detail'] ?? 'Something went wrong'};
      }
      return decoded;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ==================
  // MESSAGES APIS
  // ==================

  // Send Message
  static Future<Map<String, dynamic>> sendMessage({
    required int receiverId,
    required String message,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/messages/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'receiver_id': receiverId,
          'content': message,         // ✅ FIX 3: message → content
        }),
      );
      return await _decode(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get Messages
  static Future<List<dynamic>> getMessages() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/messages/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return await _decode(response);
    } catch (e) {
      return [];
    }
  }

  // ==================
  // HOSPITAL APIS
  // ==================
  static Future<List<dynamic>> getHospitals({String? city}) async {
    try {
      String url = '$baseUrl/api/hospitals/';
      if (city != null) url += '?city=${Uri.encodeQueryComponent(city)}';

      final token = await getToken();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return [];
    }
  }

  // ==================
  // CHANGE PASSWORD — Issue #17
  // ==================
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );
      final decoded = await _decode(response);
      if (response.statusCode != 200) {
        return {'error': decoded['detail'] ?? 'Something went wrong'};
      }
      return decoded;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
