require 'json'
require 'fileutils'
require 'hashie'

$lang = {}
File.open("D:/CommunityDragon/lang/lol.stringtable.json", 'rb') { |f| $lang = JSON.parse(f.read()).values[0] }

$maps = {
    11 => "Summoner's Rift",
    12 => "ARAM",
    21 => "Nexus Blitz",
    30 => "Arena",
}

$itemSearches = [
    "mPopularItems",
    "mItemList",
    "mChoices",
    "items"
]

def langFetch(obj)
    obj = obj.split("/")[1] if obj.is_a?(String)
    obj = obj.to_s
    obj = obj.to_s[-4..] if obj.length > 0
    name = $lang.fetch("item_#{obj}_name", obj)
    name = $lang.fetch("game_item_displayname_#{obj}", obj) if name.to_s.include?("{")
    name
end

def localizeChampItems(obj, current_key = nil)
    case obj
        when Hash
            obj.each { |k, v| obj[k] = localizeChampItems(v, k) }
        when Array
            obj.map! { |v| localizeChampItems(v, current_key) }
        when Integer
            if $itemSearches.include?(current_key.to_s)
                langFetch(obj)
            else
                obj
            end
        when String
            if $itemSearches.include?(current_key.to_s) || obj.start_with?("Item/")
                langFetch(obj)
            else
                obj
            end
        else
            obj
    end
end

home = "D:/CommunityDragon"

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
File.open("#{home}/arena/en_us.json", 'rb') { |f| arena = JSON.parse(f.read()) }
File.open("#{home}/arena/en_us.json", 'wb') { |f| f.write(JSON.pretty_generate(arena)) }

deletions = []
Dir.each_child("#{home}/out") { |path|
    next
    basepath = home + "/out/" + path
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
                File.open(filepath, 'wb') { |f| f.write(JSON.pretty_generate(localizeChampItems(champ))) }
            end
        }
    end
}

items = {}
File.open("#{home}/items/items.cdtb.bin.json", 'rb') { |f| items = JSON.parse(f.read()) }

items.each { |item, itemObj|
    if itemObj.is_a?(Hash)
        itemObj.each { |k, v|
            next if !v.is_a?(String)
            itemObj[k] = $lang.fetch(v.downcase, v) if k == "mDisplayName"
        }
    end
}

File.open("#{home}/items/items.cdtb.bin.json", 'wb') { |f| f.write(JSON.pretty_generate(items)) }

FileUtils.rm_rf(deletions)
