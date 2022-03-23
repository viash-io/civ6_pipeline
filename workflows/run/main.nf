nextflow.enable.dsl=2

workflowDir = "${params.rootDir}/workflows"
targetDir = "${params.rootDir}/target/nextflow"

include  { plot_map }      from  targetDir + '/civ6_save_renderer/plot_map/main.nf'       params(params)
include  { combine_plots } from  targetDir + '/civ6_save_renderer/combine_plots/main.nf'  params(params)
include  { convert_plot }  from  targetDir + '/civ6_save_renderer/convert_plot/main.nf'   params(params)
include  { parse_header }  from  targetDir + '/civ6_save_renderer/parse_header/main.nf'   params(params)
include  { parse_map }     from  targetDir + '/civ6_save_renderer/parse_map/main.nf'      params(params)
include  { rename }        from  workflowDir + '/utils.nf'

workflow {

    if (params.debug == true)
        println(params)

    if (!params.containsKey("input") || !params.input || params.input == "") {
        exit 1, "ERROR: Please provide a --input parameter pointing to .Civ6Save file(s)"
    }
    if (!params.containsKey("publishDir") || !params.publishDir || params.publishDir == "") {
        exit 1, "ERROR: Please provide a --publishDir parameter pointing to the directory to store output"
    }

    def listToTriplet = { it -> [ "", it.collect{ a -> a[1] }, params ] }

    Channel.fromPath(params.input, checkIfExists: false)
        | map{ it -> [ it.baseName , it, params ] }
        | ( parse_header & parse_map )
        | join
        | map{ id, parse_headerOut, params1, parse_mapOut, params2 ->
            [ id, [ "yaml" : parse_headerOut, "tsv": parse_mapOut ], params1 ] }
        | plot_map
        | convert_plot
        | toSortedList{ a,b -> a[0] <=> b[0] }
        | map( listToTriplet )
        | combine_plots

}
