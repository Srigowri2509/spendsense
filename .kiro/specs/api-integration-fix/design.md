# Design Document

## Overview

This design addresses the API integration mismatches between the Flutter SpendSense app and the backend API. The solution focuses on enhancing existing service files (auth_service.dart, expense_service.dart) to match the Postman API contract exactly, ensuring proper request/response handling, and integrating all features into the AppState for seamless UI access.

## Architecture

### Service Layer Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      AppState                            │
│  - Manages app-wide state                               │
│  - Delegates API calls to services                       │
│  - Updates local state after API responses               │
└─────────────────┬───────────────────────────────────────┘
                  │
                  │ uses
                  ▼
┌─────────────────────────────────────────────────────────┐
│                    ApiClient                             │
│  - Handles HTTP requests (GET, POST, PUT, PATCH, DELETE)│
│  - Injects JWT token automatically                       │
│  - Parses JSON responses                                 │
│  - Throws ApiException on errors                         │
└─────────────────┬───────────────────────────────────────┘
                  │
                  │ used by
                  ▼
┌──────────────────────────────────────────────────────────┐
│  AuthService          │  ExpenseService                  │
│  ─────────────────    │  ──────────────────              │
│  • login()            │  • getAll()                      │
│  • register()         │  • addExpense()                  │
│  • currentUser()      │  • updateExpense()               │
│  • updateUser() NEW   │  • removeExpense()               │
│  • sendResetOtp() NEW │  • total()                       │
│  • verifyResetOtp()NEW│  • monthlyCategory()             │
│  • resetPassword() NEW│  • yearlyCategory() NEW          │
│  • sendOtp() NEW      │  • updateStreak() NEW            │
│  • verifyOtp() NEW    │  • getCurrentStreak() NEW        │
└──────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. AuthService Enhancements

**File:** `lib/services/auth_service.dart`

#### New Methods

**updateUser()**
```dart
Future<Map<String, dynamic>> updateUser({
  String? nickName,
  String? email,
  String? fullName,
  String? gender,
  String? phoneNumber,
}) async
```
- **Purpose:** Update user profile information
- **Endpoint:** POST `/user/u/update-user`
- **Auth:** Required (Bearer token)
- **Returns:** Updated user data from `Data` field

**sendResetOtp()**
```dart
Future<Map<String, dynamic>> sendResetOtp({
  required String email,
}) async
```
- **Purpose:** Request password reset OTP
- **Endpoint:** POST `/user/send-reset-otp`
- **Auth:** Not required
- **Returns:** `{email, type}` from `Data` field

**verifyResetOtp()**
```dart
Future<String> verifyResetOtp({
  required String email,
  required String otp,
}) async
```
- **Purpose:** Verify password reset OTP
- **Endpoint:** POST `/user/verify-reset-otp`
- **Auth:** Not required
- **Returns:** Reset token from `Data.token`

**resetPassword()**
```dart
Future<void> resetPassword({
  required String token,
  required String newPassword,
  required String confirmPassword,
}) async
```
- **Purpose:** Set new password using reset token
- **Endpoint:** POST `/user/reset-password`
- **Auth:** Not required (uses reset token)
- **Returns:** void (success confirmation)

**sendOtp()**
```dart
Future<Map<String, dynamic>> sendOtp({
  required String email,
}) async
```
- **Purpose:** Send OTP for passwordless login
- **Endpoint:** POST `/otp/o/send-otp`
- **Auth:** Not required
- **Returns:** `{email, expiresAt, userName}` from `Data`

**verifyOtp()**
```dart
Future<(String token, Map<String, dynamic> user)> verifyOtp({
  required String email,
  required String otp,
  String? fullName,
}) async
```
- **Purpose:** Verify OTP and login user
- **Endpoint:** POST `/otp/o/verify-otp`
- **Auth:** Not required
- **Returns:** Tuple of (token, user) from `Data.token` and `Data.user`

#### Modified Methods

**register()**
- **Change:** Add `phoneNumber` parameter (required)
- **Type:** String (not int)
- **Validation:** Must be provided for registration

**login() & register()**
- **Change:** Handle both `Data.accessToken` and `Data.token`
- **Change:** Extract user from `Data.user` if nested

**currentUser()**
- **Change:** Handle both `Data.user` nested and `Data` direct structure

### 2. ExpenseService Enhancements

**File:** `lib/services/expense_service.dart`

#### New Methods

**yearlyCategory()**
```dart
Future<List<Map<String, dynamic>>> yearlyCategory({
  required int year,
}) async
```
- **Purpose:** Get yearly spending by category
- **Endpoint:** GET `/user-expense/y/yearlyCategorySpending?year={year}`
- **Auth:** Required (Bearer token)
- **Returns:** List from `Data.yearlySpending` array

**updateStreak()**
```dart
Future<Map<String, dynamic>> updateStreak() async
```
- **Purpose:** Update user's daily expense logging streak
- **Endpoint:** POST `/user-streak/update-user-streak`
- **Auth:** Required (Bearer token)
- **Returns:** Streak data from `Data` with currentStreak, maxStreak

