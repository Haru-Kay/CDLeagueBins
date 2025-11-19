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
                champion = c unless key.include?("anticheat")
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
                champion = c unless key.include?("anticheat")
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
                champion = c unless key.include?("anticheat")
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
        next if suffix.nil?
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

def augmentSearcher(key, data, version=0)
    if data["~class"]&.eql?("AugmentData")
        aug = {
            "id" => data.fetch("AugmentPlatformId", -1),
            "apiName" => data.fetch("AugmentNameId", ""),
            "name" => data.fetch("NameTra", ""),
            "rarity" => ["Silver", "Gold", "Prismatic"][data.fetch("rarity", 0).to_i.clamp(0, 2)],
            "disabled" => data.dig("Enabled") == false,
            "desc" => data.fetch("DescriptionTra", ""),
            "tooltip" => data.fetch("AugmentTooltipTra", ""),
            "dataValues" => {},
            "calculations" => {},
            "icons" => [
                data.fetch("AugmentSmallIconPath", ""),
                data.fetch("AugmentLargeIconPath", "")            
            ]
        }

        spellName = data.dig("RootSpell")
        if spellName
            spellObject = (version == 0 ? $arena : $aram).dig(spellName)
            if spellObject
                mSpell = spellObject.fetch("mSpell", {})
                dataValues = mSpell.fetch("DataValues", [])

                dataValues.each { |component|
                    name = component["mName"]
                    values = component["mValues"] || []
                    puts "#{spellName} ::: #{name}" if !values
                    values = values[0] if values.uniq.length == 1
                    aug["dataValues"].store(name, values)
                }

                calcs = mSpell.fetch("mSpellCalculations", {})
                aug["calculations"] = calcs
                
            end
        end
        aug.delete_if { |augKey, augValue|
            (augKey == "disabled" && augValue == false) ||
            (["dataValues", "calculations"].any? { |a| augKey == a } && augValue.empty?)
        }
        aug["name"] = $lang.fetch(aug["name"].downcase, aug["name"])
        aug["desc"] = $lang.fetch(aug["desc"].downcase, aug["desc"])
        aug["tooltip"] = $lang.fetch(aug["tooltip"].downcase, aug["tooltip"])
        return aug
    end
    return nil
end

def applyLang(obj)
    case obj
        when Hash
            obj.transform_values { |v| applyLang(v) }
        when Array
            obj.map { |v| applyLang(v) }
        when String
            return itemNameLangFix($lang.fetch(obj.downcase, obj))
        else
            return obj
    end
end
def itemNameLangFix(value)
    return value if !value.is_a?(String) && !value =~ "^Items/[0-9]+$"
    return "DoomBots/The Collector" if value == "Items/667666" # riot typo. collector id 6676, should be 666676.
    #game_item_displayname_//
    #item_//_name\
    #generatedtip
    strings = value.split("/")
    id = strings.find { |str| str.match?(/\A[+-]?\d+\z/) }
    ret = $lang.fetch("game_item_displayname_#{id}", $lang.fetch("item_#{id}_name", $lang.fetch("generatedtip_item_#{id}_displayname", value)))
    if ret.include?("Items") && id&.length == 6
        newid = id[2...]
        ret = $lang.fetch("game_item_displayname_#{newid}", $lang.fetch("item_#{newid}_name", $lang.fetch("generatedtip_item_#{newid}_displayname", value)))
        if ret.include?("Items")
            # Arena specific items moved to other modes
            newid = "44#{newid}"
            ret = $lang.fetch("game_item_displayname_#{newid}", $lang.fetch("item_#{newid}_name", $lang.fetch("generatedtip_item_#{newid}_displayname", value)))
        end
    end
    
    if id&.length == 4
        ret = "Swarm/#{ret}" if id.start_with?("9")
    end
    if id&.length == 6
        ret = "ARAMMayhem/#{ret}" if id.start_with?("12")
        ret = "TFT/#{ret}" if id.start_with?("22")
        ret = "Arena/#{ret}" if id.start_with?("44")
        ret = "DoomBots/#{ret}" if id.start_with?("66")
        ret = "99/#{ret}" if id.start_with?("99")
    end
    return ret
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
$arena = {}
File.open("temp/data/maps/shipping/map30/map30.json", 'rb') { |f| $arena = JSON.parse(f.read()) }
$arena = $arena.fetch("entries", $arena)
augments = []
$arena.each{ |key, data|
    v = augmentSearcher(key, data)
    augments.push(v) if !v.nil?
}

File.open("arena/augments.json", 'wb') { |f| f.write(JSON.pretty_generate(augments.sort_by { |a| a["id"] })) }
print "done.\n"

