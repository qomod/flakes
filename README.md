# flakes

Nix flakes for tools that I use

## Prerequisites

### Nix and Nix flakes

- Learn about [flakes](https://github.com/br4ch1st0chr0n3/the-little-things#flakes)
- Learn how to [pin inputs](https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html#flake-references)
- Study [Nix language](https://nixos.wiki/wiki/Overview_of_the_Nix_Language)

## Conventions

### Pushing to a remote repo

All flakes in this repo access some other flakes in this repo via `GitHub` URLs. 
That's why, if a change in a flake `A` here should be propagated into a flake `B`, it's necessary to update `B`'s `flake.lock`.
One can update `B`'s `flake.lock` this way iff `A`'s changes are pushed to `GitHub`.
Whenever there's a push to the remote `GitHub` repo, `B`'s `flake.lock` is updated.
That's why, there's no need to commit and push `flake.lock` changes.
After an update is completed, it's necessary to rebase the local changes onto remote changes.
Sometimes, there are local uncommitted changes.
These changes should be `git stash`ed before doing `git rebase`.
After rebasing, they can be `git stash pop`ped to continue the work.

Thus, the process is as follows:

```sh
git commit -m "another commit"
git stash
# wait some time for locks to be updated and these changes to be fetched
git rebase
git stash pop
```

## devhshell

Easily create a CLI to your `devShells`

- original `devshell` [repo](https://github.com/numtide/devshell)
- `devshell` [tutorial](https://yuanwang.ca/posts/getting-started-with-flakes.html#numtidedevshell)
- `devshell` with defaults - [here](./devshell/flake.nix)

## Templates

### VSCodium

[VSCodium troubleshooting](#vscodium-troubleshooting)

#### Generic

VSCodium with extensions and binaries

   ```console
   nix flake new codium-project -t github:br4ch1st0chr0n3/flakes#codium-generic
   cd codium-project
   git init
   git add .
   nix run .# .
   ```

- Run `hello` in a VSCodium terminal

#### Haskell

VSCodium with extensions and binaries for Haskell

   ```console
   nix flake new haskell-project -t github:br4ch1st0chr0n3/flakes#codium-haskell
   cd haskell-project
   git init
   git add .
   nix develop
   codium .
   ```

## Troubleshooting

### Substituters and keys

There are `extra-trusted-public-keys`, `extra-trusted-public-keys` (like [here](https://github.com/br4ch1st0chr0n3/flakes/blob/7bd58c9cf9708714c29dadd615d85d22ded485ae/flake.nix#L112)). If a substituter like `cachix` fails, comment out the lines containing its address

### Repair a derivation

[Derivation](https://nixos.org/manual/nix/unstable/language/derivations.html?highlight=derivation#derivations)

Repair a derivation - [manual](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-store-repair.html)

Steps:
   1. Assumptions: 
      - current directory contains `flake.nix`
      - your derivation is available inside this `flake.nix` by the name `your-corrupt-derivation`
   1. Set `packages.default = your-corrupt-derivation` in this `flake.nix`
   1. Run `nix store repair .#`
      - `.#` denotes an [installable](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix.html?highlight=installable#installables)

<!-- don't change the heading -->
### VSCodium troubleshooting

#### GitHub Personal Access Token (PAT) for VS Codium extensions

- Create a `classic` PAT with permissions: `read:user, repo, user:email, workflow`
- Supply it to extensions

#### Missing binaries on PATH in VSCodium

Case: VSCodium doesn't have the binaries provided in `runtimeDependencies` (like [here](https://github.com/br4ch1st0chr0n3/flakes/blob/7bab5d96658007f5ad0c72ec7805b5b4eb5a83dd/templates/codium/generic/flake.nix#L33)) on `PATH`:

   1. You need to repair VSCodium's derivation (see [Repair a derivation](#repair-a-derivation))
   1. Assumptions: 
      - current directory is `DIR`
      - there is a `DIR/flake.nix`
      - VSCodium is given as a derivation `codium`, like [here](https://github.com/br4ch1st0chr0n3/flakes/blob/53b2e4d8bb5fb34c50da1b45f06622bffdb9b7bf/templates/codium/generic/flake.nix#L25)
   1. In `DIR/flake.nix`, set `packages.default = codium;`, like [here](https://github.com/br4ch1st0chr0n3/flakes/blob/53b2e4d8bb5fb34c50da1b45f06622bffdb9b7bf/templates/codium/generic/flake.nix#L37)
   1. `Check`:
      1. `cd DIR`
      1. Start VSCodium: `nix run .#`
      1. Open a VSCodium terminal
      1. `echo $PATH` there
      1. It doesn't contain `/bin` dirs of specified `runtimeDependencies`
   1. Close:
      - devshells with this VSCodium
      - VSCodium itself
   1. Open a new terminal, `cd DIR`
   1. Run `nix store repair .#`
   1. Make a `Check` to verify binaries are on `PATH`
   1. If still no, continue
   1. Remove direnv profiles:
      - `cd DIR && rm -rf .direnv`
   1. Restart your OS
   1. `nix store gc` - collect garbage in Nix store - [man](https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-store-gc.html)
   1. Again, make a `Check`

