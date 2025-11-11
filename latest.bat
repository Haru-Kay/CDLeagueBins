@echo off

snip-snip https://raw.communitydragon.org/latest/game/en_us/data/menu/en_us/ --filter "lol.stringtable.json" -o "lang"
snip-snip https://raw.communitydragon.org/latest/cdragon/arena/ --filter "en_us.json" -o "arena"

snip-snip https://raw.communitydragon.org/latest/game/data/characters/ --max-depth 2
snip-snip https://raw.communitydragon.org/latest/game/ --filter "items.cdtb.bin.json" -o "items" --max-depth 1

ruby cleanup.rb