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
        :aprilfools => {},
        :bots => {},
        :spellbook => {}
    }
    filters = {
        ["tft", "teamplanner", "set6", "set8", "tier", "_spiritblossom_", "sgpig_journey_name", "companion", "durian", "chibi"] => :tft,
        ["game_objecttooltips", "tutorial", "learning_quests", "game_intro", "protips", "newplayerquest"] => :tutorial,
        ["tooltip"] => :tooltips,
        ["loot", "chroma", "loadout_", "sight_ward", "game_summoner_emote", "game_summoner_description", "summoner_icon", "regalia", "ward_", "player_title",
            "mastery_title"] => :loot,
        ["game_character_skin", "skin_augment", "current_form_tooltip", "current_meter", "selection_button"] => :skins,
        ["skin_line", "skinline"] => :skinlines,
        ["chroma"] => :chromas,
        ["queue"] => :queues,
        ["strawberry", "augment_special", "augment_weapon", "augment_stat", "augment_upgrade", "augment_default", "streaberry", "passive_desc_pickupradius",
            "rewards_details_boss_"] => :swarm,
        ["kiwi", "kingme", "upgrademodifier"] => :mayhem,
        ["cherry", "lolmode_phase", "augment"] => :arena,
        ["ruby"] => :doombots,
        ["crepe"] => :aracanearam,
        ["slime"] => :nexusblitz,
        ["awesome"] => :urf,
        ["ultbook"] => :spellbook,
        ["spell"] => :spells,
        ["buff_", "_buff", "buffdesc", "3181buffname", "3181minionbuff"] => :buffs,
        ["game_character_lore"] => :lore,
        ["game_startup_tip"] => :loadtips,
        ["perk"] => :runes,
        ["stat_stone"] => :eternals,
        ["brawl_"] => :brawl,
        ["challenges", "challenge_", "rewardgroup"] => :challenges,
        ["item"] => :items,
        ["generatedtip_passive_"] => :champs,
        ["game_character_"] => :units,
        ["ap2025", "aprilfools2025", "ap_shacoskin_bothparty"] => :aprilfools,
        ["bark_", "bountyhunter"] => :misc,
        ["game_bot"] => :bots
    }
    reverse = filters.invert
    champIgnore = reverse[:swarm] + reverse[:mayhem] + reverse[:arena] + reverse[:doombots] + reverse[:aracanearam] + reverse[:nexusblitz] + 
        reverse[:urf] + reverse[:challenges] + reverse[:misc] + reverse[:tft] + reverse[:aprilfools] + reverse[:skins] + reverse[:eternals]
    override = [
        "spell_viktorgravitonfield_augmentslow",
        "generatedtip_passive_heightenedlearning_description",
        "generatedtip_passive_heightenedlearning_displayname"
    ]
    $lang.each { |key, tl|
        next if tl.empty? || tl == "unused, please delete"
        found = nil
        filters.each { |filter, dest|
            if filter.any? { |id| key.include?(id) }
                out[dest].store(key, tl)
                found = dest
                break
            end
        }
        if ($champLang.any? { |champ| key.include?(champ) } && !found) || override.include?(key)
            out[:champs].store(key, tl)
            out[found].delete(key) if override.include?(key)
            found = :champs
            next
        end
        out[:misc].store(key, tl) if !found
    }

    out.each { |type, data|
        if type == :champs
            champsort = {}
            $champLang.sort.each { |champ|
                data.sort_by { |k, v| k }.to_h.each { |k, v|
                    champsort.store(k, v) if k.include?(champ)
                }
            }
            
            File.open("lang/#{type}.json", 'wb') { |f| f.write(JSON.pretty_generate(champsort)) }
        else
            File.open("lang/#{type}.json", 'wb') { |f| f.write(JSON.pretty_generate(data.sort_by { |k, v| k }.to_h)) }
        end
    }

end

def badString?(key, value) 
    badKeys = [
        "GeneratedTip",
        "TFT",
        #"Cherry",
        #"Kiwi",
        #"Ruby",
        #"Strawberry",
        #"Brawl",
        #"Crepe",
        #"Slime",
        #"Awesome",
        "aprilfools",
        "ultbook",
        "companion"
    ]

    badValues = [
        #going to assume that no normal English words will contain this
        #a string containing a {{GeneratedTip_XXX}} reference is not guaranteed to be invalid however
        "TFT",
        #"Cherry",
        #"Kiwi",
        #"Ruby",
        #"Strawberry",
        #"Crepe",
        "aprilfools",
        "ultbook",
    ]

    return true if badKeys.any? { |str| key.include?(str.downcase) }
    return true if badValues.any? { |str| value.include?(str.downcase) }
    return false
