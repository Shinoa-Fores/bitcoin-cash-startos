# Bitcoin Cash

## Getting Started

### Config

Your node is highly configurable. Many settings are considered _advanced_ and should be used with caution. For the vast majority of users and use-cases, we recommend using the defaults. This is where you can change RPC credentials as well. Once configured, you may start your node!

### Syncing

Depending on your hardware resources, internet bandwidth, how many other services are running, and what peers your node happens to connect to, your node should take anywhere from under a day to several days to sync from genesis to present.

### Using a Wallet

Enter your QuickConnect QR code **OR** your raw RPC credentials (both located in `Properties`) into any wallet that supports connecting to a remote node over Tor. For a full list of compatible wallets, as well as guides for setup, please see the [documentation](https://docs.start9.com/latest/service-guides/bitcoin/bitcoin-integrations).

## Backups

When your server backs up this service, it will *not* include the blocks, chainstate, or indexes, so you don't need to worry about it eating your backup drive if you run an archival node.
