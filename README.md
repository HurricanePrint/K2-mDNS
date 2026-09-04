# K2-mDNS

A small mDNS responder for K2 printers that broadcasts a local hostname so the printer can be discovered on the network with an easy to remember address like:

- http://myprinter.local
- http://k2plus.local

For example you will be able to access Fluidd at ```http://k2plus.local:4408``` or ssh ```root@k2plus.local```

If you don't have router access to put your printer on a static ip, this is a perfect fix as the printer will always be accessable from a permanent address even when the internal ip changes.

> [!IMPORTANT]
> **Windows users will need to install Bonjour**
> 
> Download it from Apple at https://support.apple.com/en-us/106380


## Install methods

You can get the project onto the printer in either of these ways:

1. Git clone
2. Copy the release folder to the printer using Fluid, then run the install script over SSH

## Option 1: Install from Git

From the printer or a connected shell:

```bash
git clone https://github.com/HurricanePrint/K2-mDNS.git
cd K2-mDNS
sh install-mdns.sh
```

Then follow the prompt to enter a hostname. If you press Enter without typing anything, it will use the default hostname:

```bash
k2plus
```

## Option 2: Install from a release folder via Fluid

1. Download the [Latest Release](https://github.com/hurricaneprint/K2-mDNS/releases/latest) and extract the folder
2. Copy the project folder or release folder to the printer using Fluid.
    * Open the "Configuration" Tab (keyboard shortcut X)
    * Click the + and select "Upload Folder"
    * Choose the K2-mDNS folder you extracted from the release zip
3. Open an SSH session to the printer.
    * ```ssh root@<your-printer-ip>```
    * password: ```creality_2024```
4. Run:

```bash
cd mnt/UDISK/printer_data/config/K2-mDNS
sh install-mdns.sh
```

4. Enter the hostname when prompted.

## Notes

- The default hostname is `k2plus`.
- If the printer does not show up immediately, make sure multicast is enabled on the network and the service is running.

## Useful commands

Start service:

```bash
/etc/init.d/K2-mDNS start
```

Stop service:

```bash
/etc/init.d/K2-mDNS stop
```

Restart service:

```bash
/etc/init.d/K2-mDNS restart
```