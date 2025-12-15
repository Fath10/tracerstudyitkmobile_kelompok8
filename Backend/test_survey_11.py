import os
import sys
import django

# Add the project to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'capstone_backend'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'capstone_backend.settings')
django.setup()

from api.models import Survey, Section, Question
from api.serializers import SurveySerializer, SectionSerializer, QuestionSerializer

# Get Survey 11
survey = Survey.objects.get(id=11)
print(f"Survey: {survey.title}")
print(f"Active: {survey.is_active}")
print(f"Created: {survey.created_at}")
print()

# Get sections
sections = Section.objects.filter(survey=survey).order_by('order', 'id')
print(f"Sections: {sections.count()}")
for section in sections:
    questions = Question.objects.filter(section=section).order_by('order', 'id')
    print(f"  - {section.title}: {questions.count()} questions")
    
    # Show first question details
    if questions.exists():
        q = questions.first()
        print(f"    First Q: id={q.id}, type={q.question_type}, text={q.text[:50]}")
print()

# Test what API returns
print("=" * 60)
print("TESTING API SERIALIZATION:")
print("=" * 60)

survey_data = SurveySerializer(survey).data
print(f"Survey data keys: {list(survey_data.keys())}")
print()

sections_data = SectionSerializer(sections, many=True).data
print(f"Sections returned: {len(sections_data)}")
for i, sec in enumerate(sections_data):
    print(f"  Section {i+1}: {sec['title']}")
    print(f"    Keys: {list(sec.keys())}")
print()

# Test questions endpoint
for section in sections:
    questions = Question.objects.filter(section=section).order_by('order', 'id')
    questions_data = QuestionSerializer(questions, many=True).data
    print(f"Section '{section.title}': {len(questions_data)} questions serialized")
    if questions_data:
        print(f"  First question keys: {list(questions_data[0].keys())}")
        print(f"  First question: {questions_data[0]}")
        break
