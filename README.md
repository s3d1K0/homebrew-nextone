# homebrew-nextone

Bootstrap public pour installer NextOne.

Installation :

```bash
curl -fsSL https://raw.githubusercontent.com/s3d1K0/homebrew-nextone/main/install.sh | bash
```

Le repo est public pour exposer :
- `install.sh`
- `Formula/nextone-agent.rb`

Le code applicatif reste dans le repo prive `s3d1K0/NextOne-Agent`.

Sans acces a `s3d1K0/NextOne-Agent`, l'installation echoue pendant la verification GitHub ou au moment du `brew install nextone-agent`.
