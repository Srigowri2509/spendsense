# Implementation Plan

- [x] 1. Enhance ApiClient error handling and response parsing


  - Modify `_ensureSuccess()` to extract error messages from response body JSON
  - Modify `_decode()` to check for API-level errors (success: false) and throw ApiException
  - Add better error context to ApiException messages
  - _Requirements: 7.1, 7.2, 9.1, 9.2, 9.5_





- [ ] 2. Update AuthService with registration phone number support
  - [x] 2.1 Add phoneNumber parameter to register() method signature (required String)


    - Update method to accept phoneNumber as required parameter
    - Include phoneNumber in request body sent to /user/register
    - _Requirements: 1.1, 1.5, 8.1, 8.2_
  


  - [ ] 2.2 Fix token extraction in login() and register() methods
    - Check for both Data.accessToken and Data.token fields
    - Return the first non-null, non-empty token value
    - Handle nested Data.user structure for user object
    - _Requirements: 1.2, 1.3, 7.5_
  
  - [ ] 2.3 Fix currentUser() response parsing
    - Handle both Data.user nested structure and Data direct structure
    - Extract user fields correctly from either format
    - _Requirements: 1.4, 7.3, 7.4_

- [ ] 3. Implement password reset flow in AuthService
  - [ ] 3.1 Add sendResetOtp() method
    - Create method that posts email to /user/send-reset-otp
    - Return Map with email and type from Data field
    - _Requirements: 3.1_
  
  - [ ] 3.2 Add verifyResetOtp() method
    - Create method that posts email and otp to /user/verify-reset-otp
    - Extract and return reset token from Data.token field
    - _Requirements: 3.2, 3.3_
  
  - [ ] 3.3 Add resetPassword() method
    - Create method that posts token, newPassword, confirmPassword to /user/reset-password
    - Return void on success
    - _Requirements: 3.4, 3.5_

- [ ] 4. Implement user profile update in AuthService
  - Add updateUser() method that accepts optional nickName, email, fullName, gender, phoneNumber
  - Send POST request to /user/u/update-user with Bearer token
  - Return updated user data from Data field
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 5. Implement OTP login flow in AuthService
  - [ ] 5.1 Add sendOtp() method
    - Create method that posts email to /otp/o/send-otp
    - Return Map with email, expiresAt, userName from Data
    - _Requirements: 4.1, 4.2_
  
  - [ ] 5.2 Add verifyOtp() method
    - Create method that posts email, fullName, otp to /otp/o/verify-otp
    - Extract Data.user and Data.token
    - Return tuple (String token, Map<String, dynamic> user)
    - _Requirements: 4.3, 4.4, 4.5_

- [ ] 6. Enhance ExpenseService with analytics and streak features
  - [ ] 6.1 Add yearlyCategory() method
    - Create method that accepts year parameter
    - Send GET request to /user-expense/y/yearlyCategorySpending with year query
    - Extract and return Data.yearlySpending array as List<Map<String, dynamic>>
    - _Requirements: 5.1, 5.2, 5.3_
  
  - [ ] 6.2 Verify updateExpense() uses correct HTTP method
    - Confirm method uses putJson (which sends PATCH internally)
    - Ensure expenseId is in request body
    - _Requirements: 5.4, 5.5_
  
  - [-] 6.3 Add updateStreak() method



    - Create method that posts to /user-streak/update-user-streak
    - Return Map with currentStreak and maxStreak from Data
    - _Requirements: 6.1, 6.2_
  



  - [ ] 6.4 Add getCurrentStreak() method
    - Create method that gets from /user-streak/current-user-streak
    - Return complete streak data Map from Data field
    - _Requirements: 6.3, 6.4_

- [ ] 7. Update AppState with new service methods
  - [ ] 7.1 Add phoneNumber field and update register() method
    - Add userPhoneNumber field to AppState
    - Update register() to require phoneNumber parameter
    - Pass phoneNumber to _auth.register()
    - _Requirements: 8.1, 8.2, 10.1_
  
  - [ ] 7.2 Update _applyUser() to handle phoneNumber
    - Extract phoneNumber from user data (handle string or number type)
    - Convert to string and store in userPhoneNumber field
    - _Requirements: 8.3, 8.4_
  
  - [ ] 7.3 Add OTP login wrapper methods
    - Add requestOtp(String email) method that calls _auth.sendOtp()
    - Add loginWithOtp(String email, String otp) method that calls _auth.verifyOtp()
    - Apply token and user data, then fetch expenses
    - _Requirements: 10.1_
  
  - [ ] 7.4 Add password reset wrapper methods
    - Add requestPasswordReset(String email) method
    - Add verifyPasswordResetOtp(String email, String otp) method
    - Add completePasswordReset(token, newPassword, confirmPassword) method
    - _Requirements: 10.2_
  
  - [ ] 7.5 Add profile update wrapper method
    - Add updateProfile() method with optional parameters
    - Call _auth.updateUser() and update local state
    - Call notifyListeners() after update
    - _Requirements: 10.4_
  
  - [ ] 7.6 Add streak tracking wrapper methods
    - Add updateUserStreak() method that calls _expensesApi.updateStreak()
    - Add getUserStreak() method that calls _expensesApi.getCurrentStreak()
    - _Requirements: 10.3_
  
  - [ ] 7.7 Add yearly analytics wrapper method
    - Add getYearlySpending(int year) method
    - Call _expensesApi.yearlyCategory() and return results
    - _Requirements: 10.5_

- [ ] 8. Update Endpoints class with any missing endpoint constants
  - Verify all endpoints match Postman collection
  - Add any missing endpoint constants
  - Ensure endpoint paths are correct
  - _Requirements: All endpoint-related requirements_

- [ ] 9. Test API integration with backend
  - [ ] 9.1 Test registration with phone number
    - Register new user with all required fields
    - Verify user is created and token is returned
    - Verify login works with new credentials
    - _Requirements: 1.1, 1.2, 1.5_
  
  - [ ] 9.2 Test OTP login flow
    - Request OTP for existing user email
    - Verify OTP and login
    - Verify token and user data are correct
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  
  - [ ] 9.3 Test password reset flow
    - Request reset OTP
    - Verify reset OTP
    - Reset password with new credentials
    - Login with new password
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_
  
  - [ ] 9.4 Test profile update
    - Update user profile fields
    - Verify changes are persisted
    - Refresh user data and confirm updates
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  
  - [ ] 9.5 Test expense operations
    - Add expense
    - Update expense
    - Fetch all expenses
    - Delete expense
    - _Requirements: 5.4, 5.5_
  
  - [ ] 9.6 Test analytics endpoints
    - Fetch monthly category spending
    - Fetch yearly category spending
    - Verify data structure matches expectations
    - _Requirements: 5.1, 5.2, 5.3_
  
  - [ ] 9.7 Test streak tracking
    - Update user streak
    - Fetch current streak
    - Verify streak data is correct
    - _Requirements: 6.1, 6.2, 6.3, 6.4_
  
  - [ ] 9.8 Test error handling
    - Test with invalid credentials
    - Test with expired OTP
    - Test with network timeout
    - Verify error messages are user-friendly
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_
