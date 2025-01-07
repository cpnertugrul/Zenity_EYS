# Zenity ile Basit Envanter Yönetim Sistemi

Bu proje, **Bash** betiği (**.sh** dosyası) ve **Zenity** araçları ile **grafik arayüz** kullanarak basit bir envanter yönetim sistemi sunar. Projede;

- **Ürün** ekleme, listeleme, güncelleme ve silme,
- **Rapor** alma,
- **Kullanıcı yönetimi** (yeni kullanıcı ekleme, listeleme, güncelleme, silme, kilit açma),
- **Log kaydı** (hata veya bilgilendirme),
- **Disk yedekleme** ve benzeri program yönetimi işlemleri

yapılabilir.

---

## İçindekiler

1. [Özellikler](#özellikler)  
2. [Ekran Görüntüleri](#ekran-görüntüleri)  
3. [Kurulum](#kurulum)  
4. [Kullanım](#kullanım)  
5. [Dizin Yapısı](#dizin-yapısı)  
6. [Teknik Bilgiler](#teknik-bilgiler)
7. [İletişim](#iletişim)
8. Youtube Linki(#YouTube-link)  

---

## Özellikler

- **Rol Tabanlı Erişim**  
  - **Yönetici (Admin)**: Ürün ekleme, güncelleme, silme ve kullanıcı yönetimi yapabilir.  
  - **Kullanıcı (User)**: Sadece ürün listeleme ve rapor alabilir.
- **Veri Saklama**  
  - `depo.csv`: Ürün bilgilerinin kaydedildiği dosya  
  - `kullanici.csv`: Kullanıcıların (admin/kullanıcı) kaydı  
  - `log.csv`: Hata ve bilgilendirme kayıtları  
- **Otomatik Dosya Oluşturma**: Dosyalar eksik ise script başlarken otomatik olarak oluşturur.  
- **MD5 Parola Kontrolü**: Kullanıcı şifreleri MD5 formatında tutulmaktadır.  
- **Gelişmiş Hata Yönetimi**  
  - Yanlış veri girişlerinde Zenity aracılığıyla uyarı pencereleri,  
  - `log.csv` dosyasına hata detayları kaydı,  
  - Yanlış parola denemesi 3 kere olursa **hesap kilitleme**.  
- **Raporlama**  
  - Stokta azalan ürünler  
  - Yüksek stoklu ürünler  
  - Eşik değeri kullanıcı tarafından değiştirilebilir.  
- **Kritik İşlemlerde Onay**: Silme veya güncelleme gibi işlemlerde `--question` ile onay ekranı.  
- **İlerleme Çubuğu**: Ürün ekleme vb. işlemlerde Zenity `--progress` özelliği.  

---

## Ekran Görüntüleri


1. **Giriş Ekranı**  
   
<img src="https://github.com/user-attachments/assets/fc4b5551-17ea-49b2-8db0-321268dec5bb" width="300" alt="Giriş Ekranı 1" />
<img src="https://github.com/user-attachments/assets/0bcb1aea-cbcf-4032-9cdf-de7964de4a7f" width="300" alt="Giriş Ekranı 2" />

2. **Ana Menü**
<img src="https://github.com/user-attachments/assets/216ca7e5-33e9-4247-b0d2-f59783930ece" width="300" alt="Ana Menü 1" />
<img src="https://github.com/user-attachments/assets/ed81050b-9f19-4943-8b78-403ccebffb4c" width="300" alt="Ana Menü 2" />
   

   
   A.**Ana Menü Fonksiyon Ekranları**
   
   --> **Ürün Ekleme Ekranı**
<img src="https://github.com/user-attachments/assets/4921a061-8276-4009-8f71-f2c41e56b96b" width="300" alt="Ürün Ekleme 1" />
<img src="https://github.com/user-attachments/assets/744af370-3b0b-4b64-954e-34fe54f45528" width="300" alt="Geri Dönüt Ekranı" />

  --> **Ürün Listeleme Ekranı**
<img src="https://github.com/user-attachments/assets/df444646-9d9d-44c5-8081-3169cb96276d" width="300" alt="Ürün Listeleme" />

   --> **Ürün Güncelleme Ekranı**
<img src="https://github.com/user-attachments/assets/987ea627-33d4-403a-aa4a-372d255641c6" width="300" alt="Ürün Güncelleme 1" />
<img src="https://github.com/user-attachments/assets/b5c53f3d-7846-4341-8b6c-52e83e238010" width="300" alt="Ürün Güncelleme 2" />
<img src="https://github.com/user-attachments/assets/e9e41012-f9de-45f8-9144-20364b708351" width="300" alt="Geri Dönüt 1" />
<img src="https://github.com/user-attachments/assets/30cb2467-4b4a-43f6-8116-5504527b8ca5" width="300" alt="Geri Dönüt 2" />

   --> **Ürün Silme Ekranı**
<img src="https://github.com/user-attachments/assets/404f01e1-1e0b-4fc7-af5b-a4e2dbb67f9b" width="300" alt="Ürün Silme 1" />
<img src="https://github.com/user-attachments/assets/25e817c2-a75d-4a7b-af15-ab907d0d86d0" width="300" alt="Ürün Silme 2" />



   --> **Rapor Menüsü Ekranları**
   <img src="https://github.com/user-attachments/assets/048e565e-ed47-48ce-81b5-050bdf25c432" width="300" alt="Rapor Menüsü" />
   <img src="https://github.com/user-attachments/assets/024341a7-be9f-4580-8009-1d0bdd60965d" width="300" alt="Azalan Ürünler" />
   <img src="https://github.com/user-attachments/assets/6cdc1829-781e-4a64-ae0b-58c6109bd86b" width="300" alt="Rapor Menüsü 2" />
   <img src="https://github.com/user-attachments/assets/e445d10d-1232-4595-b257-6069293db2bd" width="300" alt="Yüksek Stoklu Ürünler Ekranı" />
   <img src="https://github.com/user-attachments/assets/b3f61a72-ea14-4d99-ab92-78b09e535bcc" width="300" alt="Yüksek Stoklu Ürünler Listeleme Ekranı" />


   --> **Kullanıcı Yönetim Ekranları**
   <img src="https://github.com/user-attachments/assets/cdbc250c-a2d8-413c-b1d2-71eb60784e6d" width="300" alt="Kullanıcı Yönetimi Ekranı 1" />
   <img src="https://github.com/user-attachments/assets/cbcc5041-9b07-4ee7-abd1-a466c5fe0022" width="300" alt="Kullanıcı Yönetim Ekranı 2" />
   <img src="https://github.com/user-attachments/assets/8403c16f-13eb-4366-b9f7-0322c11d91cb" width="300" alt="Yeni Kullanıcı Ekranı " />
   <img src="https://github.com/user-attachments/assets/1d96aadb-3039-41ad-932a-f5ebefee97a9" width="300" alt="Kullanıcı Listesi Ekranı" />
   <img src="https://github.com/user-attachments/assets/d1c58b45-8256-4dcf-8611-0b882027dde8" width="300" alt="Kilitli Hesap Açma Ekranı" />
   <img src="https://github.com/user-attachments/assets/482d2721-b056-41a3-831f-bf30076250c8" width="300" alt="Kullanıcı Güncelleme Ekranı 1" />
   <img src="https://github.com/user-attachments/assets/b5a93bc5-0808-4678-bfaa-39e2fb930da1" width="300" alt="Kullanıcı Güncelleme Ekranı 2" />
   <img src="https://github.com/user-attachments/assets/e6752109-a063-4a34-9e3e-b04693124454" width="300" alt="Kullanıcı Silme Ekranı" />


   --> **Program Yönetim Ekranları**
   <img src="https://github.com/user-attachments/assets/dc6d7116-acee-4863-81c1-87e363667d28" width="300" alt="Program Yönetim Ekranı  1" />
   <img src="https://github.com/user-attachments/assets/1b062525-4f44-4d1e-b9d3-5deaabdd3061" width="300" alt="Program Yönetim Ekranı 2" />
   <img src="https://github.com/user-attachments/assets/f8c137f2-b727-45b4-8220-aefe4eab2901" width="300" alt="Hata Kayıtları" />
   <img src="https://github.com/user-attachments/assets/d7324bef-c5b0-4980-9a71-4abde1ca37bb" width="300" alt="Dosya Boyutu Ekranı" />
   

   --> **Çıkış Ekranı**
   <img src="https://github.com/user-attachments/assets/8fda39b0-80b7-458e-aa95-54fbd5f6c0cc" width="300" alt="Çıkış Ekranı" />

6.**Loading Menüleri**
Bu ekran Ürün Ekleme neticisinde gösterilen loding ekranıdır.Her ana menü seçeneği için ilgili menü hakkında bilgiler içeren loading ekranları projemizde mevcut olup kullanıcının ne işlem yaptığı hakkında bilgilendirme yapmaktadır.
<img src="https://github.com/user-attachments/assets/03acc723-3c2e-403d-bd0b-1ffe95b84bcb" width="300" alt="Loading Ekranı" />

   

---

## Kurulum

1. **Zenity** kurulu olduğundan emin olun. Örneğin, Ubuntu/Debian tabanlı sistemlerde:
   ```bash
   sudo apt-get update
   sudo apt-get install zenity
   ```
2. Projeyi GitHub’dan klonlayın (veya zip’ten çıkarın):
   ```bash
   git clone https://github.com/cpnertugrul/Zenity_EYS.git
   ```
3. Dizine girin:
   ```bash
   cd Zenity_EYS
   ```
4. Script’e **çalıştırma izni** verin:
   ```bash
   chmod +x envanter.sh
   ```

---

## Kullanım

1. Terminal üzerinden projenin bulunduğu dizine geçiş yapın:
   ```bash
   cd Zenity_EYS
   ```
2. **Bash betiğini** çalıştırın:
   ```bash
   ./Zenity_Uygulama.sh
   ```
3. Karşınıza **Giriş** ekranı çıkacaktır:

   - Varsayılan yönetici bilgileri:
     - **Kullanıcı Adı:** `admin`
     - **Parola:** `12345`  
   - Giriş yaptıktan sonra **Ana Menü** karşınıza gelir:
     1. **Ürün Ekle**  
     2. **Ürün Listele**  
     3. **Ürün Güncelle**  
     4. **Ürün Sil**  
     5. **Rapor Al**  
     6. **Kullanıcı Yönetimi**  
     7. **Program Yönetimi**  
     8. **Çıkış**  

4. **Kullanıcı Rolü**:  
   - **Admin**: Ürün/Kullanıcı ekleme, güncelleme, silme, rapor ve program yönetimi.  
   - **User**: Ürünleri listeleyip rapor alabilir. Diğer menü adımlarına erişince uyarı alır.  

5. **Veri Dosyaları** (`csv` formatında)  
   - `depo.csv`: Ürün bilgileri  
   - `kullanici.csv`: Kullanıcı bilgileri  
   - `log.csv`: Sistem hata ve bilgi kayıtları  

6. **Yedek Alma**  
   - Program yönetimi menüsünden **Diske Yedekle** dediğinizde `depo.csv` ve `kullanici.csv` dosyaları, `yedek` klasörüne tarih-saat etiketli dosyalar olarak kopyalanır.

---

## Dizin Yapısı

Proje klasörünün olası yapısı:

```
Zenity_EYS/
├── Zenity_Uygulama.sh
├── depo.csv          (script çalışınca oluşacak; başlangıçta yoksa otomatik)
├── kullanici.csv     (script çalışınca oluşacak; başlangıçta yoksa otomatik)
├── log.csv           (script çalışınca oluşacak; başlangıçta yoksa otomatik)
├── yedek/            (yedekler buraya atılır)
└── README.md
```

- `Zenity_Uygulaması.sh` : Projenin ana betiği.  
- `depo.csv`, `kullanici.csv`, `log.csv`: Uygulamanın kullandığı veri dosyaları.  
- `yedek/`: Yedek dosyaları oluşturmak için otomatik kullanılan klasör.  


---

## Teknik Bilgiler

- **Bash Script** üzerinde **Zenity** kullanılarak GUI sağlanır.  
- **MD5 Parola** oluşturmak için:
  ```bash
  echo -n "parola" | md5sum | awk '{print $1}'
  ```
- **Hata Kaydı Mantığı**:  
  - `logKaydi` fonksiyonuna girilen hata kodu, zaman damgası, kullanıcı bilgisi, işlem bilgisi ve mesaj, `log.csv` dosyasına kaydedilir.
- **Kullanıcı Kilitlenme**:  
  - 3 kere hatalı parola girilirse `kullanici.csv` dosyasında `kilitDurumu` sütunu `1` yapılır.  
  - Yönetici, **Kullanıcı Yönetimi** \> **Kilitli Hesap Aç** menüsünden kilidi açabilir.

---

## İletişim

Bu projeyle ilgili sorunlarınız veya katkılarınız için lütfen GitHub üzerinden **Issue** açarak veya **Pull Request** yollayarak destek sağlayabilirsiniz.  

Eğer doğrudan irtibat kurmak isterseniz:  
**Email:** ertugrulcpn@gmail.com 

## Youtube Linki
https://youtu.be/FGmn7-IyjzU


> **Teşekkürler ve İyi Çalışmalar!**

---  


---

**Not**: Proje gerçek bir üretim ortamına geçirilmeden önce;  
- Güvenlik (örn. şifreleme yöntemleri)  
- Veri doğrulama (örn. regex, ek kontroller)  
- Yedekleme / geri yükleme mekanizmaları  
- Çok kullanıcılı senaryolar için yarış durumları (örn. dosya kilitleme)  

gibi konular mutlaka detaylıca gözden geçirilmelidir.  
