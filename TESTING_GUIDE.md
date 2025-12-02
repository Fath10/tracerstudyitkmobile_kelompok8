# TRACER STUDY APP - TESTING GUIDE

## ✅ BACKEND STATUS
- **Server**: Running on http://192.168.1.107:8000
- **Firewall**: ✅ Configured (port 8000 open)
- **Database**: 7 users, 4 roles, 23 program studies
- **Surveys**: 1 backend survey available
- **Local Surveys**: Multiple templates in SurveyStorage

## 📱 MOBILE APP CONFIGURATION
- **API Base URL**: http://192.168.1.107:8000 (configured for Android physical device)
- **Location**: `lib/config/api_config.dart`
- **Network**: App and backend must be on same Wi-Fi network

## 🧪 TESTING CHECKLIST

### 1. AUTHENTICATION TESTS
- [ ] **Login with backend user**
  - Use credentials from Backend/capstone_backend/README.md
  - Example: admin / admin123
  - Should load user profile and show role-based menu

- [ ] **Login with local user (offline mode)**
  - Use any username/password if backend is unreachable
  - Should work with local database fallback

- [ ] **Logout**
  - Should clear session and return to login screen
  - Should remove stored tokens

### 2. USER MANAGEMENT TESTS (Admin Only)
- [ ] **View Users**
  - Navigate to Dashboard → Unit Directory → User Management
  - Should display 7 users from backend
  - Should show Alumni users only (not Admin/Surveyor/Team Prodi)

- [ ] **Create New User**
  - Click "+" button
  - Fill all required fields:
    - User ID (NIM): e.g., "11221050"
    - Full Name: e.g., "Test User"
    - Email: test@example.com
    - Phone: e.g., "081234567890" (required for password generation)
    - Role: Alumni (auto-selected)
    - Program Studi: Choose from dropdown
  - Password: Leave blank for auto-generated (UserID-Phone) or set custom
  - Click "Create User"
  - Should show success message
  - Should refresh user list with new user

- [ ] **Edit User**
  - Click three-dot menu on any user
  - Select "Edit"
  - Modify any field
  - Click "Update User"
  - Should show success message
  - Should reflect changes in list

- [ ] **Delete User**
  - Click three-dot menu on any user
  - Select "Delete"
  - Confirm deletion
  - Should show success message
  - Should remove user from list

- [ ] **Bulk Delete Users**
  - Check checkboxes for multiple users
  - Click delete icon in top bar
  - Confirm deletion
  - Should delete all selected users

- [ ] **Search Users**
  - Type in search box
  - Should filter by name, ID, or email

- [ ] **Filter Users**
  - Click filter icon
  - Select Role filter
  - Select Fakultas filter
  - Should show filtered results

### 3. SURVEY TESTS

#### Backend Surveys (with ID)
- [ ] **View Backend Surveys**
  - Navigate to Questionnaire → Take Questionnaire
  - Should see backend survey (ID: 1) if available
  - Should show survey title and sections

- [ ] **Take Backend Survey**
  - Click on backend survey
  - Answer all questions in all sections
  - Click "Submit Survey"
  - Should submit to backend API
  - Should show success message

#### Local Surveys (no ID)
- [ ] **View Local Surveys**
  - Navigate to Take Questionnaire
  - Should see multiple local survey templates:
    - Informatics Alumni Survey
    - Business Administration Alumni Survey
    - Civil Engineering Alumni Survey
    - (and more...)

- [ ] **Take Local Survey**
  - Click on any local survey
  - Answer questions
  - Click "Submit Survey"
  - Should save locally (no backend call)
  - Should show success message

### 4. SURVEY AUTOFILL TESTS
- [ ] **Personal Info Autofill**
  - Take any survey
  - Personal info questions should auto-fill from user profile:
    - Name → username
    - NIM → nim
    - Email → email
    - Phone → phone_number
    - Program Studi → program_study.name
    - Fakultas → fakultas

