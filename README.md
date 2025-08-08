# 🚀 Verus Hellminer Auto Setup Script

**Script bash sederhana** untuk memudahkan mining koin **Verus (VRSC)** di VPS atau server Linux menggunakan **Hellminer** di pool **LuckPool**.  
Cocok untuk pemula maupun pengguna berpengalaman yang ingin setup cepat, aman, dan bisa auto-run saat reboot.

---

## ✨ Fitur Utama
- 🔹 **Input interaktif** – masukkan wallet, worker name, password, jumlah CPU threads.
- 🔹 **Pilih server & port otomatis** – North America, Europe, Asia-Pacific.
- 🔹 **Opsi autorun** – mining otomatis jalan setelah reboot (via `systemd`).
- 🔹 **Mode background** – jalankan di `screen` jika tidak ingin autorun.
- 🔹 **Aman dari banned VPS** – rekomendasi jumlah threads 75–80% dari total core.
- 🔹 **Mudah dipantau** – lihat progress langsung di LuckPool dashboard.

---

## 📋 Prasyarat
- Linux x86_64 (VPS atau bare metal)
- `hellminer` binary (taruh di folder yang sama dengan script ini)
- Koneksi internet stabil

---

## 🔧 Instalasi
1. **Clone repo & masuk folder**
   ```bash
   git clone https://github.com/username/verus-hellminer-setup.git
   cd verus-hellminer-setup
