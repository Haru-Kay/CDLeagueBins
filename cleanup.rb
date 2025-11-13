require 'json'
require 'fileutils'
require 'hashie'

def formatChampion(obj)
    obj = obj.fetch("entries", obj)
    fluff = [
        "ItemRecommendationOverrideSet",
        "RecSpellRankUpInfoList",
        "ItemRecommendationContextList",
        "ChampionRuneRecommendationsContext",
        "JunglePathRecommendation"
    ]
    obj.delete_if { |key, value|
        (value.is_a?(Hash) && fluff.include?(value["~class"]))
    }
    # TODO: Statstones and other hash values
    #obj.each { |key, value| }

    return obj
end

def sortLang
    out = {
        :tft => {}, #tft, teamplanner
        :tutorial => {}, #game_objecttooltips, tutorial, learning_quests, protips, newplayerquest
        :tooltips => {}, #tooltip
        :loot => {}, #loot, chroma, loadout_, sight_ward, game_summoner_emote, game_summoner_description, summoner_icon, regalia
        :skins => {}, #game_character_skin, skin_, current_form_tooltip, current_meter
        :skinlines => {}, #skin_line, skinline
        :chromas => {}, #chroma
        :urf => {}, #awesome
        :mayhem => {}, #kiwi
        :arena => {}, #cherry, lolmode_phase
        :swarm => {}, #strawberry, augment_special
        :brawl => {}, #brawl
        :doombots => {}, #ruby
        :aracanearam => {}, #crepe
        :nexusblitz => {}, #slime
        :items => {}, #game_items
        :spells => {}, #spells RUN AFTER TFT
        :buffs => {}, #buff
        :lore => {}, #game_character_lore
        :runes => {}, #perk
        :eternals => {}, #stat_stone
        :queues => {}, #queue
        :challenges => {}, #challenges, challenge_, rewardgroup
        :loadtips => {},
        :titles => {}, #player_title,
        :champs => {}, #champs, generatedtip_passive_
        :units => {}, #game_character
        :misc => {}, #replayui, game_cheats, game_hud, scoreboard, game_floatingtext, game_, standalone, lolmodes, shop_, vanguard, 
                    #stats_filter, message_box, replaycameracontrolpanel, loading_screen, surrender, reminder_, radial_menu,
                    #playercard_switcher_, keyboard_lcd, game_announcement
    }
    filters = {
        ["tft", "teamplanner", "set6", "set8", "tier", "_spiritblossom_", "sgpig_journey_name", "companion"] => :tft,
        ["game_objecttooltips", "tutorial", "learning_quests", "game_intro", "protips", "newplayerquest"] => :tutorial,
        ["tooltip"] => :tooltips,
        ["loot", "chroma", "loadout_", "sight_ward", "game_summoner_emote", "game_summoner_description", "summoner_icon", "regalia", "ward_", "player_title"] => :loot,
        ["game_character_skin", "skin", "current_form_tooltip", "current_meter", "selection_button"] => :skins,
        ["skin_line", "skinline"] => :skinlines,
        ["chroma"] => :chromas,
        ["strawberry", "augment_special", "augment_weapon", "augment_stat", "augment_upgrade", "augment_default", "streaberry", "passive_desc_pickupradius"] => :swarm,
        ["cherry", "lolmode_phase", "augment"] => :arena,
        ["ruby"] => :doombots,
        ["kiwi"] => :mayhem,
        ["crepe"] => :aracanearam,
        ["slime"] => :nexusblitz,
        ["awesome"] => :urf,
        ["spell"] => :spells,
        ["buff"] => :buffs,
        ["game_character_lore"] => :lore,
        ["game_startup_tip"] => :loadtips,
        ["perk"] => :runes,
        ["stat_stone"] => :eternals,
        ["queue"] => :queues,
        ["brawl"] => :brawl,
        ["challenges", "challenge_", "rewardgroup"] => :challenges,
        ["item"] => :items,
        ["generatedtip_passive_"] => :champs,
        ["game_character_"] => :units 
    }
    $lang.each { |key, tl|
        found = false
        filters.each { |filter, dest|
            if filter.any? { |id| key.include?(id) }
                out[dest].store(key, tl)
                found = true
                break
            end
        }
        out[:misc].store(key, tl) if !found
    }

    out.each { |type, data|
        File.open("lang/#{type}.json", 'wb') { |f| f.write(JSON.pretty_generate(data.sort_by { |k, v| k })) }
    }

