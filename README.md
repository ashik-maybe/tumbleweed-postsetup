# Tumbleweed Post-Setup

Minimalist orchestrator to optimize **openSUSE Tumbleweed**.

## 🚀 Quick Start

```bash
git clone https://github.com/ashik-maybe/tumbleweed-postsetup.git
cd tumbleweed-postsetup
chmod +x tumbleweed-postinstall-optimization.sh
./tumbleweed-postinstall-optimization.sh

```

## ⚡ Fast Bootstrap (No Git)

If `zypper` is slow, run this to optimize throughput and install Git:

```bash
echo -e "[main]\ndownload.max_concurrent_connections = 10\ndeltarpm = false" | sudo tee /etc/zypp/zypp.conf
sudo env ZYPP_CURL2=1 zypper ref
sudo zypper in -y git-core

```

## ✨ Key Optimizations

* **Zypper**: 10x parallel downloads + `ZYPP_CURL2` enabled.
* **Codecs**: Full Packman vendor change (H.264, FFmpeg, etc.).
* **Bloat**: Removes GNOME Maps, Weather, Music, and LibreOffice.
* **Performance**: Enables `zRAM` (zstd) and `fstrim`.
* **Dev**: Pre-installs `bun` and `uv`.

> [!TIP]
> **Reboot** after execution to apply the new multimedia libraries and zRAM configuration.

---

**Would you like me to add a short "Removal List" table so users know exactly what is being deleted?**
