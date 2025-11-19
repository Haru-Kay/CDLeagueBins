require 'base64'
require 'digest/xxhash'

class CustomParser
  attr_accessor :file
  attr_accessor :pos
  def initialize(file)
    @file = file
    @pos = 0
  end

  def unpack(fmt)
    return read(calcsize(fmt)).unpack(fmt)
  end

  def read(length)
    read = @file[@pos...@pos + length]
    @pos += length
    return read
  end

  def calcsize(fmt)
    i = 0
    total = 0

    while i < fmt.length
      c = fmt[i]

      if c =~ /\s/
        i += 1
        next
      end

      if c == '\\'
        i += 2
        next
      end

      if c == "<" || c == ">"
        i += 1
        next
      end

      j = i + 1
      while j < fmt.length && fmt[j] =~ /\d/
        j += 1
      end
      count = fmt[i + 1...j].to_i
      count = 1 if count == 0

      case c
        when 'C', 'c' then size = 1
        when 'S', 's' then size = 2
        when 'L', 'l', 'I', 'i' then size = 4
        when 'Q', 'q' then size = 8
        when 's', 'S', 'l', 'L', 'q', 'Q'
          size = { 
            's' => 2,
            'S' => 2,
            'l' => 4,
            'L' => 4,
            'q' => 8,
            'Q' => 8
          }[c]
        when 'f' then size = 4
        when 'd' then size = 8
        when 'a', 'A', 'Z'
          if count == 1
            raise ArgumentError, "String directive '#{c}' must have a count"
          end
          size = count
        when 'x' then size = count
        when '@'
          pos = fmt[i+1...j].to_i
          total = pos
          size = 0
        else
          raise ArgumentError, "Unsupported directive #{c.inspect}"
      end

      total += size
      i = j
    end

    return total
  end
end

def intFromBytes(data, endian = :little)
  bytes = data.dup
  bytes.reverse if endian == :little
  return bytes.unpack1("H*").to_i(16)
end

def parse_rst(path)
  stringtable = nil
  File.open(path, 'rb') { |f|
    stringtable = f.read()
  }
  parser = CustomParser.new(stringtable)
  magic, version = parser.unpack("a3C")
  fontConfig = nil
  hashBits = 40

  if magic != "RST"
    puts "invalid magic code"
    return
  end
  if version == 2
    if parser.unpack("C")
      n, _ = parser.unpack("L<")
      fontConfig = parser.read(n).force_encoding("UTF-8")
    end
  elsif version == 3
    # do nothing
  elsif [4, 5].include?(version)
    hashBits = 38
  else
    puts "unsupported RST version #{version}"
    return
  end

  hashMask = (1 << hashBits) - 1
  count, _ = parser.unpack("L<")
  entries = []
  for i in 0...count
    v, _ = parser.unpack("Q<")
    entries.append([v >> hashBits, v & hashMask])
  end

  hasTrenc = false
  hasTrenc = parser.unpack("C")[0] if version < 5

  data = parser.file[parser.pos...]
  for index in 0...entries.length
    entry = entries[index]
    i, h = entry
    if hasTrenc && data[i] == 0xFF
      size = intFromBytes(data[i + 1...][...2])
      d = Base64.strict_encode64(data[i + 3...][...size])
      entries[index][1] = d.force_encoding("UTF-8")
    else
      e = data.index("\0", i) || data.length
      d = data[i...e]
      entries[index][1] = d.force_encoding("UTF-8")
    end
  end

  ret = {}
  entries.each { |entry|
    key, value = entry
    key
  }
  return entries
end

entries = parse_rst("bins/data/menu/en_us/lol.stringtable")
File.open("temp/stringtable.json", 'wb') { |f|
  f.write("{\n")
  entries.each { |entry|
    #f.write("  \"{#{Digest::XXH3_64bits.new.reset_with_secret("0" * 136).update(("%x" % entry[0]).downcase).hexdigest.to_i(16)}}\" : \"#{entry[1]}\"#{entry == entries[-1] ? "" : ","}\n")
    #puts entry[1].include?("\#") if entry[0] == 0x0000cb95d9
    f.write("\"{#{"%010x" % entry[0]}}\" : #{entry[1].gsub(/#@/, "\#@").inspect}#{entry == entries[-1] ? "" : ","}\n")
  }
  f.write("}")
}