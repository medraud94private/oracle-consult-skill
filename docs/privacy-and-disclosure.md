# Privacy and Disclosure

Oracle sends prompts and selected files to an external model path, usually ChatGPT browser automation or an API provider.

Do not attach secrets by default:

- `.env` files
- credentials, tokens, cookies, or private keys
- service-account files
- auth dumps
- unredacted production logs
- database exports
- private session transcripts

Oracle session artifacts can persist under `$HOME\.oracle\sessions`. Treat those transcripts as sensitive if the prompt or attached files were sensitive.

