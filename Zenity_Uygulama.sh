#!/bin/bash
################################################################################
#  Envanter Yönetim Sistemi
# Yazar      : Ertuğrul Çapan
# Açıklama   : Zenity ile Envanter Yönetim Sistemi
################################################################################

###############################################################################
# 1. GENEL DEĞİŞKENLER ve DOSYA KONTROLLERİ
###############################################################################
DEPO_FILE="depo.csv"
KULLANICI_FILE="kullanici.csv"
LOG_FILE="log.csv"
TEMP_FILE="temp.csv"
BACKUP_FOLDER="yedek"

# Varsayılan yönetici hesabı (İlk kullanım için)
# MD5 parolasını almak için: echo -n "12345" | md5sum | awk '{print $1}'
DEFAULT_ADMIN_USER="admin"
DEFAULT_ADMIN_PASS="827ccb0eea8a706c4c34a16891f84e7b"  # "12345" MD5'i
# Rol parametreleri
ROLE_ADMIN="Yonetici"
ROLE_USER="Kullanici"

# Oturum bilgileri
CURRENT_USER=""
CURRENT_ROLE=""

# Eşik değerleri örneği (Raporlamada kullanılacak)
LOW_STOCK_THRESHOLD=5
HIGH_STOCK_THRESHOLD=50

###############################################################################
# 2. GEREKLİ DOSYALARIN MEVCUT OLMASINI SAĞLA
###############################################################################
function dosyalariKontrolEt() {
    # depo.csv kontrol
    if [[ ! -f "$DEPO_FILE" ]]; then
        touch "$DEPO_FILE"
    fi

    # kullanici.csv kontrol
    if [[ ! -f "$KULLANICI_FILE" ]]; then
        touch "$KULLANICI_FILE"
        # Dosya boşsa, varsayılan admin hesabı ekleyelim
        echo "1,$DEFAULT_ADMIN_USER,Admin,Soyad,$ROLE_ADMIN,$DEFAULT_ADMIN_PASS,0" >> "$KULLANICI_FILE"
        # Format: KullaniciNo,KullaniciAdi,Ad,Soyad,Rol,MD5Parola,KilitliMi
    fi

    # log.csv kontrol
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE"
    fi
}

###############################################################################
# 3. LOG KAYDI (HATA VEYA BİLGİ KAYDI)
###############################################################################
# log.csv formatı: HataNo,Timestamp,KullanıcıBilgisi,İşlemBilgisi/ÜrünBilgisi,Mesaj
function logKaydi() {
    local hataKodu="$1"
    local kullaniciBilgi="$2"
    local islemBilgi="$3"
    local mesaj="$4"
    local zamanDamgasi
    zamanDamgasi=$(date +"%Y-%m-%d %H:%M:%S")

    echo "$hataKodu,$zamanDamgasi,$kullaniciBilgi,$islemBilgi,$mesaj" >> "$LOG_FILE"
}

