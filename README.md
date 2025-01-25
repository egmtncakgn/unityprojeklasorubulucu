# Unity Project Finder

Unity Project Finder, bilgisayarınızda bulunan Unity projelerini kolayca bulmanızı sağlayan bir Windows masaüstü uygulamasıdır. Flutter ile geliştirilmiş olan bu uygulama, seçtiğiniz klasörde ve alt klasörlerinde Unity projelerini otomatik olarak tarar ve listeler.

## Özellikler

- 🔍 Klasörleri hızlı ve etkili şekilde tarama
- 📁 Unity projelerini otomatik tespit etme
- 🚀 Bulunan projeleri tek tıkla açma
- 📊 Detaylı tarama istatistikleri
- ⚡ Paralel işleme ile hızlı tarama
- 🛡️ Sistem klasörlerini otomatik atlama
- 🌙 Karanlık mod desteği

## Kurulum

### Gereksinimler

- Flutter SDK (en son versiyon)
- Windows işletim sistemi
- Git (opsiyonel)

### Adımlar

1. Projeyi klonlayın veya indirin:
```bash
git clone https://github.com/yourusername/unity-project-finder.git
```

2. Proje klasörüne gidin:
```bash
cd unity-project-finder
```

3. Bağımlılıkları yükleyin:
```bash
flutter pub get
```

4. Uygulamayı çalıştırın:
```bash
flutter run -d windows
```

## Kullanım

1. Uygulamayı başlatın
2. "Klasör Seç" butonuna tıklayın
3. Taramak istediğiniz klasörü seçin
4. Uygulama otomatik olarak Unity projelerini tarayacak ve listeleyecektir
5. Bulunan projeleri açmak için liste öğelerindeki "Klasörü Aç" butonunu kullanın

## Bağımlılıklar

```yaml
dependencies:
  flutter:
    sdk: flutter
  file_picker: ^6.1.1
  window_size:
    git:
      url: https://github.com/google/flutter-desktop-embedding.git
      path: plugins/window_size
```

## Özellik ve Katkılar

Bu proje açık kaynaklıdır ve katkılara açıktır. Özellik istekleri ve hata raporları için GitHub Issues'ı kullanabilirsiniz.

### Yapılacaklar Listesi

- [ ] Proje versiyonlarını görüntüleme
- [ ] Projeleri favorilere ekleme
- [ ] Son aranan klasörleri hatırlama
- [ ] Proje boyutlarını gösterme
- [ ] Çoklu dil desteği

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakınız.

## İletişim

Sorularınız ve önerileriniz için [GitHub Issues](https://github.com/yourusername/unity-project-finder/issues) kullanabilirsiniz.