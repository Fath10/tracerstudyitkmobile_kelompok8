import requests
import json

response = requests.get("http://localhost:8000/api/users/")
users = response.json()

print("=" * 60)
print("USERS IN DATABASE")
print("=" * 60)
for user in users:
    role_name = user.get('role', {}).get('name', 'No role') if user.get('role') else 'No role'
    print(f"ID: {user['id']:15} | Name: {user['username']:20} | Role: {role_name}")
print("=" * 60)
print(f"Total users: {len(users)}")
