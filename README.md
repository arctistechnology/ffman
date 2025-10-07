# FFMan

**Professional live stream encoding and management software powered by FFmpeg**

FFMan is a versatile stream encoding system that allows you to manage the full power of FFmpeg through a modern web interface. With its web-based management interface, you can easily control complex FFmpeg operations and professionally manage hundreds of streams from a single panel.

## Why FFMan?

Using FFmpeg through traditional methods can be extremely cumbersome, especially when managing multiple streams. Running separate commands for each stream via terminal, tracking processes, and intervening during errors creates a significant workload. FFMan eliminates all this complexity, making professional stream management simple enough for everyone.

While there are many stream management tools available, what makes FFMan special is its approach to FFmpeg. Other solutions typically work with fixed parameters and offer limited flexibility. FFMan gives you complete control - use ready-made profiles or write your own custom FFmpeg commands.

## Feature Highlights

### Unlimited FFmpeg Flexibility

One of FFMan's most powerful features is its unique flexibility in FFmpeg binary management:

- **Integrated FFmpeg Support**: Start using the tested and optimized FFmpeg version that comes with FFMan immediately
- **Custom Binary Usage**: Introduce your own compiled custom FFmpeg binary to the system
- **Multi-Version Management**: Use different FFmpeg versions for each profile
- **Dynamic Path Management**: Define different binary paths per profile

### Professional Stream Management

- **Profile System**: Configure your encoding settings once and use them forever
- **Multi-URL Failover**: Prevent stream interruptions with backup URLs for uninterrupted broadcasting
- **Real-time Monitoring**: Track your system resources and stream metrics in real-time
- **Telegram Integration**: Stay informed about your streams' status wherever you are

### Advanced Control

- **Category Management**: Organize your streams by categorizing them
- **Bulk Operations**: Perform operations on multiple streams at once
- **Queue System**: Control stream startup sequence and timing
- **Auto-start**: Automatically start streams on system boot
- **Scheduled Restart**: Automatically restart your streams at specified intervals
- **Test Mode**: Test your streams before going live
- **Pre-execution Scripts**: Run custom scripts before streams start
- **Custom Parameters**: Define custom FFmpeg parameters for each stream

### Enterprise-Level Reliability

FFMan not only offers ease of use but also provides enterprise-level reliability:

- **Isolated Process Management**: Problems in one stream don't affect others
- **Automatic Restart Policies**: Temporary interruptions are no longer an issue
- **Health Check System**: Continuously monitors your streams and intervenes immediately when problems are detected
- **PID Tracking**: Process tracking and management
- **Graceful Shutdown**: Safe termination operations
- **Log Rotation**: Automatic log file management
- **Session Management**: Session management and security

## System Requirements

### Supported Linux Distributions

FFMan is compiled with **GLIBC 2.28**. It runs seamlessly on the following Linux distributions:

**Debian-based:**
- Debian 10 (Buster) and later
- Ubuntu 20.04 LTS (Focal Fossa) and later
- Linux Mint 20 and later
- Pop!_OS 20.04 and later

**Red Hat-based:**
- RHEL 8 and later
- CentOS 8 and later
- Rocky Linux 8 and later
- AlmaLinux 8 and later
- Fedora 29 and later

**Other Distributions:**
- openSUSE Leap 15.1 and later
- Arch Linux (current)
- Manjaro (current)

**Note:** Ubuntu 18.04, Debian 9, CentOS 7, and older distributions are not supported as they have GLIBC versions older than 2.28. To check your system's GLIBC version: `ldd --version`

## Installation

### Automatic Installation (Recommended)

The easiest way to install FFMan is using our installation script:

```bash
wget https://raw.githubusercontent.com/arctistechnology/ffman/main/install.sh
bash install.sh
```

The installer will:
- Verify system compatibility (GLIBC 2.28+)
- Download the latest FFMan release
- Install to `/opt/ffman`
- Configure and enable systemd service
- Start FFMan automatically

**Note:** Run as root user or the script will prompt for root access.

### Manual Installation

For manual installation, download and extract the latest release:

```bash
wget https://github.com/arctistechnology/ffman/releases/latest/download/ffman-linux-x86_64.tar.gz
tar -xzf ffman-linux-x86_64.tar.gz -C /opt/ffman
chmod +x /opt/ffman/app.bin
```

Create the systemd service file:

```bash
cat > /etc/systemd/system/ffman.service << EOF
[Unit]
Description=FFman Stream Transcoder
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ffman
ExecStart=/opt/ffman/app.bin --host 0.0.0.0 --port 7080 --loglevel normal
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
```

Enable and start the service:

```bash
systemctl daemon-reload
systemctl enable ffman
systemctl start ffman
systemctl status ffman
```

## Quick Start

Once installed, access the web interface:

```
http://your-server-ip:7080
```

Default login credentials:
- Username: `admin`
- Password: `admin`

**Important:** Change the default password after first login.

## Updating

To update FFMan to the latest version, simply run the installer again:

```bash
wget https://raw.githubusercontent.com/arctistechnology/ffman/main/install.sh
bash install.sh
```

The installer will:
- Detect existing installation
- Preserve your configuration
- Update only changed files
- Restart the service if it was running

## Command Line Options

FFMan supports the following command-line parameters:

```bash
./app.bin [options]

Options:
  --host       IP address to bind (default: 0.0.0.0)
  --port       Port number (default: 7080)
  --loglevel   Log verbosity: normal|debug (default: normal)
```

Example:
```bash
./app.bin --host 127.0.0.1 --port 8080 --loglevel debug
```

## Service Management

Control FFMan service with systemctl:

```bash
systemctl start ffman      # Start service
systemctl stop ffman       # Stop service
systemctl restart ffman    # Restart service
systemctl status ffman     # Check status
journalctl -u ffman -f     # View live logs
```

## Uninstallation

To completely remove FFMan:

```bash
systemctl stop ffman
systemctl disable ffman
rm -rf /opt/ffman
rm /etc/systemd/system/ffman.service
systemctl daemon-reload
```

## Support

For issues, feature requests, or questions:
- Visit our [GitHub repository](https://github.com/arctistechnology/ffman)
- Check the [documentation](https://github.com/arctistechnology/ffman/wiki)
- Open an [issue](https://github.com/arctistechnology/ffman/issues)

---

**FFMan** - The professional solution that redefines stream encoding with user-focused design and unlimited flexibility. Manage complex FFmpeg commands with simple clicks, control hundreds of streams from a single panel, and accomplish everything you imagine.
