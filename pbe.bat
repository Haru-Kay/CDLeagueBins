@echo off

snip-snip https://raw.communitydragon.org/pbe/cdragon/arena/ --filter "en_us.json" -o "arena"

snip-snip https://raw.communitydragon.org/pbe/game/data/characters/ --max-depth 2

ruby cleanup.rb