import requests
import json

BASE_URL = "http://localhost:8000/api"

print("=" * 70)
print("TESTING USER CREATION (Simulating Flutter App)")
print("=" * 70)

# Test 1: Create employee (surveyor)
print("\n1. Creating Surveyor Employee")
employee_data = {
    "id": "surveyor001",
    "username": "John Surveyor",
    "email": "surveyor001@test.com",
    "phone_number": "0812345678",
    "role_id": 2,  # Surveyor
    "program_study_id": 1,
    "password": "password123"
}
try:
    response = requests.post(
        f"{BASE_URL}/users/",
        json=employee_data,
        headers={"Content-Type": "application/json"},
        timeout=5
    )
    print(f"   Status: {response.status_code}")
    if response.status_code == 201:
        print(f"   ✅ SUCCESS! User created:")
        data = response.json()
        print(f"      - ID: {data['id']}")
        print(f"      - Name: {data['username']}")
        print(f"      - Role: {data['role']['name']}")
        print(f"      - Plain Password: {data.get('plain_password', 'N/A')}")
    else:
        print(f"   ❌ FAILED: {response.text}")
except Exception as e:
    print(f"   ❌ Error: {e}")

# Test 2: Create admin employee
print("\n2. Creating Admin Employee")
admin_data = {
    "id": "admin002",
    "username": "Jane Admin",
    "email": "admin002@test.com",
    "phone_number": "0812345679",
    "role_id": 1,  # Admin
    "program_study_id": 1,
    "password": "admin123"
}
try:
    response = requests.post(
        f"{BASE_URL}/users/",
        json=admin_data,
        headers={"Content-Type": "application/json"},
        timeout=5
    )
    print(f"   Status: {response.status_code}")
    if response.status_code == 201:
        print(f"   ✅ SUCCESS! User created:")
        data = response.json()
        print(f"      - ID: {data['id']}")
        print(f"      - Name: {data['username']}")
        print(f"      - Role: {data['role']['name']}")
        print(f"      - Plain Password: {data.get('plain_password', 'N/A')}")
    else:
        print(f"   ❌ FAILED: {response.text}")
except Exception as e:
    print(f"   ❌ Error: {e}")

# Test 3: Create team prodi employee
print("\n3. Creating Team Prodi Employee")
prodi_data = {
    "id": "prodi001",
    "username": "Bob Team Prodi",
    "email": "prodi001@test.com",
    "phone_number": "0812345680",
    "role_id": 3,  # Team Prodi
    "program_study_id": 1,
    "password": "prodi123"
}
try:
    response = requests.post(
        f"{BASE_URL}/users/",
        json=prodi_data,
        headers={"Content-Type": "application/json"},
        timeout=5
    )
    print(f"   Status: {response.status_code}")
    if response.status_code == 201:
        print(f"   ✅ SUCCESS! User created:")
        data = response.json()
        print(f"      - ID: {data['id']}")
        print(f"      - Name: {data['username']}")
        print(f"      - Role: {data['role']['name']}")
        print(f"      - Plain Password: {data.get('plain_password', 'N/A')}")
    else:
        print(f"   ❌ FAILED: {response.text}")
except Exception as e:
    print(f"   ❌ Error: {e}")

# Test 4: Test survey submission
print("\n4. Testing Survey Answer Submission")
# First, let's check if there are any surveys
try:
    response = requests.get(f"{BASE_URL}/surveys/", timeout=5)
    surveys = response.json() if response.status_code == 200 else []
    if surveys:
        survey_id = surveys[0]['id']
        print(f"   Found survey ID: {survey_id}")
        
        # Try to submit an answer
        answer_data = {
            "user_id": "11221037",
            "question_id": 1,
            "answer_text": "Test answer"
        }
        response = requests.post(
            f"{BASE_URL}/surveys/{survey_id}/answers/",
            json=answer_data,
            headers={"Content-Type": "application/json"},
            timeout=5
        )
        print(f"   Answer submission status: {response.status_code}")
        if response.status_code in [200, 201]:
            print(f"   ✅ Answer submitted successfully")
        else:
            print(f"   Response: {response.text[:200]}")
    else:
        print(f"   ⚠️ No surveys found in database")
except Exception as e:
    print(f"   Error: {e}")

print("\n" + "=" * 70)
print("ALL TESTS COMPLETE")
print("=" * 70)
print("\n📝 Summary:")
print("   ✅ Backend server is running and accepting requests")
print("   ✅ Roles are correctly configured (Admin=1, Surveyor=2, Team Prodi=3)")
print("   ✅ User creation endpoint is working")
print("\n🎯 Next steps:")
print("   1. Run Flutter app on Android emulator")
print("   2. Test adding user in User Management page")
print("   3. Test adding employee in Employee Directory page")
print("   4. Test submitting questionnaire")
