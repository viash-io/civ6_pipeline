nextflow.enable.dsl=2

moduleRoot="./target/nextflow/civ6_save_renderer/"

include  { plot_map }      from  moduleRoot + 'plot_map/main.nf'       params(params)
include  { combine_plots } from  moduleRoot + 'combine_plots/main.nf'  params(params)
include  { convert_plot }  from  moduleRoot + 'convert_plot/main.nf'   params(params)
include  { parse_header }  from  moduleRoot + 'parse_header/main.nf'   params(params)
include  { parse_map }     from  moduleRoot + 'parse_map/main.nf'      params(params)
include  { rename }        from  './utils.nf'

workflow {

    if (params.debug == true)
        println(params)

    if (!params.containsKey("input") || params.input == "") {
        exit 1, "ERROR: Please provide a --input parameter pointing to .Civ6Save file(s)"
    }
    if (!params.containsKey("output") || params.input == "") {
        exit 1, "ERROR: Please provide a --output parameter pointing to the directory to store output"
    }

    def listToTriplet = { it -> [ "", it.collect{ a -> a[1] }, params ] }

    Channel.fromPath(params.input) \
        | map{ it -> [ it.baseName , it, params ] } \
        | ( parse_header & parse_map ) \
        | join \
        | map{ id, parse_headerOut, params1, parse_mapOut, params2 ->
            [ id, [ "yaml" : parse_headerOut, "tsv": parse_mapOut ], params1 ] } \
        | plot_map \
        | convert_plot \
        | rename \
        | toSortedList{ a,b -> a[0] <=> b[0] }  \
        | map( listToTriplet ) \
        | combine_plots

}
