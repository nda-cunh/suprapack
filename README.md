# Suprapack the package manager without root

# Build

## Dependency

- valac
- C compiler (gcc or clang ...)
- Glib-2.0

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


If you want create a repository you need fill a folder with all file.suprapack
```
./a.suprapack
./b.suprapack
./hello.suprapack
```

and use `suprapack prepare`
you can push your repository and add it in mirrorlist