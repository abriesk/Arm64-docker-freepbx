#  FreePBX Docker (ARM64 & x86_64)

A working Docker Compose setup for FreePBX 17 with Asterisk 22 on ARM64 architecture. Built from source — no prebuilt binaries required.

## Features

- **ARM64 native** — tested on Raspberry Pi 4/5
- **Built from source** — Asterisk 22.2.0, FreePBX 17
- **Persistent data** — survives container rebuilds
- **Host networking** — proper SIP/RTP without NAT headaches

## Requirements

- Raspberry Pi 4/5 (or any ARM64 Linux host)
- Docker & Docker Compose
- 2GB+ RAM recommended
- ~4GB disk space for build + data

## Quick Start

```bash
# Clone the repo
git clone https://github.com/abriesk/Arm64-docker-freepbx.git
cd Arm64-docker-freepbx

# Build and run (Asterisk source downloaded automatically)
docker compose build
docker compose up -d

# Watch the logs (first boot takes 5-10 minutes)
docker compose logs -f
```

## Access

- **Web UI**: `http://<your-pi-ip>/`
- **First run**: Complete the FreePBX setup wizard
- **SSH/Console**: `docker exec -it freepbx bash`
- **Asterisk CLI**: `docker exec -it freepbx asterisk -rvvv`

## Configuration

### Environment Variables

Create a `.env` file to override defaults:

```bash
# .env
DB_HOST=127.0.0.1
DB_USER=freepbxuser
DB_PASS=your_secure_password
DB_NAME=asterisk
MYSQL_ROOT_PASSWORD=your_root_password
```

### Ports

Using `network_mode: host`, so FreePBX binds directly to host ports:

| Port | Protocol | Service |
|------|----------|---------|
| 80 | TCP | Web UI |
| 5060 | UDP | SIP |
| 5160 | UDP | SIP (alternate) |
| 10000-20000 | UDP | RTP media |

### Persistent Data

All data stored in `./data/`:

```
./data/
├── asterisk/    # Asterisk runtime data
├── backup/      # FreePBX backups
├── db/          # MariaDB database
├── etc/         # Asterisk configs
└── web/         # FreePBX web files
```

To reset completely:
```bash
docker compose down -v
rm -rf ./data
docker compose up -d
```

## File Structure

```
.
├── Dockerfile              # Asterisk + FreePBX build
├── docker-compose.yml      # Service orchestration
├── docker-entrypoint.sh    # Startup script
└── data/                   # Persistent volumes (created on first run)
```

## Troubleshooting

### Container keeps restarting
```bash
# Check logs
docker compose logs freepbx

# Common issues:
# - Database not ready: wait longer, check mariadb logs
# - Missing configs: rm -rf ./data and restart fresh
```

### Asterisk won't start
```bash
docker exec -it freepbx bash
/usr/sbin/asterisk -cvvvg
# Check for missing libraries or config errors
```

### Web UI not accessible
```bash
# Check Apache is running
docker exec freepbx ss -tlnp | grep 80

# Check Apache logs
docker exec freepbx tail -20 /var/log/apache2/error.log
```

### SIP registration failing
- Ensure UDP 5060 and 10000-20000 aren't blocked by firewall
- Check `Asterisk SIP Settings` in FreePBX for correct external IP

## Building on x86_64

This should work on x86_64 too — just rebuild:
```bash
docker compose build --no-cache
```

## Security Notes

⚠️ **Before exposing to internet:**

1. Change all default passwords in `.env`
2. Enable HTTPS (reverse proxy recommended)
3. Configure FreePBX firewall module
4. Use strong SIP passwords
5. Consider fail2ban for Asterisk

## Known Issues

- First boot takes 5-10 minutes (compiling + module install)
- MariaDB shows "Aborted connection" warnings during install — harmless
- Apache "ServerName" warning — cosmetic, add `ServerName localhost` to suppress

## License

- **Asterisk**: GPLv2 — https://www.asterisk.org/
- **FreePBX**: GPLv3 + proprietary modules — https://www.freepbx.org/
- **This Docker setup**: MIT

## Credits

- **Gemini** — Initial writing of code base files
- **Claude** — Working rewrite of code base files
- **Sangoma** — Asterisk and FreePBX
- **Guerilla Cognitive Commander-in-Chimp** — Testing and deployment and initial spark

## Contributing

Issues and PRs welcome. Please test on ARM64 before submitting.

---

*Built because surprisingly there wasn't a good Docker Compose build-from-source setup for ARM64 that actually worked.*
