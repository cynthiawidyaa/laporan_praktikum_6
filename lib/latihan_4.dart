import 'package:flutter/material.dart'; // Import paket flutter untuk membangun UI
import 'package:http/http.dart' as http; // Import paket http untuk melakukan permintaan HTTP
import 'dart:convert'; // Import pustaka dart:convert untuk mengonversi JSON
import 'package:provider/provider.dart'; // Import paket provider untuk manajemen keadaan

// Membuat kumpulan kelas untuk universitas
class University {
  final String name; // Atribut untuk menampung nama universitas
  final String website; // Atribut untuk menampung situs web universitas

  University({required this.name, required this.website}); // Konstruktor untuk kelas University

  // Metode untuk mengonversi JSON menjadi instance dari kelas University
  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'] ?? '',  // Mengambil nilai 'name' dari JSON
      website: json['web_pages'] != null && json['web_pages'].length > 0
          ? json['web_pages'][0] // Mengambil situs web dari JSON, jika ada
          : '', // Jika tidak ada situs web, atur nilai kosong
    );
  }
}

class UniversityProvider with ChangeNotifier {
  late List<University> _universities; // Variabel untuk menyimpan daftar universitas
  late String _selectedCountry; // Variabel untuk menyimpan negara yang dipilih

  UniversityProvider() {
    _universities = []; // Inisialisasi daftar universitas
    _selectedCountry = 'Brunei Darussalam'; // Default country
    fetchUniversities(); // Memanggil metode untuk mengambil data universitas
  }

  List<University> get universities => _universities; // Getter untuk mendapatkan daftar universitas
  String get selectedCountry => _selectedCountry; // Getter untuk mendapatkan negara yang dipilih

  set selectedCountry(String country) {
    _selectedCountry = country; // Mengatur negara yang dipilih
    fetchUniversities(); // Memanggil metode untuk mengambil data universitas sesuai negara yang dipilih
    notifyListeners(); // Memberitahu pendengar bahwa ada perubahan pada state provider
  }

  Future<void> fetchUniversities() async {
    final response = await http.get(
        Uri.parse('http://universities.hipolabs.com/search?country=$_selectedCountry')); // Mengambil data universitas dari API

    if (response.statusCode == 200) { // Jika permintaan berhasil
      List<dynamic> data = json.decode(response.body); // Mendekode data JSON
      _universities = data.map((json) => University.fromJson(json)).toList(); // Mengonversi data JSON menjadi list dari objek University
    } else {
      throw Exception('Failed to load universities'); // Jika permintaan gagal, lemparkan pengecualian
    }
  }
}

void main() {
  runApp( // Memulai aplikasi Flutter
    ChangeNotifierProvider(
      create: (context) => UniversityProvider(), // Membuat provider untuk manajemen state
      child: MyApp(), // Menjalankan aplikasi utama
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Menampilkan Universitas dan Situs', // Judul aplikasi
      home: Scaffold(
        appBar: AppBar(
          title: Text('Menampilkan Universitas dan Situs'), // Judul app bar
        ),
        body: Center(
          child: Column(
            children: [
              CountryDropdown(), // Widget dropdown untuk memilih negara
              Expanded(
                child: UniversityList(), // Widget untuk menampilkan daftar universitas
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CountryDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<UniversityProvider>(context); // Mendapatkan instance dari provider

    return DropdownButton<String>(
      value: provider.selectedCountry, // Nilai dropdown yang dipilih
      onChanged: (String? newValue) {
        provider.selectedCountry = newValue!; // Mengubah negara yang dipilih ketika dropdown diganti
      },
      items: <String>[
        'Brunei Darussalam','Indonesia','Cambodia','Laos','Malaysia','Myanmar','Philippines', 'Singapore', 'Thailand','Vietnam'
      ] // Daftar negara ASEAN
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value), // Teks yang ditampilkan dalam dropdown
        );
      }).toList(),
    );
  }
}

class UniversityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<UniversityProvider>(context); // Mendapatkan instance dari provider

    return FutureBuilder(
      future: provider.fetchUniversities(), // Memanggil metode untuk mengambil data universitas
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Tampilkan indikator loading saat data sedang diambil
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}'); // Tampilkan pesan kesalahan jika terjadi kesalahan
        } else {
          return ListView.builder(
            itemCount: provider.universities.length, // Jumlah item dalam daftar universitas
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(border: Border.all()), // Gaya border container
                padding: const EdgeInsets.all(14), // Padding dalam container
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(provider.universities[index].name), // Tampilkan nama universitas
                    Text(provider.universities[index].website), // Tampilkan situs web universitas
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }
}
