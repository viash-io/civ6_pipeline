const zlib = require('zlib');

/**
 * Output a decompressed buffer from the primary zlib zip of the .Civ6Save file
 * @param {Buffer} savefile
 * @return {Buffer} decompressed
 */
function decompress(savefile) {
  const civsav = savefile;
  const modindex = civsav.lastIndexOf('MOD_TITLE');
  const bufstartindex = civsav.indexOf(new Buffer([0x78, 0x9c]), modindex);
  const bufendindex = civsav.lastIndexOf(new Buffer([0x00, 0x00, 0xFF, 0xFF]));

  const data = civsav.slice(bufstartindex, bufendindex);

  // drop 4 bytes away after every chunk
  const chunkSize = 64 * 1024;
  const chunks = [];
  let pos = 0;
  while (pos < data.length) {
    chunks.push(data.slice(pos, pos + chunkSize));
    pos += chunkSize + 4;
  }
  const compressedData = Buffer.concat(chunks);

  const decompressed = zlib.inflateSync(compressedData, {finishFlush: zlib.Z_SYNC_FLUSH});

  return decompressed;
}

/**
 * Convert compressed tile data in .Civ6Save file into json format
 * @param {buffer} savefile
 * @return {object} tiles
 */
function savetomap(savefile) {
  const mapsizedata = {
    '1144': {x: 44, y: 26},
    '2280': {x: 60, y: 38},
    '3404': {x: 74, y: 46},
    '4536': {x: 84, y: 54},
    '5760': {x: 96, y: 60},
    '6996': {x: 106, y: 66},
  }

  const bin = decompress(savefile);
  const searchBuffer = new Buffer([0x0E, 0x00, 0x00, 0x00, 0x0F, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00]);
  const mapstartindex = bin.indexOf(searchBuffer);
  const tiles = bin.readInt32LE(mapstartindex + 12);
  const map = {'tiles': []};

  let mindex = mapstartindex + 16;

  for (let i = 0; i < tiles; i++) {
    let orig_mindex = mindex;
    
    let obj = {
      'x': i % mapsizedata[tiles].x,
      'y': Math.floor(i / mapsizedata[tiles].x),
      'hex_location': mindex,
      'travel_regions': bin.readUInt32LE(mindex),
      'connected_regions': bin.readUInt32LE(mindex + 4),
      'landmass': bin.readUInt32LE(mindex + 8),
      'terrain': bin.readUInt32LE(mindex + 12),
      'feature': bin.readUInt32LE(mindex + 16),
      'natural_wonder_order': bin.readUInt16LE(mindex + 20),
      'continent': bin.readUInt32LE(mindex + 22),
      'number_of_units': bin.readUInt8(mindex + 26),
      'resource': bin.readUInt32LE(mindex + 27),
      'resource_boolean': bin.readUInt16LE(mindex + 31),
      'improvement': bin.readUInt32LE(mindex + 33),
      'improvement_owner': bin.readInt8(mindex + 37),
      'road': bin.readInt16LE(mindex + 38),                // -1: none, 257: classical, 1026: industrial, 1283: modern
      'appeal': bin.readInt16LE(mindex + 40),
      'river_e': bin.readInt8(mindex + 42),                // river at eastern border        -1: no, 0: yes, 3: yes
      'river_se': bin.readInt8(mindex + 43),               // river at south-eastern border  -1: no, 1: yes, 4: yes
      'river_sw': bin.readInt8(mindex + 44),               // river at south-western border  -1: no, 2: yes, 5: yes
      'river_count': bin.readUInt8(mindex + 45),           // number of adjacent river tiles
      'river_map': bin.readUInt8(mindex + 46),             // river 6 bits: NW, W, SW, SE, E, NE
      'cliff_map': bin.readUInt8(mindex + 47),             // cliff 6 bits: NW, W, SW, SE, E, NE
      'flags1': bin.readUInt8(mindex + 48),                // bits: [is_pillaged, road_pillaged??, has_road, is_capital_or_citystate, -, river_sw, river_e, river_se]
      'flags2': bin.readUInt8(mindex + 49),                // bits: [cliff_sw, cliff_e, cliff_se, -, -, is_impassable, is_owned, -]
      'flags3': bin.readUInt8(mindex + 50),                // bits: [is_ice, -, -, -, -, -, -, -]
      'flags4': bin.readUInt8(mindex + 51),                // bits: [buffer length 24, buffer length 44, -, -, -, -, -, -]
      'flags5': bin.readUInt8(mindex + 52),                // empty?
      'flags6': bin.readUInt8(mindex + 53),                // empty?
      'flags7': bin.readUInt8(mindex + 54),                // empty?
    }
    mindex += 55;
    
    let buflength = 0;

    if (obj['flags4'] & 1) {
      // tile produces/captures co2?
      obj['buffer1'] = bin.slice(mindex, mindex + 24).toString('hex');
      obj['buffer1_flag'] = bin.readUInt8(mindex + 20);
      mindex += 24;
     
      if (obj['buffer1_flag'] & 1) {
        // tile is ski resort or tunnel??
        obj['buffer2'] = bin.slice(mindex, mindex + 20).toString('hex');
        mindex += 20;
      } else {
        obj['buffer2'] = '';
      }
    } else if (obj['flags4'] & 2) {
      obj['buffer1'] = bin.slice(mindex, mindex + 24).toString('hex');
      obj['buffer1_flag'] = bin.readUInt8(mindex + 20);
      obj['buffer2'] = bin.slice(mindex + 24, mindex + 44).toString('hex');
      mindex += 44;
    } else {
      obj['buffer1'] = '';
      obj['buffer1_flag'] = '';
      obj['buffer2'] = '';
    }

    if (obj['flags2'] & 64) {
      // tile is owned by a player
      obj['city_1'] = bin.readUInt32LE(mindex);
      obj['city_2'] = bin.readUInt32LE(mindex + 4);
      obj['district'] = bin.readUInt32LE(mindex + 8);
      obj['owner'] = bin.readUInt8(mindex + 12);
      obj['world_wonder'] = bin.readUInt32LE(mindex + 13);
      mindex += 17;
    } else {
      obj['city_1'] = '';
      obj['city_2'] = '';
      obj['district'] = '';
      obj['owner'] = '';
      obj['world_wonder'] = '';
    }
    
    obj['tile_length'] = mindex - orig_mindex;

    map.tiles.push(obj);
  }
  return map;
}

module.exports = {
  decompress,
  savetomap
}
