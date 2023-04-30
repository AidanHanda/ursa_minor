# Ursa Minor

Built because I wanted a quick tool that would let me update DNS entries with Dynamic IP addresses. This tool is somewhat hacky - I wrote it in an hour.

## Install

Install with `opam install ursa_minor.opam`

## Example Config

You can run with: `ursa_minor -config config.sexp`

Where `config.sexp` looks like
```
((Cloudflare (
  (apikey somekeyhere)
  (zone   example.com)
  (url    some.example.com)))
 (Cloudflare (
  (apikey somekeyhere)
  (zone   example.com)
  (url    another.example.com))))
```
