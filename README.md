# Suprapack the package manager without root

## Dependency

- valac
- C compiler (gcc or clang ...)
- Glib-2.0

# Compiling - install

```bash
git clone https://gitlab.com/nda-cunh/suprapack
cd suprapack
make install
```

# Config

## RepositoryList '~/.config/suprapack/repo.list'
```
Cosmos https://gitlab.com/supraproject/suprastore_repository/-/raw/master/
Elixir https://raw.githubusercontent.com/Strong214356/suprapack-list/master/
Supravim https://gitlab.com/supraproject/suprastore_repository/-/raw/plugin-supravim/
```
you can add a repository with NAME url


## `~/.config/suprapack/user.conf`

is_cached:true          # if true suprapack keep suprapack at `~/.config/suprapack/pkg`
show_script:false       # show script pre and post install before installing
prefix:~/.local         # change your prefix installation like '/' or other

## Arguments

--yes           # say yes everytime ! dont tell this ([Y/n])
--force         # force reinstall ([Y/n])
--prefix        # change the prefix temporary ([Y/n])


# Developper

you can build a package with fake `usr` folder or with a script `PKGBUILD`

## Without Script

To build a package you need create a fake root directory like
```
usr/
usr/bin/your_program
usr/share/applications/blabla.desktop
usr/lib/your_lib
usr/...
```

and make ``suprapack build usr``

you will enter the package creation mode
if you need a script pre and/or post install you can add at usr/post_install or usr/pre_install


## With Script

Suprapack support PKGBUILD-script since 2.2 like ArchLinux Pacman

exemple of pkgbuild:
```bash
pkgname=nameofpkg
pkgver=128.521.20
pkgdesc="The supra description"
pkgauthor=suprAuthor


source=('https://supra-project/file.zip')

makedepends=('vala')

package() {
    unzip file.zip
    mv file $pkgdir/usr/bin/
}
	
```
here all variable:
- srcdir
- pkdir
- prefix

here all attributs suprapack build can use:
- pkgname
- pkgver
- pkgdesc
- pkgauthor
- source 
- depends 
- conflicts
- makedepends

here function:
<details><summary>prepare</summary>call before package</details>
<details><summary>package</summary>move $srcdir/file to $pkgdir</details>


you can add as many functions as you like
example:
```bash
pkgver(){
    echo -n "5.2"
}

# all output is now the content of pkgver
package() {
    echo $pkgver
    #output is 5.2
}
```
this principle applies to all your functions


### source

with source() you can download some source or copy file into srcdir
```bash
source=('https://domain.net/file'
        'https://otherdomain.net/file2')
```

source support:
- http download
- simple file
- git url

use 'git+url' if it's git url
```bash
source=('git+https://gitlab.com/nda-cunh/suprapack')
```

my_file will be copied to $srcdir
```bash
source=('my_file')
```

you can force rename the source with '::'
```bash
source=('name::https://gitlab.com/nda-cunh/suprapack')
```

### other tips

you can make a variable with other variable:
```bash
pkgname=hello
pkgver=5.2
nameofsource=${pkgname}-${pkgver}

source='$nameofsource::https://download/file-${pkgver}.tar.gz'
```

# Repository

If you want create a repository you need fill a folder with all file.suprapack
```
./a.suprapack
./b.suprapack
./hello.suprapack
```

and use `suprapack prepare`
you can push your repository and add it in mirrorlist