# ARAM: Mayhem Augment handling
print "Loading and formatting ARAM: Mayhem augment data..."
$aram = {}
File.open("temp/data/maps/modespecificdata/augments.json", 'rb') { |f| $aram = JSON.parse(f.read()) }
$aram = $aram.fetch("entries", $aram)
aramAugments = []
$aram.each { |key, data|
    v = augmentSearcher(key, data, 1)
    aramAugments.push(v) if !v.nil?
}
File.open("mayhem/augments.json", 'wb') { |f| f.write(JSON.pretty_generate(aramAugments.sort_by { |a| a["id"] })) }
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
itemBin = {}
items = {}
itemsSpells = {}
itemsVFX = {}
itemsTFT = {}
itemsMisc = {}
File.open("temp/data/items.ltk.json", 'rb') { |f| itemBin = JSON.parse(f.read()) }
itemBin = itemBin.fetch("entries", itemBin)
itemBin.each { |item, itemObj|
    transObj = applyLang(itemObj)
    transItem = itemNameLangFix(item)
    if transItem.include?("TFT")
        itemsTFT.store(transItem, transObj)
        next
    end
    if transObj["~class"]
        case transObj["~class"]
            when "ItemData"
                items.store(transItem, transObj)
            when "SpellObject"
                itemsSpells.store(transItem, transObj)
            when "VfxSystemDefinitionData"
                itemsVFX.store(transItem, transObj)
            else
                itemsMisc.store(transItem, transObj)
        end
    else
        itemsMisc.store(transItem, transObj)
    end
}

File.open("items/items.json", 'wb') { |f| f.write(JSON.pretty_generate(items)) }
File.open("items/itemsMisc.json", 'wb') { |f| f.write(JSON.pretty_generate(itemsMisc)) }
File.open("items/itemsVFX.json", 'wb') { |f| f.write(JSON.pretty_generate(itemsVFX)) }
File.open("items/itemsSpells.json", 'wb') { |f| f.write(JSON.pretty_generate(itemsSpells)) }
print "done.\n"

print "Loading and formatting tft.stringtable..."
tft = {}
File.open("lang/tft.stringtable.json", 'rb') { |f| tft = JSON.parse(f.read()) }
tft = tft["entries"] || tft
File.open("lang/tft.stringtable.json", 'wb') { |f| f.write(JSON.pretty_generate(tft)) }

print "done.\n"

print "Loading and formatting loadtips..."
loadtips1 = {}
$lang.each { |key, string|
    next if !key.start_with?("game_startup_tip_") || key.start_with?("game_startup_tip_category")
    id, category = key.split("game_startup_tip_")[1].split("_")
    loadtips1[category] ||= {}
    loadtips1[category].store(key, string)
}

globals = {}
File.open("temp/globals.ltk.json") { |f| globals = JSON.parse(f.read()) }
globals = globals.fetch("entries", globals)
loadtipSets = {}
globals.each { |key, value|
    if value.is_a?(Hash)
        loadtipSets.store(key, value) if value["~class"] == "LoadScreenTipSet"
    end
}

loadtips = {}
loadtipSets.each { |key, value|
    name = value["mName"]
    case name.downcase
        when "gamemodex"
            name = "Nexus Blitz"
        when "cherry"
            name = "Arena"
        when "strawberry"
            name = "Swarm"
        when "0xa110bc47"
            name = "Brawl"
        when "0x28ba866a"
            name = "Worlds"
        when "0x56b5590"
            name = "Battle of the God-Kings"
        else
            # do nothing
    end
    list = value["mTips"]
    loadtips[name] = []
    list.each { |tip|
        d = {}
        tipData = globals[tip]
        next if !tipData
        text = tipData.dig("mLocalizationKey") || tip
        next if text == "unused"
        prefix = tipData.dig("mHeaderLocalizationKey")
        d.store("type", $lang.fetch(prefix&.downcase, prefix))
        d.store("text", $lang.fetch(text.downcase, tft.fetch(text.downcase, text)))
        d.store("minimumLevel", tipData["mMinimumSummonerLevel"])
        d.store("maximumLevel", tipData["mMaximumSummonerLevel"])
        d.delete_if { |k, v| v.nil? }
        loadtips[name].push(d)
    }
}
loadtips.delete_if { |k, v| v.empty? || v.nil? }
usedStrings = []
loadtips.each { |name, tips|
    usedStrings += tips.map { |t| t["text"] }
}
for cat in loadtips1.keys
    for key in loadtips1[cat].keys
        loadtips1[cat].delete(key) if usedStrings.include?(loadtips1[cat][key])
    end
end
loadtips1.delete_if { |k, v| v.empty? || v.nil? }
loadtips.store("Unused", loadtips1)



File.open("loadtips/loadtips.json", 'wb') { |f| f.write(JSON.pretty_generate(loadtips)) }

print "done.\n"