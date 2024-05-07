import 'package:flutter/material.dart'; // Import paket flutter untuk membangun UI
import 'package:http/http.dart' as http; // Import paket http untuk melakukan permintaan HTTP
import 'dart:convert'; // Import pustaka dart:convert untuk mengonversi JSON
import 'package:flutter_bloc/flutter_bloc.dart'; // Import paket flutter_bloc untuk manajemen state

// Definisikan kelas University untuk merepresentasikan data universitas
class University {
  final String name; // Atribut untuk menampung nama universitas
  final String website; // Atribut untuk menampung situs web universitas

  University({required this.name, required this.website}); // Konstruktor untuk kelas University

  // Metode untuk mengonversi JSON menjadi instance dari kelas University
  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'] ?? '', // Mengambil nilai 'name' dari JSON
      website: json['web_pages'] != null && json['web_pages'].length > 0
          ? json['web_pages'][0] // Mengambil situs web dari JSON, jika ada
          : '', // Jika tidak ada situs web, atur nilai kosong
    );
  }
}

// Definisikan kelas UniversityCubit untuk mengelola daftar universitas
class UniversityCubit extends Cubit<List<University>> {
  UniversityCubit() : super([]); // Konstruktor untuk UniversityCubit, inisialisasi dengan daftar kosong

  // Metode untuk mengambil daftar universitas berdasarkan negara yang dipilih
  void fetchUniversities(String country) async {
    final response = await http.get(
        Uri.parse('http://universities.hipolabs.com/search?country=$country')); // Memanggil API untuk mendapatkan data universitas berdasarkan negara

    if (response.statusCode == 200) { // Jika permintaan berhasil
      List<dynamic> data = json.decode(response.body); // Mendekode data JSON
      List<University> universities =
          data.map((json) => University.fromJson(json)).toList(); // Mengonversi data JSON menjadi list dari objek University
      emit(universities); // Memancarkan daftar universitas ke pendengar
    } else {
      throw Exception('Failed to load universities'); // Jika permintaan gagal, lemparkan pengecualian
    }
  }
}

void main() { // Memulai aplikasi Flutter
  runApp(
    MaterialApp(
      title: 'Menampilkan Universitas dan Situs', // Judul aplikasi
      home: MultiBlocProvider( // MultiBlocProvider digunakan untuk menyediakan beberapa BlocProvider
        providers: [
          BlocProvider<UniversityCubit>( // Memberikan instance UniversityCubit kepada provider
            create: (BuildContext context) => UniversityCubit(),
          ),
          BlocProvider<CountryCubit>( // Memberikan instance CountryCubit kepada provider
            create: (BuildContext context) => CountryCubit(),
          ),
        ],
        child: MyApp(), // Menjalankan aplikasi utama
      ),
    ),
  );
}

// MyApp adalah kelas widget utama untuk aplikasi
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menampilkan Universitas dan Situs'), // Judul app bar
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 20), // Spasi vertikal
            CountryDropdown(), // Widget dropdown untuk memilih negara
            SizedBox(height: 20), // Spasi vertikal
            Expanded(
              child: UniversityList(), // Widget untuk menampilkan daftar universitas
            ),
          ],
        ),
      ),
    );
  }
}

// CountryDropdown adalah kelas widget untuk menampilkan dropdown negara
class CountryDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final countryCubit = BlocProvider.of<CountryCubit>(context); // Mendapatkan instance dari CountryCubit
    final universityCubit = BlocProvider.of<UniversityCubit>(context); // Mendapatkan instance dari UniversityCubit

    return BlocBuilder<CountryCubit, String>(
      builder: (context, selectedCountry) {
        return DropdownButton<String>(
          value: selectedCountry, // Nilai dropdown yang dipilih
          onChanged: (String? newValue) {
            countryCubit.selectCountry(newValue!); // Memperbarui negara yang dipilih
            universityCubit.fetchUniversities(newValue); // Mengambil universitas sesuai dengan negara yang dipilih
          },
          items: CountryCubit.aseanCountries
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value), // Teks yang ditampilkan dalam dropdown
            );
          }).toList(),
        );
      },
    );
  }
}

// UniversityList adalah kelas widget untuk menampilkan daftar universitas
class UniversityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UniversityCubit, List<University>>(
      builder: (context, universities) {
        if (universities.isEmpty) {
          return CircularProgressIndicator(); // Tampilkan indikator loading saat data sedang diambil
        } else {
          return ListView.builder(
            itemCount: universities.length, // Jumlah item dalam daftar universitas
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(border: Border.all()), // Gaya border container
                padding: const EdgeInsets.all(14), // Padding dalam container
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(universities[index].name), // Tampilkan nama universitas
                    Text(universities[index].website), // Tampilkan situs web universitas
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

// CountryCubit adalah kelas untuk mengelola negara yang dipilih
class CountryCubit extends Cubit<String> {
  CountryCubit() : super(aseanCountries[0]); // Menginisialisasi negara yang dipilih dengan negara pertama dalam daftar

  static const List<String> aseanCountries = [
    'Brunei Darussalam',
    'Indonesia',
    'Cambodia',
    'Laos',
    'Malaysia',
    'Myanmar',
    'Philippines',
    'Singapore',
    'Thailand',
    'Vietnam'
  ]; // Daftar negara-negara ASEAN

  // Metode untuk memperbarui negara yang dipilih
  void selectCountry(String country) {
    emit(country); // Memancarkan negara yang dipilih
  }
}
