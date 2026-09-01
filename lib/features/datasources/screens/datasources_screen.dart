import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_service.dart';
import '../../../core/constants/api_constants.dart';

class DatasourcesScreen extends ConsumerStatefulWidget {
  const DatasourcesScreen({super.key});

  @override
  ConsumerState<DatasourcesScreen> createState() => _DatasourcesScreenState();
}

class _DatasourcesScreenState extends ConsumerState<DatasourcesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _datasources = [];
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadDatasources();
  }

  // Load the available data sources.
  Future<void> _loadDatasources() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.datasources);
      setState(() {
        _datasources = response.data['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Upload a CSV file.
  Future<void> _uploadCSV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null) return;

    setState(() => _isUploading = true);

    try {
      final file = result.files.first;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path!, filename: file.name),
      });

      await _apiService.postForm(ApiConstants.upload, formData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV uploaded successfully! ✅'),
            backgroundColor: Color(0xFF00C896),
          ),
        );
      }

      await _loadDatasources();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload failed ❌'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Text(
          'Data Sources',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadDatasources,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _datasources.isEmpty
          ? _buildEmptyState()
          : _buildDatasourcesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _uploadCSV,
        backgroundColor: const Color(0xFF6C63FF),
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.upload_file, color: Colors.white),
        label: Text(
          _isUploading ? 'Uploading...' : 'Upload CSV',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'No data sources yet',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a CSV file to get started',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDatasourcesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _datasources.length,
      itemBuilder: (context, index) {
        final ds = _datasources[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.table_chart, color: Color(0xFF6C63FF)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ds['name'] ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${ds['row_count'] ?? 0} rows · ${ds['status']}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Data-source status indicator.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ds['status'] == 'ready'
                      ? const Color(0xFF00C896).withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ds['status'] ?? 'unknown',
                  style: TextStyle(
                    color: ds['status'] == 'ready'
                        ? const Color(0xFF00C896)
                        : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