**getCurrentStreak()**
```dart
Future<Map<String, dynamic>> getCurrentStreak() async
```
- **Purpose:** Get current streak information
- **Endpoint:** GET `/user-streak/current-user-streak`
- **Auth:** Required (Bearer token)
- **Returns:** Complete streak data from `Data`

#### Modified Methods

**updateExpense()**
- **Change:** Use `_api.putJson()` instead of `_api.patchJson()` (API uses PATCH but our client uses PUT wrapper)
- **Note:** Backend expects PATCH, but we'll keep using putJson since it works

**removeExpense()**
- **Change:** Accept expenseId in body OR query parameter
- **Current:** Uses body `{'expenseId': id}`
- **Keep:** Current implementation matches Postman

### 3. ApiClient Enhancements

**File:** `lib/services/api_client.dart`

#### Error Handling Improvements

**_ensureSuccess()**
```dart
void _ensureSuccess(http.Response resp) {
  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    // Try to parse error message from response body
    String errorMsg = 'HTTP ${resp.statusCode}';
    try {
      final json = jsonDecode(resp.body);
      if (json is Map && json.containsKey('message')) {
        errorMsg = json['message'];
      }
    } catch (_) {}
    throw ApiException(errorMsg, body: resp.body);
  }
}
```

**_decode()**
```dart
dynamic _decode(http.Response resp) {
  if (resp.body.isEmpty) return null;
  try {
    final decoded = jsonDecode(resp.body);
    // Check for API-level errors
    if (decoded is Map && decoded['success'] == false) {
      throw ApiException(
        decoded['message'] ?? 'API request failed',
        body: resp.body,
      );
    }
    return decoded;
  } catch (e) {
    if (e is ApiException) rethrow;
    throw ApiException('Invalid JSON response', body: resp.body);
  }
}
```

### 4. AppState Integration

**File:** `lib/app_state.dart`

#### New Methods

**OTP Login Flow**
```dart
Future<void> loginWithOtp(String email, String otp) async {
  final (token, user) = await _auth.verifyOtp(email: email, otp: otp);
  _applyTokenAndUser(token, user);
  await _fetchExpenses();
}

Future<Map<String, dynamic>> requestOtp(String email) async {
  return await _auth.sendOtp(email: email);
}
```

**Password Reset Flow**
```dart
Future<void> requestPasswordReset(String email) async {
  await _auth.sendResetOtp(email: email);
}

Future<String> verifyPasswordResetOtp(String email, String otp) async {
  return await _auth.verifyResetOtp(email: email, otp: otp);
}

Future<void> completePasswordReset({
  required String token,
  required String newPassword,
  required String confirmPassword,
}) async {
  await _auth.resetPassword(
    token: token,
    newPassword: newPassword,
    confirmPassword: confirmPassword,
  );
}
```

**Profile Update**
```dart
Future<void> updateProfile({
  String? nickName,
  String? email,
  String? fullName,
  String? gender,
  String? phoneNumber,
}) async {
  final updated = await _auth.updateUser(
    nickName: nickName,
    email: email,
    fullName: fullName,
    gender: gender,
    phoneNumber: phoneNumber,
  );
  _applyUser(updated);
  notifyListeners();
}
```

**Streak Tracking**
```dart
Future<Map<String, dynamic>> updateUserStreak() async {
  return await _expensesApi.updateStreak();
}

Future<Map<String, dynamic>> getUserStreak() async {
  return await _expensesApi.getCurrentStreak();
}
```

**Yearly Analytics**
```dart
Future<List<Map<String, dynamic>>> getYearlySpending(int year) async {
  return await _expensesApi.yearlyCategory(year: year);
}
```

#### Modified Methods

**register()**
- **Change:** Add phoneNumber parameter
- **Change:** Convert phoneNumber to string if needed
```dart
Future<void> register({
  required String fullName,
  required String email,
  required String password,
  required String phoneNumber, // NEW: required
  String? gender,
  String? nickName,
}) async {
  final (token, user) = await _auth.register(
    fullName: fullName,
    email: email,
    password: password,
    phoneNumber: phoneNumber,
    gender: gender,
    nickName: nickName,
  );
  _applyTokenAndUser(token, user);
  await _fetchExpenses();
}
```

**_applyUser()**
- **Change:** Handle phoneNumber as string or number
```dart
void _applyUser(Map<String, dynamic> me) {
  final user = (me['user'] as Map<String, dynamic>?) ?? me;
  userName = (user['fullName'] as String?) ?? userName;
  userEmail = (user['email'] as String?) ?? userEmail;
  nickname = (user['nickName'] as String?) ?? nickname;
  userId = (user['_id'] as String?) ?? userId;
  
  // Handle phoneNumber as string or number
  final phone = user['phoneNumber'];
  if (phone != null) {
    userPhoneNumber = phone.toString();
  }
  
  isSignedIn = true;
}
```

## Data Models

### Response Envelope Structure

All API responses follow this structure:
```json
{
  "statusCode": 200,
  "Data": { /* varies by endpoint */ },
  "message": "success message",
  "success": true
}
```