###############################################################################
# 4. PAROLA KONTROL (MD5 KARŞILAŞTIRMA)
###############################################################################
function md5SifreKontrol() {
    local girilenSifre="$1"
    local kayitliMD5="$2"

    # Girilen sifrenin MD5 karşılığı
    local girilenMD5
    girilenMD5=$(echo -n "$girilenSifre" | md5sum | awk '{print $1}')

    if [[ "$girilenMD5" == "$kayitliMD5" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

###############################################################################
# 5. GİRİŞ EKRANI
###############################################################################
function girisEkrani() {
    local denemeHakki=3

    while : ; do
        # Kullanıcıdan giriş bilgilerini al
        IFS="|" read -r girilenKullaniciAdi girilenParola < <(
            zenity --forms --title="Giriş Yap" --text="Kullanıcı Adı ve Parolanızı Giriniz" \
            --add-entry="Kullanıcı Adı" \
            --add-password="Parola" \
            2>/dev/null
        )

        # İptal tuşuna basılırsa scriptten çık
        if [[ $? -ne 0 ]]; then
            exit 0
        fi

        # Kullanıcı kontrolü
        if [[ -z "$girilenKullaniciAdi" || -z "$girilenParola" ]]; then
            zenity --error --text="Boş değer girmeyiniz!"
            logKaydi "ERR01" "Sisteme Giriş" "$girilenKullaniciAdi" "Boş değer girişi"
            continue
        fi

        # kullanici.csv içinden arama
        if grep -q "^.*,$girilenKullaniciAdi,.*$" "$KULLANICI_FILE"; then
            # Bulunan satırı al
            local satir
            satir=$(grep "^.*,$girilenKullaniciAdi,.*" "$KULLANICI_FILE")
            # Format: KullaniciNo,KullaniciAdi,Ad,Soyad,Rol,MD5Parola,KilitliMi
            local kullaniciNo ad soyad rol md5Sifre kilitDurumu
            IFS="," read -r kullaniciNo kAdi ad soyad rol md5Sifre kilitDurumu <<< "$satir"

            # Kilit kontrol
            if [[ "$kilitDurumu" == "1" ]]; then
                zenity --error --text="Hesabınız kilitli. Lütfen yöneticiye başvurun."
                logKaydi "ERR02" "$girilenKullaniciAdi" "Giriş Denemesi" "Hesap kilitli"
                exit 0
            fi

            # Parola kontrol
            local sonuc
            sonuc=$(md5SifreKontrol "$girilenParola" "$md5Sifre")
            if [[ "$sonuc" == "true" ]]; then
                # Başarılı giriş
                CURRENT_USER="$girilenKullaniciAdi"
                CURRENT_ROLE="$rol"
                zenity --info --text="Giriş Başarılı. Hoşgeldiniz, $ad!"
                break
            else
                ((denemeHakki--))
                zenity --error --text="Hatalı parola. Kalan deneme hakkı: $denemeHakki"
                logKaydi "ERR03" "$girilenKullaniciAdi" "Giriş Denemesi" "Hatalı parola"

                # 3 denemede kilitle
                if (( denemeHakki == 0 )); then
                    # kullanici.csv güncelle -> kilitle
                    sed -i "s/^$kullaniciNo,$kAdi,$ad,$soyad,$rol,$md5Sifre,0/$kullaniciNo,$kAdi,$ad,$soyad,$rol,$md5Sifre,1/" "$KULLANICI_FILE"
                    zenity --error --text="Çok fazla hatalı giriş yaptınız. Hesabınız kilitlendi!"
                    logKaydi "ERR04" "$girilenKullaniciAdi" "Giriş Denemesi" "Hesap kilitlendi"
                    exit 0
                fi
            fi
        else
            zenity --error --text="Böyle bir kullanıcı bulunamadı!"
            logKaydi "ERR05" "Sisteme Giriş" "$girilenKullaniciAdi" "Kullanıcı bulunamadı"
        fi
    done
}

###############################################################################
# 6. ANA MENÜ
###############################################################################
function anaMenu() {
    while : ; do
        SECIM=$(zenity --list --title="Ana Menü" \
            --column="ID" --column="İşlem Seçiniz" \
            1 "Ürün Ekle" \
            2 "Ürün Listele" \
            3 "Ürün Güncelle" \
            4 "Ürün Sil" \
            5 "Rapor Al" \
            6 "Kullanıcı Yönetimi" \
            7 "Program Yönetimi" \
            8 "Çıkış" \
            --height=400 --width=400 \
            2>/dev/null)

        if [[ $? -ne 0 ]]; then
            # İptal tuşuna basılırsa çıkış
            cikisOnay
        fi

        case "$SECIM" in
            1)
                if [[ "$CURRENT_ROLE" == "$ROLE_ADMIN" ]]; then
                    urunEkle
                else
                    yetkiYok
                fi
                ;;
            2)
                urunListele
                ;;
            3)
                if [[ "$CURRENT_ROLE" == "$ROLE_ADMIN" ]]; then
                    urunGuncelle
                else
                    yetkiYok
                fi
                ;;
            4)
                if [[ "$CURRENT_ROLE" == "$ROLE_ADMIN" ]]; then
                    urunSil
                else
                    yetkiYok
                fi
                ;;
            5)
                raporMenu
                ;;
            6)
                if [[ "$CURRENT_ROLE" == "$ROLE_ADMIN" ]]; then
                    kullaniciMenu
                else
                    yetkiYok
                fi
                ;;
            7)
                if [[ "$CURRENT_ROLE" == "$ROLE_ADMIN" ]]; then
                    programMenu
                else
                    yetkiYok
                fi
                ;;
            8)
                cikisOnay
                ;;
        esac
    done
}

