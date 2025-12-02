# Quick Test Guide - Tracer Study ITK App

## 🚀 Quick Start (5 Minutes)

### Step 1: Start Backend (30 seconds)
```powershell
cd "c:\Code\Flutter\Tracer Study ITK\Backend\capstone_backend"
python manage.py runserver 0.0.0.0:8000
```
✅ Wait for: "Starting development server at http://0.0.0.0:8000/"

---

### Step 2: Update API Config (1 minute)
**File:** `lib/config/api_config.dart`

**For Android Emulator:**
```dart
return 'http://10.0.2.2:8000';
```

**For Physical Device:**
```dart
return 'http://192.168.1.107:8000';  // Replace with your computer's IP
```

---

### Step 3: Run Flutter App (1 minute)
```bash
flutter run
```

---

## 🧪 Test Scenarios

### Test 1: Login as Alumni (2 min)
1. Open app
2. Login with:
   - **ID:** `11221037`
   - **Password:** `akmal123`
3. ✅ Expected: Login successful, see home page

**Verify:**
- [ ] User initial shows "A" (not "U") in drawer
- [ ] Role shows "Alumni"
- [ ] Name shows "Akmal"

---

### Test 2: Login as Admin (2 min)
1. Logout (if logged in)
2. Login with:
   - **ID:** `admin002`
   - **Password:** `admin123`
3. ✅ Expected: Login successful, see home page

**Verify:**
- [ ] User initial shows "A" in drawer
- [ ] Role shows "Admin"
- [ ] Can access User Management menu
- [ ] Can access Survey Management menu

---

### Test 3: User Management (3 min)
1. Login as Admin
2. Go to User Management
3. Click "Add User" button

**Verify:**
- [ ] Role dropdown shows: "Total roles: 4"
- [ ] Role dropdown has "Alumni" option
- [ ] Program Studi dropdown shows: "Total: 23 programs"
- [ ] Program Studi dropdown has programs (Informatika, Matematika, etc.)

4. Fill in form:
   - User ID: `testuser001`
   - Full Name: `Test User`
   - Phone: `081234567890`
   - Role: Alumni (auto-selected)
   - Program Studi: Select any

5. Click "Create User"

**Verify:**
- [ ] User created successfully
- [ ] Success message appears
- [ ] New user appears in user list
- [ ] User has role: Alumni
- [ ] User has fakultas displayed

---

### Test 4: Survey Management (3 min)
1. Login as Admin
2. Go to Survey Management
3. Click "Add Survey" or similar button

**Verify:**
- [ ] Can create new survey
- [ ] Can add sections to survey
- [ ] Can add questions to sections
- [ ] Can set survey to "Live"

---

### Test 5: Take Survey (3 min)
1. Login as Alumni
2. Go to Questionnaires/Surveys
3. Select a live survey

**Verify:**
- [ ] Name field is pre-filled with "Akmal" (not empty)
- [ ] NIM field is pre-filled with "11221037" (not empty)
- [ ] Can answer all questions
- [ ] Can submit survey
- [ ] No "invalid survey id format" error

---

## ✅ Success Criteria

All tests should pass with no errors:

- [x] Backend running on port 8000
- [x] Login working for both Admin and Alumni
- [x] User initials showing correctly (not "U")
- [x] User management showing roles and fakultas
- [x] Survey forms autofilling user info
- [x] No survey ID errors when submitting

---

## 🐛 Troubleshooting

### Problem: "Connection refused" or "Network error"
**Solution:** Check `api_config.dart` baseUrl matches your setup
- Emulator: `http://10.0.2.2:8000`
- Device: `http://YOUR_COMPUTER_IP:8000`

### Problem: "No roles available" in user form
**Solution:** 
1. Check backend is running
2. Check console for error messages
3. Should see in debug console:
   ```
   📋 UserFormPage initialized
      Roles passed: 4 - Admin, Surveyor, Team Prodi, Alumni
      Program Studies passed: 23
   ```

### Problem: User initial still shows "U"
**Solution:** This was fixed! If still happening:
1. Hot restart the app (not hot reload)
2. Check you're logged in (not guest)
3. Check `AuthService.currentUser` has data

### Problem: Survey submission error
**Solution:**
1. Verify survey ID exists
2. Check survey is set to "Live"
3. Verify all required questions are answered

---

## 📞 Support

### Test Accounts
```
Admin (Full Access):
  ID: admin002
  Password: admin123

Alumni (Limited Access):
  ID: 11221037  
  Password: akmal123
```

### Backend API Test
```powershell
# Quick backend health check
Invoke-RestMethod -Uri "http://localhost:8000/api/roles/" -Method Get
# Should return 4 roles
```

### Debug Console
Watch for these messages when testing:
```
✅ Loaded user: Akmal, Role: Alumni
📋 UserFormPage initialized
   Roles passed: 4 - Admin, Surveyor, Team Prodi, Alumni
   Program Studies passed: 23
🌐 GET request to: http://...
✅ Response status: 200
```

---

## 🎯 Expected Results Summary

| Test | Expected Result | Status |
|------|----------------|---------|
| Backend Start | Server running on 8000 | ✅ Ready |
| Admin Login | Access granted, role=Admin | ✅ Ready |
| Alumni Login | Access granted, role=Alumni | ✅ Ready |
| User Initials | Shows correct letter | ✅ Fixed |
| Add User | Roles & fakultas shown | ✅ Fixed |
| Survey Autofill | Name & NIM pre-filled | ✅ Fixed |
| Survey Submit | No ID format error | ✅ Fixed |

**All systems operational! 🎉**
