nextflow.enable.dsl=2

workflowDir = params.rootDir + "/workflows"
targetDir = params.rootDir + "/target/nextflow"

include  { plot_map }      from  targetDir + '/civ6_save_renderer/plot_map/main.nf'       params(params)
include  { combine_plots } from  targetDir + '/civ6_save_renderer/combine_plots/main.nf'  params(params)
include  { convert_plot }  from  targetDir + '/civ6_save_renderer/convert_plot/main.nf'   params(params)
include  { parse_header }  from  targetDir + '/civ6_save_renderer/parse_header/main.nf'   params(params)
include  { parse_map }     from  targetDir + '/civ6_save_renderer/parse_map/main.nf'      params(params)
include  { filterOutput }  from  targetDir + '/civ6_save_renderer/parse_header/main.nf'   params(params)
include  { filterLog as headerLog }  from  targetDir + '/civ6_save_renderer/parse_header/main.nf'   params(params)
include  { concat } from targetDir + '/markdown/concat/main.nf' params(params)
include  { overrideOptionValue } from workflowDir + "/utils.nf"

workflow {

    if (params.debug == true)
        println(params)

    if (!params.containsKey("input") || !params.input || params.input == "") {
        exit 1, "ERROR: Please provide a --input parameter pointing to .Civ6Save file(s)"
    }
    if (!params.containsKey("publishDir") || !params.publishDir || params.publishDir == "") {
        exit 1, "ERROR: Please provide a --publishDir parameter pointing to the directory to store output"
    }

    input_ = Channel.fromPath(params.input, checkIfExists: false)
        | map{ it -> [ it.baseName , it, params ] }

    parse_header_ = input_ | parse_header | filterOutput
    parse_map_    = input_ | parse_map

    parse_header_
        | join(parse_map_)
        | map{ id, data_parse_header, params1, data_parse_map, params2 ->
            [ id, [ "yaml" : data_parse_header, "tsv": data_parse_map ], params1 ] }
        | plot_map
        | convert_plot
        | toSortedList{ a,b -> a[0] <=> b[0] }
        | map{ tuples -> [ "final", tuples.collect{it[1]}, params ] }
        | combine_plots

    parse_header.out
        | headerLog
        | map{ it[1] }
        | toSortedList
        | map{ [ "doc", it, params ] }
        | map { overrideOptionValue(it, "concat", "header", "# Header for this report") }
        | concat

}
