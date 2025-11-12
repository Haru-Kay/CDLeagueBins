require 'json'
require 'fileutils'
require 'hashie'

$lang = {}
File.open("lang/lol.stringtable.json", 'rb') { |f| $lang = JSON.parse(f.read()) }
$lang = $lang["entries"] || $lang
File.open("lang/lol.stringtable.json", 'wb') { |f| f.write(JSON.pretty_generate($lang)) }
loadtips = {}
$lang.each { |key, string|
    next if !key.start_with?("game_startup_tip_")
    id, category = key.split("game_startup_tip_")[1].split("_")
    loadtips[category] ||= {}
    loadtips[category].store(id, string)
}
Dir.mkdir("loadtips") unless Dir.exist?("loadtips")
File.open("loadtips/loadtips.json", 'wb') { |f| f.write(JSON.pretty_generate(loadtips)) }

$maps = {
    11 => "Summoner's Rift",
    12 => "ARAM",
    21 => "Nexus Blitz",
    30 => "Arena",
}

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


# Arena handling
arena = {}
File.open("arena/en_us.json", 'rb') { |f| arena = JSON.parse(f.read()) }
File.open("arena/en_us.json", 'wb') { |f| f.write(JSON.pretty_generate(arena)) }

# ARAM: Mayhem Augment handling
aram = {}
File.open("mayhem/augments.bin.json", 'rb') { |f| aram = JSON.parse(f.read()) }
File.open("mayhem/augments.bin.json", 'wb') { |f| f.write(JSON.pretty_generate(aram)) }

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

FileUtils.rm_rf(deletions)
