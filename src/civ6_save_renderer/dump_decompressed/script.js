
//// VIASH START
let par = {
  'input': "data/saves/000085.Civ6Save",
  'output': "data/saves/000085_map.bin"
};
let meta = {
  'resources_dir': "src/civ6_save_renderer/parse_map",
};

//// VIASH END

// read helper libraries & functions
let fs = require("fs");
let helper = require(meta["resources_dir"] + "/helper.js");

// read data from file
let savefile = fs.readFileSync(par.input);
let bin = helper.decompress(savefile);
fs.writeFileSync(par.output, bin);