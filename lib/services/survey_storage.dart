class SurveyStorage {
  static final List<Map<String, dynamic>> _customSurveys = [];
  static final List<Map<String, dynamic>> _defaultSurveys = [];
  static final List<Map<String, dynamic>> _templateSurveys = [];
  
  static List<Map<String, dynamic>> get customSurveys => List.from(_customSurveys);
  
  static void addSurvey(Map<String, dynamic> survey) {
    _customSurveys.add(survey);
  }
  
  static void updateSurvey(int index, Map<String, dynamic> survey) {
    if (index >= 0 && index < _customSurveys.length) {
      print('DEBUG [SURVEY STORAGE]: Updating custom survey at index $index');
      print('DEBUG [SURVEY STORAGE]: Old survey: ${_customSurveys[index]}');
      print('DEBUG [SURVEY STORAGE]: New survey keys: ${survey.keys}');
      print('DEBUG [SURVEY STORAGE]: New survey sections: ${survey['sections']}');
      _customSurveys[index] = survey;
      print('DEBUG [SURVEY STORAGE]: Survey updated successfully');
    } else {
      print('DEBUG [SURVEY STORAGE]: ERROR - Invalid index $index (total surveys: ${_customSurveys.length})');
    }
  }
  
  static void updateDefaultSurvey(String surveyName, Map<String, dynamic> updates) {
    // Update default survey properties (like isLive status)
    final index = _defaultSurveys.indexWhere((s) => s['name'] == surveyName);
    if (index >= 0) {
      print('DEBUG [SURVEY STORAGE]: Updating default survey "$surveyName"');
      print('DEBUG [SURVEY STORAGE]: Updates: $updates');
      print('DEBUG [SURVEY STORAGE]: Updates sections: ${updates['sections']}');
      _defaultSurveys[index] = {..._defaultSurveys[index], ...updates};
      print('DEBUG [SURVEY STORAGE]: Default survey updated successfully');
    } else {
      print('DEBUG [SURVEY STORAGE]: ERROR - Default survey "$surveyName" not found');
    }
  }
  
  static void updateTemplateSurvey(String surveyTitle, Map<String, dynamic> updates) {
    // Update template survey properties (like isLive status)
    print('DEBUG [SURVEY STORAGE]: ========== UPDATE TEMPLATE SURVEY ==========');
    print('DEBUG [SURVEY STORAGE]: Searching for: "$surveyTitle"');
    print('DEBUG [SURVEY STORAGE]: Current _templateSurveys length: ${_templateSurveys.length}');
    
    final index = _templateSurveys.indexWhere((s) => s['title'] == surveyTitle || s['name'] == surveyTitle);
    print('DEBUG [SURVEY STORAGE]: Found at index: $index');
    
    if (index >= 0) {
      print('DEBUG [SURVEY STORAGE]: BEFORE UPDATE:');
      print('DEBUG [SURVEY STORAGE]:   Keys: ${_templateSurveys[index].keys.toList()}');
      print('DEBUG [SURVEY STORAGE]:   Title: ${_templateSurveys[index]['title']}');
      print('DEBUG [SURVEY STORAGE]:   Name: ${_templateSurveys[index]['name']}');
      print('DEBUG [SURVEY STORAGE]:   Has sections: ${_templateSurveys[index]['sections'] != null}');
      if (_templateSurveys[index]['sections'] != null) {
        print('DEBUG [SURVEY STORAGE]:   Sections count: ${(_templateSurveys[index]['sections'] as List).length}');
      }
      
      print('DEBUG [SURVEY STORAGE]: UPDATES TO APPLY:');
      print('DEBUG [SURVEY STORAGE]:   Keys: ${updates.keys.toList()}');
      print('DEBUG [SURVEY STORAGE]:   Has sections: ${updates['sections'] != null}');
      if (updates['sections'] != null) {
        print('DEBUG [SURVEY STORAGE]:   Sections count: ${(updates['sections'] as List).length}');
        print('DEBUG [SURVEY STORAGE]:   Sections data: ${updates['sections']}');
      }
      
      // Create the updated survey
      final updatedSurvey = {..._templateSurveys[index], ...updates};
      print('DEBUG [SURVEY STORAGE]: MERGED SURVEY:');
      print('DEBUG [SURVEY STORAGE]:   Keys: ${updatedSurvey.keys.toList()}');
      print('DEBUG [SURVEY STORAGE]:   Has sections: ${updatedSurvey['sections'] != null}');
      if (updatedSurvey['sections'] != null) {
        print('DEBUG [SURVEY STORAGE]:   Sections count: ${(updatedSurvey['sections'] as List).length}');
      }
      
      // Assign to list
      _templateSurveys[index] = updatedSurvey;
      
      print('DEBUG [SURVEY STORAGE]: AFTER ASSIGNMENT TO LIST:');
      print('DEBUG [SURVEY STORAGE]:   _templateSurveys[$index] keys: ${_templateSurveys[index].keys.toList()}');
      print('DEBUG [SURVEY STORAGE]:   Has sections: ${_templateSurveys[index]['sections'] != null}');
      if (_templateSurveys[index]['sections'] != null) {
        print('DEBUG [SURVEY STORAGE]:   Sections count: ${(_templateSurveys[index]['sections'] as List).length}');
        print('DEBUG [SURVEY STORAGE]:   Sections data: ${_templateSurveys[index]['sections']}');
      }
      print('DEBUG [SURVEY STORAGE]: ✅ Template survey updated successfully');
    } else {
      print('DEBUG [SURVEY STORAGE]: ❌ ERROR - Template survey "$surveyTitle" not found');
      print('DEBUG [SURVEY STORAGE]: Available template surveys:');
      for (int i = 0; i < _templateSurveys.length; i++) {
        print('DEBUG [SURVEY STORAGE]:   [$i] title="${_templateSurveys[i]['title']}" name="${_templateSurveys[i]['name']}"');
      }
    }
    print('DEBUG [SURVEY STORAGE]: ==========================================');
  }
  
  static void removeSurvey(int index) {
    if (index >= 0 && index < _customSurveys.length) {
      _customSurveys.removeAt(index);
    }
  }
  
  // Get essential 10 ITK Alumni Tracer Study questions in Bahasa Indonesia
  // Streamlined to cover all critical dashboard statistics (10 questions total)
  static List<Map<String, dynamic>> getDefaultQuestions() {
    return [
      // === BAGIAN 1: STATUS & PROFIL KERJA (5 pertanyaan) ===
      {
        'id': 8,
        'field': 'f8',
        'type': 'multiple_choice',
        'question': 'Jelaskan status Anda saat ini?',
        'options': [
          'Bekerja (full time/waktu penuh)',
          'Bekerja (part time/paruh waktu)', 
          'Wiraswasta',
          'Melanjutkan pendidikan',
          'Tidak bekerja tetapi sedang mencari kerja',
          'Belum memungkinkan bekerja'
        ],
        'chartType': 'pie', // For dashboard: Employment status distribution
      },
      {
        'id': 502,
        'field': 'f502',
        'type': 'text',
        'question': 'Berapa bulan waktu yang Anda butuhkan untuk mendapat pekerjaan pertama setelah lulus?',
        'placeholder': 'Masukkan jumlah bulan (contoh: 3)',
        'chartType': 'bar', // For dashboard: Time to employment distribution
      },
      {
        'id': 505,
        'field': 'f505',
        'type': 'text',
        'question': 'Berapa rata-rata pendapatan (take home pay) Anda per bulan? (dalam Rupiah)',
        'placeholder': 'Contoh: 5000000',
        'chartType': 'bar', // For dashboard: Salary range distribution
      },
      {
        'id': 5001,
        'field': 'f5a1',
        'type': 'text',
        'question': 'Di Provinsi mana lokasi tempat kerja Anda?',
        'placeholder': 'Contoh: Kalimantan Timur',
        'chartType': 'map', // For dashboard: Geographic distribution
      },
      {
        'id': 1101,
        'field': 'f1101',
        'type': 'multiple_choice',
        'question': 'Jenis institusi/perusahaan tempat Anda bekerja sekarang?',
        'options': [
          'Instansi pemerintah',
          'BUMN/BUMD',
          'Institusi/organisasi multilateral',
          'Organisasi non-profit/Lembaga Swadaya Masyarakat',
          'Perusahaan swasta',
          'Wiraswasta/perusahaan sendiri',
          'Lainnya'
        ],
        'chartType': 'pie', // For dashboard: Institution type distribution
      },
      
      // === BAGIAN 2: RELEVANSI PENDIDIKAN (2 pertanyaan) ===
      {
        'id': 14,
        'field': 'f14',
        'type': 'multiple_choice',
        'question': 'Seberapa erat hubungan bidang studi dengan pekerjaan Anda?',
        'options': [
          'Sangat erat',
          'Erat',
          'Cukup erat',
          'Kurang erat',
          'Tidak sama sekali'
        ],
        'chartType': 'bar', // For dashboard: Education relevance
      },
      {
        'id': 15,
        'field': 'f15',
        'type': 'multiple_choice',
        'question': 'Tingkat pendidikan apa yang paling tepat/sesuai untuk pekerjaan Anda saat ini?',
        'options': [
          'Setingkat lebih tinggi',
          'Tingkat yang sama',
          'Setingkat lebih rendah',
          'Tidak perlu pendidikan tinggi'
        ],
        'chartType': 'pie', // For dashboard: Education level match
      },
      
      // === BAGIAN 3: KOMPETENSI (2 pertanyaan - competency gap analysis) ===
      {
        'id': 1763,
        'field': 'f1763',
        'type': 'rating',
        'question': 'Pada saat lulus, tingkat kompetensi Anda dalam KEAHLIAN BIDANG ILMU:',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
        'chartType': 'radar', // For dashboard: Competency radar chart
        'category': 'competency_before',
      },
      {
        'id': 1764,
        'field': 'f1764',
        'type': 'rating',
        'question': 'Tingkat kompetensi KEAHLIAN BIDANG ILMU yang dibutuhkan dalam pekerjaan:',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
        'chartType': 'radar', // For dashboard: Competency radar chart (compare with f1763)
        'category': 'competency_after',
      },
      
      // === BAGIAN 4: METODE PEMBELAJARAN (1 pertanyaan kunci) ===
      {
        'id': 24,
        'field': 'f24',
        'type': 'rating',
        'question': 'Seberapa besar penekanan MAGANG di program studi Anda membantu pekerjaan?',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
        'chartType': 'bar', // For dashboard: Learning method effectiveness
      },
    ];
  }
  
  static List<Map<String, dynamic>> getAllAvailableSurveys() {
    // Initialize default surveys once
    if (_defaultSurveys.isEmpty) {
      _defaultSurveys.addAll([
        {
          'name': 'Tracer Study Alumni ITK 2024',
          'description': 'Kuesioner lengkap untuk melacak kondisi kerja, profil pekerjaan, relevansi pendidikan, kompetensi, dan pencarian kerja alumni ITK',
          'isDefault': true,
          'isLive': true, // Live by default for response tracking
          'questions': getDefaultQuestions(),
        },
      ]);
    }
    
    // Initialize template surveys once
    if (_templateSurveys.isEmpty) {
      _templateSurveys.addAll([
        {
          'name': 'Informatics Alumni Survey',
          'title': 'Informatics Alumni Survey',
          'description': 'Career tracking for Informatics graduates',
          'subtitle': 'Career tracking for Informatics graduates',
          'isTemplate': true,
          'isLive': false,
          'questions': getDefaultQuestions(),
        },
        {
          'name': 'Chemical Engineering Survey',
          'title': 'Chemical Engineering Survey',
          'description': 'Industry placement for Chemical Engineering alumni',
          'subtitle': 'Industry placement for Chemical Engineering alumni',
          'isTemplate': true,
          'isLive': false,
          'questions': getDefaultQuestions(),
        },
        {
          'name': 'Mathematics Alumni Survey',
          'title': 'Mathematics Alumni Survey',
          'description': 'Career development for Mathematics graduates',
          'subtitle': 'Career development for Mathematics graduates',
          'isTemplate': true,
          'isLive': false,
          'questions': getDefaultQuestions(),
        },
        {
          'name': 'Industrial Engineering Survey',
          'title': 'Industrial Engineering Survey',
          'description': 'Professional advancement tracking',
          'subtitle': 'Professional advancement tracking',
          'isTemplate': true,
          'isLive': false,
          'questions': getDefaultQuestions(),
        },
        {
          'name': 'Environmental Engineering Survey',
          'title': 'Environmental Engineering Survey',
          'description': 'Environmental sector career survey',
          'subtitle': 'Environmental sector career survey',
          'isTemplate': true,
          'isLive': false,
          'questions': getDefaultQuestions(),
        },
        {
          'name': 'Food Technology Survey',
          'title': 'Food Technology Survey',
          'description': 'Food industry career assessment',
          'subtitle': 'Food industry career assessment',
          'isTemplate': true,
          'isLive': false,
          'questions': getDefaultQuestions(),
        },
      ]);
    }
    
    // Combine all surveys: default + template + custom
    final allSurveys = List<Map<String, dynamic>>.from(_defaultSurveys);
    allSurveys.addAll(_templateSurveys);
    allSurveys.addAll(_customSurveys.map((survey) => {
      ...survey,
      'isDefault': false,
    }));
    
    print('DEBUG [SURVEY STORAGE]: getAllAvailableSurveys - Returning ${allSurveys.length} surveys');
    print('DEBUG [SURVEY STORAGE]: Template surveys with sections:');
    for (var survey in _templateSurveys) {
      if (survey['sections'] != null) {
        print('DEBUG [SURVEY STORAGE]:   "${survey['title']}" has ${(survey['sections'] as List).length} sections');
      } else {
        print('DEBUG [SURVEY STORAGE]:   "${survey['title']}" has NO sections field');
      }
    }
    
    return allSurveys;
  }
}