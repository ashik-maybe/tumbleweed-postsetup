# openSUSE Tumbleweed Post-Setup

A collection of scripts to optimize a fresh **openSUSE Tumbleweed + GNOME** install.

## How to use (with Git)

```bash
git clone https://github.com/ashik-maybe/opensuse-tumbleweed-postsetup.git
cd opensuse-tumbleweed-postsetup
chmod +x tumbleweed-postinstall-optimization.sh
./tumbleweed-postinstall-optimization.sh
```

---

## 🔥 No Git? Fix slow zypper first, then install Git

On a fresh install, `zypper` can be painfully slow. **Paste this in your terminal first** to enable fast mirrors and deltarpm:

```bash
sudo rm -f /etc/zypp/repos.d/*.repo
sudo zypper ar -cfG https://download.opensuse.org/tumbleweed/repo/oss/ repo-oss
sudo zypper ar -cfG https://download.opensuse.org/tumbleweed/repo/non-oss/ repo-non-oss
echo -e "[main]\ndeltarpm = true\ndeltarpm.always = true" | sudo tee /etc/zypp/zypp.conf
sudo zypper refresh
sudo zypper install -y --no-recommends git-core
```

Now you can clone and run the script normally!

> ✅ Uses **MirrorCache** (`download.opensuse.org`) → auto-selects the fastest local mirror.
> ✅ Enables **deltarpm** → smaller, faster updates.
