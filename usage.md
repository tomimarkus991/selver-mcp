# Usage

## How you use it

```bash
cd ~/Documents/code/selver-mcp
cp .mcp.json.example .mcp.json      # fill in SELVER_ID_CODE
devcontainer exec --workspace-folder . claude
```

### Where to get `SELVER_ID_CODE`

It's your Estonian personal identification code (isikukood): the 11-digit number on your ID card, passport
or residence permit (e.g. `39001010000`), also shown after logging in to [eesti.ee](https://www.eesti.ee).
It must belong to the Smart-ID account you log in to Selver with, because login sends a confirmation
to that Smart-ID app.

`.mcp.json` is gitignored, so the code stays on your machine.
