import 'package:flutter/material.dart'; // Import paket flutter untuk membangun UI
import 'package:http/http.dart' as http; // Import paket http untuk melakukan permintaan HTTP
import 'dart:convert'; // Import pustaka dart:convert untuk mengonversi JSON
import 'package:flutter_bloc/flutter_bloc.dart'; // Import paket flutter_bloc untuk manajemen state

class University {
  final String name; // Deklarasi atribut name dengan tipe data String
  final String website; // Deklarasi atribut website dengan tipe data String

  University({required this.name, required this.website}); // Deklarasi konstruktor untuk kelas University dengan parameter wajib name dan website

  factory University.fromJson(Map<String, dynamic> json) { // Deklarasi factory method fromJson untuk mengonversi JSON menjadi instance University
    return University( // Kembalikan instance University dengan nilai atribut yang diambil dari JSON
      name: json['name'] ?? '', // Ambil nilai 'name' dari JSON, jika tidak ada, kembalikan string kosong
      website: json['web_pages'] != null && json['web_pages'].length > 0 // Periksa apakah 'web_pages' ada dan memiliki panjang lebih dari 0
          ? json['web_pages'][0] // Jika ya, ambil nilai pertama dari 'web_pages'
          : '', // Jika tidak, kembalikan string kosong
    );
  }
}
//Events
abstract class UniversityEvent {} // Deklarasi kelas abstrak UniversityEvent

class FetchUniversitiesEvent extends UniversityEvent { // Deklarasi kelas FetchUniversitiesEvent yang merupakan turunan dari UniversityEvent
  final String country; // Deklarasi atribut country dengan tipe data String

  FetchUniversitiesEvent(this.country); // Deklarasi konstruktor untuk event FetchUniversitiesEvent dengan parameter wajib country
}
//Bloc
class UniversityBloc extends Bloc<UniversityEvent, List<University>> { // Deklarasi kelas UniversityBloc yang merupakan turunan dari Bloc dengan parameter event UniversityEvent dan state List<University>
  UniversityBloc() : super([]) { // Deklarasi konstruktor untuk UniversityBloc dengan inisialisasi state awal berupa list kosong
    on<FetchUniversitiesEvent>(_fetchUniversities); // Menangani event FetchUniversitiesEvent dengan memanggil method _fetchUniversities
  }

  Future<void> _fetchUniversities( // Deklarasi method async _fetchUniversities untuk mengambil data universitas dari API
    FetchUniversitiesEvent event, // Parameter event bertipe FetchUniversitiesEvent
    Emitter<List<University>> emit, // Parameter emit bertipe Emitter untuk memancarkan perubahan state
  ) async {
    try {
      final universities = await _fetchUniversitiesFromApi(event.country); // Panggil method _fetchUniversitiesFromApi untuk mengambil data universitas
      emit(universities); // Memancarkan daftar universitas
    } catch (e) {
      print('Error: $e'); // Tangani kesalahan dengan mencetak pesan error
      emit([]); // Memancarkan list kosong jika terjadi kesalahan
    }
  }

  Future<List<University>> _fetchUniversitiesFromApi(String country) async { // Deklarasi method async _fetchUniversitiesFromApi untuk melakukan permintaan HTTP ke API universitas
    final response = await http.get( // Panggil method get dari paket http untuk melakukan permintaan GET
        Uri.parse('http://universities.hipolabs.com/search?country=$country')); // URL endpoint API yang diambil berdasarkan negara

    if (response.statusCode == 200) { // Periksa apakah permintaan berhasil (kode status 200)
      final List<dynamic> data = jsonDecode(response.body); // Dekode respon JSON menjadi list dinamis
      return data.map((json) => University.fromJson(json)).toList(); // Konversi data JSON menjadi list objek University menggunakan method fromJson
    } else {
      throw Exception('Failed to load universities'); // Lebihankan pengecualian jika gagal memuat universitas
    }
  }
}

void main() {
  runApp(
    MaterialApp(
      title: 'Menampilkan Universitas dan Situs', // Judul aplikasi
      home: BlocProvider( // Menyediakan BlocProvider di tingkat atas untuk UniversityBloc
        create: (BuildContext context) => UniversityBloc(), // Membuat instance UniversityBloc dan memberikannya ke BlocProvider
        child: MyApp(), // Widget utama aplikasi
      ),
    ),
  );
}

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
            CountryDropdown(), // Tampilkan widget CountryDropdown
            SizedBox(height: 20), // Spasi vertikal
            Expanded(
              child: UniversityList(), // Tampilkan widget UniversityList
            ),
          ],
        ),
      ),
    );
  }
}

class CountryDropdown extends StatefulWidget { // Deklarasi kelas CountryDropdown sebagai StatefulWidget
  @override
  _CountryDropdownState createState() => _CountryDropdownState(); // Membuat instance state dari _CountryDropdownState
}

class _CountryDropdownState extends State<CountryDropdown> { // Deklarasi kelas state _CountryDropdownState sebagai State
  String? selectedCountry; // Deklarasi variabel selectedCountry untuk menyimpan negara yang dipilih

  @override
  Widget build(BuildContext context) {
    final universityBloc = BlocProvider.of<UniversityBloc>(context); // Mendapatkan instance UniversityBloc dari BlocProvider

    return DropdownButton<String>( // Widget DropdownButton untuk memilih negara
      value: selectedCountry, // Nilai dropdown yang dipilih
      onChanged: (String? newValue) { // Handler ketika nilai dropdown berubah
        setState(() { // Set state untuk memperbarui tampilan
          selectedCountry = newValue; // Update nilai selectedCountry
        });
        if (newValue != null) {
          universityBloc.add(FetchUniversitiesEvent(newValue)); // Panggil event FetchUniversitiesEvent dengan negara yang dipilih
        }
      },
      items: CountryBloc.aseanCountries // Item-item dalam dropdown berdasarkan daftar negara ASEAN
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value), // Teks yang ditampilkan dalam dropdown
        );
      }).toList(),
    );
  }
}

class UniversityList extends StatelessWidget { // Deklarasi kelas UniversityList sebagai StatelessWidget
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UniversityBloc, List<University>>( // Widget BlocBuilder untuk membangun UI berdasarkan state UniversityBloc
      builder: (context, universities) { // Builder untuk membangun UI
        if (universities.isEmpty) { // Jika daftar universitas kosong
          return CircularProgressIndicator(); // Tampilkan indikator loading
        } else {
          return ListView.builder( // Tampilkan daftar universitas dalam ListView
            itemCount: universities.length, // Jumlah item dalam daftar universitas
            itemBuilder: (context, index) {
              return Container( // Container untuk setiap item dalam daftar universitas
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

class CountryBloc { // Deklarasi kelas CountryBloc
  static const List<String> aseanCountries = [ // Daftar negara-negara ASEAN
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
  ];
}
