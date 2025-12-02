# Backend Setup Complete ✅

## Current Configuration

### Network Settings
- **Backend URL**: `http://192.168.0.105:8000`
- **Server Status**: ✅ Running on port 8000
- **Firewall**: ✅ Django Dev Server rule enabled

### Database Status
- **Users**: 15 (including 4 admin accounts)
- **Roles**: 4 (Admin, Surveyor, Team Prodi, Alumni)
- **Program Studies**: 23
- **Surveys**: 1

### Test Credentials
- **Username**: `admin`
- **Password**: `admin123`
- **Role**: Admin

Alternative admin accounts:
- `admin001` / (check backend)
- `admin@itk.ac.id` / (check backend)

## Quick Start Guide

### 1. Start Backend Server
```bash
cd "c:\Code\Flutter\Tracer Study ITK\Backend\capstone_backend"
python manage.py runserver 0.0.0.0:8000
```

### 2. Verify Backend is Running
Open browser: http://192.168.0.105:8000/api/users/
Or run: `python test_complete.py`

### 3. Connect Mobile Device
- Ensure your phone is on the **same WiFi network**
- WiFi: Your computer's network
- Phone should be able to access: http://192.168.0.105:8000

### 4. Run Flutter App
```bash
cd "c:\Code\Flutter\Tracer Study ITK"
flutter run
```

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
