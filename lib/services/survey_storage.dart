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
      _customSurveys[index] = survey;
    }
  }
  
  static void updateDefaultSurvey(String surveyName, Map<String, dynamic> updates) {
    // Update default survey properties (like isLive status)
    final index = _defaultSurveys.indexWhere((s) => s['name'] == surveyName);
    if (index >= 0) {
      _defaultSurveys[index] = {..._defaultSurveys[index], ...updates};
    }
  }
  
  static void updateTemplateSurvey(String surveyTitle, Map<String, dynamic> updates) {
    // Update template survey properties (like isLive status)
    final index = _templateSurveys.indexWhere((s) => s['title'] == surveyTitle || s['name'] == surveyTitle);
    if (index >= 0) {
      _templateSurveys[index] = {..._templateSurveys[index], ...updates};
    }
  }
  
  static void removeSurvey(int index) {
    if (index >= 0 && index < _customSurveys.length) {
      _customSurveys.removeAt(index);
    }
  }
  
  // Get essential 30 ITK Alumni Tracer Study questions in Bahasa Indonesia
  // Optimized to cover all dashboard statistics requirements (30 questions total)
  static List<Map<String, dynamic>> getDefaultQuestions() {
    return [
      // === BAGIAN 1: STATUS & KONDISI KERJA (10 pertanyaan) ===
      {
        'id': 8,
        'field': 'f8',
        'type': 'multiple_choice',
        'question': '1. Jelaskan status Anda saat ini?',
        'options': [
          'Bekerja (full time/waktu penuh)',
          'Bekerja (part time/paruh waktu)', 
          'Wiraswasta',
          'Melanjutkan pendidikan',
          'Tidak bekerja tetapi sedang mencari kerja',
          'Belum memungkinkan bekerja'
        ],
      },
      {
        'id': 502,
        'field': 'f502',
        'type': 'text',
        'question': '2. Berapa bulan waktu yang Anda butuhkan untuk mendapat pekerjaan pertama setelah lulus?',
        'placeholder': 'Masukkan jumlah bulan (contoh: 3)',
      },
      {
        'id': 504,
        'field': 'f504',
        'type': 'yes_no',
        'question': '3. Apakah Anda mendapat pekerjaan dalam waktu kurang dari 6 bulan atau sebelum lulus?',
        'options': ['Ya', 'Tidak'],
      },
      {
        'id': 505,
        'field': 'f505',
        'type': 'text',
        'question': '4. Berapa rata-rata pendapatan (take home pay) Anda per bulan? (dalam Rupiah)',
        'placeholder': 'Contoh: 5000000',
      },
      {
        'id': 5001,
        'field': 'f5a1',
        'type': 'text',
        'question': '5. Di Provinsi mana lokasi tempat kerja Anda?',
        'placeholder': 'Contoh: Kalimantan Timur',
      },
      {
        'id': 5002,
        'field': 'f5a2',
        'type': 'text',
        'question': '6. Di Kota/Kabupaten mana lokasi tempat kerja Anda?',
        'placeholder': 'Contoh: Balikpapan',
      },
      {
        'id': 1101,
        'field': 'f1101',
        'type': 'multiple_choice',
        'question': '7. Jenis institusi/perusahaan tempat Anda bekerja sekarang?',
        'options': [
          'Instansi pemerintah',
          'BUMN/BUMD',
          'Institusi/organisasi multilateral',
          'Organisasi non-profit/Lembaga Swadaya Masyarakat',
          'Perusahaan swasta',
          'Wiraswasta/perusahaan sendiri',
          'Lainnya'
        ],
      },
      {
        'id': 5003,
        'field': 'f5b',
        'type': 'text',
        'question': '8. Nama perusahaan/kantor/institusi tempat Anda bekerja?',
        'placeholder': 'Contoh: PT Indah Kiat Pulp & Paper',
      },
      {
        'id': 5004,
        'field': 'f5c',
        'type': 'text',
        'question': '9. Apa jabatan/posisi Anda saat ini?',
        'placeholder': 'Contoh: Staff Engineer / Manager / CEO',
      },
      {
        'id': 5005,
        'field': 'f5d',
        'type': 'multiple_choice',
        'question': '10. Tingkat/skala tempat kerja Anda?',
        'options': [
          'Lokal/wilayah/wiraswasta tidak berbadan hukum',
          'Nasional/wiraswasta berbadan hukum',
          'Multinasional/Internasional'
        ],
      },
      
      // === BAGIAN 2: RELEVANSI PENDIDIKAN (2 pertanyaan) ===
      {
        'id': 14,
        'field': 'f14',
        'type': 'multiple_choice',
        'question': '11. Seberapa erat hubungan bidang studi dengan pekerjaan Anda?',
        'options': [
          'Sangat erat',
          'Erat',
          'Cukup erat',
          'Kurang erat',
          'Tidak sama sekali'
        ],
      },
      {
        'id': 15,
        'field': 'f15',
        'type': 'multiple_choice',
        'question': '12. Tingkat pendidikan apa yang paling tepat/sesuai untuk pekerjaan Anda saat ini?',
        'options': [
          'Setingkat lebih tinggi',
          'Tingkat yang sama',
          'Setingkat lebih rendah',
          'Tidak perlu pendidikan tinggi'
        ],
      },
      
      // === BAGIAN 3: KOMPETENSI (7 pairs = 14 pertanyaan) ===
      // ETIKA
      {
        'id': 1761,
        'field': 'f1761',
        'type': 'rating',
        'question': '13. Pada saat lulus, tingkat kompetensi Anda dalam ETIKA:',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
      },
      {
        'id': 1762,
        'field': 'f1762',
        'type': 'rating',
        'question': '14. Tingkat kompetensi ETIKA yang dibutuhkan dalam pekerjaan Anda:',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
      },
      // KEAHLIAN BIDANG ILMU
      {
        'id': 1763,
        'field': 'f1763',
        'type': 'rating',
        'question': '15. Pada saat lulus, tingkat kompetensi Anda dalam KEAHLIAN BIDANG ILMU:',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
      },
      {
        'id': 1764,
        'field': 'f1764',
        'type': 'rating',
        'question': '16. Tingkat kompetensi KEAHLIAN BIDANG ILMU yang dibutuhkan dalam pekerjaan:',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
      },
      // BAHASA INGGRIS
      {
        'id': 1765,
        'field': 'f1765',
        'type': 'rating',
        'question': '17. Pada saat lulus, tingkat kompetensi Anda dalam BAHASA INGGRIS:',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
      },
      {
        'id': 1766,
        'field': 'f1766',
        'type': 'rating',
        'question': '18. Tingkat kompetensi BAHASA INGGRIS yang dibutuhkan dalam pekerjaan:',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
      },
      // TEKNOLOGI INFORMASI
      {
        'id': 1767,
        'field': 'f1767',
        'type': 'rating',
        'question': '19. Pada saat lulus, tingkat kompetensi Anda dalam PENGGUNAAN TEKNOLOGI INFORMASI:',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
      },
      {
        'id': 1768,
        'field': 'f1768',
        'type': 'rating',
        'question': '20. Tingkat kompetensi PENGGUNAAN TEKNOLOGI INFORMASI yang dibutuhkan:',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
      },
      // KOMUNIKASI
      {
        'id': 1769,
        'field': 'f1769',
        'type': 'rating',
        'question': '21. Pada saat lulus, tingkat kompetensi Anda dalam KOMUNIKASI:',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
      },
      {
        'id': 1770,
        'field': 'f1770',
        'type': 'rating',
        'question': '22. Tingkat kompetensi KOMUNIKASI yang dibutuhkan dalam pekerjaan:',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
      },
      // KERJA SAMA TIM
      {
        'id': 1771,
        'field': 'f1771',
        'type': 'rating',
        'question': '23. Pada saat lulus, tingkat kompetensi Anda dalam KERJA SAMA TIM:',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
      },
      {
        'id': 1772,
        'field': 'f1772',
        'type': 'rating',
        'question': '24. Tingkat kompetensi KERJA SAMA TIM yang dibutuhkan dalam pekerjaan:',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
      },
      // PENGEMBANGAN DIRI
      {
        'id': 1773,
        'field': 'f1773',
        'type': 'rating',
        'question': '25. Pada saat lulus, tingkat kompetensi Anda dalam PENGEMBANGAN DIRI:',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
      },
      {
        'id': 1774,
        'field': 'f1774',
        'type': 'rating',
        'question': '26. Tingkat kompetensi PENGEMBANGAN DIRI yang dibutuhkan dalam pekerjaan:',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
      },
      
      // === BAGIAN 4: METODE PEMBELAJARAN (Pilih 3 metode terpenting = 3 pertanyaan) ===
      {
        'id': 21,
        'field': 'f21',
        'type': 'rating',
        'question': '27. Seberapa besar penekanan PERKULIAHAN di program studi Anda membantu pekerjaan?',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
      },
      {
        'id': 24,
        'field': 'f24',
        'type': 'rating',
        'question': '28. Seberapa besar penekanan MAGANG di program studi Anda membantu pekerjaan?',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
      },
      {
        'id': 25,
        'field': 'f25',
        'type': 'rating',
        'question': '29. Seberapa besar penekanan PRAKTIKUM di program studi Anda membantu pekerjaan?',
        'scale': 5,
        'labels': ['Sangat Rendah', 'Sangat Tinggi'],
      },
      
      // === BAGIAN 5: PENCARIAN KERJA (1 pertanyaan komprehensif) ===
      {
        'id': 404,
        'field': 'f404',
        'type': 'yes_no',
        'question': '30. Apakah Anda menggunakan internet/iklan online dalam mencari pekerjaan pertama?',
        'options': ['Ya', 'Tidak'],
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
    
    return allSurveys;
  }
}