import requests
from collections import Counter

users = requests.get('http://localhost:8000/api/users/').json()
print(f'\nTotal users returned: {len(users)}')

roles = [u['role']['name'] if u.get('role') else 'None' for u in users]
print('\nUsers by role:')
for role, count in Counter(roles).items():
    print(f'  {role}: {count}')

print('\nUser list:')
for u in users[:10]:
    role_name = u['role']['name'] if u.get('role') else 'No role'
    fakultas = u.get('fakultas', '-')
    print(f'  - {u["id"]}: {u["username"]} (Role: {role_name}, Fakultas: {fakultas})')