- [ ] **User Initials**
  - Check if user initials appear correctly in profile
  - Should show first letter of username

### 5. EMPLOYEE DIRECTORY TESTS (Admin Only)
- [ ] **View Employees**
  - Navigate to Dashboard → Unit Directory → Employee Directory
  - Should show Admin, Surveyor, and Team Prodi users
  - Should NOT show Alumni users

- [ ] **Create Employee**
  - Click "+" button
  - Fill employee details
  - Select role: Admin, Surveyor, or Team Prodi
  - Should create successfully

### 6. SURVEY MANAGEMENT TESTS (Admin/Surveyor/Team Prodi)
- [ ] **View Surveys**
  - Navigate to Dashboard → Questionnaire → Survey Management
  - Should show backend surveys

- [ ] **Create Survey**
  - Click "Create New Survey"
  - Fill survey details
  - Add sections and questions
  - Click "Create Survey"
  - Should create backend survey with ID

### 7. OFFLINE MODE TESTS
- [ ] **Network Disconnected**
  - Turn off Wi-Fi or disconnect device
  - Try to view users
  - Should show cached data
  - Should display "Backend offline" message

- [ ] **Create User Offline**
  - Try to create user while offline
  - Should show error message
  - Should explain backend is required

## 🐛 KNOWN ISSUES FIXED
1. ✅ Survey ID missing error - Fixed: Now handles local vs backend surveys
2. ✅ Network connectivity - Fixed: Backend accessible at 192.168.1.107:8000
3. ✅ Firewall blocking - Fixed: Windows Firewall rule added for port 8000
4. ✅ User initials not showing - Fixed: Autofill working correctly
5. ✅ Roles/Fakultas dropdowns - Fixed: Loading from backend

## 📊 BACKEND DATA
```
Roles: 4 (Admin, Surveyor, Team Prodi, Alumni)
Program Studies: 23
Users: 7
Surveys: 1 backend survey
Local Surveys: 7+ templates
```

## 🔧 TROUBLESHOOTING

### "No route to host" Error
- **Cause**: Phone can't reach backend
- **Fix**: 
  1. Ensure phone is on same Wi-Fi network as computer
  2. Verify firewall rule exists: `Get-NetFirewallRule -DisplayName "Django Dev Server"`
  3. Test backend accessibility: `curl http://192.168.1.107:8000/api/roles/`

### "Survey ID is missing" Error
- **Cause**: Fixed in latest code
- **Fix**: Code now handles local surveys without IDs

### "Connection timeout" Error
- **Cause**: Backend not running or network issue
- **Fix**:
  1. Check backend is running: `cd Backend/capstone_backend; python manage.py runserver 0.0.0.0:8000`
  2. Verify IP address: `Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like '*Wi-Fi*' }`

### App Shows Cached Data
- **Cause**: Backend offline, app using cached data
- **Status**: Working as designed (graceful degradation)
- **Action**: Restart backend to sync fresh data

## 🚀 QUICK START
1. **Start Backend**: 
   ```powershell
   cd "c:\Code\Flutter\Tracer Study ITK\Backend\capstone_backend"
   python manage.py runserver 0.0.0.0:8000
   ```

2. **Verify Connectivity**:
   ```powershell
   cd "c:\Code\Flutter\Tracer Study ITK"
   powershell -ExecutionPolicy Bypass -File ".\test_backend_connectivity.ps1"
   ```

3. **Run Flutter App**:
   - Connect physical device via USB
   - Ensure device is on same Wi-Fi network
   - Run: `flutter run`
   - Select your device

4. **Login**:
   - Username: admin
   - Password: admin123
   - (or any user from Backend/capstone_backend/README.md)

## 📝 NOTES
- Local surveys don't need backend - they work offline
- Backend surveys require active backend connection
- User management requires backend connection
- Survey autofill works with both local and backend authentication
- Caching provides graceful offline fallback for read operations