end

def diff
    print "Loading previous patch stringtable..."
    oldLang = {}
    File.open("live.lol.stringtable.json", 'rb') { |f| oldLang = JSON.parse(f.read()) }
    oldLang = oldLang["entries"] || oldLang
    print "done.\n"

    print "Finding file diffs..."
    newStrings = {}
    removedStrings = {}
    changedStrings = {}

    oldLang.each { |key, tl|
        next if badString?(key, tl)
        newTl = $lang[key]

        if newTl.nil?
            removedStrings.store(key, tl)
        else
            changedStrings.store(key, [tl, newTl]) if tl != newTl
        end
    }

    $lang.each { |key, newTl|
        next if badString?(key, newTl)
        tl = oldLang[key]
        if tl.nil?
            newStrings.store(key, newTl)
        end
    }
    
    output = ""
    champDiff = {}
    removedStrings.each { |key, tl|
        champion = nil
        $champLang.each { |c| 
            if key.include?(c)
                champion = c
                break
            end
        }

        str = "REMOVED:\n#{key.inspect} = #{tl.inspect}\n"
        output += str
        if champion
            champDiff[champion] ||= [] if champion
            champDiff[champion].push(str)
        end
    }
    newStrings.each { |key, tl|
        champion = nil
        $champLang.each { |c| 
            if key.include?(c)
                champion = c
                break
            end
        }
        
        str = "ADDED:\n#{key.inspect} = #{tl.inspect}\n"
        output += str
        if champion
            champDiff[champion] ||= [] if champion
            champDiff[champion].push(str)
        end
    }
    changedStrings.each { |key, tl|
        champion = nil
        $champLang.each { |c| 
            if key.include?(c)
                champion = c
                break
            end
        }
        
        oldStr, newStr = tl

        firstDiff = -1
        i = 0
        while i < oldStr.length && i < newStr.length
            if oldStr[i] != newStr[i]
                firstDiff = i
                break
            end
            i += 1
        end

        oldLastDiff = 0
        newLastDiff = 0
        if firstDiff < 0
            # append/removal. strings were equal until one ended
            firstDiff = oldStr.length < newStr.length ? oldStr.length : newStr.length
            oldLastDiff = firstDiff
            newLastDiff = firstDiff
        else
            i = oldStr.length - 1
            j = newStr.length - 1
            while i >= firstDiff && j >= firstDiff
                if oldStr[i] != newStr[j]
                    oldLastDiff = i
                    newLastDiff = j
                    break
                end
                if i == firstDiff || j == firstDiff
                    oldLastDiff = i - 1
                    newLastDiff = j - 1
                    break
                end
                i -= 1
                j -= 1
            end
        end
        
        prefix = oldStr[0, firstDiff]
        oldInfix = oldStr[firstDiff, oldLastDiff - firstDiff + 1]
        newInfix = newStr[firstDiff, newLastDiff - firstDiff + 1]
        suffix = oldStr[oldLastDiff + 1...]

        str = "CHANGED:\n#{key.inspect} =\n#{prefix.inspect}...\n  ...#{oldInfix.inspect}...\n  -->\n  ...#{newInfix.inspect}...\n#{suffix.inspect}\n"
        output += str
        if champion
            champDiff[champion] ||= [] if champion
            champDiff[champion].push(str)
        end
    }

    output2 = ""
    champDiff.each { |champ, changes|
        output2 += "#{champ}:\n"
        changes.each { |change|
            output2 += change
        }
        output2 += "\n"
    }

    File.open("filediffs/lang.txt", 'wb') { |f| f.write(output) }
    File.open("filediffs/champs.txt", 'wb') { |f| f.write(output2) }
    print "done.\n"
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
$champLang = []
File.open("game-data/champion-summary.json", 'rb') { |f| 
    c = JSON.parse(f.read()) 
    c.each { |champ|
        next if !champ.is_a?(Hash)
        id = champ["id"]
        name = champ["name"]
        champs.store(id, name)
        $champLang.push(champ["alias"].downcase)
    }
}
queues.each { |queue|
    next if !queue.is_a?(Hash)
    next if !queue["viableChampionRoster"]
    queue["viableChampionRoster"] = queue["viableChampionRoster"].map { |v| champs.fetch(v, v) }
}
File.open("game-data/queues.json", 'wb') { |f| f.write(JSON.pretty_generate(queues)) }
print "done.\n"

diff()

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
