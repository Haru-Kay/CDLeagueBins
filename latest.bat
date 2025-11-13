@echo off

start /b /wait snip-snip https://raw.communitydragon.org/latest/game/en_us/data/menu/en_us/ --filter "lol.stringtable.json" -o "lang"
start /b /wait snip-snip https://raw.communitydragon.org/latest/cdragon/arena/ --filter "en_us.json" -o "arena"

start /b /wait snip-snip https://raw.communitydragon.org/latest/game/ --filter "items.cdtb.bin.json" -o "items" --max-depth 1

start /b /wait snip-snip https://raw.communitydragon.org/latest/game/maps/modespecificdata/ --filter "augments.bin.json" -o "mayhem" --max-depth 1
start /b /wait snip-snip https://raw.communitydragon.org/latest/plugins/rcp-be-lol-game-data/global/default/v1/ -o "game-data" --max-depth 1

start /b /wait ruby bincompile.rb
start /b /wait ritobin -o info -i bin -r -d "Data/hashes/lol" "bins" "temp"

start /b /wait ruby cleanup.rb
pause