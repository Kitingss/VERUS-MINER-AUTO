#!/usr/bin/env bash
set -euo pipefail

# =========================
# Verus Hellminer Quick Setup (LuckPool)
# =========================

# --- helper ---
ask() { local p="$1" d="${2:-}"; read -rp "$p" _ans; echo "${_ans:-$d}"; }
err() { echo "ERROR: $*" >&2; exit 1; }

# --- check binary ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${SCRIPT_DIR}/hellminer"
[[ -x "$BIN" ]] || err "Binary 'hellminer' tidak ditemukan/tdk executable di ${SCRIPT_DIR}. Letakkan script ini di folder yg sama & jalankan: chmod +x hellminer verus_setup.sh"

# --- sudo helper (kalau bukan root) ---
SUDO=""
if [[ $EUID -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    err "Jalankan sebagai root atau install 'sudo'."
  fi
fi

echo "=== Verus Hellminer Quick Setup (LuckPool) ==="

# ---- Wallet / Worker / Password ----
WALLET="$(ask 'Wallet VRSC (format R...): ')"
[[ "$WALLET" =~ ^R ]] || echo "Peringatan: alamat tidak mulai dengan 'R'. Pastikan bukan exchange address."
WORKER_DEF="$(hostname | tr '[:upper:]' '[:lower:]')"
WORKER="$(ask "Nama Worker (default: ${WORKER_DEF}): " "$WORKER_DEF")"
PASS="$(ask 'Password (-p) (default: x): ' 'x')"

# ---- CPU threads ----
CPU_MAX="$(nproc)"
CPU_SUG=$(( CPU_MAX*3/4 ))
(( CPU_SUG < 1 )) && CPU_SUG=1
CPU="$(ask "Jumlah CPU threads (1-${CPU_MAX}, saran: ${CPU_SUG}): " "$CPU_SUG")"
[[ "$CPU" =~ ^[0-9]+$ && "$CPU" -ge 1 && "$CPU" -le "$CPU_MAX" ]] || err "CPU threads harus 1..${CPU_MAX}"

# ---- Server region ----
echo
echo "Pilih Server Region:"
echo "  1) NA  (North America)  -> na.luckpool.net"
echo "  2) EU  (Europe)         -> eu.luckpool.net"
echo "  3) AP  (Asia-Pacific)   -> ap.luckpool.net"
REG_CHOICE="$(ask 'Masukkan pilihan [1-3] (default: 3/AP): ' '3')"
case "$REG_CHOICE" in
  1) HOST="na.luckpool.net" ;;
  2) HOST="eu.luckpool.net" ;;
  3|*) HOST="ap.luckpool.net" ;;
esac

# ---- Port / protocol ----
echo
echo "Pilih Port:"
echo "  1) CPU (3960)  - non-SSL   [disarankan]"
echo "  2) SSL (3958)  - SSL"
echo "  3) Alt (3957)  - non-SSL"
echo "  4) Alt (3956)  - non-SSL"
echo "  5) Custom"
PORT_CHOICE="$(ask 'Masukkan pilihan [1-5] (default: 1/3960): ' '1')"
case "$PORT_CHOICE" in
  1) PORT="3960"; PROTO="stratum+tcp" ;;
  2) PORT="3958"; PROTO="stratum+ssl" ;;
  3) PORT="3957"; PROTO="stratum+tcp" ;;
  4) PORT="3956"; PROTO="stratum+tcp" ;;
  5)
     PORT="$(ask 'Masukkan port kustom: ')"
     [[ "$PORT" =~ ^[0-9]+$ ]] || err "Port tidak valid."
     PROTO="$(ask 'Protocol (stratum+tcp / stratum+ssl) [default: stratum+tcp]: ' 'stratum+tcp')"
     ;;
  *) PORT="3960"; PROTO="stratum+tcp" ;;
esac

# ---- Ringkasan ----
echo
echo "=== Ringkasan ==="
echo " Wallet : $WALLET"
echo " Worker : $WORKER"
echo " Server : $HOST:$PORT ($PROTO)"
echo " -p     : $PASS"
echo " Threads: $CPU"
echo " Folder : $SCRIPT_DIR"
echo

# ---- Autorun? ----
AUTORUN="$(ask 'Jalankan sebagai autorun saat reboot? (y/N): ' 'N')"
CMD="${BIN} -c ${PROTO}://${HOST}:${PORT} -u ${WALLET}.${WORKER} -p ${PASS} --cpu ${CPU}"

if [[ "$AUTORUN" =~ ^[Yy]$ ]]; then
  SERVICE_NAME="verus"
  SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"

  echo "Membuat systemd service: ${SERVICE_PATH}"
  $SUDO bash -c "cat > '${SERVICE_PATH}'" <<EOF
[Unit]
Description=Verus Hellminer
After=network.target

[Service]
Type=simple
WorkingDirectory=${SCRIPT_DIR}
ExecStart=${CMD}
Restart=always
RestartSec=5
Nice=10

[Install]
WantedBy=multi-user.target
EOF

  $SUDO systemctl daemon-reload
  $SUDO systemctl enable --now "${SERVICE_NAME}"
  $SUDO systemctl status "${SERVICE_NAME}" --no-pager -l || true

  echo
  echo "✅ Autorun aktif. Perintah berguna:"
  echo "  Lihat log   : journalctl -u ${SERVICE_NAME} -f"
  echo "  Stop        : systemctl stop ${SERVICE_NAME}"
  echo "  Disable     : systemctl disable ${SERVICE_NAME}"
else
  # jalankan di screen
  if ! command -v screen >/dev/null 2>&1; then
    echo "Menginstal 'screen'..."
    $SUDO apt update -y && $SUDO apt install -y screen
  fi
  screen -dmS verus bash -c "${CMD}"
  echo
  echo "✅ Miner berjalan di background (screen)."
  echo "  Attach  : screen -r verus"
  echo "  Detach  : CTRL + A, lalu D"
fi

echo
echo "Cek dashboard pool:"
echo "  https://luckpool.net/verus/miner.html?address=${WALLET}"
echo "Selesai. Selamat mining! 🚀"
