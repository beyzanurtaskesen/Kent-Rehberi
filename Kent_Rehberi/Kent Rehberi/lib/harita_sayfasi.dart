import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model: eczaneler view veya sade tablo varsayımıyla çalışır.
/// Tablo adı: `eczaneler`
/// Kolonlar: id, eczane, nobet_turu, ilce, mahalle, adres
///
/// Bu sınıf, Supabase’ten gelen nöbetçi eczane verisini temsil eder.
//
// fromMap ile Supabase sorgusundan gelen JSON verisini bu sınıfa dönüştürüyor.
class Eczane {
  final int id;
  final String eczane;
  final String nobetTuru;
  final String ilce;
  final String mahalle;
  final String adres;

  Eczane({  //Eczane sınıfının kurucusu.requıred zorunlu oldugunu belırtıyor.
    required this.id,
    required this.eczane,
    required this.nobetTuru,
    required this.ilce,
    required this.mahalle,
    required this.adres,
  });
  factory Eczane.fromMap(Map<String, dynamic> map) {  //Factory constructorı.Gelen verileri eczane nesnesine dönüştürüyor.
    return Eczane(
      id: map['id'] is int //map ıd ınt  dırek kullanılır degılse hata verır.
          ? map['id']
          : int.tryParse('${map['id']}') ??
          0, // Güvenli cast, yoksa 0 (dilersen hata da fırlatabilirsin)
      eczane: map['eczane']?.toString() ?? '',
      nobetTuru: map['nobet_turu']?.toString() ?? '',
      ilce: map['ilce']?.toString() ?? '',
      mahalle: map['mahalle']?.toString() ?? '',
      adres: map['adres']?.toString() ?? '',
    );
  }
}
Future<List<Eczane>> fetchEczaneler() async {
  try {
    final data = await Supabase.instance.client.from('eczaneler').select();
    // Supabase.instance.client: Supabase baglantısını temsıl eder.
    //From ecaneler kısmı eczaneler tablosunu hedef alır.
    //Select tablodakı tum satırları secer.
    //await : Asenkron verı cekme ıslemı burada gerceklesır.

    if (data == null || data is! List) return [];
    //verı boşsa veya lıste degılse bos lıste donderır.

    return (data as List).map((e) {
      if (e is Map<String, dynamic>) {
        return Eczane.fromMap(e);
      } else if (e is Map) {
        return Eczane.fromMap(Map<String, dynamic>.from(e));
      } else {
        throw Exception('Beklenmeyen veri formatı: $e');
      }
    }).toList();
  } catch (e) {
    throw Exception('Supabase sorgu hatası: $e');
  }
}
class NobetciEczanelerSheet extends StatelessWidget {
  const NobetciEczanelerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Eczane>>(
      future: fetchEczaneler(), //Supabase’ten verileri çeken fonksiyon (asenkron).
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) { //snapshot → fetchEczaneler() fonksiyonunun durumunu (loading, success, error) ve veriyi tutar.
          return SizedBox(
            height: 300,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 300,
            child: Center(child: Text('Hata: ${snapshot.error}')),
          );
        }
        final eczaneler = snapshot.data ?? [];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Nöbetçi Eczaneler",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: eczaneler.isEmpty
                    ? const Center(child: Text("Kayıt bulunamadı."))
                    : ListView.builder(
                  itemCount: eczaneler.length,
                  itemBuilder: (context, i) {
                    final eczane = eczaneler[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(eczane.eczane),
                        subtitle: Text(
                          "${eczane.adres}\n${eczane.ilce} - ${eczane.mahalle}\nNöbet: ${eczane.nobetTuru}",
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
class HaritaSayfasi extends StatefulWidget {
  const HaritaSayfasi({super.key});
  @override
  State<HaritaSayfasi> createState() => _HaritaSayfasiState();
}
class _HaritaSayfasiState extends State<HaritaSayfasi> {
  final MapController _mapController = MapController();
  LatLng merkezKonum = LatLng(38.7228, 35.4857); // Kayseri Cumhuriyet Meydanı

  bool aramaAcik = false;
  final TextEditingController aramaController = TextEditingController();

  // İlçe listesi
  final List<String> kayseriIlceleri = [
    "Akkışla",
    "Bünyan",
    "Develi",
    "Felahiye",
    "Hacılar",
    "İncesu",
    "Kocasinan",
    "Melikgazi",
    "Özvatan",
    "Pınarbaşı",
    "Sarıoğlan",
    "Sarız",
    "Talas",
    "Tomarza",
    "Yahyalı",
    "Yeşilhisar",
  ];

  // Fallback mahalleler
  final List<String> fallbackMahalleler = [
    'Akkışla',
    'Akin',
    'Alevkışla',
    'Ganişeyh',
    'Girinci',
    'Gömürgen Yeni',
    'Gömürgen',
    'Gümüşsu',
    'Kululu',
    'Manavuz',
    'Ortaköy',
    'Şen',
    'Uğurlu',
    'Yenimahalle',
    'Yeşil',
    'Yukarı',
    'Ağcalı',
    'Akçatı',
    'Akmescit',
    'Asmakaya',
    'Bayramlı',
    'Burhaniye',
    'Büyüktuzhisar',
    'Camiicedit',
    'Camiikebir',
    'Cumhuriyet',
    'Dağardı',
    'Danişmend',
    'Dervişağa',
    'Doğanlar',
    'Ekinciler',
    'Elbaşı',
    'Emirören',
    'Fatih',
    'Gergeme',
    'Girveli',
    'Güllüce',
    'Hazarşah',
    'İbrahimbey',
    'İğdecik',
    'Kahveci',
    'Karacaören',
    'Karahıdırlı',
    'Karakaya',
    'Karatay',
    'Kardeşler',
    'Köprübaşı',
    'Kösehacılı',
    'Koyunabdal',
    'Musaşeyh',
    'Pirahmet',
    'Sağlık',
    'Samağır',
    'Sıvgın',
    'Sultanhanı',
    'Sümer',
    'Topsöğüt',
    'Yaylacık',
    'Yazıbaşı',
    'Yedek',
    'Yenihayat',
    'Yeşilyurt',
    'Yüzevler',
    'Zile',
  ];
  // İlçeye özel mahalleler (örnek)
  final Map<String, List<String>> mahalleListesi = {
    'Melikgazi': [
      "19 Mayıs",
      "30 Ağustos",
      "Ağırnas",
      "Alpaslan",
      "Altınoluk",
      "Anafartalar",
      "Anbar",
      "Aydınlıkevler",
      "Bağpınar",
      "Bahçelievler",
      "Battalgazi",
      "Becen",
      "Büyükbürüngüz",
      "Cumhuriyet",
      "Danişmentgazi",
      "Demokrasi",
      "Eğribucak",
      "Erenköy",
      "Esentepe",
      "Esenyurt",
      "Fatih",
      "Germir",
      "Gesi Fatih",
      "Gesi",
      "Gökkent",
      "Gültepe",
      "Gülük",
      "Gürpınar",
      "Güzelköy",
      "Hisarcık",
      "Hunat",
      "Hürriyet",
      "İldem Cumhuriyet",
      "Kayabağ",
      "Kazımkarabekir",
      "Keykubat",
      "Kılıçaslan",
      "Kıranardı",
      "Kocatepe",
      "Köşk",
      "Küçükbürüngüz",
      "Mimarsinan",
      "Osman Kavuncu",
      "Osmanlı",
      "Sakarya",
      "Sarımsaklı",
      "Selçuklu",
      "Selimiye",
      "Şirintepe",
      "Subaşı",
      "Tacettinveli",
      "Tavlusun",
      "Tınaztepe",
      "Turan",
      "Vekse",
      "Yeniköy",
      "Yeşilyurt",
      "Yıldırım Beyazıt",
    ],
    'Kocasinan': ['Dumlupınar', 'Yunusemre', 'Göztepe', 'Selimiye', 'Selçuklu'],
    'Talas': ['Yavuz Selim', 'Yeniköy', 'Yenişehir', 'Yeşil'],
    'Bünyan': [
      'Akkışla',
      'Akin',
      'Alevkışla',
      'Ganişeyh',
      'Girinci',
      'Gömürgen Yeni',
      'Gömürgen',
      'Gümüşsu',
      'Kululu'
    ],
    'Develi': [
      'Abdulbaki',
      'Alpaslan',
      'Aşağıeverek',
      'Aşık Seyrani',
      'Ayşepınar',
      'Ayvazhacı',
      'Bahçebaşı',
      'Çataloluk'
    ],
  };
  final List<Map<String, dynamic>> genelAramaListesi = [
    {
      "baslik": "Adrese Git",
      "ikon": Icons.location_on,
      "renk": Colors.redAccent
    },
    {
      "baslik": "Parsel Sorgulama",
      "ikon": Icons.map,
      "renk": Colors.blueAccent
    },
    {
      "baslik": "Nöbetçi Eczaneler",
      "ikon": Icons.local_pharmacy,
      "renk": Colors.green
    },
    {
      "baslik": "Satılacak Parseller",
      "ikon": Icons.sell,
      "renk": Colors.deepPurpleAccent
    },
    {
      "baslik": "Bina Arama",
      "ikon": Icons.apartment,
      "renk": Colors.orangeAccent
    },
    {"baslik": "Önemli Yer Arama", "ikon": Icons.place, "renk": Colors.teal},
    {"baslik": "Muhtarlar", "ikon": Icons.people, "renk": Colors.indigo},
    {
      "baslik": "Vefat İlanları",
      "ikon": Icons.airline_seat_flat,
      "renk": Colors.grey
    },
    {"baslik": "Mezar Yeri Arama", "ikon": Icons.grass, "renk": Colors.brown},
    {"baslik": "Pazar Yerleri", "ikon": Icons.store, "renk": Colors.amber},
    {
      "baslik": "Mezarlık Arama",
      "ikon": Icons.account_tree,
      "renk": Colors.teal
    },
    {
      "baslik": "Mezar Tapu Arama",
      "ikon": Icons.description,
      "renk": Colors.brown
    },
    {
      "baslik": "Elektrik Direkleri",
      "ikon": Icons.electrical_services,
      "renk": Colors.blueAccent
    },
  ];
  final List<String> digerBasliklar = [
    "Altlıklar",
    "Diğer Katmanlar",
    "İmar Planları",
    "Önemli Yerler (POI)",
    "Pazar Yerleri",
    "Özel Hiz. ve Ustalar",
    "Erciyes Turizm Mer.",
    "Polis",
    "Altyapı",
  ];
  String seciliSekme = "Genel Arama";

  // Ortak Nominatim arama fonksiyonu
  Future<void> _nominatimSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _hataGoster("Aranacak ifade boş olamaz.");
      return;
    }
   //Girilen metnin başındaki/sonundaki boşluklar silinir.
    final params = {
      'q': trimmed,
      'format': 'json',
      'limit': '1',
      'countrycodes': 'tr',
      'addressdetails': '1',
    };

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
   // parametrelerle bir HTTPS adresi (Uri) oluşturuluyor
    debugPrint('Nominatim sorgu URI: $uri');
    //URL Yİ debug konsoluna yazdırıyor.

    final response = await http.get(uri, headers: {

     // Asagıda oluşturulan uri adresine GET isteği gönderiliyor.

    //  Bu, adresi sorgulamak için Nominatim’e veri gönderme işlemidir.

     // headers içinde User-Agent eklenmesi zorunlu;aksi halde API erişimi engellenebilir.
      'User-Agent': 'KayseriHaritasi/1.0 (iletisim@ornek.com)',
    });

    if (response.statusCode == 200) {

      //HTTP basarılı oldu mu dıye kontrol eder.
      final List data = json.decode(response.body);
      if (data.isNotEmpty) {
        try {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final yeniKonum = LatLng(lat, lon);

          setState(() {
            merkezKonum = yeniKonum;
          });

          _mapController.move(yeniKonum, 16.0);
          return;
        } catch (e) {
          _hataGoster('Konum parse edilemedi: $e');
          return;
        }
      } else {
        debugPrint(
            'İlk aramada sonuç yok, countrycodes olmadan tekrar deneniyor.');
        final fallbackUri =
        Uri.https('nominatim.openstreetmap.org', '/search', {
          'q': trimmed,
          'format': 'json',
          'limit': '1',
          'addressdetails': '1',
        });
        debugPrint('Fallback URI: $fallbackUri');
        final fallbackResp = await http.get(fallbackUri, headers: {
          'User-Agent': 'KayseriHaritasi/1.0 (iletisim@ornek.com)',
        });
        if (fallbackResp.statusCode == 200) { //if (fallbackResp.statusCode == 200) {
          final List fallbackData = json.decode(fallbackResp.body);
          if (fallbackData.isNotEmpty) {
            try {
              final lat = double.parse(fallbackData[0]['lat']);
              final lon = double.parse(fallbackData[0]['lon']);
              final yeniKonum = LatLng(lat, lon);
              setState(() {
                merkezKonum = yeniKonum;
              });
              _mapController.move(yeniKonum, 16.0);
              return;
            } catch (e) {
              _hataGoster('Fallback konum parse edilemedi: $e');
              return;
            }
          }
        }
        _hataGoster("Kayseri'de böyle bir yer bulunamadı.");
      }
    } else {
      _hataGoster("Sunucu hatası: ${response.statusCode}");
    }
  }
  void _hataGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }
  // Yardımcı görsel bileşenler
  Widget _buildHeader(String baslik, VoidCallback onClose) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          baslik,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        IconButton(icon: const Icon(Icons.close), onPressed: onClose),
      ],
    );
  }
  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
  Widget _buildPlaceholderDetail(String baslik) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(baslik, () => Navigator.of(context).pop()),
            const SizedBox(height: 16),
            _buildCardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "$baslik için veri henüz sağlanmadı.",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24),
                    ),
                    child: const Text(
                      "İçerik Yok",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Küçük dikey araç butonu (estetik)
  Widget _smallToolButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE1E8F0)),
                ),
                child: Icon(icon, size: 18, color: Colors.blueGrey[700]),
              ),
              if (label != null && label.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 8, height: 1.0),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  // Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: merkezKonum,
              zoom: 13.0,
              interactiveFlags: InteractiveFlag.all,
            ),
            children: [
              TileLayer(
                urlTemplate:
                "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ["a", "b", "c"],
                userAgentPackageName: 'com.example.kayseri_haritasi',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: merkezKonum,
                    width: 80,
                    height: 80,
                    builder: (ctx) => const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Arama kutusu
          Positioned(
            top: 40,
            left: 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: aramaAcik ? 280 : 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(aramaAcik ? 15 : 25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        aramaAcik = !aramaAcik;
                        if (!aramaAcik) aramaController.clear();
                      });
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue[400],
                      ),
                      child: const Icon(Icons.search, color: Colors.white),
                    ),
                  ),
                  if (aramaAcik)
                    Expanded(
                      child: Padding(
                        padding:
                        const EdgeInsets.only(left: 14, right: 8),
                        child: TextField(
                          controller: aramaController,
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _nominatimSearch(value);
                              FocusScope.of(context).unfocus();
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: "Kayseri'de yer ara...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Sol-alt araç çubuğu
          Positioned(
            bottom: 12,
            left: 8,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withOpacity(0.9),
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDCE7F0)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _smallToolButton(
                      icon: Icons.insert_drive_file,
                      tooltip: 'SHP',
                      onTap: () {},
                    ),
                    const SizedBox(height: 6),
                    _smallToolButton(
                      icon: Icons.folder,
                      tooltip: 'Klasör',
                      onTap: () {},
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE1E8F0),
                      ),
                    ),
                    _smallToolButton(
                      icon: Icons.add,
                      tooltip: 'Yakınlaştır',
                      onTap: () {
                        _mapController.move(
                            _mapController.center, _mapController.zoom + 1);
                      },
                    ),
                    const SizedBox(height: 4),
                    _smallToolButton(
                      icon: Icons.remove,
                      tooltip: 'Uzaklaştır',
                      onTap: () {
                        _mapController.move(
                            _mapController.center, _mapController.zoom - 1);
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE1E8F0),
                      ),
                    ),
                    _smallToolButton(
                      icon: Icons.edit,
                      tooltip: 'Çizim',
                      onTap: () {},
                    ),
                    const SizedBox(height: 4),
                    _smallToolButton(
                      icon: Icons.crop_square,
                      tooltip: 'Poligon',
                      onTap: () {},
                    ),
                    const SizedBox(height: 4),
                    _smallToolButton(
                      icon: Icons.delete,
                      tooltip: 'Sil',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Alt panel tetikleyici
          Positioned(
            bottom: 0,
            left: MediaQuery.of(context).size.width / 2 - 30,
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => buildAltPanel(),
                );
              },
              child: Container(
                width: 70,
                height: 25,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.keyboard_arrow_up,
                      size: 20, color: Colors.black45),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget buildAltPanel() {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildSekmeButton("Genel Arama", setModalState),
                      const SizedBox(width: 12),
                      buildSekmeButton("Diğer", setModalState),
                    ],
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: seciliSekme == "Genel Arama"
                        ? buildGenelAramaGrid(scrollController)
                        : buildDigerListe(scrollController),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  Widget buildSekmeButton(
      String label, void Function(void Function()) setModalState) {
    final secili = seciliSekme == label;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: secili ? Colors.white : Colors.black87,
        backgroundColor: secili ? Colors.blueAccent : Colors.grey[300],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        setModalState(() {
          seciliSekme = label;
        });
      },
      child: Text(label),
    );
  }
  Widget buildGenelAramaGrid(ScrollController controller) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        controller: controller,
        itemCount: genelAramaListesi.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final kategori = genelAramaListesi[index];
          return GestureDetector(
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) =>
                    buildKutuDetay(context, kategori['baslik'] ?? ''),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (kategori['renk'] as Color).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (Rect bounds) {
                      final renk =
                          kategori['renk'] as Color? ?? Colors.blueAccent;
                      return LinearGradient(
                        colors: [renk.withOpacity(0.7), renk],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: Icon(
                      kategori['ikon'],
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    kategori['baslik'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Widget buildDigerListe(ScrollController controller) {
    return ListView.builder(
      controller: controller,
      itemCount: digerBasliklar.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(digerBasliklar[index]),
          onTap: () {
            Navigator.pop(context);
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) =>
                  buildKutuDetay(context, digerBasliklar[index]),
            );
          },
        );
      },
    );
  }
  Widget buildKutuDetay(BuildContext context, String baslik) {
    if (baslik == "Bina Arama") {
      String? seciliIlce;
      String? seciliMahalle;
      final TextEditingController binaAdiController = TextEditingController();
      final TextEditingController binaKimlikController =
      TextEditingController();

      return StatefulBuilder(builder: (context, setModalState) {
        Future<void> araBina() async {
          if (seciliIlce == null || seciliMahalle == null) {
            _hataGoster('Lütfen ilçe ve mahalle seçiniz.');
            return;
          }
          final binaAdi = binaAdiController.text.trim();
          final binaKimlik = binaKimlikController.text.trim();
          if (binaAdi.isEmpty && binaKimlik.isEmpty) {
            _hataGoster('Bina adı veya kimlik no giriniz.');
            return;
          }
          String adresQuery;
          if (binaKimlik.isNotEmpty) {
            adresQuery =
            '$binaKimlik, $seciliMahalle, $seciliIlce, Kayseri, Türkiye';
          } else {
            adresQuery =
            '$binaAdi, $seciliMahalle, $seciliIlce, Kayseri, Türkiye';
          }
          Navigator.of(context).pop();
          await _nominatimSearch(adresQuery);
        }
        final mahalleler = seciliIlce != null
            ? (mahalleListesi[seciliIlce] ?? fallbackMahalleler)
            : <String>[];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(baslik, () => Navigator.of(context).pop()),
                const SizedBox(height: 16),
                _buildCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "İlçe",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: kayseriIlceleri
                            .map((ilce) => DropdownMenuItem(
                          value: ilce,
                          child: Text(ilce),
                        ))
                            .toList(),
                        value: seciliIlce,
                        onChanged: (val) {
                          setModalState(() {
                            seciliIlce = val;
                            seciliMahalle = null;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Mahalle",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: mahalleler
                            .map((mah) => DropdownMenuItem(
                          value: mah,
                          child: Text(mah),
                        ))
                            .toList(),
                        value: seciliMahalle,
                        onChanged: (val) {
                          setModalState(() {
                            seciliMahalle = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: binaAdiController,
                        decoration: InputDecoration(
                          labelText: "Bina Adı",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: binaKimlikController,
                        decoration: InputDecoration(
                          labelText: "Bina Kimlik No",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: araBina,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                        ),
                        child: const Text(
                          "Ara",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      });
    } else if (baslik == "Adrese Git" || baslik == "Önemli Yer Arama") {
      String? seciliIlce;
      String? seciliMahalle;
      String? seciliYol;
      final TextEditingController kapiNoController = TextEditingController();
      final TextEditingController serbestController = TextEditingController();

      final List<String> fallbackYollar = [
        "Atatürk Caddesi",
        "Cumhuriyet",
        "İstiklal Caddesi",
        "Mevlana Caddesi",
        "Fatih Sokak",
        "Zafer Sokak",
        "Yeni Caddesi",
        "Bahçe Caddesi",
        "Barbaros Caddesi",
        "Şehitler Caddesi",
      ];
      return StatefulBuilder(builder: (context, setModalState) {
        Future<void> araAdres() async {
          String query = "";
          if (baslik == "Önemli Yer Arama") {
            final yazi = serbestController.text.trim();
            if (yazi.isEmpty) {
              _hataGoster("Aranacak yer giriniz.");
              return;
            }
            query = "$yazi Kayseri";
          } else {
            if (seciliIlce == null) {
              _hataGoster("İlçe seçiniz.");
              return;
            }
            if (kapiNoController.text.trim().isNotEmpty &&
                seciliYol != null &&
                seciliMahalle != null) {
              query =
              "${kapiNoController.text.trim()} $seciliYol, $seciliMahalle, $seciliIlce, Kayseri, Türkiye";
            } else if (seciliYol != null &&
                seciliMahalle != null &&
                seciliIlce != null) {
              query =
              "$seciliYol, $seciliMahalle, $seciliIlce, Kayseri, Türkiye";
            } else if (seciliMahalle != null && seciliIlce != null) {
              query = "$seciliMahalle, $seciliIlce, Kayseri, Türkiye";
            } else {
              query = "$seciliIlce, Kayseri, Türkiye";
            }
          }
          Navigator.of(context).pop();
          await _nominatimSearch(query);
        }
        final mahalleler = seciliIlce != null
            ? (mahalleListesi[seciliIlce] ?? fallbackMahalleler)
            : <String>[];
        final yollar = seciliMahalle != null ? fallbackYollar : <String>[];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(baslik, () => Navigator.of(context).pop()),
                const SizedBox(height: 16),
                _buildCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (baslik == "Adrese Git") ...[
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "İlçe",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: kayseriIlceleri
                              .map((ilce) => DropdownMenuItem(
                            value: ilce,
                            child: Text(ilce),
                          ))
                              .toList(),
                          value: seciliIlce,
                          onChanged: (val) {
                            setModalState(() {
                              seciliIlce = val;
                              seciliMahalle = null;
                              seciliYol = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "Mahalle",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: mahalleler
                              .map((mah) => DropdownMenuItem(
                            value: mah,
                            child: Text(mah),
                          ))
                              .toList(),
                          value: seciliMahalle,
                          onChanged: (val) {
                            setModalState(() {
                              seciliMahalle = val;
                              seciliYol = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "Yol",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: yollar
                              .map((yol) => DropdownMenuItem(
                            value: yol,
                            child: Text(yol),
                          ))
                              .toList(),
                          value: seciliYol,
                          onChanged: (val) {
                            setModalState(() {
                              seciliYol = val;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: kapiNoController,
                          decoration: InputDecoration(
                            labelText: "Kapı No",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ] else if (baslik == "Önemli Yer Arama") ...[
                        TextField(
                          controller: serbestController,
                          decoration: InputDecoration(
                            labelText: "Önemli yer adı",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: araAdres,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                        ),
                        child: Text(
                          baslik == "Adrese Git"
                              ? "Haritada Göster"
                              : "Yer Bul",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      });
    } else if (baslik == "Nöbetçi Eczaneler") {
      return const NobetciEczanelerSheet();
    } else {
      return _buildPlaceholderDetail(baslik);
    }
  }
  Widget buildOvalBox({
    required double width,
    required double height,
    String label = "",
  }) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}
