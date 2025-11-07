# Requirements Document

## Introduction

This specification addresses the misalignment between the SpendSense Flutter application's API service layer and the actual backend API contract as documented in the Postman collection. The goal is to ensure complete API compatibility, proper error handling, and full feature implementation for authentication, expense management, OTP verification, and streak tracking.

## Glossary

- **API Client**: The HTTP client wrapper that handles all network requests with authentication
- **Auth Service**: Service layer handling user authentication operations (login, register, password reset)
- **Expense Service**: Service layer managing expense CRUD operations and analytics
- **OTP Service**: Service layer for OTP-based authentication and verification
- **Streak Service**: Service layer for tracking user expense logging streaks
- **Backend API**: The Express.js REST API server running on localhost:5000
- **JWT Token**: JSON Web Token used for authenticated requests
- **Response Envelope**: The standard API response structure with statusCode, Data, message, and success fields

## Requirements

### Requirement 1: Authentication Service Alignment

**User Story:** As a user, I want to register and login with all required fields so that my account is created correctly on the backend

#### Acceptance Criteria

1. WHEN the User calls the register method, THE Auth Service SHALL send all required fields including nickName, email, fullName, gender, phoneNumber, and password
2. WHEN the Backend API returns a registration response, THE Auth Service SHALL extract the token from Data.accessToken or Data.token
3. WHEN the Backend API returns a login response, THE Auth Service SHALL extract both Data.user and Data.accessToken fields
4. WHEN the User profile is fetched, THE Auth Service SHALL handle both Data.user nested structure and Data direct structure
5. WHERE the phoneNumber field is provided, THE Auth Service SHALL validate it is a string representation of the number

### Requirement 2: User Profile Update Implementation

**User Story:** As a user, I want to update my profile information so that my account details stay current

#### Acceptance Criteria

1. THE Auth Service SHALL implement an updateUser method that accepts nickName, email, fullName, gender, and phoneNumber
2. WHEN updateUser is called, THE Auth Service SHALL send a POST request to /user/u/update-user endpoint
3. WHEN the update succeeds, THE Auth Service SHALL return the updated user data from the response
4. THE Auth Service SHALL require Bearer token authentication for the update request

### Requirement 3: Password Reset Flow Implementation

**User Story:** As a user, I want to reset my forgotten password using OTP verification so that I can regain access to my account

#### Acceptance Criteria

1. THE Auth Service SHALL implement sendResetOtp method that sends email to /user/send-reset-otp
2. THE Auth Service SHALL implement verifyResetOtp method that sends email and otp to /user/verify-reset-otp
3. WHEN verifyResetOtp succeeds, THE Auth Service SHALL return the reset token from Data.token
4. THE Auth Service SHALL implement resetPassword method that sends token, newPassword, and confirmPassword to /user/reset-password
5. WHEN resetPassword succeeds, THE Auth Service SHALL return success confirmation

### Requirement 4: OTP Login Methods in Auth Service

**User Story:** As a user, I want to login using OTP sent to my email so that I can access the app without remembering my password

#### Acceptance Criteria

1. THE Auth Service SHALL implement sendOtp method that posts email to /otp/o/send-otp
2. WHEN sendOtp succeeds, THE Auth Service SHALL return email, expiresAt, and userName from Data
3. THE Auth Service SHALL implement verifyOtp method that posts email, fullName, and otp to /otp/o/verify-otp
4. WHEN verifyOtp succeeds, THE Auth Service SHALL return both Data.user and Data.token as a tuple
5. THE Auth Service SHALL handle the 3-minute OTP expiration window

### Requirement 5: Expense Service Enhancement

**User Story:** As a user, I want all expense analytics features to work correctly so that I can track my spending patterns

#### Acceptance Criteria

1. THE Expense Service SHALL implement yearlyCategorySpending method that accepts year parameter
2. WHEN yearlyCategorySpending is called, THE Expense Service SHALL send GET request to /user-expense/y/yearlyCategorySpending with year query parameter
3. WHEN the response is received, THE Expense Service SHALL extract Data.yearlySpending array
4. THE Expense Service SHALL handle the update-expense endpoint using PATCH method instead of PUT
5. THE Expense Service SHALL accept expenseId in the request body for update and remove operations

### Requirement 6: Streak Methods in Expense Service

**User Story:** As a user, I want my daily expense logging streak tracked so that I stay motivated to log expenses regularly

#### Acceptance Criteria

1. THE Expense Service SHALL implement updateStreak method that posts to /user-streak/update-user-streak
2. WHEN updateStreak succeeds, THE Expense Service SHALL return currentStreak and maxStreak from Data
3. THE Expense Service SHALL implement getCurrentStreak method that gets from /user-streak/current-user-streak
4. WHEN getCurrentStreak succeeds, THE Expense Service SHALL return the complete streak data as a Map including owner, currentStreak, maxStreak, and timestamps

### Requirement 7: Response Parsing Consistency

**User Story:** As a developer, I want consistent response parsing across all services so that the app handles API responses reliably

#### Acceptance Criteria

1. WHEN any service receives an API response, THE Service SHALL check for the success field in the response
2. WHEN success is false, THE Service SHALL throw an ApiException with the message field
3. WHEN Data field contains nested user object, THE Service SHALL extract Data.user
4. WHEN Data field contains direct data, THE Service SHALL use Data directly
5. THE Services SHALL handle both accessToken and token field names for JWT tokens

### Requirement 8: Phone Number Handling

**User Story:** As a user, I want my phone number stored correctly so that I can be contacted if needed

#### Acceptance Criteria

1. WHEN the registration form collects phoneNumber, THE App SHALL convert numeric input to string format
2. THE Auth Service SHALL send phoneNumber as a string in the registration request body
3. WHEN user data is received, THE App SHALL handle phoneNumber as either string or number type
4. THE App SHALL display phoneNumber correctly regardless of backend storage format

### Requirement 9: Error Handling Enhancement

**User Story:** As a user, I want clear error messages when API calls fail so that I understand what went wrong

#### Acceptance Criteria

1. WHEN an API call fails with HTTP error, THE ApiClient SHALL include the response body in ApiException
2. WHEN the response contains a message field, THE Services SHALL extract and propagate the message
3. WHEN network timeout occurs, THE ApiClient SHALL throw ApiException with timeout message
4. THE Services SHALL not swallow exceptions but propagate them to the UI layer
5. WHEN JSON parsing fails, THE ApiClient SHALL throw ApiException with parsing error details

### Requirement 10: Service Method Integration in AppState

**User Story:** As a developer, I want all service methods accessible through AppState so that UI components can use them easily

#### Acceptance Criteria

1. THE AppState SHALL add wrapper methods for OTP login flow (sendOtp, verifyOtp)
2. THE AppState SHALL add wrapper methods for password reset flow (sendResetOtp, verifyResetOtp, resetPassword)
3. THE AppState SHALL add wrapper methods for streak tracking (updateStreak, getCurrentStreak)
4. THE AppState SHALL add wrapper method for user profile update (updateUserProfile)
5. WHEN these methods are called, THE AppState SHALL delegate to the appropriate service and update local state as needed
