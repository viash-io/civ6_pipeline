const zlib = require('zlib');

/**
 * Output a decompressed buffer from the primary zlib zip of the .Civ6Save file
 * @param {Buffer} savefile
 * @return {Buffer} decompressed
 */
function decompress(savefile) {
  const civsav = savefile;
  const bufstartindex =
    civsav.indexOf(Buffer.from([0, 0, 0, 0, 0, 1, 0, 0x78, 0x9c])) + 7;
  const bufendindex = civsav.lastIndexOf(Buffer.from([0x00, 0x00, 0xFF, 0xFF]));

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
  const bin = decompress(savefile);
  const searchBuffer = Buffer.from([0x0E, 0x00, 0x00, 0x00, 0x0F, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00]);
  const mapstartindex = bin.indexOf(searchBuffer);
  const tiles = bin.readInt32LE(mapstartindex + 12);
  const map = {'tiles': []};

  const mapWidthSearchBuffer = Buffer.concat([
    Buffer.from([0x00, 0x00, 0x00, 0x00]),
    bin.subarray(mapstartindex + 12, mapstartindex + 16),
  ]);

  let width = 0;
  let mapWidthStartIndex = -1;

  while (width === 0) {
    mapWidthStartIndex += 1;
    mapWidthStartIndex = bin.indexOf(mapWidthSearchBuffer, mapWidthStartIndex);
    width = bin.readInt16LE(mapWidthStartIndex + 8);
    
    if (width < 0) {
      width = 0;
    }
  }

  let mindex = mapstartindex + 16;

  for (let i = 0; i < tiles; i++) {
    let orig_mindex = mindex;
    
    let obj = {
      'x': i % width,
      'y': Math.floor(i / width),
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
      'overlayNum': bin.readUint32LE(mindex + 51),
    }
    mindex += 55;

    let buflength = {
      1: 24,
      2: 44,
      3: 64
    }[obj.overlayNum];

    if (buflength) {
      obj['buffer'] = bin.slice(mindex, mindex + buflength).toString('hex');
      mindex += buflength;
    } else {
      obj['buffer'] = '';
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

    // Validate next tile terrain to get us synced back up if buffer is bad
    if (i < tiles - 1) {
      const terrains = [
        2213004848,
        1855786096,
        1602466867,
        4226188894,
        3872285854,
        2746853616,
        3852995116,
        3108058291,
        1418772217,
        1223859883,
        3949113590,
        3746160061,
        1743422479,
        3842183808,
        699483892,
        1248885265,
        1204357597
      ];

      let nextTerrainOffset = 0;

      while (nextTerrainOffset < 100 && !terrains.includes(bin.readUint32LE(mindex + nextTerrainOffset))) {
        nextTerrainOffset++;  
      }

      if (nextTerrainOffset < 100) {
        mindex = mindex - 12 + nextTerrainOffset;
      }
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
