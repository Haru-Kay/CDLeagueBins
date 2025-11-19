import os
import copy
import json
import cdtb
from cdtb.storage import PatchVersion
from cdtb.binfile import BinFile
#from cdtb.rstfile import RstFile
from cdtb.tools import convert_cdragon_path, json_dump, stringtable_paths
from base64 import b64encode
from xxhash import xxh3_64_intdigest, xxh64_intdigest
from cdtb.tools import BinaryParser


class ArenaTransformer:
    def __init__(self):
        self.input_dir = "D:/CommunityDragon/Data/ObsidianExtract/data/maps/shipping/map30/"
        self.game_version = 1502

    def build_template(self):
        """Parse bin data into template data"""
        map30_file = os.path.join(self.input_dir, "map30.bin")

        map30 = BinFile(map30_file)

        augments = self.parse_augments(map30)

        return {
            "augments": augments,
        }

    def export(self, output, langs="en_us"):
        """Export Arena data for given languages

        By default (`langs` is `None`), export all available languages.
        Otherwise, export for given `xx_yy` language codes.
        """

        with open('D:/CommunityDragon/lang/lol.stringtable.json', 'r', encoding='utf-8') as file:
            stringtable = json.load(file)

        os.makedirs(output, exist_ok=True)

        template = self.build_template()
        
        instance = copy.deepcopy(template)

        def replace_in_data(entry):
            for key in ("name", "desc", "tooltip"):
                if key in entry and entry[key].lower() in stringtable:
                    entry[key] = stringtable[entry[key].lower()]
                

        for augment in instance["augments"]:
            replace_in_data(augment)
        #print(stringtable[instance["augments"][0]["name"].lower()])

        with open(os.path.join(output, f"en_us.json"), "w", encoding="utf-8") as f:
            json_dump(instance, f, indent=4, sort_keys=True, ensure_ascii=False)

    def parse_augments(self, map30):
        """Returns a list of augments"""

        augment_entries = [x for x in map30.entries if x.type == 0x6DFAB860]
        spellobject_entries = {x.path: x for x in map30.entries if x.type == "SpellObject"}

        augments = []
        for augment in augment_entries:
            if not augment.getv("enabled", True):
                continue
            augment_datavalues = {}
            augment_calculations = {}
            augment_spellobject = augment.getv(0x1418F849)
            if augment_spellobject:
                augment_spell = spellobject_entries[augment_spellobject].getv('mSpell')
                for datavalue in augment_spell.getv('DataValues', []):
                    augment_datavalues[datavalue.getv("mName")] = datavalue.getv("mValues", [0])[0]

                # Giving raw calculations data due to not having a well defined standard
                if augment_spell.get('mSpellCalculations'):
                    augment_calculations = augment_spell.get('mSpellCalculations').to_serializable()[1]

            augments.append({
                "id": augment.getv(0x827DC19E),
                "apiName": augment.getv(0x19AE3E16),
                "name": augment.getv(0x2127EB37),
                "desc": augment.getv("DescriptionTra"),
                "tooltip": augment.getv(0x366935FC),
                "iconSmall": convert_cdragon_path(augment.getv(0x45481FB5)),
                "iconLarge": convert_cdragon_path(augment.getv(0xF1F7E50D)),
                "rarity": augment.getv("rarity", 0),
                "dataValues": augment_datavalues,
                "calculations": augment_calculations,
            })

        return augments



def parse_rst(f):
    parser = BinaryParser(f)

    font_config = None
    hash_bits = 40
    game_version = 1502

    magic, version = parser.unpack("<3sB")
    if magic != b'RST':
        raise ValueError("invalid magic code")

    if version == 2:
        if parser.unpack("<B")[0]:
            n, = parser.unpack("<L")
            font_config = parser.raw(n).decode("utf-8")
        else:
            font_config = None
    elif version == 3:
        pass
    elif version in (4, 5):
        hash_bits = 39
        if game_version >= 1502:
            hash_bits = 38
    else:
        raise ValueError(f"unsupported RST version: {version}")

    hash_mask = (1 << hash_bits) - 1
    count, = parser.unpack("<L")
    entries = []
    for _ in range(count):
        v, = parser.unpack("<Q")
        entries.append((v >> hash_bits, v & hash_mask))

    print(sum(1 for e in entries if e[0] == 0x0000ef441f))

    has_trenc = False
    if version < 5:
        has_trenc = parser.unpack("<B")[0]

    data = parser.f.read()

    # Files are sometimes messed-up (e.g. windows-1252 quote)
    # Don't fail on UTF-8 decoding errors
    for i, h in entries:
        if has_trenc and data[i] == 0xFF:
            size = int.from_bytes(data[i+1:][:2], 'little')
            d = b64encode(data[i+3:][:size])
            entries[h] = d.decode('utf-8', 'replace')
        else:
            end = data.find(b"\0", i)
            d = data[i:end]
            entries[h] = d.decode('utf-8', 'replace')
    
    return entries

rstfile = None
with open("bins/data/menu/en_us/lol.stringtable", "rb") as f:
    rstfile = parse_rst(f)
rst_json = {}

for key, value in rstfile:
    key = f"{{{key:010x}}}"
    rst_json[key] = value
    
with write_file_or_remove("temp/stringtable.json", False) as fout:
    json_dump(rst_json, ensure_ascii=False)