end

print "Loading and formatting stringtable..."
$lang = {}
File.open("lang/lol.stringtable.json", 'rb') { |f| $lang = JSON.parse(f.read()) }
$lang = $lang["entries"] || $lang
File.open("lang/lol.stringtable.json", 'wb') { |f| f.write(JSON.pretty_generate($lang)) }
print "done.\n"

print "Loading and formatting miscellaneous game data..."
Dir.each_child("game-data") { |path|
    data = {}
    File.open("game-data/#{path}", 'rb') { |f| data = JSON.parse(f.read()) }

    File.open("game-data/#{path}", 'wb') { |f| f.write(JSON.pretty_generate(data)) }
}

queues = {}
File.open("game-data/queues.json", 'rb') { |f| queues = JSON.parse(f.read()) }
champs = {}
File.open("game-data/champion-summary.json", 'rb') { |f| 
    c = JSON.parse(f.read()) 
    c.each { |champ|
        next if !champ.is_a?(Hash)
        id = champ["id"]
        name = champ["name"]
        champs.store(id, name)
    }
}
queues.each { |queue|
    next if !queue.is_a?(Hash)
    next if !queue["viableChampionRoster"]
    queue["viableChampionRoster"] = queue["viableChampionRoster"].map { |v| champs.fetch(v, v) }
}
File.open("game-data/queues.json", 'wb') { |f| f.write(JSON.pretty_generate(queues)) }
print "done.\n"

print "Extracting and sorting lang data..."
sortLang()
print "done.\n"

print "Loading and formatting map data..."
$maps = {}
File.open("game-data/maps.json", 'rb') { |f| $maps = JSON.parse(f.read()) }
File.open("game-data/maps.json", 'wb') { |f| f.write(JSON.pretty_generate($maps)) }
print "done.\n"

# Arena handling
print "Loading and formatting Arena augment data..."
arena = {}
File.open("arena/en_us.json", 'rb') { |f| arena = JSON.parse(f.read()) }
File.open("arena/en_us.json", 'wb') { |f| f.write(JSON.pretty_generate(arena)) }
print "done.\n"

# ARAM: Mayhem Augment handling
print "Loading and formatting ARAM: Mayhem augment data..."
aram = {}
File.open("mayhem/augments.bin.json", 'rb') { |f| aram = JSON.parse(f.read()) }
File.open("mayhem/augments.bin.json", 'wb') { |f| f.write(JSON.pretty_generate(aram)) }
print "done.\n"

print "Loading and formatting champion data..."
Dir.mkdir("champions") if !Dir.exist?("champions")
deletions = []
Dir.each_child("temp/data/characters") { |path|
    basepath = "temp/data/characters/" + path
    Dir.each_child(basepath) { |file|
        filepath = basepath + "/" + file
        champ = {}
        File.open(filepath, 'rb') { |f| champ = JSON.parse(f.read()) }
        File.open("champions/" + file, 'wb') { |f| f.write(JSON.pretty_generate(formatChampion(champ))) }
    }
}
print "done.\n"

print "Loading and formatting item data..."
items = {}
File.open("items/items.cdtb.bin.json", 'rb') { |f| items = JSON.parse(f.read()) }

items.each { |item, itemObj|
    if itemObj.is_a?(Hash)
        itemObj.each { |k, v|
            next if !v.is_a?(String)
            itemObj[k] = $lang.fetch(v.downcase, v) if v.include?("_") && k == "mDisplayName"
        }
    end
}

File.open("items/items.cdtb.bin.json", 'wb') { |f| f.write(JSON.pretty_generate(items)) }
print "done.\n"
