# Dotfiles

```sh
git clone https://github.com/olzabi/dotifles ~/Dotfiles
gh repo clone olzabi/dotifles ~/Dotfiles

```

```bash
sudo apt update && sudo apt-get install \
  build-essential libreadline-dev unzip liblua5.4-dev lua5.4 \
  libclang-dev libxml2-utils \
  ztsd \
  libcurl4-openssl-dev \
  libtidy-dev libonig-dev \
  gcc make pkg-config bison \
  libevent-dev libncurses-dev \
  clangd-15
```

## Installation

### bat

```sh
bat cache --build
```

```sh
curl https://mise.run | sh
ln -s ~/.config/dotfiles/mise/config.toml ~/.config/mise/config.toml
mise install
mise run symlinks:create
```
