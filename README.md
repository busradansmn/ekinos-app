# 🌾 EKINOS — İlçe Tabanlı Adil Gıda & Yöresel Emek Ağı

<p align="center">
  <img src="https://raw.githubusercontent.com/busradansmn/busradansmn/main/assets/icon/app_logo.png" alt="EKINOS Logo" width="160" />
</p>

---

## EKINOS Nedir?

**EKINOS**, yerel ilçelerde (örneğin Malatya/Darende) üretim yapan çiftçiler ile yöresel el emeği üreten ev kadınlarını, doğrudan mahalle sakinleri (tüketiciler) ile bir araya getiren **premium, merkeziyetsiz bir toplu alım ve adil ticaret platformudur.**

Uygulama, karmaşık lojistik süreçlerini, sezonluk hasat takvimlerini ve yerel teslimat noktalarını teknolojiyle optimize ederek, WhatsApp grupları gibi geleneksel yöntemlerin operasyonel kabuslarını çözer. Hem taze tarım ürünlerini hem de "Erişte", "Tarhana", "El Örgüsü" gibi yöresel el emeklerini tek çatı altında toplar.

## Vizyon ve Problem

Geleneksel tarım ve el emeği zincirinde üreticiler, aracılar (komisyoncular) ve lojistik engeller nedeniyle emeğinin karşılığını tam alamazken; tüketiciler güvenilir, temiz ve taze ürüne ulaşmakta zorlanmaktadır.

EKINOS, bu zinciri **kısaltır** ve **şeffaflaştırır**.

**Temel Hedef:**
1.  **Üreticiye Tam Destek:** Aracıları aradan kaldırarak üreticinin kâr marjını artırmak.
2.  **Güvenilir Adil Gıda:** Tüketicinin, laboratuvar onaylı veya yerel güven ağına dayalı (Yıldızlama) temiz ürüne ulaşmasını sağlamak.
3.  **Lojistik Optimizasyon:** "Toplu Alım Gücü" ile kargo ve lojistik maliyetlerini minimize etmek.
4.  **WhatsApp Karmaşasına Son:** Sipariş takibi, ödeme ve teslimat süreçlerini dijitalleştirerek hata payını sıfırlamak.

---

## Teknik Mimari

EKINOS, modern Flutter standartlarına ve Senior seviyesinde temiz kod mimarisine sadık kalınarak geliştirilmiştir.

*   **UI/UX:** Material 3 Spec, **GoogleFonts.poppins** veya **Inter**, **Forest Green (#1B4332)** ve **Warm Ochre (#D4A373)** renk paleti ile premium, minimalist bir tasarım dili.
*   **State Management:** **Riverpod** (Daha sürdürülebilir, güvenli ve test edilebilir bir yapı için Provider'ın modern alternatifi).
*   **Architecure:** Clean Architecture (Domain, Data, Presentation) prensiplerine uygun, katmanlı dosya yapısı.
*   **Database (Simülasyon):** Demo gösterimleri ve prototip aşaması için tüm veri akışı, hiçbir internet sunucusuna ihtiyaç duymadan **In-Memory State Simulation** (Riverpod Notifiers ile RAM'de canlı veri tutma) ile yönetilmektedir.

---

**Büşra Danışman**
*   GitHub: [@busradansmn](https://github.com/busradansmn)

<p align="center">© 2024 EKINOS Projesi. Tüm Hakları Saklıdır.</p>