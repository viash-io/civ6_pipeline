nextflow.enable.dsl=2

workflowDir = params.rootDir + "/workflows"
targetDir = params.rootDir + "/target/nextflow"

include  { plot_map }      from  targetDir + '/civ6_save_renderer/plot_map/main.nf'       params(params)
include  { combine_plots } from  targetDir + '/civ6_save_renderer/combine_plots/main.nf'  params(params)
include  { convert_plot }  from  targetDir + '/civ6_save_renderer/convert_plot/main.nf'   params(params)
include  { parse_header }  from  targetDir + '/civ6_save_renderer/parse_header/main.nf'   params(params)
include  { parse_map }     from  targetDir + '/civ6_save_renderer/parse_map/main.nf'      params(params)

workflow {

    if (params.debug == true)
        println(params)

    if (!params.containsKey("input") || !params.input || params.input == "") {
        exit 1, "ERROR: Please provide a --input parameter pointing to .Civ6Save file(s)"
    }
    if (!params.containsKey("publishDir") || !params.publishDir || params.publishDir == "") {
        exit 1, "ERROR: Please provide a --publishDir parameter pointing to the directory to store output"
    }

    Channel.fromPath(params.input, checkIfExists: false)
        | map{ it -> [ it.baseName , [ input: it ] ] }
        | ( parse_header & parse_map )
        | join
        | plot_map.run(
            map: { id, data_parse_header, data_parse_map ->
                [ id, [ "yaml" : data_parse_header, "tsv": data_parse_map ] ] } )
        | convert_plot
        | toSortedList{ a,b -> a[0] <=> b[0] }
        | combine_plots.run(
            directives: [ publishDir: [ path: params.publishDir ] ],
            map: { tuples -> [ "final", [ input: tuples.collect{it[1] }, output: "final.webm" ] ] } )

}
