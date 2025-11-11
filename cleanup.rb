require 'json'
require 'fileutils'

home = "D:/CommunityDragon/out"

filter = [
    "bloom_",
    "brawl_",
    "bw_",
    "cherry_",
    "crepe_",
    "doombots_"
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
                File.open(filepath, 'wb') { |f| f.write(JSON.pretty_generate(champ)) }
            end
        }
    end
}

FileUtils.rm_rf(deletions)