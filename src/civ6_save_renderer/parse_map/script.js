
//// VIASH START
const par = {
  'input': "data/saves/000085.Civ6Save",
  'output': "data/saves/000085_map.bin"
};
const meta = {
  'resources_dir': "src/civ6_save_renderer/parse_map",
};

//// VIASH END

// read helper libraries & functions
const fs = require("fs");
const helper = require(meta["resources_dir"] + "/helper.js");

// read data from file
const savefile = fs.readFileSync(par.input);
const json = helper.savetomap(savefile);

// convert to tsv
const headers = Object.keys(json.tiles[0]);
const header = headers.join("\t") + "\n";
const lines = json.tiles.map(o => {
  return Object.values(o).map(b => JSON.stringify(b)).join("\t") + "\n";
});
const tsvLines = header + lines.join('')

// save to file
fs.writeFileSync(par.output, tsvLines);