###############################################################################
# 7. YETKİSİZ İŞLEMLERDE VERİLECEK UYARI
###############################################################################
function yetkiYok() {
    zenity --error --text="Bu işlemi yapmaya yetkiniz yok!"
    logKaydi "ERR06" "$CURRENT_USER" "Yetkisiz İşlem" "Yetkisiz işlem denemesi"
}

###############################################################################
# 8. ÜRÜN EKLE
###############################################################################
function urunEkle() {
    # İlerleme çubuğu gösterimi için bir alt fonksiyon
    (
        echo "0" ; sleep 1
        echo "# Ürün Ekleme Başlatıldı..." ; sleep 1
        echo "50" ; sleep 1
        echo "# Ürün Ekleme Tamamlanıyor..." ; sleep 1
        echo "100"
    ) | zenity --progress --title="Ürün Ekleme" --auto-close --width=400 2>/dev/null

    # Form girişi al
    IFS="|" read -r urunAdi stokMiktari birimFiyati kategori < <(
        zenity --forms --title="Ürün Ekle" --text="Yeni Ürün Bilgilerini Giriniz" \
        --add-entry="Ürün Adı (Boşluksuz)" \
        --add-entry="Stok Miktarı" \
        --add-entry="Birim Fiyatı" \
        --add-entry="Kategori (Boşluksuz)" \
        2>/dev/null
    )

    # İptal edilirse
    if [[ $? -ne 0 ]]; then
        return
    fi

    # Veri doğrulama
    if [[ -z "$urunAdi" || -z "$stokMiktari" || -z "$birimFiyati" || -z "$kategori" ]]; then
        zenity --error --text="Boş alan bırakmayınız!"
        logKaydi "ERR07" "$CURRENT_USER" "Ürün Ekleme" "Boş alan hatası"
        return
    fi

    # Boşluk kontrolü (istenmiyor)
    if [[ "$urunAdi" =~ \  || "$kategori" =~ \  ]]; then
        zenity --error --text="Ürün adı veya kategori boşluk içeremez!"
        logKaydi "ERR08" "$CURRENT_USER" "Ürün Ekleme" "Boşluk içeren alan hatası"
        return
    fi

    # Sayısal kontrol
    if ! [[ "$stokMiktari" =~ ^[0-9]+(\.[0-9]+)?$ ]] || ! [[ "$birimFiyati" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        zenity --error --text="Stok miktarı ve birim fiyatı pozitif sayı olmalıdır!"
        logKaydi "ERR09" "$CURRENT_USER" "Ürün Ekleme" "Geçersiz sayı girişi"
        return
    fi

    # Aynı isimli ürün var mı kontrol
    if grep -q ",$urunAdi," "$DEPO_FILE"; then
        zenity --error --text="Bu ürün adıyla başka bir kayıt bulunmaktadır. Lütfen farklı bir ad giriniz."
        logKaydi "ERR10" "$CURRENT_USER" "Ürün Ekleme" "Aynı isimli ürün"
        return
    fi

    # Mevcut satır sayısına göre ürün numarası oluştur (en son satırın ilk kolonu)
    local urunNo
    if [[ ! -s "$DEPO_FILE" ]]; then
        urunNo=1
    else
        urunNo=$(( $(tail -n1 "$DEPO_FILE" | cut -d',' -f1) + 1 ))
    fi

    # CSV'ye yazalım: Format -> UrunNo,UrunAdi,Stok,BirimFiyati,Kategori
    echo "$urunNo,$urunAdi,$stokMiktari,$birimFiyati,$kategori" >> "$DEPO_FILE"
    zenity --info --text="Ürün başarıyla eklendi!"
    logKaydi "INFO" "$CURRENT_USER" "Ürün Ekleme" "Ürün eklendi: $urunAdi"
}

###############################################################################
# 9. ÜRÜN LİSTELE
###############################################################################
function urunListele() {
    # CSV'yi oku ve uygun formatta sun
    local icerik
    if [[ ! -s "$DEPO_FILE" ]]; then
        icerik="Hiç ürün bulunmamaktadır."
    else
        icerik=$(awk -F',' 'BEGIN {printf "%-5s | %-15s | %-8s | %-12s | %-15s\n", "No", "Ad", "Stok", "BirimFiyat", "Kategori"}
                 {printf "%-5s | %-15s | %-8s | %-12s | %-15s\n", $1, $2, $3, $4, $5}' "$DEPO_FILE")
    fi
    zenity --text-info --title="Ürün Listesi" --width=600 --height=400 --filename=<(echo "$icerik")
}

###############################################################################
# 10. ÜRÜN GÜNCELLE
###############################################################################
function urunGuncelle() {
    local urunAdi
    urunAdi=$(zenity --entry --title="Ürün Güncelle" --text="Güncellemek istediğiniz ürünün adını giriniz" 2>/dev/null)

    # İptal
    if [[ $? -ne 0 ]]; then
        return
    fi

    # Ürün var mı?
    local satir
    satir=$(grep ",$urunAdi," "$DEPO_FILE")
    if [[ -z "$satir" ]]; then
        zenity --error --text="Bu ada sahip ürün bulunamadı!"
        logKaydi "ERR11" "$CURRENT_USER" "Ürün Güncelle" "Ürün bulunamadı"
        return
    fi

    # UrunNo,UrunAdi,Stok,BirimFiyati,Kategori
    local urunNo eskiUrunAdi eskiStok eskiFiyat eskiKategori
    IFS="," read -r urunNo eskiUrunAdi eskiStok eskiFiyat eskiKategori <<< "$satir"

    # Ne güncellenecek?
    IFS="|" read -r yeniStok yeniFiyat < <(
        zenity --forms --title="Ürün Güncelle" \
        --text="Yeni değerleri giriniz (Boş bıraktığınız alan değişmeyecektir)" \
        --add-entry="Yeni Stok Miktarı (mevcut: $eskiStok)" \
        --add-entry="Yeni Birim Fiyat (mevcut: $eskiFiyat)" \
        2>/dev/null
    )

    # İptal
    if [[ $? -ne 0 ]]; then
        return
    fi

    # Değer atamaları (boş değilse güncelle)
    if [[ -n "$yeniStok" ]]; then
        # Pozitif sayı mı?
        if ! [[ "$yeniStok" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            zenity --error --text="Stok miktarı pozitif sayı olmalıdır!"
            logKaydi "ERR12" "$CURRENT_USER" "Ürün Güncelle" "Geçersiz stok"
            return
        fi
    else
        yeniStok="$eskiStok"
    fi

    if [[ -n "$yeniFiyat" ]]; then
        # Pozitif sayı mı?
        if ! [[ "$yeniFiyat" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            zenity --error --text="Birim fiyat pozitif sayı olmalıdır!"
            logKaydi "ERR13" "$CURRENT_USER" "Ürün Güncelle" "Geçersiz fiyat"
            return
        fi
    else
        yeniFiyat="$eskiFiyat"
    fi

    # Güncellemeden önce onay al (kritik işlem sayılabilir)
    zenity --question --text="Ürünü güncellemek istediğinize emin misiniz?" --default-cancel
    if [[ $? -eq 0 ]]; then
        # dosyadan eski kaydı sil -> yeni kaydı ekle
        sed -i "/^$urunNo,/d" "$DEPO_FILE"
        echo "$urunNo,$urunAdi,$yeniStok,$yeniFiyat,$eskiKategori" >> "$DEPO_FILE"

        zenity --info --text="Ürün başarıyla güncellendi!"
        logKaydi "INFO" "$CURRENT_USER" "Ürün Güncelle" "Ürün güncellendi: $urunAdi"
    fi
}

###############################################################################
# 11. ÜRÜN SİL
###############################################################################
function urunSil() {
    local urunAdi
    urunAdi=$(zenity --entry --title="Ürün Sil" --text="Silmek istediğiniz ürünün adını giriniz" 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        return
    fi

    local satir
    satir=$(grep ",$urunAdi," "$DEPO_FILE")
    if [[ -z "$satir" ]]; then
        zenity --error --text="Bu ada sahip ürün bulunamadı!"
        logKaydi "ERR14" "$CURRENT_USER" "Ürün Silme" "Ürün bulunamadı"
        return
    fi

    zenity --question --text="Bu ürünü silmek istediğinize emin misiniz?" --default-cancel
    if [[ $? -eq 0 ]]; then
        sed -i "/,$urunAdi,/d" "$DEPO_FILE"
        zenity --info --text="Ürün başarıyla silindi!"
        logKaydi "INFO" "$CURRENT_USER" "Ürün Silme" "Ürün silindi: $urunAdi"
    fi
}

###############################################################################
# 12. RAPOR AL
###############################################################################
function raporMenu() {
    SECIM=$(zenity --list --title="Rapor Menüsü" \
        --column="ID" --column="Rapor Seçiniz" \
        1 "Stokta Azalan Ürünler" \
        2 "En Yüksek Stoka Sahip Ürünler" \
        --height=200 --width=400 \
        2>/dev/null)

    if [[ $? -ne 0 ]]; then
        return
    fi

    case "$SECIM" in
        1) raporAzalan ;;
        2) raporYuksek ;;
    esac
}

function raporAzalan() {
    # Eşik değerini kullanıcı belirleyebilir ya da sabit LOW_STOCK_THRESHOLD kullanılabilir
    local threshold
    threshold=$(zenity --entry --title="Azalan Ürünler" --text="Eşik değerini giriniz (Varsayılan: $LOW_STOCK_THRESHOLD)" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        return
    fi
    if [[ -z "$threshold" ]]; then
        threshold=$LOW_STOCK_THRESHOLD
    fi

    # threshold altında kalan ürünler
    local icerik
    icerik=$(awk -F',' -v t="$threshold" '
        BEGIN {
          printf "%-5s | %-15s | %-8s | %-12s | %-15s\n", "No", "Ad", "Stok", "BirimFiyat", "Kategori"
        }
        { if($3 < t) {
            printf "%-5s | %-15s | %-8s | %-12s | %-15s\n", $1, $2, $3, $4, $5
          }
        }' "$DEPO_FILE")

    if [[ -z "$icerik" || "$icerik" == *"Ad"* && ! "$icerik" == *"|"* ]]; then
        icerik="Eşik değerinin altında kalan ürün bulunamadı."
    fi

    zenity --text-info --title="Azalan Ürünler" --width=600 --height=400 --filename=<(echo "$icerik")
}

function raporYuksek() {
    local threshold
    threshold=$(zenity --entry --title="Yüksek Stoklu Ürünler" --text="Eşik değerini giriniz (Varsayılan: $HIGH_STOCK_THRESHOLD)" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        return
    fi
    if [[ -z "$threshold" ]]; then
        threshold=$HIGH_STOCK_THRESHOLD
    fi

    local icerik
    icerik=$(awk -F',' -v t="$threshold" '
        BEGIN {
          printf "%-5s | %-15s | %-8s | %-12s | %-15s\n", "No", "Ad", "Stok", "BirimFiyat", "Kategori"
        }
        { if($3 >= t) {
            printf "%-5s | %-15s | %-8s | %-12s | %-15s\n", $1, $2, $3, $4, $5
          }
        }' "$DEPO_FILE")

    if [[ -z "$icerik" || "$icerik" == *"Ad"* && ! "$icerik" == *"|"* ]]; then
        icerik="Eşik değerine ulaşan veya geçen ürün bulunamadı."
    fi

    zenity --text-info --title="Yüksek Stoklu Ürünler" --width=600 --height=400 --filename=<(echo "$icerik")
}

###############################################################################
# 13. KULLANICI YÖNETİMİ
###############################################################################
function kullaniciMenu() {
    SECIM=$(zenity --list --title="Kullanıcı Yönetimi" \
        --column="ID" --column="İşlem Seçiniz" \
        1 "Yeni Kullanıcı Ekle" \
        2 "Kullanıcıları Listele" \
        3 "Kullanıcı Güncelle" \
        4 "Kullanıcı Sil" \
        5 "Kilitli Hesap Aç" \
        --height=300 --width=400 \
        2>/dev/null)

    if [[ $? -ne 0 ]]; then
        return
    fi

    case "$SECIM" in
        1) yeniKullaniciEkle ;;
        2) kullanicilariListele ;;
        3) kullaniciGuncelle ;;
        4) kullaniciSil ;;
        5) hesapKilidiAc ;;
    esac
}

function yeniKullaniciEkle() {
    IFS="|" read -r kAdi ad soyad rol parola < <(
        zenity --forms --title="Yeni Kullanıcı Ekle" \
        --text="Kullanıcı bilgilerini giriniz" \
        --add-entry="Kullanıcı Adı" \
        --add-entry="Adı" \
        --add-entry="Soyadı" \
        --add-combo="Rol" --combo-values="$ROLE_ADMIN|$ROLE_USER" \
        --add-password="Parola" \
        2>/dev/null
    )
    if [[ $? -ne 0 ]]; then
        return
    fi

    if [[ -z "$kAdi" || -z "$ad" || -z "$soyad" || -z "$rol" || -z "$parola" ]]; then
        zenity --error --text="Hiçbir alan boş bırakılamaz!"
        logKaydi "ERR15" "$CURRENT_USER" "Yeni Kullanıcı Ekle" "Boş alan hatası"
        return
    fi

    # Aynı kullanıcı var mı?
    if grep -q ",$kAdi," "$KULLANICI_FILE"; then
        zenity --error --text="Bu kullanıcı adıyla başka bir kayıt bulunmaktadır. Farklı bir ad deneyiniz."
        logKaydi "ERR16" "$CURRENT_USER" "Yeni Kullanıcı Ekle" "Aynı kullanıcı adı"
        return
    fi

    # KullaniciNo otomatik artış
    local userNo
    if [[ ! -s "$KULLANICI_FILE" ]]; then
        userNo=1
    else
        userNo=$(( $(tail -n1 "$KULLANICI_FILE" | cut -d',' -f1) + 1 ))
    fi

    # Parolayı MD5 ile sakla
    local md5Pass
    md5Pass=$(echo -n "$parola" | md5sum | awk '{print $1}')

    echo "$userNo,$kAdi,$ad,$soyad,$rol,$md5Pass,0" >> "$KULLANICI_FILE"
    zenity --info --text="Kullanıcı başarıyla eklendi!"
    logKaydi "INFO" "$CURRENT_USER" "Yeni Kullanıcı Ekle" "Kullanıcı eklendi: $kAdi"
}

function kullanicilariListele() {
    local icerik
    if [[ ! -s "$KULLANICI_FILE" ]]; then
        icerik="Hiç kullanıcı bulunmamaktadır."
    else
        icerik=$(awk -F',' 'BEGIN {printf "%-5s | %-10s | %-10s | %-10s | %-10s | %-32s | %-6s\n", "No", "Kullanici", "Ad", "Soyad", "Rol", "MD5Parola", "Kilit"}
                 {printf "%-5s | %-10s | %-10s | %-10s | %-10s | %-32s | %-6s\n", $1, $2, $3, $4, $5, $6, $7}' "$KULLANICI_FILE")
    fi
    zenity --text-info --title="Kullanıcı Listesi" --width=700 --height=400 --filename=<(echo "$icerik")
}

function kullaniciGuncelle() {
    local kAdi
    kAdi=$(zenity --entry --title="Kullanıcı Güncelle" --text="Güncellenecek kullanıcının adını giriniz" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        return
    fi

    local satir
    satir=$(grep ",$kAdi," "$KULLANICI_FILE")
    if [[ -z "$satir" ]]; then
        zenity --error --text="Bu kullanıcı adı bulunamadı."
        return
    fi

    # Format: KullaniciNo,KullaniciAdi,Ad,Soyad,Rol,MD5Parola,KilitliMi
    local userNo eskiKadi eskiAd eskiSoyad eskiRol eskiMD5 kilitDurumu
    IFS="," read -r userNo eskiKadi eskiAd eskiSoyad eskiRol eskiMD5 kilitDurumu <<< "$satir"

    IFS="|" read -r yeniAd yeniSoyad yeniRol yeniParola < <(
        zenity --forms --title="Kullanıcı Güncelle" \
        --text="Yeni değerleri giriniz (Boş bırakma = Değiştirme)" \
        --add-entry="Yeni Ad (Mevcut: $eskiAd)" \
        --add-entry="Yeni Soyad (Mevcut: $eskiSoyad)" \
        --add-combo="Yeni Rol (Mevcut: $eskiRol)" --combo-values="$ROLE_ADMIN|$ROLE_USER" \
        --add-password="Yeni Parola (***** boş bırakılırsa aynı kalır)" \
        2>/dev/null
    )
    if [[ $? -ne 0 ]]; then
        return
    fi

    # Boş bırakılanlar eski haliyle kalsın
    if [[ -z "$yeniAd" ]]; then
        yeniAd=$eskiAd
    fi
    if [[ -z "$yeniSoyad" ]]; then
        yeniSoyad=$eskiSoyad
    fi
    if [[ -z "$yeniRol" ]]; then
        yeniRol=$eskiRol
    fi
    if [[ -z "$yeniParola" ]]; then
        yeniParola=""  # MD5 pass güncellenmesin
    fi

    # Güncelle
    zenity --question --text="Kullanıcı bilgilerini güncellemek istediğinize emin misiniz?" --default-cancel
    if [[ $? -eq 0 ]]; then
        sed -i "/^$userNo,/d" "$KULLANICI_FILE"

        if [[ -n "$yeniParola" ]]; then
            local yeniMD5
            yeniMD5=$(echo -n "$yeniParola" | md5sum | awk '{print $1}')
            echo "$userNo,$kAdi,$yeniAd,$yeniSoyad,$yeniRol,$yeniMD5,$kilitDurumu" >> "$KULLANICI_FILE"
        else
            echo "$userNo,$kAdi,$yeniAd,$yeniSoyad,$yeniRol,$eskiMD5,$kilitDurumu" >> "$KULLANICI_FILE"
        fi

        zenity --info --text="Kullanıcı bilgileri güncellendi."
        logKaydi "INFO" "$CURRENT_USER" "Kullanıcı Güncelle" "Kullanıcı güncellendi: $kAdi"
    fi
}

function kullaniciSil() {
    local kAdi
    kAdi=$(zenity --entry --title="Kullanıcı Sil" --text="Silinecek kullanıcının adını giriniz" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        return
    fi

    local satir
    satir=$(grep ",$kAdi," "$KULLANICI_FILE")
    if [[ -z "$satir" ]]; then
        zenity --error --text="Kullanıcı bulunamadı!"
        return
    fi

    # Yönetici kendini silemesin örnek kuralı da ekleyebilirsiniz
    # Burada kAdi == DEFAULT_ADMIN_USER ise engellenebilir.

    zenity --question --text="Kullanıcıyı silmek istediğinize emin misiniz?" --default-cancel
    if [[ $? -eq 0 ]]; then
        sed -i "/,$kAdi,/d" "$KULLANICI_FILE"
        zenity --info --text="Kullanıcı silindi."
        logKaydi "INFO" "$CURRENT_USER" "Kullanıcı Sil" "Kullanıcı silindi: $kAdi"
    fi
}

function hesapKilidiAc() {
    local kAdi
    kAdi=$(zenity --entry --title="Kilitli Hesap Aç" --text="Kilit açılacak kullanıcının adını giriniz" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        return
    fi

    local satir
    satir=$(grep ",$kAdi," "$KULLANICI_FILE")
    if [[ -z "$satir" ]]; then
        zenity --error --text="Kullanıcı bulunamadı!"
        return
    fi

    # Format: KullaniciNo,KullaniciAdi,Ad,Soyad,Rol,MD5Parola,KilitliMi
    local userNo eskiKadi eskiAd eskiSoyad eskiRol eskiMD5 kilitDurumu
    IFS="," read -r userNo eskiKadi eskiAd eskiSoyad eskiRol eskiMD5 kilitDurumu <<< "$satir"

    # Kilit 1 ise 0 yap
    if [[ "$kilitDurumu" == "1" ]]; then
        sed -i "/^$userNo,/d" "$KULLANICI_FILE"
        echo "$userNo,$eskiKadi,$eskiAd,$eskiSoyad,$eskiRol,$eskiMD5,0" >> "$KULLANICI_FILE"
        zenity --info --text="Kullanıcının kilidi açıldı."
        logKaydi "INFO" "$CURRENT_USER" "Kilitli Hesap Aç" "Kullanıcı kilidi açıldı: $kAdi"
    else
        zenity --error --text="Bu kullanıcı zaten kilitli değil!"
    fi
}

###############################################################################
# 14. PROGRAM YÖNETİMİ
###############################################################################
function programMenu() {
    SECIM=$(zenity --list --title="Program Yönetimi" \
        --column="ID" --column="İşlem Seçiniz" \
        1 "Diskteki Alanı Göster" \
        2 "Diske Yedekle" \
        3 "Hata Kayıtlarını Göster" \
        --height=250 --width=400 \
        2>/dev/null)

    if [[ $? -ne 0 ]]; then
        return
    fi

    case "$SECIM" in
        1) diskteAlanGoster ;;
        2) diskeYedekle ;;
        3) hataKayitlariniGoster ;;
    esac
}

function diskteAlanGoster() {
    local boyut
    boyut=$(du -sh "$0" "$DEPO_FILE" "$KULLANICI_FILE" "$LOG_FILE" 2>/dev/null | awk '{print $2" -> "$1}' )
    zenity --info --text="Dosya Boyutları:\n$boyut"
}

function diskeYedekle() {
    # Yedek klasörü yoksa oluşturalım
    if [[ ! -d "$BACKUP_FOLDER" ]]; then
        mkdir "$BACKUP_FOLDER"
    fi

    cp "$DEPO_FILE" "$BACKUP_FOLDER/depo_$(date +%Y%m%d_%H%M%S).csv"
    cp "$KULLANICI_FILE" "$BACKUP_FOLDER/kullanici_$(date +%Y%m%d_%H%M%S).csv"

    zenity --info --text="Yedekleme tamamlandı. Yedekler '$BACKUP_FOLDER' klasöründe."
    logKaydi "INFO" "$CURRENT_USER" "Diske Yedekle" "Dosyalar yedeklendi"
}

function hataKayitlariniGoster() {
    if [[ ! -s "$LOG_FILE" ]]; then
        zenity --info --text="Herhangi bir log kaydı bulunmamaktadır."
    else
        zenity --text-info --title="Hata / Olay Kayıtları" --width=800 --height=400 --filename="$LOG_FILE"
    fi
}

###############################################################################
# 15. ÇIKIŞ İŞLEMİ
###############################################################################
function cikisOnay() {
    zenity --question --text="Çıkmak istediğinize emin misiniz?" --default-cancel
    if [[ $? -eq 0 ]]; then
        exit 0
    fi
}

###############################################################################
# 16. ANA AKIŞ
###############################################################################
dosyalariKontrolEt
girisEkrani
anaMenu
