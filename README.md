# Alvaro's dotfiles
Thanks to Balkian for introducing me to this world. Based on https://github.com/balkian/dotfiles.git
## Usage

### Download
The Git Way:
```bash
git clone https://github.com/alvarocarrera/dotfiles.git
```
The fast way:
```bash
curl -#L https://github.com/alvarocarrera/dotfiles/tarball/master | tar -xzv --strip-components 1 --exclude={README.md}
```
### Quick install

```
make
```
### Install
Each folder contains the configuration files for a specific program, as they would appear under "$HOME" (~).
To install them, first initialize the submodules:

```
git submodule update --init --recursive
```

Then, you can use the [GNU Stow](https://www.gnu.org/software/stow/) utility to link the files to the appropriate folder:
```bash
stow <modules that you want to install>
```

Alternatively, you may simply copy the files to your $HOME folder.
