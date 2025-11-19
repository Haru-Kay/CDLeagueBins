require 'concurrent-ruby'
loc, fluff = *ARGV 
loc = "C:/Program Files (x86)/Riot Games/League of Legends/League of Legends" if !loc
loc = "D:/Games/Riot Games/League of Legends (PBE)" if loc.to_i == 1

path = "#{loc}/Game/DATA/FINAL/"
champs = []

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
Dir.each_child(path+"Champions") { |d|
    next if filter.any? { |f| d.downcase.start_with?(f) }
    champs.push(d.split(".")[0])
    champs.uniq!
}

pool = Concurrent::FixedThreadPool.new(7)
champs.each { |champ|
    pool.post { 
        system("wadtools -L error --progress false e -i \"#{path}Champions/#{champ}.wad.client\" -o \"#{Dir.getwd}/bins\" -x \"^data/characters/(.*?)/\\1\\.bin$\"")
        puts "Generated #{champ}"
    }
}

pool.post {
    system("wadtools -L error --progress false e -i \"#{path}Maps/Shipping/Map30.wad.client\" -o \"#{Dir.getwd}/bins\" -x \"^data/maps/shipping/map30/map30.bin$\"")
    puts "Generated arena"
}
pool.post {
    system("wadtools -L error --progress false e -i \"#{path}Maps/Shipping/Map12.wad.client\" -o \"#{Dir.getwd}/bins/data\" -x \"^maps/modespecificdata/augments.bin$\"")
    puts "Generated mayhem"
}
pool.post {
    system("wadtools -L error --progress false e -i \"#{path}Global.wad.client\" -o \"#{Dir.getwd}/bins/data\" -x \"^items$\"")
    puts "Generated items"
}
# Map30.wad.client data/maps/shipping/map30/map30.bin
# Map12.wad.client data/maps/augments.bin

pool.shutdown
pool.wait_for_termination
