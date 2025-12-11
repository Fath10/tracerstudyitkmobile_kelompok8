# Backend Server Auto-Start Guide 🚀

## Problem
When you change WiFi networks, your computer's IP address changes, and the Flutter app can't connect to the backend.

## Solution ✅
Use the automated scripts to detect your IP and update the configuration automatically.

---

## 🚀 QUICK START (Easiest Method)

### Double-click `QUICK_START.bat`
This will:
1. ✅ Auto-detect your current IP address
2. ✅ Update Flutter config (`lib/config/api_config.dart`)
3. ✅ Start the Django backend server
4. ✅ Show you the IP address to verify

**Then:**
- Hot restart your Flutter app (press 'r' in terminal)
- The app will connect to the backend automatically

---

## Alternative Methods

### 📱 Option A: Update IP only
Double-click `UPDATE_IP.bat`
- Updates Flutter config with current IP
- Hot restart your Flutter app after

### 🖥️ Option B: Start server only
Double-click `START_BACKEND.bat`
- Auto-detects IP and starts Django server
- Shows the IP address for manual configuration

---

## When WiFi Changes:

1. **Double-click** `QUICK_START.bat` in the project root
2. **Wait** for it to detect IP and start server (takes ~5 seconds)
3. **Hot restart** your Flutter app
4. **Done!** App should connect

### Current Configuration

**Network Settings:**
- Backend running on port 8000
- Server listens on all interfaces (0.0.0.0)
- Current IP: Check `lib/config/api_config.dart` line with `_hostIp`

**Database:**
- Users: 15 (including 4 admin accounts)
- Survey: "Tracer Study Alumni ITK 2024" (ID: 10, 15 questions)
- Test Login: `admin` / `admin123`

## API Endpoints (All Working ✅)

### Authentication
- `POST /accounts/login/` - Login with JWT
- `POST /accounts/register/` - Register new user
- `POST /accounts/refresh/` - Refresh access token

### Public Endpoints (No Auth Required)
- `GET /api/roles/` - List all roles
- `GET /api/users/` - List all users
- `GET /api/unit/program-studies/` - List program studies
- `GET /api/surveys/` - List surveys

### Survey Management
- `GET /api/surveys/` - List surveys
- `POST /api/surveys/` - Create survey
- `GET /api/surveys/{id}/` - Survey details
- `PUT /api/surveys/{id}/` - Update survey
- `DELETE /api/surveys/{id}/` - Delete survey
- `GET /api/surveys/{id}/sections/` - Survey sections
- `POST /api/surveys/{id}/answers/bulk/` - Submit answers

### User Management
- `GET /api/users/` - List users
- `POST /api/users/` - Create user
- `GET /api/users/{id}/` - User details
- `PUT /api/users/{id}/` - Update user
- `DELETE /api/users/{id}/` - Delete user

## Troubleshooting

### Backend Not Accessible
1. Check server is running: `Get-NetTCPConnection -LocalPort 8000`
2. Verify IP address: `ipconfig | Select-String "IPv4"`
3. Update `lib/config/api_config.dart` if IP changed
4. Check firewall: `Get-NetFirewallRule -DisplayName "*Django*"`

### App Can't Connect
1. Ensure phone on same WiFi as computer
2. Test from phone browser: http://192.168.0.105:8000/api/users/
3. Check Flutter app IP in `lib/config/api_config.dart`
4. Restart Flutter app after IP change

### Login Fails
1. Test login: `python test_complete.py`
2. Check credentials in database
3. Verify JWT tokens are being generated
4. Check console logs in Flutter app

## Files Modified
- ✅ `lib/config/api_config.dart` - Updated IP to 192.168.0.105
- ✅ `lib/services/auth_service.dart` - Increased timeout to 10s
- ✅ `test_backend_connectivity.ps1` - Updated IP
- ✅ Database - Fixed admin user roles

## Status: READY FOR TESTING 🚀

All systems operational. Backend is ready for Flutter app connection.
