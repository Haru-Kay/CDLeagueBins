require 'json'
require 'fileutils'
require 'hashie'

def removeFluff(obj)
    values = [
        "ItemRecommendationOverrideSet",
        "RecSpellRankUpInfoList",
        "ItemRecommendationContextList",
        "ChampionRuneRecommendationsContext",
        "JunglePathRecommendation"
    ]
    obj.delete_if { |key, value|
        key == "__linked" || (value.is_a?(Hash) && values.include?(value["__type"]))
    }

end

print "Loading and formatting stringtable..."
$lang = {}
File.open("lang/lol.stringtable.json", 'rb') { |f| $lang = JSON.parse(f.read()) }
$lang = $lang["entries"] || $lang
File.open("lang/lol.stringtable.json", 'wb') { |f| f.write(JSON.pretty_generate($lang)) }
print "done.\n"

print "Extracting loading screen tips..."
loadtips = {}
$lang.each { |key, string|
    next if !key.start_with?("game_startup_tip_")
    id, category = key.split("game_startup_tip_")[1].split("_")
    loadtips[category] ||= {}
    loadtips[category].store(id, string.gsub("''", "'"))
}
Dir.mkdir("loadtips") unless Dir.exist?("loadtips")
File.open("loadtips/loadtips.json", 'wb') { |f| f.write(JSON.pretty_generate(loadtips)) }
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
filter = [
    "bloom_",
    "brawl_",
    "bw_",
    "cherry_",
    "crepe_",
    "doombots_",
    "durian_",
    "ha_",
    "habw_",
    "nexusblitz_",
    "nightmarebots_",
    "npc_",
    "ruby_",
    "slime_",
    "sru_",
    "sruap_",
    "srx_",
    "strawberry_",
    "testcube",
    "tft",
    "tutorial_",
    "ultbook",
    "urf_"
]
deletions = []
Dir.each_child("out") { |path|
    basepath = "out/" + path
    if filter.any? { |prefix| path.start_with?(prefix) }
        deletions.push(basepath)
    else
        Dir.each_child(basepath) { |file|
            filepath = basepath + "/" + file
            if !file.end_with?(".json")
                deletions.push(filepath)
            else
                champ = {}
                File.open(filepath, 'rb') { |f| champ = JSON.parse(f.read()) }

                File.open(filepath, 'wb') { |f| f.write(JSON.pretty_generate(removeFluff(champ))) }
            end
        }
    end
}
print "done.\n"
print "Deleting bloat (see 'filter' variable in code for modifying)..."
FileUtils.rm_rf(deletions)
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