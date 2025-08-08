#!/usr/bin/env bash
set -euo pipefail

BIN="./hellminer"   # pastikan file hellminer ada di folder ini
SERVICE_NAME="verus"

# ===== Helper =====
ask() { local p="$1" d="${2:-}"; read -rp "$p" _ans; echo "${_ans:-$d}"; }
err() { echo "ERROR: $*" >&2; exit 1; }

echo "=== Verus Hellminer Quick Setup (LuckPool) ==="
[[ -x "$BIN" ]] || err "Binary $BIN tidak ditemukan/tdk executable. Taruh script ini di folder yg sama dg hellminer, lalu: chmod +x hellminer verus_setup.sh"

# ---- Wallet / Worker / Password ----
WALLET=$(ask "Wallet VRSC (format R...): ")
[[ "$WALLET" =~ ^R ]] || echo "Peringatan: alamat tidak mulai dengan 'R'. Pastikan bukan exchange address."
WORKER_DEF="$(hostname | tr '[:upper:]' '[:lower:]')"
WORKER=$(ask "Nama Worker (default: $WORKER_DEF): " "$WORKER_DEF")
PASS=$(ask "Password (-p) (default: x): " "x")

# ---- CPU threads ----
CPU_MAX=$(nproc)
CPU_SUG=$(( CPU_MAX*3/4 ))
CPU=$(ask "Jumlah CPU threads (1-$CPU_MAX, saran: $CPU_SUG): " "$CPU_SUG")
[[ "$CPU" =~ ^[0-9]+$ && "$CPU" -ge 1 && "$CPU" -le "$CPU_MAX" ]] || err "CPU threads harus 1..$CPU_MAX"

# ---- Server region menu ----
echo
echo "Pilih Server Region:"
echo "  1) NA  (North America)  -> na.luckpool.net"
echo "  2) EU  (Europe)         -> eu.luckpool.net"
echo "  3) AP  (Asia-Pacific)   -> ap.luckpool.net"
REG_CHOICE=$(ask "Masukkan pilihan [1-3] (default: 3/AP): " "3")
case "$REG_CHOICE" in
  1) HOST="na.luckpool.net" ;;
  2) HOST="eu.luckpool.net" ;;
  3) HOST="ap.luckpool.net" ;;
  *) HOST="ap.luckpool.net" ;;
esac

# ---- Port menu ----
echo
echo "Pilih Port:"
echo "  1) CPU (3960)  - non-SSL   [disarankan]"
echo "  2) SSL (3958)  - SSL"
echo "  3) Alt (3957)  - non-SSL"
echo "  4) Alt (3956)  - non-SSL"
echo "  5) Custom"
PORT_CHOICE=$(ask "Masukkan pilihan [1-5] (default: 1/3960): " "1")
case "$PORT_CHOICE" in
  1) PORT="3960" ; PROTO="stratum+tcp" ;;
  2) PORT="3958" ; PROTO="stratum+ssl" ;;
  3) PORT="3957" ; PROTO="stratum+tcp" ;;
  4) PORT="3956" ; PROTO="stratum+tcp" ;;
  5)
     PORT=$(ask "Masukkan port kustom: ")
     [[ "$PORT" =~ ^[0-9]+$ ]] || err "Port tidak valid"
     PROTO=$(ask "Protocol (stratum+tcp / stratum+ssl) [default: stratum+tcp]: " "stratum+tcp")
     ;;
  *) PORT="3960" ; PROTO="stratum+tcp" ;;
esac

echo
echo "=== Ringkasan ==="
echo " Wallet : $WALLET"
echo " Worker : $WORKER"
echo " Server : $HOST:$PORT ($PROTO)"
echo " -p     : $PASS"
echo " Threads: $CPU"
echo

AUTORUN=$(ask "Jalankan sebagai autorun saat reboot? (y/N): " "N")

CMD="$BIN -c $PROTO://$HOST:$PORT -u ${WALLET}.${WORKER} -p $PASS --cpu $CPU"

if [[ "$AUTORUN" =~ ^[Yy]$ ]]; then
  SVC="/etc/systemd/system/${SERVICE_NAME}.service"
  echo "Membuat systemd service: $SVC"
  sudo bash -c "cat > '$SVC'" <<EOF
[Unit]
Description=Verus Hellminer
After=network.target

[Service]
Type=simple
WorkingDirectory=$(pwd)
ExecStart=$CMD
Restart=always
RestartSec=5
Nice=10
CPUWeight=80

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable --now "$SERVICE_NAME"
  sudo systemctl status "$SERVICE_NAME" --no-pager -l || true
  echo "✅ Autorun aktif. Log: journalctl -u $SERVICE_NAME -f"
else
  if ! command -v screen >/dev/null 2>&1; then
    echo "Menginstal 'screen'..."
    sudo apt update -y && sudo apt install -y screen
  fi
  screen -dmS verus bash -c "$CMD"
  echo "✅ Miner berjalan di background (screen)."
  echo "   Lihat: screen -r verus   |   Detach: CTRL+A lalu D"
fi

echo
echo "Cek dashboard: https://luckpool.net/verus/miner.html?address=$WALLET"
echo "Selesai. Selamat mining! 🚀"
