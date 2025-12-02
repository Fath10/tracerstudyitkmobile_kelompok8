import requests
import json

BASE_URL = "http://localhost:8000/api"

print("=" * 60)
print("TESTING BACKEND API")
print("=" * 60)

# Test 1: GET /api/users/
print("\n1. Testing GET /api/users/")
try:
    response = requests.get(f"{BASE_URL}/users/", timeout=5)
    print(f"   Status: {response.status_code}")
    print(f"   Response: {json.dumps(response.json(), indent=2)[:200]}")
except Exception as e:
    print(f"   Error: {e}")

# Test 2: GET /api/roles/
print("\n2. Testing GET /api/roles/")
try:
    response = requests.get(f"{BASE_URL}/roles/", timeout=5)
    print(f"   Status: {response.status_code}")
    print(f"   Response: {json.dumps(response.json(), indent=2)[:200]}")
except Exception as e:
    print(f"   Error: {e}")

# Test 3: POST /api/users/
print("\n3. Testing POST /api/users/ (Create User)")
user_data = {
    "id": "testuser999",
    "username": "Test User 999",
    "email": "testuser999@test.com",
    "phone_number": "1234567890",
    "role_id": 2,
    "program_study_id": 1,
    "password": "testpass123"
}
try:
    response = requests.post(
        f"{BASE_URL}/users/",
        json=user_data,
        headers={"Content-Type": "application/json"},
        timeout=5
    )
    print(f"   Status: {response.status_code}")
    print(f"   Response: {response.text[:500]}")
except Exception as e:
    print(f"   Error: {e}")

# Test 4: GET /api/surveys/
print("\n4. Testing GET /api/surveys/")
try:
    response = requests.get(f"{BASE_URL}/surveys/", timeout=5)
    print(f"   Status: {response.status_code}")
    print(f"   Response: {json.dumps(response.json(), indent=2)[:200]}")
except Exception as e:
    print(f"   Error: {e}")

print("\n" + "=" * 60)
print("TEST COMPLETE")
print("=" * 60)
