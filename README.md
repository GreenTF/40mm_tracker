# 40mm Tracking server mod

This mod connects a server to the 40mm rating system, which currently lives at
https://40mm.greenboi.me

# Usage

Simply install this mod as usual, then reach out to `anactualemerald` in the
Northstar discord to get an API key. Pass that key to the mod by setting the
`40mm_api_key` convar

## example

If you're using docker-compose to host your server, you'd want something that 
looks like
```yml
...
environment:
  - |
    NS_EXTRA_ARGS=
    +40mm_api_key yourlongapikeyhere
...
```