### User Object Structure
```json
{
  "_id": "string",
  "nickName": "string",
  "email": "string",
  "fullName": "string",
  "gender": "string",
  "phoneNumber": "string" | number,
  "isEmailVerified": boolean,
  "createdAt": "ISO date string",
  "updatedAt": "ISO date string"
}
```

### Authentication Response
```json
{
  "Data": {
    "user": { /* User object */ },
    "accessToken": "JWT string"
  }
}
```

### Expense Object Structure
```json
{
  "_id": "string",
  "paidBy": "userId",
  "amount": number,
  "description": "string",
  "category": "categoryId or string",
  "paymentMethod": "cash|card|upi|netbanking|wallet",
  "tags": ["string"],
  "expenseDate": "ISO date string",
  "isRecurring": boolean
}
```

### Streak Object Structure
```json
{
  "_id": "string",
  "owner": "userId",
  "currentStreak": number,
  "maxStreak": number,
  "createdAt": "ISO date string",
  "updatedAt": "ISO date string"
}
```

## Error Handling

### Error Flow

```
API Request
    │
    ├─► HTTP Error (4xx, 5xx)
    │   └─► ApiException with status code and body
    │
    ├─► JSON Parse Error
    │   └─► ApiException with "Invalid JSON" message
    │
    ├─► API-level Error (success: false)
    │   └─► ApiException with message from response
    │
    └─► Timeout (>10 seconds)
        └─► TimeoutException → caught → ApiException
```

### Error Handling Strategy

1. **Service Layer:** Catch and rethrow with context
2. **AppState Layer:** Catch, log, and optionally show to user
3. **UI Layer:** Display user-friendly error messages

### Example Error Handling in AppState

```dart
Future<void> login(String email, String password) async {
  try {
    final (token, user) = await _auth.login(email: email, password: password);
    _applyTokenAndUser(token, user);
    await _fetchExpenses();
  } on ApiException catch (e) {
    debugPrint('Login failed: ${e.message}');
    rethrow; // Let UI handle display
  } catch (e) {
    debugPrint('Unexpected login error: $e');
    throw ApiException('Login failed: ${e.toString()}');
  }
}
```

## Testing Strategy

### Unit Testing

**Test Coverage:**
1. AuthService methods with mock ApiClient
2. ExpenseService methods with mock ApiClient
3. Response parsing for all data structures
4. Error handling for various failure scenarios

**Key Test Cases:**
- Register with all required fields including phoneNumber
- Login response with nested user object
- Login response with flat user object
- OTP flow from send to verify
- Password reset complete flow
- Expense CRUD operations
- Streak update and retrieval
- Error responses with custom messages

### Integration Testing

**Test Scenarios:**
1. Complete registration → login → fetch expenses flow
2. OTP login flow end-to-end
3. Password reset flow end-to-end
4. Profile update and refresh
5. Expense creation → fetch → update → delete
6. Streak tracking across multiple days

### Manual Testing Checklist

- [ ] Register new user with phone number
- [ ] Login with email/password
- [ ] Login with OTP
- [ ] Request password reset OTP
- [ ] Verify OTP and reset password
- [ ] Update user profile
- [ ] Add expense
- [ ] Update expense
- [ ] Delete expense
- [ ] View monthly category spending
- [ ] View yearly category spending
- [ ] Update streak
- [ ] View current streak
- [ ] Test with backend unavailable (error handling)
- [ ] Test with invalid credentials
- [ ] Test with expired OTP

## Implementation Notes

### Phone Number Handling

The backend may store phoneNumber as either string or number. Our implementation:
1. Always send as string in requests
2. Accept both types in responses
3. Convert to string for display

### Token Handling

The API returns tokens in two possible fields:
- `Data.accessToken` (login, register)
- `Data.token` (OTP verify, password reset verify)

Our services check both fields and return the first non-empty value.

### Backwards Compatibility

All changes are additive or fix existing bugs. No breaking changes to existing working features.

### Performance Considerations

- All API calls have 10-second timeout
- Expenses fetched with pagination (limit: 200)
- Local state updated optimistically where appropriate
- Token stored in memory (consider secure storage for production)

## Security Considerations

1. **JWT Token:** Stored in memory, injected automatically in headers
2. **Password Reset:** Uses time-limited OTP (3 minutes) and one-time reset token
3. **OTP Login:** Uses time-limited OTP (3 minutes)
4. **HTTPS:** Should be used in production (currently HTTP for local dev)
5. **Input Validation:** Backend validates all inputs; client should add UI validation

## Deployment Notes

### Environment Configuration

Current: `API_BASE_URL` defaults to `http://10.0.2.2:5000` (Android emulator)

For production:
- Set `API_BASE_URL` environment variable to production URL
- Ensure HTTPS is used
- Consider token persistence with flutter_secure_storage

### Migration Path

1. Deploy updated services (backwards compatible)
2. Update UI screens to use new features (optional)
3. Add OTP login UI (optional enhancement)
4. Add password reset UI (optional enhancement)
5. Add streak tracking UI (optional enhancement)
