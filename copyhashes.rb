require 'fileutils'

Dir.each_child("Data/hashes/lol") { |f|
    FileUtils.cp("Data/hashes/lol/#{f}", "C:/Users/Kay/Documents/LeagueToolkit/wad_hashtables/#{f}")
}