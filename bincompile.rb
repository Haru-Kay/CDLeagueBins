require 'concurrent-ruby'
loc, fluff = *ARGV 
loc = "C:/Program Files (x86)/Riot Games/League of Legends/League of Legends" if !loc
loc = "D:/Games/Riot Games/League of Legends (PBE)" if loc.to_i == 1

path = "#{loc}/Game/DATA/FINAL/Champions/"
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
Dir.each_child(path) { |d|
    next if filter.any? { |f| d.downcase.start_with?(f) }
    champs.push(d.split(".")[0])
    champs.uniq!
}

pool = Concurrent::FixedThreadPool.new(7)
champs.each { |champ|
    puts "Starting #{champ}"
    pool.post { system("wadtools -L error --progress false e -i \"#{path}#{champ}.wad.client\" -o \"#{Dir.getwd}/bins\" -x \"^data/characters/(.*?)/\\1\\.bin$\""); puts "Finished #{champ}" }
}

pool.shutdown
pool.wait_for_termination
