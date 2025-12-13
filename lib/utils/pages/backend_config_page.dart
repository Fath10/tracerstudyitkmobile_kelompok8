import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/network_discovery.dart';

class BackendConfigPage extends StatefulWidget {
  const BackendConfigPage({super.key});

  @override
  State<BackendConfigPage> createState() => _BackendConfigPageState();
}

class _BackendConfigPageState extends State<BackendConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  String _currentBackend = 'Tidak terhubung';
  bool _isDiscovering = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentBackend();
  }

  void _loadCurrentBackend() {
    final current = ApiConfig.baseUrl;
    setState(() {
      _currentBackend = current;
      // Extract IP from URL
      try {
        final uri = Uri.parse(current);
        _ipController.text = uri.host;
      } catch (e) {
        _ipController.text = '';
      }
    });
  }

  Future<void> _autoDiscover() async {
    setState(() {
      _isDiscovering = true;
      _statusMessage = 'Mencari server...';
    });

    try {
      final discovered = await NetworkDiscovery.forceRediscover();
      if (discovered != null) {
        setState(() {
          _currentBackend = discovered;
          _statusMessage = 'Server ditemukan!';
          _isDiscovering = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server ditemukan: $discovered'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _statusMessage = 'Server tidak ditemukan';
          _isDiscovering = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server tidak ditemukan. Coba atur manual.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isDiscovering = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setManualIp() {
    if (_formKey.currentState!.validate()) {
      final ip = _ipController.text.trim();
      final url = 'http://$ip:8000';
      
      ApiConfig.setManualUrl(url);
      
      setState(() {
        _currentBackend = url;
        _statusMessage = 'Backend diatur manual';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backend diatur ke: $url'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfigurasi Backend'),
        backgroundColor: const Color(0xFF0066CC),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current backend status
              Card(
                color: ApiConfig.isProduction ? Colors.green[50] : Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            ApiConfig.isProduction ? Icons.cloud : Icons.developer_mode,
                            color: ApiConfig.isProduction ? Colors.green[700] : Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ApiConfig.isProduction ? 'MODE: PRODUCTION' : 'MODE: DEVELOPMENT',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ApiConfig.isProduction ? Colors.green[700] : Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const Text(
                        'Backend URL:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentBackend,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (_statusMessage.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (ApiConfig.isProduction) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.lock, size: 16, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Production mode: Configuration locked',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Auto-discovery button (disabled in production)
              ElevatedButton.icon(
                onPressed: (ApiConfig.isProduction || _isDiscovering) ? null : _autoDiscover,
                icon: _isDiscovering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(_isDiscovering ? 'Mencari...' : 'Cari Server Otomatis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Divider(),
              
              const SizedBox(height: 24),
              
              // Manual configuration
              const Text(
                'Atau Atur Manual:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'IP Address',
                  hintText: '192.168.0.106',
                  prefixIcon: Icon(Icons.computer),
                  border: OutlineInputBorder(),
                  helperText: 'Masukkan IP address komputer server',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'IP address tidak boleh kosong';
                  }
                  
                  final parts = value.split('.');
                  if (parts.length != 4) {
                    return 'Format IP tidak valid';
                  }
                  
                  for (final part in parts) {
                    final num = int.tryParse(part);
                    if (num == null || num < 0 || num > 255) {
                      return 'Format IP tidak valid';
                    }
                  }
                  
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: ApiConfig.isProduction ? null : _setManualIp,
                icon: const Icon(Icons.save),
                label: const Text('Simpan IP Manual'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Instructions
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Cara Mendapatkan IP:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '1. Buka Command Prompt di komputer server\n'
                        '2. Ketik: ipconfig\n'
                        '3. Cari "IPv4 Address"\n'
                        '4. Masukkan IP tersebut di form di atas\n\n'
                        'Pastikan:\n'
                        '• Backend server berjalan (port 8000)\n'
                        '• HP dan komputer di WiFi yang sama\n'
                        '• Firewall mengizinkan port 8000',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }
}
