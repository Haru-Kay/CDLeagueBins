@echo off

snip-snip https://raw.communitydragon.org/pbe/game/en_us/data/menu/en_us/ --filter "lol.stringtable.json" -o "lang"
snip-snip https://raw.communitydragon.org/pbe/cdragon/arena/ --filter "en_us.json" -o "arena"

snip-snip https://raw.communitydragon.org/pbe/game/data/characters/ --max-depth 2
snip-snip https://raw.communitydragon.org/pbe/game/ --filter "items.cdtb.bin.json" -o "items"

ruby cleanup.rb