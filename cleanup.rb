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

def localizeItems(obj)
  case obj
    when Hash
        obj.transform_values { |v| localizeItems(v) }
    when Array
        obj.map { |v| localizeItems(v) }
    when Integer
        langFetch(obj)
    when String
        if obj.start_with?("Item/")
            langFetch(obj)
        else
            obj
        end
    else
        obj
  end
end

home = "D:/CommunityDragon/out"

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


#nasus = {}
#File.open("D:/CommunityDragon/out/nasus/nasus.bin.json", 'rb') { |f| nasus = JSON.parse(f.read()) }
#File.open("D:/CommunityDragon/out/nasus/nasus.bin.json", 'wb') { |f| f.write(JSON.pretty_generate(nasus)) }

#=begin
# Arena handling
arena = {}
File.open("D:/CommunityDragon/arena/en_us.json", 'rb') { |f| arena = JSON.parse(f.read()) }
File.open("D:/CommunityDragon/arena/en_us.json", 'wb') { |f| f.write(JSON.pretty_generate(arena)) }

deletions = []
Dir.each_child(home) { |path|
    basepath = home + "/" + path
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
                champ.extend(Hashie::Extensions::DeepLocate)
                File.open(filepath, 'wb') { |f| f.write(JSON.pretty_generate(champ)) }
            end
        }
    end
}

FileUtils.rm_rf(deletions)
#=end